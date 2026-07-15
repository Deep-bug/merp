// -----------------------------------------------------------------------------
// 文件：map_sdk_service.dart
// 作用：集中管理百度地图 SDK 配置、隐私同意状态与 iOS 激活流程
// 编写时间：2026-07-15
// 维护说明：严禁记录 AK；检索、定位等扩展能力应继续通过独立服务接入
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'baidu_privacy_consent_store.dart';

/// 百度地图 SDK 的应用级适配器。
///
/// SDK 不能在应用启动时直接激活。页面先展示隐私说明，用户明确同意后才调用
/// 百度官方的隐私接口和 AK 初始化接口，从而保证业务页面不依赖第三方 SDK 细节。
class MapSdkService {
  MapSdkService({
    required AppConfig config,
    required AppLogger logger,
    BaiduPrivacyConsentStore privacyConsentStore =
        const BaiduPrivacyConsentStore(),
  }) : _config = config,
       _logger = logger,
       _privacyConsentStore = privacyConsentStore;

  final AppConfig _config;
  final AppLogger _logger;
  final BaiduPrivacyConsentStore _privacyConsentStore;
  bool _activated = false;

  /// 当前版本只启用 iOS 百度基础地图，Android/Web 留待单独配置 AK 后接入。
  bool get isIosSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get isConfigured =>
      _config.mapProvider == 'baidu' && _config.iosMapApiKey.trim().isNotEmpty;

  bool get isActivated => _activated;

  /// 启动阶段仅检查配置，不调用任何百度 SDK API。
  Future<void> initialize() async {
    _logger.info(
      'map',
      '地图适配服务已装配',
      fields: {'provider': _config.mapProvider, 'iosConfigured': isConfigured},
    );
  }

  Future<bool> hasPrivacyConsent() => _privacyConsentStore.hasConsent();

  /// 保存用户授权并激活 SDK。调用方必须由用户点击操作触发。
  Future<void> acceptPrivacyAndActivate() async {
    await _privacyConsentStore.accept();
    await _activate();
  }

  /// 已同意过的用户再次进入页面时，可直接恢复 SDK。
  Future<void> activateIfConsented() async {
    if (!await hasPrivacyConsent()) {
      throw StateError('Baidu map privacy consent is required.');
    }
    await _activate();
  }

  Future<void> _activate() async {
    if (_activated) {
      return;
    }
    if (!isIosSupported) {
      throw UnsupportedError('Baidu map is enabled for iOS only.');
    }
    if (!isConfigured) {
      throw StateError('Baidu iOS map key is not configured.');
    }

    // 百度官方要求：任何 SDK API 调用前必须先设置隐私同意状态。
    BMFMapSDK.setAgreePrivacy(true);
    BMFMapSDK.setApiKeyAndCoordType(
      _config.iosMapApiKey.trim(),
      BMF_COORD_TYPE.BD09LL,
    );

    // 官方 API 使用异步 MethodChannel 但返回 void；让出一次事件循环，使原生端
    // 有机会完成初始化。最终可用性由地图页面的加载回调和超时状态判断。
    await Future<void>.delayed(Duration.zero);
    _activated = true;
    _logger.info('map', '百度 iOS 基础地图 SDK 已激活');
  }
}
