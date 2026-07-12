// -----------------------------------------------------------------------------
// 文件：location_service.dart
// 作用：定义统一定位结果并隔离未来地图厂商插件实现
// 编写时间：2026-07-10
// 维护说明：Bridge 和原生业务页只依赖 AppLocation
// -----------------------------------------------------------------------------

import '../config/app_config.dart';

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

class LocationService {
  LocationService({required AppConfig config}) : _config = config;

  final AppConfig _config;

  Future<AppLocation> locateOnce() {
    // 地图 SDK 未接入前只保留业务接口，页面和业务层不直接依赖第三方插件类型。
    // 后续接入百度/高德/腾讯时，在这里把插件返回值转换成 AppLocation。
    throw MapSdkNotConfiguredException(
      '地图定位 SDK 尚未接入，请先在 AppConfig 填写密钥并实现 LocationService。',
      provider: _config.mapProvider,
    );
  }
}

class MapSdkNotConfiguredException implements Exception {
  const MapSdkNotConfiguredException(this.message, {required this.provider});

  final String message;
  final String provider;

  @override
  String toString() => '$message provider=$provider';
}
