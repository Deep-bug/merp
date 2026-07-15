// -----------------------------------------------------------------------------
// 文件：baidu_location_adapter_mobile.dart
// 作用：实现百度 iOS 最高精度单次定位、系统权限和定位服务检查
// 编写时间：2026-07-15
// 维护说明：仅在业务调用时触发权限；日志严禁记录经纬度和完整地址
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../logging/app_logger.dart';
import 'location_adapter.dart';
import 'location_models.dart';

LocationAdapter createBaiduLocationAdapter(AppLogger logger) {
  return BaiduLocationAdapter(logger: logger);
}

class BaiduLocationAdapter implements LocationAdapter {
  BaiduLocationAdapter({required AppLogger logger}) : _logger = logger;

  static const _maximumAttempts = 3;

  final AppLogger _logger;
  final LocationFlutterPlugin _plugin = LocationFlutterPlugin();
  bool _configured = false;

  @override
  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> configure({required String apiKey}) async {
    if (_configured) {
      return;
    }

    // 百度定位 SDK 要求在调用其他 SDK API 前先设置隐私同意状态。
    final privacyConfigured = await _plugin.setAgreePrivacy(true);
    final keyConfigured = await _plugin.authAK(apiKey);
    final optionsConfigured = await _plugin.prepareLoc(
      const <String, Object?>{},
      BaiduLocationIOSOption(
        coordType: BMFLocationCoordType.bd09ll,
        desiredAccuracy: BMFDesiredAccuracy.bestForNavigation,
        activityType: BMFActivityType.otherNavigation,
        distanceFilter: 0,
        locationTimeout: 15,
        reGeocodeTimeout: 10,
        isNeedNewVersionRgc: true,
        allowsBackgroundLocationUpdates: false,
        pausesLocationUpdatesAutomatically: true,
      ).getMap(),
    );

    if (!privacyConfigured || !keyConfigured || !optionsConfigured) {
      throw AppLocationException(
        LocationFailureCode.sdkFailure,
        '百度定位 SDK 初始化失败',
        details: {
          'privacyConfigured': privacyConfigured,
          'keyConfigured': keyConfigured,
          'optionsConfigured': optionsConfigured,
        },
      );
    }
    _configured = true;
    _logger.info('location', '百度 iOS 精确定位 SDK 已按需初始化');
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    final status = await permissions.Permission.locationWhenInUse.serviceStatus;
    return status.isEnabled;
  }

  @override
  Future<LocationPermissionState> requestWhenInUsePermission() async {
    var status = await permissions.Permission.locationWhenInUse.status;
    if (status.isDenied) {
      // 这是唯一会触发系统权限弹窗的位置，只能由明确的用户操作调用。
      status = await permissions.Permission.locationWhenInUse.request();
    }
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return LocationPermissionState.restricted;
    }
    return LocationPermissionState.denied;
  }

  @override
  Future<AppLocation> locateOnce({
    required Duration timeout,
    required double maximumAccuracyMeters,
  }) async {
    final deadline = DateTime.now().add(timeout);
    AppLocation? lastLocation;

    for (var attempt = 1; attempt <= _maximumAttempts; attempt++) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        break;
      }
      final location = await _requestSingleLocation(remaining);
      lastLocation = location;
      _logger.debug(
        'location',
        '收到定位候选结果',
        fields: {
          'attempt': attempt,
          'accuracyMeters': location.accuracyMeters,
          'meetsRequiredAccuracy':
              location.accuracyMeters <= maximumAccuracyMeters,
        },
      );
      if (location.accuracyMeters <= maximumAccuracyMeters) {
        return location;
      }
    }

    if (lastLocation != null) {
      throw AppLocationException(
        LocationFailureCode.insufficientAccuracy,
        '当前定位精度不足，请移动到开阔位置后重试',
        details: {
          'actualAccuracyMeters': lastLocation.accuracyMeters,
          'requiredAccuracyMeters': maximumAccuracyMeters,
        },
      );
    }
    throw const AppLocationException(
      LocationFailureCode.timeout,
      '定位超时，请检查网络和定位服务后重试',
    );
  }

  Future<AppLocation> _requestSingleLocation(Duration timeout) async {
    final completer = Completer<AppLocation>();
    _plugin.singleLocationCallback(
      callback: (result) {
        if (completer.isCompleted) {
          return;
        }
        try {
          completer.complete(_convertResult(result));
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    final started = await _plugin.singleLocation({
      'isReGeocode': true,
      'isNetworkState': true,
    });
    if (!started) {
      throw const AppLocationException(
        LocationFailureCode.sdkFailure,
        '百度定位服务启动失败',
      );
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () => throw const AppLocationException(
        LocationFailureCode.timeout,
        '定位超时，请检查网络和定位服务后重试',
      ),
    );
  }

  AppLocation _convertResult(BaiduLocation result) {
    final errorCode = result.errorCode;
    if (errorCode != null && errorCode != 0) {
      throw AppLocationException(
        LocationFailureCode.sdkFailure,
        result.errorInfo?.trim().isNotEmpty == true
            ? result.errorInfo!.trim()
            : '百度定位失败',
        details: {'sdkErrorCode': errorCode},
      );
    }

    final latitude = result.latitude;
    final longitude = result.longitude;
    final accuracy = result.horizontalAccuracy ?? result.radius;
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        !accuracy.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        accuracy < 0) {
      throw const AppLocationException(
        LocationFailureCode.sdkFailure,
        '定位 SDK 返回了无效坐标或精度数据',
      );
    }

    return AppLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      altitude: result.altitude,
      address: _nonEmpty(result.address) ?? _nonEmpty(result.locationDetail),
      city: _nonEmpty(result.city),
      district: _nonEmpty(result.district),
      timestamp: DateTime.now(),
    );
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  Future<bool> openAppSettings() => permissions.openAppSettings();
}
