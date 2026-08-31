import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/home/data/favorite_feature_controller.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('默认不显示任何拖动项，只有用户点击收藏后才加入', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();

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
    await restored.load();
    expect(restored.ids, ['second', 'first']);
    expect(restored.favoritesFrom([_item('first')]), hasLength(1));
  });

  test('移动到末尾时会保留不可见的旧收藏记录', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.manualFavoriteFeatureIds.v2': [
        'first',
        'removed',
        'second',
        'third',
      ],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();

    await controller.reorderVisible(['first', 'second', 'third'], 0, 3);

    expect(controller.ids, ['second', 'removed', 'third', 'first']);
  });

  test('Mock 收藏默认为空且与正常 QAS 隔离', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.manualFavoriteFeatureIds.v2': ['qas-favorite'],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();
    expect(controller.ids, ['qas-favorite']);

    controller.enableDevelopmentMockMode();
    expect(controller.ids, isEmpty);

    await controller.toggle('e-form');
    expect(controller.isFavorite('e-form'), isTrue);

    await controller.toggle('e-form');
    expect(controller.isFavorite('e-form'), isFalse);

    // Mock 操作只影响当前进程，不污染正常 QAS 收藏。
    final restored = FavoriteFeatureController(logger: AppLogger());
    await restored.load();
    expect(restored.ids, ['qas-favorite']);
  });

  test('Mock 主动收藏后第一项可以拖动排序', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();
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
      'merp.home.manualFavoriteFeatureIds.v2': [
        'first',
        '',
        'first',
        ' second ',
      ],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());

    await controller.load();

    expect(controller.ids, ['first', 'second']);
  });

  test('旧版自动收藏数据不会迁移到手动收藏和拖动区域', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.favoriteFeatureIds': ['existing'],
      'merp.home.favoriteFeatureDefaultsVersion': 1,
    });
    final controller = FavoriteFeatureController(logger: AppLogger());

    await controller.load();

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
