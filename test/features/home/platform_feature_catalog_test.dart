import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/features/home/data/mock_user_feature_permissions.dart';
import 'package:merp/features/home/data/platform_feature_catalog.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:merp/routing/app_routes.dart';

void main() {
  const config = AppConfig(
    electronicFormUrl: 'https://qas.example/e-form',
    assetInventoryUrl: 'https://qas.example/assets',
  );
  final features = PlatformFeatureCatalog(config).features;

  test('platform catalog is typed, stable and free of duplicate ids', () {
    expect(features, hasLength(25));
    expect(features.map((item) => item.id).toSet(), hasLength(features.length));
    expect(features.every((item) => item.title.trim().isNotEmpty), isTrue);
    expect(features.every((item) => item.group.trim().isNotEmpty), isTrue);
    expect(
      features.every((item) => item.permissionCode.trim().isNotEmpty),
      isTrue,
    );
    expect(
      features.every((item) => item.route == '/legacy/${item.id}'),
      isTrue,
    );
    expect(
      features.every((item) => item.launchMode == FeatureLaunchMode.legacyWeb),
      isTrue,
    );
    expect(
      features.every((item) => item.legacyPath?.trim().isNotEmpty ?? false),
      isTrue,
    );
    expect(
      {
        for (final group in ['Marketing', 'Sales', 'Customer Service', 'Admin'])
          group: features.where((item) => item.group == group).length,
      },
      {'Marketing': 2, 'Sales': 12, 'Customer Service': 6, 'Admin': 5},
    );
  });

  test('environment configured H5 targets are resolved by the catalog', () {
    expect(
      features.singleWhere((item) => item.id == 'e-form').legacyPath,
      'https://qas.example/e-form',
    );
    expect(
      features.singleWhere((item) => item.id == 'asset-inventory').legacyPath,
      'https://qas.example/assets',
    );
  });

  test('legacy server aliases map to canonical platform ids and icons', () {
    expect(
      PlatformFeatureCatalog.platformIdForServerCode('wechat-eform'),
      'e-form',
    );
    expect(
      PlatformFeatureCatalog.platformIdForServerCode(' WECHAT-SALESREPORT '),
      'sales-report',
    );
    expect(
      PlatformFeatureCatalog.platformIdForServerCode('customer'),
      'customer',
    );
    expect(PlatformFeatureCatalog.platformIdForServerCode('unknown'), isNull);
    expect(
      PlatformFeatureCatalog.iconForCode('wechat-csinventory'),
      Icons.other_houses_outlined,
    );
  });

  test(
    'native capabilities are allowlisted separately from catalog entries',
    () {
      expect(features.map((item) => item.id), isNot(contains('map-location')));
      expect(
        PlatformFeatureCatalog.nativeRouteFor('map-location'),
        AppRoute.map,
      );
      expect(PlatformFeatureCatalog.nativeRouteFor('server-injected'), isNull);
    },
  );

  test(
    'default Mock user authorization is explicit and currently complete',
    () {
      final catalogIds = features.map((item) => item.id).toSet();
      expect(MockUserFeaturePermissions.fullAccessIds, catalogIds);
    },
  );
}
