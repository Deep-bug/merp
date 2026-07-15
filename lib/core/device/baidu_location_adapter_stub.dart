// -----------------------------------------------------------------------------
// 文件：baidu_location_adapter_stub.dart
// 作用：为 Web 等不支持百度原生定位插件的平台提供安全占位实现
// 编写时间：2026-07-15
// 维护说明：此文件不得导入 dart:io 或原生定位插件，保证 Web 可编译
// -----------------------------------------------------------------------------

import '../logging/app_logger.dart';
import 'location_adapter.dart';
import 'location_models.dart';

LocationAdapter createBaiduLocationAdapter(AppLogger logger) {
  return const _UnsupportedLocationAdapter();
}

class _UnsupportedLocationAdapter implements LocationAdapter {
  const _UnsupportedLocationAdapter();

  @override
  bool get isSupportedPlatform => false;

  @override
  Future<void> configure({required String apiKey}) async {}

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<AppLocation> locateOnce({
    required Duration timeout,
    required double maximumAccuracyMeters,
  }) {
    throw const AppLocationException(
      LocationFailureCode.unsupportedPlatform,
      '当前平台不支持原生精确定位',
    );
  }

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<LocationPermissionState> requestWhenInUsePermission() async {
    return LocationPermissionState.denied;
  }
}
