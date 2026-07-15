// -----------------------------------------------------------------------------
// 文件：location_models.dart
// 作用：定义地图页与 Vue Bridge 共用的定位结果、权限状态和统一错误码
// 编写时间：2026-07-15
// 维护说明：坐标属于敏感数据，不得写入日志或未授权持久化存储
// -----------------------------------------------------------------------------

enum LocationPermissionState { granted, denied, permanentlyDenied, restricted }

enum LocationFailureCode {
  unsupportedPlatform('LOCATION_UNSUPPORTED_PLATFORM'),
  privacyRequired('LOCATION_PRIVACY_REQUIRED'),
  keyMissing('LOCATION_KEY_MISSING'),
  serviceDisabled('LOCATION_SERVICE_DISABLED'),
  permissionDenied('LOCATION_PERMISSION_DENIED'),
  permissionPermanentlyDenied('LOCATION_PERMISSION_PERMANENTLY_DENIED'),
  timeout('LOCATION_TIMEOUT'),
  insufficientAccuracy('LOCATION_ACCURACY_INSUFFICIENT'),
  sdkFailure('LOCATION_SDK_FAILED');

  const LocationFailureCode(this.value);

  final String value;
}

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.coordinateType = 'bd09ll',
    this.provider = 'baidu',
    this.altitude,
    this.address,
    this.city,
    this.district,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final String coordinateType;
  final String provider;
  final double? altitude;
  final String? address;
  final String? city;
  final String? district;

  Map<String, Object?> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      // 兼容旧 Vue 页面常用字段名。
      'accuracy': accuracyMeters,
      'coordinateType': coordinateType,
      'provider': provider,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'altitude': ?altitude,
      'address': ?address,
      'city': ?city,
      'district': ?district,
    };
  }
}

class AppLocationException implements Exception {
  const AppLocationException(
    this.code,
    this.message, {
    this.details = const {},
  });

  final LocationFailureCode code;
  final String message;
  final Map<String, Object?> details;

  bool get canOpenSettings =>
      code == LocationFailureCode.permissionPermanentlyDenied ||
      code == LocationFailureCode.serviceDisabled ||
      code == LocationFailureCode.insufficientAccuracy;

  @override
  String toString() => '${code.value}: $message';
}
