import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/auth/user_data_scope.dart';
import 'package:merp/features/home/data/favorite_feature_controller.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserDataScope _scope(String user, [String environment = 'qas']) =>
    UserDataScope.fromProfile(
      environment,
      UserProfile(
        id: user,
        accountName: user,
        displayName: user,
        department: '',
      ),
    )!;

void main() {
  test('快速收藏和排序按提交顺序持久化', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('a'));
    final first = controller.toggle('first');
    final second = controller.toggle('second');
    final reorder = controller.reorderVisible(['first', 'second'], 1, 0);
    await Future.wait([first, second, reorder]);
    final restored = FavoriteFeatureController(logger: AppLogger());
    await restored.activateScope(_scope('a'));
    expect(restored.ids, ['second', 'first']);
  });

  test('收藏存储初始化失败后可以重试当前用户', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final controller = FavoriteFeatureController(
      logger: AppLogger(),
      preferencesProvider: () {
        if (++calls == 1) return Future.error(StateError('temporary failure'));
        return SharedPreferences.getInstance();
      },
    );
    await controller.activateScope(_scope('a'));
    expect(controller.isReady, isFalse);
    await controller.activateScope(_scope('a'));
    expect(controller.isReady, isTrue);
    await controller.toggle('first');
    expect(controller.ids, ['first']);
  });

  test('收藏按账号和环境隔离，退出不删除本人记录', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('a'));
    await controller.toggle('e-form');
    controller.clearActiveScope();
    expect(controller.ids, isEmpty);
    await controller.activateScope(_scope('b'));
    expect(controller.ids, isEmpty);
    await controller.toggle('my-task');
    await controller.activateScope(_scope('a', 'prd'));
    expect(controller.ids, isEmpty);
    await controller.activateScope(_scope('a'));
    expect(controller.ids, ['e-form']);
    await controller.activateScope(_scope('b'));
    expect(controller.ids, ['my-task']);
  });

  test('全局 v2 收藏不认领给新用户，原数据仍保留', () async {
    const legacyKey = 'merp.home.manualFavoriteFeatureIds.v2';
    SharedPreferences.setMockInitialValues({
      legacyKey: ['private-feature'],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();
    await controller.toggle('ignored-before-login');
    expect(controller.ids, isEmpty);
    await controller.activateScope(_scope('a'));
    expect(controller.ids, isEmpty);
    expect((await SharedPreferences.getInstance()).getStringList(legacyKey), [
      'private-feature',
    ]);
  });

  test('延迟加载的 A 用户数据不能覆盖 B 用户', () async {
    SharedPreferences.setMockInitialValues({
      FavoriteFeatureController.storageKeyFor(_scope('a')): ['a-only'],
      FavoriteFeatureController.storageKeyFor(_scope('b')): ['b-only'],
    });
    final ready = Completer<SharedPreferences>();
    final controller = FavoriteFeatureController(
      logger: AppLogger(),
      preferencesProvider: () => ready.future,
    );
    final loadingA = controller.activateScope(_scope('a'));
    final loadingB = controller.activateScope(_scope('b'));
    ready.complete(await SharedPreferences.getInstance());
    await Future.wait([loadingA, loadingB]);
    expect(controller.ids, ['b-only']);
  });

  test('保存期间退出和切换账号，不把 A 收藏写给 B', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('a'));
    final saving = controller.toggle('a-only');
    controller.clearActiveScope();
    await controller.activateScope(_scope('b'));
    await saving;
    expect(controller.ids, isEmpty);
    await controller.activateScope(_scope('a'));
    expect(controller.ids, ['a-only']);
  });

  test('退出后未完成的加载不能重新展示收藏', () async {
    SharedPreferences.setMockInitialValues({
      FavoriteFeatureController.storageKeyFor(_scope('a')): ['a-only'],
    });
    final ready = Completer<SharedPreferences>();
    final controller = FavoriteFeatureController(
      logger: AppLogger(),
      preferencesProvider: () => ready.future,
    );
    final loading = controller.activateScope(_scope('a'));
    controller.clearActiveScope();
    ready.complete(await SharedPreferences.getInstance());
    await loading;
    expect(controller.ids, isEmpty);
    expect(controller.isReady, isFalse);
  });

  test('默认不显示任何拖动项，只有用户点击收藏后才加入', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('user-a'));

    expect(controller.ids, isEmpty);
    expect(
      controller.favoritesFrom([_item('first'), _item('second')]),
      isEmpty,
    );

    await controller.toggle('first');
    expect(
      controller
          .favoritesFrom([_item('first'), _item('second')])
          .map((item) => item.id),
      ['first'],
    );

    await controller.toggle('second');
    await controller.reorderVisible(['first', 'second'], 1, 0);

    expect(controller.ids, ['second', 'first']);
    final restored = FavoriteFeatureController(logger: AppLogger());
    await restored.activateScope(_scope('user-a'));
    expect(restored.ids, ['second', 'first']);
    expect(restored.favoritesFrom([_item('first')]), hasLength(1));
  });

  test('移动到末尾时会保留不可见的旧收藏记录', () async {
    SharedPreferences.setMockInitialValues({
      FavoriteFeatureController.storageKeyFor(_scope('user-a')): [
        'first',
        'removed',
        'second',
        'third',
      ],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('user-a'));

    await controller.reorderVisible(['first', 'second', 'third'], 0, 3);

    expect(controller.ids, ['second', 'removed', 'third', 'first']);
  });

  test('Mock 收藏默认为空且与正常 QAS 隔离', () async {
    SharedPreferences.setMockInitialValues({
      FavoriteFeatureController.storageKeyFor(_scope('user-a')): [
        'qas-favorite',
      ],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('user-a'));
    expect(controller.ids, ['qas-favorite']);

    controller.enableDevelopmentMockMode();
    expect(controller.ids, isEmpty);

    await controller.toggle('e-form');
    expect(controller.isFavorite('e-form'), isTrue);

    await controller.toggle('e-form');
    expect(controller.isFavorite('e-form'), isFalse);

    // Mock 操作只影响当前进程，不污染正常 QAS 收藏。
    final restored = FavoriteFeatureController(logger: AppLogger());
    await restored.activateScope(_scope('user-a'));
    expect(restored.ids, ['qas-favorite']);
  });

  test('Mock 主动收藏后第一项可以拖动排序', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.activateScope(_scope('user-a'));
    controller.enableDevelopmentMockMode();
    await controller.toggle('e-form');
    await controller.toggle('my-task');
    await controller.toggle('service-dispatch');
    final originalIds = List<String>.of(controller.ids);

    await controller.reorderVisible(originalIds, 0, 2);

    expect(controller.ids, ['my-task', 'service-dispatch', 'e-form']);
  });

  test('加载时会清除空值和重复功能 id', () async {
    SharedPreferences.setMockInitialValues({
      FavoriteFeatureController.storageKeyFor(_scope('user-a')): [
        'first',
        '',
        'first',
        ' second ',
      ],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());

    await controller.activateScope(_scope('user-a'));

    expect(controller.ids, ['first', 'second']);
  });

  test('旧版自动收藏数据不会迁移到手动收藏和拖动区域', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.favoriteFeatureIds': ['existing'],
      'merp.home.favoriteFeatureDefaultsVersion': 1,
    });
    final controller = FavoriteFeatureController(logger: AppLogger());

    await controller.activateScope(_scope('user-a'));

    expect(controller.ids, isEmpty);
  });
}

FeatureItem _item(String id) => FeatureItem(
  id: id,
  title: id,
  description: '',
  icon: Icons.apps_outlined,
  permissionCode: id,
  launchMode: FeatureLaunchMode.native,
  route: '/$id',
);
