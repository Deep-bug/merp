// -----------------------------------------------------------------------------
// 文件：map_sdk_service_test.dart
// 作用：验证百度地图平台、密钥和隐私同意状态的前置判断
// 编写时间：2026-07-15
// 维护说明：单元测试不得调用真实百度 SDK 或包含生产 AK
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/device/map_sdk_service.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS map reports configured only when a Baidu AK is injected', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final configured = MapSdkService(
      config: const AppConfig(iosMapApiKey: 'test-ios-ak'),
      logger: AppLogger(),
    );
    final missing = MapSdkService(
      config: const AppConfig(iosMapApiKey: ''),
      logger: AppLogger(),
    );

    expect(configured.isIosSupported, isTrue);
    expect(configured.isConfigured, isTrue);
    expect(missing.isConfigured, isFalse);
  });

  test(
    'reads the versioned local privacy consent without activating SDK',
    () async {
      SharedPreferences.setMockInitialValues({
        'merp.baidu_sdk.privacy_accepted.v1': true,
      });
      final service = MapSdkService(
        config: const AppConfig(iosMapApiKey: 'test-ios-ak'),
        logger: AppLogger(),
      );

      expect(await service.hasPrivacyConsent(), isTrue);
      expect(service.isActivated, isFalse);
    },
  );
}
