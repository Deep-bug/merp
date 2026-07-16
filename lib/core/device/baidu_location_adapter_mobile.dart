// -----------------------------------------------------------------------------
// 文件：baidu_location_adapter_mobile.dart
// 作用：实现百度 iOS/Android 最高精度单次定位、系统权限和定位服务检查
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
  static const _privacyCallReturnTimeout = Duration(milliseconds: 500);
  static const _startLocationTimeout = Duration(seconds: 5);
  static const _androidSuccessfulLocationTypes = {61, 66, 161};

  final AppLogger _logger;
  final LocationFlutterPlugin _plugin = LocationFlutterPlugin();
  bool _configured = false;

  @override
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> configure({required String apiKey}) async {
    if (_configured) {
      _logger.info('location', '百度定位 SDK 已配置，跳过重复配置');
      return;
    }

    // 百度定位 SDK 要求在调用其他 SDK API 前先设置隐私同意状态。
    _logger.info('location', '配置百度定位 SDK：设置隐私同意');
    final privacyConfigured = await _setAgreePrivacy();
    _logger.info(
      'location',
      '配置百度定位 SDK：隐私同意设置完成',
      fields: {'privacyConfigured': privacyConfigured},
    );
    // Android 定位 AK 由 Manifest 的 com.baidu.lbsapi.API_KEY 提供；
    // iOS 才支持运行时 authAK。
    _logger.info(
      'location',
      '配置百度定位 SDK：配置 AK',
      fields: {'platform': defaultTargetPlatform.name},
    );
    final keyConfigured = defaultTargetPlatform == TargetPlatform.android
        ? true
        : await _plugin.authAK(apiKey);
    _logger.info(
      'location',
      '配置百度定位 SDK：AK 配置完成',
      fields: {'keyConfigured': keyConfigured},
    );
    _logger.info('location', '配置百度定位 SDK：写入定位参数');
    final optionsConfigured = await _plugin.prepareLoc(
      BaiduLocationAndroidOption(
        coorType: 'bd09ll',
        coordType: BMFLocationCoordType.bd09ll,
        locationMode: BMFLocationMode.hightAccuracy,
        locationPurpose: BMFLocationPurpose.signIn,
        isNeedAddress: true,
        isNeedAltitude: true,
        isNeedLocationPoiList: false,
        isNeedNewVersionRgc: true,
        isNeedLocationDescribe: true,
        openGps: true,
        scanspan: 0,
      ).getMap(),
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
    _logger.info(
      'location',
      '配置百度定位 SDK：定位参数写入完成',
      fields: {'optionsConfigured': optionsConfigured},
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
    _logger.info('location', '百度精确定位 SDK 已按需初始化');
  }

  Future<bool> _setAgreePrivacy() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _plugin.setAgreePrivacy(true);
    }

    // flutter_bmflocation 3.8.4 的 Android setAgreePrivacy 原生方法会同步调用
    // LocationClient.setAgreePrivacy(true)，但没有向 MethodChannel 返回结果。
    // 因此这里短暂等待后继续，避免定位按钮永久 loading。
    return _plugin
        .setAgreePrivacy(true)
        .timeout(
          _privacyCallReturnTimeout,
          onTimeout: () {
            _logger.warning(
              'location',
              'Android 百度定位隐私同意调用未返回，按插件兼容逻辑继续',
              fields: {'timeoutMs': _privacyCallReturnTimeout.inMilliseconds},
            );
            return true;
          },
        );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    _logger.info('location', '调用 permission_handler 检查系统定位服务');
    final status = await permissions.Permission.locationWhenInUse.serviceStatus;
    _logger.info(
      'location',
      'permission_handler 系统定位服务返回',
      fields: {'status': status.name, 'isEnabled': status.isEnabled},
    );
    return status.isEnabled;
  }

  @override
  Future<LocationPermissionState> requestWhenInUsePermission() async {
    _logger.info('location', '读取前台定位权限状态');
    var status = await permissions.Permission.locationWhenInUse.status;
    _logger.info('location', '当前前台定位权限状态', fields: {'status': status.name});
    if (status.isDenied) {
      // 这是唯一会触发系统权限弹窗的位置，只能由明确的用户操作调用。
      _logger.info('location', '开始请求前台定位权限');
      status = await permissions.Permission.locationWhenInUse.request();
      _logger.info('location', '前台定位权限请求返回', fields: {'status': status.name});
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
    _logger.info(
      'location',
      '百度定位适配器开始定位',
      fields: {
        'timeoutSeconds': timeout.inSeconds,
        'maximumAttempts': _maximumAttempts,
        'maximumAccuracyMeters': maximumAccuracyMeters,
      },
    );
    final deadline = DateTime.now().add(timeout);
    AppLocation? lastLocation;

    for (var attempt = 1; attempt <= _maximumAttempts; attempt++) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _logger.warning(
          'location',
          '百度定位适配器剩余时间不足，停止重试',
          fields: {'attempt': attempt},
        );
        break;
      }
      _logger.info(
        'location',
        '百度定位适配器开始单次请求',
        fields: {'attempt': attempt, 'remainingMs': remaining.inMilliseconds},
      );
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
        _logger.info(
          'location',
          '百度定位候选结果满足精度要求',
          fields: {'attempt': attempt},
        );
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
    final stopwatch = Stopwatch()..start();
    final completer = Completer<AppLocation>();
    _logger.info(
      'location',
      '注册百度单次定位回调',
      fields: {'timeoutMs': timeout.inMilliseconds},
    );
    _plugin.singleLocationCallback(
      callback: (result) {
        _logger.info(
          'location',
          '收到百度定位原始回调',
          fields: {
            'elapsedMs': stopwatch.elapsedMilliseconds,
            'errorCode': result.errorCode,
            'hasLatitude': result.latitude != null,
            'hasLongitude': result.longitude != null,
            'radius': result.radius,
            'horizontalAccuracy': result.horizontalAccuracy,
          },
        );
        if (completer.isCompleted) {
          _logger.warning('location', '百度定位回调到达时 Future 已完成，忽略该回调');
          return;
        }
        try {
          completer.complete(_convertResult(result));
        } catch (error, stackTrace) {
          _logger.warning(
            'location',
            '百度定位回调结果转换失败',
            error: error,
            stackTrace: stackTrace,
          );
          completer.completeError(error, stackTrace);
        } finally {
          if (defaultTargetPlatform == TargetPlatform.android) {
            _logger.info('location', 'Android 百度定位回调后停止定位');
            unawaited(_plugin.stopLocation());
          }
        }
      },
    );

    _logger.info(
      'location',
      '调用百度 singleLocation/startSeriesLocation',
      fields: {'startTimeoutMs': _startLocationTimeout.inMilliseconds},
    );
    final started = await _plugin
        .singleLocation({'isReGeocode': true, 'isNetworkState': true})
        .timeout(
          _startLocationTimeout,
          onTimeout: () {
            _logger.warning(
              'location',
              '百度 singleLocation/startSeriesLocation 启动超时',
              fields: {'elapsedMs': stopwatch.elapsedMilliseconds},
            );
            return false;
          },
        );
    _logger.info(
      'location',
      '百度 singleLocation/startSeriesLocation 返回',
      fields: {'started': started, 'elapsedMs': stopwatch.elapsedMilliseconds},
    );
    if (!started) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _logger.info('location', '百度定位启动失败后停止 Android 定位');
        unawaited(_plugin.stopLocation());
      }
      throw const AppLocationException(
        LocationFailureCode.sdkFailure,
        '百度定位服务启动失败',
      );
    }

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _logger.warning(
            'location',
            '等待百度定位回调超时',
            fields: {'elapsedMs': stopwatch.elapsedMilliseconds},
          );
          throw const AppLocationException(
            LocationFailureCode.timeout,
            '定位超时，请检查网络和定位服务后重试',
          );
        },
      );
    } on TimeoutException {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _logger.info('location', '百度定位回调超时后停止 Android 定位');
        unawaited(_plugin.stopLocation());
      }
      throw const AppLocationException(
        LocationFailureCode.timeout,
        '定位超时，请检查网络和定位服务后重试',
      );
    }
  }

  AppLocation _convertResult(BaiduLocation result) {
    final errorCode = result.errorCode;
    final isSuccessfulAndroidType =
        defaultTargetPlatform == TargetPlatform.android &&
        errorCode != null &&
        _androidSuccessfulLocationTypes.contains(errorCode);
    if (errorCode != null && errorCode != 0 && !isSuccessfulAndroidType) {
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
