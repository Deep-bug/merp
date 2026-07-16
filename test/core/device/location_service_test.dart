// -----------------------------------------------------------------------------
// 文件：location_service_test.dart
// 作用：验证定位权限只在业务调用时申请，并校验隐私、精度与拒绝错误码
// 编写时间：2026-07-15
// 维护说明：测试使用假适配器，禁止连接真实定位 SDK 或保存真实坐标
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/device/location_adapter.dart';
import 'package:merp/core/device/location_service.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'does not touch SDK or request permission before user consent',
    () async {
      final adapter = _FakeLocationAdapter();
      final service = LocationService(
        config: const AppConfig(
          androidMapApiKey: 'test-android-ak',
          iosMapApiKey: 'test-ios-ak',
        ),
        logger: AppLogger(),
        adapter: adapter,
      );

      expect(adapter.configureCalls, 0);
      expect(adapter.permissionRequests, 0);

      await expectLater(
        service.locateOnce(),
        throwsA(
          isA<AppLocationException>().having(
            (error) => error.code,
            'code',
            LocationFailureCode.privacyRequired,
          ),
        ),
      );
      expect(adapter.configureCalls, 0);
      expect(adapter.permissionRequests, 0);
    },
  );

  test(
    'requests when-in-use permission only during explicit locate call',
    () async {
      final adapter = _FakeLocationAdapter();
      final service = LocationService(
        config: const AppConfig(
          androidMapApiKey: 'test-android-ak',
          iosMapApiKey: 'test-ios-ak',
        ),
        logger: AppLogger(),
        adapter: adapter,
      );
      await service.acceptPrivacyConsent();

      expect(adapter.permissionRequests, 0);
      final result = await service.locateOnce(maximumAccuracyMeters: 50);

      expect(adapter.configureCalls, 1);
      expect(adapter.permissionRequests, 1);
      expect(adapter.locateCalls, 1);
      expect(result.accuracyMeters, 12);
      expect(result.coordinateType, 'bd09ll');
    },
  );

  test('maps permanent denial to a recoverable settings error', () async {
    final adapter = _FakeLocationAdapter(
      permissionState: LocationPermissionState.permanentlyDenied,
    );
    final service = LocationService(
      config: const AppConfig(
        androidMapApiKey: 'test-android-ak',
        iosMapApiKey: 'test-ios-ak',
      ),
      logger: AppLogger(),
      adapter: adapter,
    );
    await service.acceptPrivacyConsent();

    await expectLater(
      service.locateOnce(),
      throwsA(
        isA<AppLocationException>()
            .having(
              (error) => error.code,
              'code',
              LocationFailureCode.permissionPermanentlyDenied,
            )
            .having(
              (error) => error.canOpenSettings,
              'canOpenSettings',
              isTrue,
            ),
      ),
    );
    expect(adapter.locateCalls, 0);
  });
}

class _FakeLocationAdapter implements LocationAdapter {
  _FakeLocationAdapter({
    this.permissionState = LocationPermissionState.granted,
  });

  final LocationPermissionState permissionState;
  int configureCalls = 0;
  int permissionRequests = 0;
  int locateCalls = 0;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<void> configure({required String apiKey}) async {
    configureCalls++;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermissionState> requestWhenInUsePermission() async {
    permissionRequests++;
    return permissionState;
  }

  @override
  Future<AppLocation> locateOnce({
    required Duration timeout,
    required double maximumAccuracyMeters,
  }) async {
    locateCalls++;
    return AppLocation(
      latitude: 39.9,
      longitude: 116.4,
      accuracyMeters: 12,
      timestamp: DateTime.utc(2026, 7, 15),
    );
  }

  @override
  Future<bool> openAppSettings() async => true;
}
