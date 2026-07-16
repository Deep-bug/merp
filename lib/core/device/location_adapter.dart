// -----------------------------------------------------------------------------
// 文件：location_adapter.dart
// 作用：定义定位厂商适配协议，使业务层不依赖百度插件类型
// 编写时间：2026-07-15
// 维护说明：更换定位厂商时新增适配器，不修改地图页与 Vue Bridge 协议
// -----------------------------------------------------------------------------

import 'location_models.dart';

abstract interface class LocationAdapter {
  bool get isSupportedPlatform;

  Future<void> configure({required String apiKey});

  Future<bool> isLocationServiceEnabled();

  Future<LocationPermissionState> requestWhenInUsePermission();

  Future<AppLocation> locateOnce({
    required Duration timeout,
    required double maximumAccuracyMeters,
  });

  Future<bool> openAppSettings();
}
