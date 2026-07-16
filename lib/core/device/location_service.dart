// -----------------------------------------------------------------------------
// 文件：location_service.dart
// 作用：编排百度定位隐私、配置、按需权限、精度门槛和统一错误处理
// 编写时间：2026-07-15
// 维护说明：应用启动阶段不得调用 locateOnce，定位必须由用户明确操作触发
// -----------------------------------------------------------------------------

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'baidu_location_adapter_stub.dart'
    if (dart.library.io) 'baidu_location_adapter_mobile.dart';
import 'baidu_privacy_consent_store.dart';
import 'location_adapter.dart';
import 'location_models.dart';

export 'location_models.dart';

class LocationService {
  LocationService({
    required AppConfig config,
    required AppLogger logger,
    BaiduPrivacyConsentStore privacyConsentStore =
        const BaiduPrivacyConsentStore(),
    LocationAdapter? adapter,
  }) : _config = config,
       _logger = logger,
       _privacyConsentStore = privacyConsentStore,
       _adapter = adapter ?? createBaiduLocationAdapter(logger);

  final AppConfig _config;
  final AppLogger _logger;
  final BaiduPrivacyConsentStore _privacyConsentStore;
  final LocationAdapter _adapter;
  Future<AppLocation>? _inFlight;

  bool get isSupportedPlatform => _adapter.isSupportedPlatform;

  bool get isConfigured => _currentPlatformApiKey.trim().isNotEmpty;

  String get _currentPlatformApiKey {
    if (kIsWeb) {
      return _config.webMapApiKey;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _config.androidMapApiKey,
      TargetPlatform.iOS => _config.iosMapApiKey,
      _ =>
        _config.iosMapApiKey.trim().isNotEmpty
            ? _config.iosMapApiKey
            : _config.androidMapApiKey,
    };
  }

  Future<bool> hasPrivacyConsent() => _privacyConsentStore.hasConsent();

  Future<void> acceptPrivacyConsent() => _privacyConsentStore.accept();

  /// 执行一次满足业务精度门槛的定位。
  ///
  /// 同一时刻的多个 Vue/Flutter 调用共享一个原生定位请求，避免并发弹权限框或
  /// 多次启动定位 SDK。默认要求误差不超过 100 米，调用方可按业务提高门槛。
  Future<AppLocation> locateOnce({
    Duration timeout = const Duration(seconds: 25),
    double maximumAccuracyMeters = 100,
  }) {
    final active = _inFlight;
    if (active != null) {
      _logger.info('location', '复用进行中的定位请求');
      return active;
    }
    _logger.info(
      'location',
      '创建新的定位请求',
      fields: {
        'timeoutSeconds': timeout.inSeconds,
        'maximumAccuracyMeters': maximumAccuracyMeters,
      },
    );
    final future = _locateOnce(
      timeout: timeout,
      maximumAccuracyMeters: maximumAccuracyMeters,
    );
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _logger.info('location', '定位请求结束，清理 in-flight 状态');
        _inFlight = null;
      }
    });
  }

  Future<AppLocation> _locateOnce({
    required Duration timeout,
    required double maximumAccuracyMeters,
  }) async {
    _logger.info(
      'location',
      '阶段 1/7 检查平台支持',
      fields: {'isSupportedPlatform': _adapter.isSupportedPlatform},
    );
    if (!_adapter.isSupportedPlatform) {
      throw const AppLocationException(
        LocationFailureCode.unsupportedPlatform,
        '当前平台未启用百度精确定位',
      );
    }
    _logger.info('location', '阶段 2/7 检查隐私同意状态');
    final hasConsent = await _privacyConsentStore.hasConsent();
    _logger.info('location', '隐私同意状态检查完成', fields: {'hasConsent': hasConsent});
    if (!hasConsent) {
      throw const AppLocationException(
        LocationFailureCode.privacyRequired,
        '使用定位前需要同意百度地图与定位隐私说明',
      );
    }

    final apiKey = _currentPlatformApiKey.trim();
    _logger.info(
      'location',
      '阶段 3/7 检查定位 AK 配置',
      fields: {
        'hasApiKey': apiKey.isNotEmpty,
        'platform': defaultTargetPlatform.name,
      },
    );
    if (apiKey.isEmpty) {
      throw const AppLocationException(
        LocationFailureCode.keyMissing,
        '百度定位 AK 未配置',
      );
    }

    // SDK 初始化同样延迟到用户发起定位时，不占用启动时间，也不会提前申请权限。
    _logger.info('location', '阶段 4/7 开始配置百度定位 SDK');
    await _adapter.configure(apiKey: apiKey);
    _logger.info('location', '百度定位 SDK 配置完成');
    _logger.info('location', '阶段 5/7 检查系统定位服务开关');
    final serviceEnabled = await _adapter.isLocationServiceEnabled();
    _logger.info(
      'location',
      '系统定位服务开关检查完成',
      fields: {'serviceEnabled': serviceEnabled},
    );
    if (!serviceEnabled) {
      throw const AppLocationException(
        LocationFailureCode.serviceDisabled,
        '系统定位服务未开启，请在系统设置中开启定位服务',
      );
    }

    _logger.info('location', '阶段 6/7 检查并申请前台定位权限');
    final permission = await _adapter.requestWhenInUsePermission();
    _logger.info(
      'location',
      '前台定位权限检查完成',
      fields: {'permission': permission.name},
    );
    switch (permission) {
      case LocationPermissionState.granted:
        break;
      case LocationPermissionState.permanentlyDenied:
        throw const AppLocationException(
          LocationFailureCode.permissionPermanentlyDenied,
          '定位权限已被永久拒绝，请前往系统设置允许“使用 App 期间”访问位置',
        );
      case LocationPermissionState.restricted:
        throw const AppLocationException(
          LocationFailureCode.permissionDenied,
          '定位权限受系统或家长控制限制',
        );
      case LocationPermissionState.denied:
        throw const AppLocationException(
          LocationFailureCode.permissionDenied,
          '用户拒绝了定位权限',
        );
    }

    final stopwatch = Stopwatch()..start();
    try {
      _logger.info(
        'location',
        '阶段 7/7 开始请求百度单次定位',
        fields: {
          'timeoutSeconds': timeout.inSeconds,
          'maximumAccuracyMeters': maximumAccuracyMeters,
        },
      );
      final location = await _adapter.locateOnce(
        timeout: timeout,
        maximumAccuracyMeters: maximumAccuracyMeters,
      );
      _logger.info(
        'location',
        '精确定位完成',
        fields: {
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'accuracyMeters': location.accuracyMeters,
          'provider': location.provider,
          'coordinateType': location.coordinateType,
        },
      );
      return location;
    } catch (error, stackTrace) {
      _logger.warning(
        'location',
        '精确定位失败',
        error: error,
        stackTrace: stackTrace,
        fields: {'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      rethrow;
    }
  }

  Future<bool> openAppSettings() => _adapter.openAppSettings();
}
