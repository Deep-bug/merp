import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/home/data/favorite_feature_controller.dart';
import 'package:merp/features/home/data/mock_feature_menu.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('收藏和排序会持久保存，并忽略已不存在的功能', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();

    await controller.toggle('first');
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
      'merp.home.favoriteFeatureIds': ['first', 'removed', 'second', 'third'],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());
    await controller.load();

    await controller.reorderVisible(['first', 'second', 'third'], 0, 3);

    expect(controller.ids, ['second', 'removed', 'third', 'first']);
  });

  test('加载时会清除空值和重复功能 id', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.favoriteFeatureIds': ['first', '', 'first', ' second '],
    });
    final controller = FavoriteFeatureController(logger: AppLogger());

    await controller.load();

    expect(controller.ids, ['first', 'second']);
  });

  test('旧版首页应用默认顺序会一次性合并到已有收藏', () async {
    SharedPreferences.setMockInitialValues({
      'merp.home.favoriteFeatureIds': ['existing'],
    });
    final controller = FavoriteFeatureController(
      logger: AppLogger(),
      defaultIds: MockFeatureMenu.defaultFavoriteIds,
      defaultIdsVersion: 1,
    );

    await controller.load();

    expect(controller.ids.first, 'existing');
    expect(controller.ids.skip(1), MockFeatureMenu.defaultFavoriteIds);
    expect(controller.ids, hasLength(20));
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
