// -----------------------------------------------------------------------------
// 文件：merp_native_bridge.dart
// 作用：定义 Vue/H5 调用 Flutter 鉴权、资源和设备能力的受控协议
// 编写时间：2026-07-10
// 维护说明：新增 action 必须校验参数、定义错误码并同步 Bridge 文档
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../device/location_service.dart';

/// MERP WebView 原生能力 Bridge。
///
/// 旧 Vue2 页面和本地测试页都使用同一套 JS API：
/// `window.MERPBridge.call(action, payload)`。
/// Flutter 侧只暴露受控 action，避免旧页面直接依赖插件或散落多套协议。
class MerpNativeBridge {
  MerpNativeBridge({required this.context, required this.controller});

  static const channelName = 'MerpNative';

  final BuildContext context;
  final WebViewController controller;

  /// 注入 JS 端 Promise 风格 API。
  ///
  /// 页面加载完成后调用即可。Vue2 页面可以在 mounted 后等待
  /// `window.MERPBridge` 存在，也可以监听 `MERPBridgeReady` 事件。
  Future<void> inject() async {
    final logger = AppScope.of(context).logger;
    try {
      await controller.runJavaScript(_bridgeScript);
      logger.info('bridge', 'MERPBridge 注入完成');
    } catch (error, stackTrace) {
      logger.error(
        'bridge',
        'MERPBridge 注入失败',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> handleMessage(String rawMessage) async {
    final logger = AppScope.of(context).logger;
    String? requestId;
    String? action;
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        throw const _BridgeException(
          'BRIDGE_BAD_REQUEST',
          'Bridge 消息必须是 JSON Object',
        );
      }

      requestId = decoded['id']?.toString();
      action = decoded['action']?.toString();
      final payload = decoded['payload'];

      if (requestId == null || requestId.isEmpty || action == null) {
        throw const _BridgeException(
          'BRIDGE_BAD_REQUEST',
          'Bridge 缺少 id 或 action',
        );
      }

      logger.debug(
        'bridge',
        '收到 WebView Bridge 调用',
        fields: {'action': action, 'requestId': requestId},
      );

      switch (action) {
        case 'bridge.ping':
          await _resolve(requestId, _pingPayload());
        case 'auth.getSession':
          await _resolve(requestId, _sessionPayload());
        case 'resource.getManifest':
          await _resolve(requestId, _resourceManifestPayload());
        case 'app.getLocale':
          await _resolve(requestId, _localePayload());
        case 'app.showToast':
          await _showToast(requestId, payload);
        case 'camera.takePhoto':
          await _takePhoto(requestId, payload);
        case 'location.getCurrentPosition':
          await _getCurrentPosition(requestId, payload);
        case 'device.openAppSettings':
          await _openAppSettings(requestId);
        default:
          logger.warning(
            'bridge',
            'WebView 请求了未开放的原生能力',
            fields: {'action': action, 'requestId': requestId},
          );
          await _reject(
            requestId,
            'BRIDGE_UNSUPPORTED_ACTION',
            '暂不支持的原生能力：$action',
          );
      }
    } catch (error, stackTrace) {
      final bridgeError = error is _BridgeException
          ? error
          : _BridgeException('BRIDGE_ERROR', error.toString());
      final incidentId = logger.error(
        'bridge',
        bridgeError.message,
        error: error,
        stackTrace: stackTrace,
        fields: {'action': action, 'requestId': requestId},
      );
      if (requestId != null && requestId.isNotEmpty) {
        await _reject(
          requestId,
          bridgeError.code,
          bridgeError.message,
          incidentId: incidentId,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bridge 调用失败：${bridgeError.message}\n故障编号：$incidentId',
            ),
          ),
        );
      }
    }
  }

  Map<String, Object?> _pingPayload() {
    return {
      'message': 'pong',
      'bridgeVersion': '1.1.0',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, Object?> _sessionPayload() {
    final session = AppScope.of(context).authController.session;
    return {
      'authenticated': session != null,
      'userName': session?.profile.displayName,
      'userInfo': session?.profile.toJson(),
      // Bridge 仅提供短期 access_token，绝不向 H5 暴露 refresh_token。
      // `token` 是旧 Vue 迁移兼容字段，新页面应读取 access_token。
      'access_token': session?.accessToken,
      'token': session?.accessToken,
    };
  }

  Map<String, Object?> _resourceManifestPayload() {
    final manifest = AppScope.of(context).resourceUpdateController.manifest;
    return manifest.toJson();
  }

  Map<String, Object?> _localePayload() {
    final language = AppScope.of(context).settingsController.language;
    return {'code': language.code, 'locale': language.locale.toLanguageTag()};
  }

  Future<void> _showToast(String requestId, Object? payload) async {
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final message =
        options['message']?.toString() ?? 'Vue 页面调用 Flutter Toast 成功';
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    await _resolve(requestId, {'shown': true, 'message': message});
  }

  Future<void> _takePhoto(String requestId, Object? payload) async {
    final cameraService = AppScope.of(context).cameraService;
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final includeBase64 = options['includeBase64'] == true;
    final imageQuality = _readInt(
      options['imageQuality'],
      fallback: 88,
    ).clamp(1, 100);
    final maxWidth = _readDouble(options['maxWidth'], fallback: 1920);

    final capture = await cameraService.takePhoto(
      includeBase64: includeBase64,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );

    if (capture == null) {
      await _reject(requestId, 'CAMERA_CANCELLED', '用户取消拍照');
      return;
    }
    await _resolve(requestId, capture.toJson());
  }

  Future<void> _getCurrentPosition(String requestId, Object? payload) async {
    final locationService = AppScope.of(context).locationService;
    final l10n = context.l10n;
    if (!await locationService.hasPrivacyConsent()) {
      final accepted = await _requestLocationPrivacyConsent();
      if (!accepted) {
        await _reject(
          requestId,
          LocationFailureCode.privacyRequired.value,
          l10n.locationPrivacyDeclined,
        );
        return;
      }
      await locationService.acceptPrivacyConsent();
    }

    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final timeoutMs = _readInt(
      options['timeoutMs'],
      fallback: 25000,
    ).clamp(5000, 60000).toInt();
    final maximumAccuracyMeters = _readDouble(
      options['maximumAccuracyMeters'] ?? options['accuracy'],
      fallback: 50,
    ).clamp(5, 1000).toDouble();

    try {
      final location = await locationService.locateOnce(
        timeout: Duration(milliseconds: timeoutMs),
        maximumAccuracyMeters: maximumAccuracyMeters,
      );
      await _resolve(requestId, location.toJson());
    } on AppLocationException catch (error) {
      await _reject(
        requestId,
        error.code.value,
        error.message,
        details: {...error.details, 'canOpenSettings': error.canOpenSettings},
      );
    }
  }

  Future<bool> _requestLocationPrivacyConsent() async {
    if (!context.mounted) {
      return false;
    }
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.privacy_tip_outlined),
            title: Text(context.l10n.locationPrivacyTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.locationPrivacyMessage),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'https://lbsyun.baidu.com/index.php?title=openprivacy',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.mapDecline),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.mapAgreeAndContinue),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openAppSettings(String requestId) async {
    final opened = await AppScope.of(context).locationService.openAppSettings();
    await _resolve(requestId, {'opened': opened});
  }

  int _readInt(Object? value, {required int fallback}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  double _readDouble(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  Future<void> _resolve(String requestId, Object? data) {
    return _runCallback('_resolve', requestId, data);
  }

  Future<void> _reject(
    String requestId,
    String code,
    String message, {
    String? incidentId,
    Map<String, Object?> details = const {},
  }) {
    return _runCallback('_reject', requestId, {
      'code': code,
      'message': message,
      'incidentId': ?incidentId,
      'details': details,
    });
  }

  Future<void> _runCallback(
    String method,
    String requestId,
    Object? payload,
  ) async {
    final script =
        'window.MERPBridge && window.MERPBridge.$method(${jsonEncode(requestId)}, ${jsonEncode(payload)});';
    await controller.runJavaScript(script);
  }
}

class _BridgeException implements Exception {
  const _BridgeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

const _bridgeScript = r'''
(function () {
  if (window.MERPBridge) {
    window.dispatchEvent(new Event('MERPBridgeReady'));
    return;
  }

  var pending = {};

  function createId() {
    return Date.now().toString(36) + '_' + Math.random().toString(36).slice(2);
  }

  window.MERPBridge = {
    version: '1.1.0',

    call: function (action, payload) {
      var id = createId();
      MerpNative.postMessage(JSON.stringify({
        id: id,
        action: action,
        payload: payload || {}
      }));

      return new Promise(function (resolve, reject) {
        pending[id] = { resolve: resolve, reject: reject };
      });
    },

    ping: function () {
      return this.call('bridge.ping', {});
    },

    getSession: function () {
      return this.call('auth.getSession', {});
    },

    getResourceManifest: function () {
      return this.call('resource.getManifest', {});
    },

    getLocale: function () {
      return this.call('app.getLocale', {});
    },

    showToast: function (message) {
      return this.call('app.showToast', { message: message });
    },

    takePhoto: function (options) {
      return this.call('camera.takePhoto', options || {});
    },

    getCurrentPosition: function (options) {
      return this.call('location.getCurrentPosition', options || {});
    },

    openAppSettings: function () {
      return this.call('device.openAppSettings', {});
    },

    _resolve: function (id, data) {
      if (!pending[id]) {
        return;
      }
      pending[id].resolve(data);
      delete pending[id];
    },

    _reject: function (id, error) {
      if (!pending[id]) {
        return;
      }
      pending[id].reject(error);
      delete pending[id];
    }
  };

  window.dispatchEvent(new Event('MERPBridgeReady'));
})();
''';
