// -----------------------------------------------------------------------------
// 文件：merp_native_bridge.dart
// 作用：定义 Vue/H5 调用 Flutter 鉴权、资源和设备能力的受控协议
// 编写时间：2026-07-10
// 维护说明：新增 action 必须校验参数、定义错误码并同步 Bridge 文档
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/app_scope.dart';
import '../../features/scanner/barcode_scanner_page.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../device/camera_service.dart';
import '../device/file_service.dart';
import '../device/location_service.dart';
import '../device/scanner_models.dart';
import '../resources/runtime_resource_manifest.dart';
import 'bridge_document_session.dart';
import 'bridge_script.dart';
import 'web_access_policy.dart';

/// MERP WebView 原生能力 Bridge。
///
/// 旧 Vue2 页面和本地测试页都使用同一套 JS API：
/// `window.MERPBridge.call(action, payload)`。
/// Flutter 侧只暴露受控 action，避免旧页面直接依赖插件或散落多套协议。
class MerpNativeBridge {
  MerpNativeBridge({
    required this.context,
    required this.controller,
    required this.entryUri,
    required this.accessPolicy,
    required this.isSessionActive,
  });

  static const channelName = 'MerpNative';

  final BuildContext context;
  final WebViewController controller;
  final Uri entryUri;
  final WebAccessPolicy accessPolicy;
  final bool Function() isSessionActive;
  final _document = BridgeDocumentSession();
  static final _nonceZoneKey = Object();
  bool _disposed = false;
  bool _closePageInProgress = false;
  bool _logoutInProgress = false;

  /// 顶层文档开始导航/重试时撤销旧消息与未完成的相机、定位等回调。
  void navigationStarted() {
    _document.invalidate();
    _closePageInProgress = false;
    _logoutInProgress = false;
  }

  void dispose() {
    _disposed = true;
    _document.dispose();
  }

  Future<bool> _canAccessDocument() async {
    if (_disposed || !context.mounted || !isSessionActive()) return false;
    final revision = _document.revision;
    String? url;
    try {
      url = await controller.currentUrl();
    } catch (_) {
      return false; // 原生 WebView 已销毁或正在切换文档时按拒绝处理。
    }
    final uri = url == null ? null : Uri.tryParse(url);
    return !_disposed &&
        context.mounted &&
        isSessionActive() &&
        revision == _document.revision &&
        uri != null &&
        accessPolicy.allowsNavigation(entry: entryUri, target: uri);
  }

  /// 注入 JS 端 Promise 风格 API。
  ///
  /// 页面加载完成后调用即可。Vue2 页面可以在 mounted 后等待
  /// `window.MERPBridge` 存在，也可以监听 `MERPBridgeReady` 事件。
  Future<void> inject() async {
    if (_disposed || !context.mounted) return;
    final logger = AppScope.of(context).logger;
    try {
      final revision = _document.revision;
      if (!await _canAccessDocument()) return;
      final nonce = _document.activate(revision);
      if (nonce == null) return;
      await controller.runJavaScript(
        buildBridgeScript(nonce: nonce, origin: entryUri.origin),
      );
      logger.info('bridge', 'MERPBridge 注入完成');
    } catch (error, stackTrace) {
      logger.error(
        'bridge',
        'MERPBridge 注入失败',
        error: error,
        stackTrace: stackTrace,
      );
      // 页面回调由原生触发，不能产生未处理的异步异常。
    }
  }

  Future<void> handleMessage(String rawMessage) => runZoned(
    () => _handleMessage(rawMessage),
    zoneValues: {_nonceZoneKey: _document.nonce},
  );

  Future<void> _handleMessage(String rawMessage) async {
    if (_disposed || !context.mounted || !isSessionActive()) return;
    final logger = AppScope.of(context).logger;
    String? requestId;
    String? action;
    final nonce = Zone.current[_nonceZoneKey] as String?;
    var accepted = false;
    try {
      // 原始 channel 对 iframe 也可能可见；先验证文档绑定，再执行原生能力。
      // 不记录原始消息，避免 Token、照片和文件内容进入诊断日志。
      if (rawMessage.length > 1024 * 1024) return;
      Object? decoded;
      try {
        decoded = jsonDecode(rawMessage);
      } on FormatException {
        return; // FormatException 可能包含原始消息片段，不记录到日志。
      }
      if (decoded is! Map<String, dynamic>) {
        throw const _BridgeException(
          'BRIDGE_BAD_REQUEST',
          'Bridge 消息必须是 JSON Object',
        );
      }

      if (decoded['id'] is! String || decoded['action'] is! String) return;
      requestId = decoded['id'] as String;
      action = decoded['action'] as String;
      if (action.length > 96) return;
      final payload = decoded['payload'];

      if (requestId.isEmpty || action.isEmpty) {
        throw const _BridgeException(
          'BRIDGE_BAD_REQUEST',
          'Bridge 缺少 id 或 action',
        );
      }

      accepted = _document.accepts(requestId, decoded['documentNonce']);
      if (!accepted) return;
      if (!await _canAccessDocument() ||
          !_document.canReply(requestId, nonce)) {
        return;
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
        case 'auth.logout':
          await _logout(requestId);
        case 'closePage':
        case 'navigation.closePage':
          await _closePage(requestId, payload);
        case 'resource.getManifest':
          await _resolve(requestId, _resourceManifestPayload());
        case 'app.getLocale':
          await _resolve(requestId, _localePayload());
        case 'app.showToast':
          await _showToast(requestId, payload);
        case 'camera.takePhoto':
          await _takePhoto(requestId, payload);
        case 'file.pick':
          await _pickFiles(requestId, payload);
        case 'device.getInfo':
          await _getDeviceInfo(requestId);
        case 'location.getCurrentPosition':
          await _getCurrentPosition(requestId, payload);
        case 'scanner.scanCode':
          await _scanCode(requestId, payload);
        case 'system.showMessage':
          await _showSystemMessage(requestId, payload);
        case 'system.confirm':
          await _showSystemConfirm(requestId, payload);
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
      }
    } finally {
      if (accepted && requestId != null) _document.complete(requestId, nonce);
    }
  }

  Map<String, Object?> _pingPayload() {
    return {
      'message': 'pong',
      'bridgeVersion': '2.4.0',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
      'capabilities': [
        'location.getCurrentPosition',
        'scanner.scanCode',
        'camera.takePhoto',
        'file.pick',
        'device.getInfo',
        'system.showMessage',
        'system.confirm',
        'auth.logout',
        'navigation.closePage',
      ],
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

  Future<void> _closePage(String requestId, Object? payload) async {
    if (!context.mounted) {
      await _reject(requestId, 'BRIDGE_CONTEXT_UNAVAILABLE', '当前页面不可用');
      return;
    }
    if (_closePageInProgress) {
      await _reject(
        requestId,
        'NAVIGATION_CLOSE_IN_PROGRESS',
        '正在返回手机端页面，请勿重复操作',
      );
      return;
    }

    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final reason = options['reason']?.toString().trim();
    _closePageInProgress = true;
    final scope = AppScope.of(context);
    await _resolve(requestId, {
      'accepted': true,
      'reason': reason == null || reason.isEmpty ? 'web_back' : reason,
    }).catchError((Object error, StackTrace stackTrace) {
      scope.logger.warning(
        'bridge',
        '关闭 WebView 前回传结果失败',
        error: error,
        stackTrace: stackTrace,
        fields: {'requestId': requestId},
      );
    });
    if (!await _canContinueRequest(requestId)) return;

    scope.logger.info(
      'bridge',
      '已安排关闭 WebView 并返回手机首页',
      fields: {'requestId': requestId},
    );
    final revision = _document.revision;
    Timer(const Duration(milliseconds: 100), () {
      if (_disposed ||
          !context.mounted ||
          !isSessionActive() ||
          revision != _document.revision) {
        return;
      }
      scope.logger.info(
        'bridge',
        '开始关闭 WebView 并返回手机首页',
        fields: {'requestId': requestId},
      );
      AppNavigator.backToHome(context);
    });
  }

  Future<void> _logout(String requestId) async {
    final scope = AppScope.of(context);
    if (!scope.authController.isAuthenticated) {
      await _reject(requestId, 'AUTH_NOT_AUTHENTICATED', '当前用户未登录');
      return;
    }
    if (_logoutInProgress) {
      await _reject(requestId, 'AUTH_LOGOUT_IN_PROGRESS', '正在退出登录，请勿重复操作');
      return;
    }
    if (!context.mounted) {
      await _reject(requestId, 'BRIDGE_CONTEXT_UNAVAILABLE', '当前页面不可用');
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('退出登录'),
            content: const Text('确定要退出当前账号吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('退出'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      await _resolve(requestId, {'accepted': false, 'cancelled': true});
      return;
    }

    if (!await _canContinueRequest(requestId)) return;

    _logoutInProgress = true;
    await _resolve(requestId, {'accepted': true, 'cancelled': false});
    if (!await _canContinueRequest(requestId)) return;
    unawaited(_completeLogout(scope));
  }

  Future<void> _completeLogout(AppScope scope) async {
    try {
      await scope.authController.logout();
    } catch (error, stackTrace) {
      _logoutInProgress = false;
      scope.logger.error(
        'bridge',
        'WebView 发起的退出登录失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, Object?> _resourceManifestPayload() {
    return RuntimeResourceManifest.defaults().toJson();
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

    try {
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
    } on DevicePermissionException catch (error) {
      await _reject(
        requestId,
        'CAMERA_PERMISSION_DENIED',
        error.message,
        details: {'canOpenSettings': true},
      );
    }
  }

  Future<void> _pickFiles(String requestId, Object? payload) async {
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final allowMultiple = options['allowMultiple'] == true;
    final includeBase64 = options['includeBase64'] == true;
    final maximumFileBytes = _readInt(
      options['maximumFileBytes'],
      fallback: 10 * 1024 * 1024,
    ).clamp(1024, 20 * 1024 * 1024).toInt();
    final allowedExtensions = options['allowedExtensions'] is List
        ? (options['allowedExtensions'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];

    try {
      final files = await AppScope.of(context).fileService.pickFiles(
        allowMultiple: allowMultiple,
        includeBase64: includeBase64,
        allowedExtensions: allowedExtensions,
        maximumFileBytes: maximumFileBytes,
      );
      if (files == null) {
        await _reject(requestId, 'FILE_CANCELLED', '用户取消选择文件');
        return;
      }
      await _resolve(requestId, {
        'count': files.length,
        'files': files.map((file) => file.toJson()).toList(growable: false),
      });
    } on FileSelectionException catch (error) {
      await _reject(
        requestId,
        'FILE_INVALID',
        error.message,
        details: error.details,
      );
    }
  }

  Future<void> _scanCode(String requestId, Object? payload) async {
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    late final List<BarcodeFormat> formats;
    try {
      formats = parseScannerFormats(options['formats']);
    } on ScannerFormatException catch (error) {
      await _reject(requestId, 'SCANNER_INVALID_FORMATS', error.message);
      return;
    }
    if (!context.mounted) {
      await _reject(requestId, 'BRIDGE_CONTEXT_UNAVAILABLE', '当前页面不可用');
      return;
    }

    final result = await Navigator.of(context).push<ScanCodeResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerPage(formats: formats),
      ),
    );
    if (result == null) {
      await _reject(requestId, 'SCANNER_CANCELLED', '用户取消扫码');
      return;
    }
    await _resolve(requestId, result.toJson());
  }

  Future<void> _getDeviceInfo(String requestId) async {
    final info = await AppScope.of(context).deviceInfoService.getInfo();
    await _resolve(requestId, info);
  }

  Future<void> _showSystemMessage(String requestId, Object? payload) async {
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final title = options['title']?.toString().trim();
    final message = options['message']?.toString().trim();
    final mode = options['mode']?.toString() ?? 'toast';
    if (message == null || message.isEmpty) {
      throw const _BridgeException('SYSTEM_MESSAGE_REQUIRED', '系统消息内容不能为空');
    }

    if (mode == 'dialog') {
      if (!context.mounted) {
        await _reject(requestId, 'BRIDGE_CONTEXT_UNAVAILABLE', '当前页面不可用');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title?.isNotEmpty == true ? title! : '系统消息'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.acknowledge),
            ),
          ],
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
    await _resolve(requestId, {'shown': true, 'mode': mode});
  }

  Future<void> _showSystemConfirm(String requestId, Object? payload) async {
    final options = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final title = options['title']?.toString().trim();
    final message = options['message']?.toString().trim();
    if (message == null || message.isEmpty) {
      throw const _BridgeException('SYSTEM_MESSAGE_REQUIRED', '确认消息内容不能为空');
    }
    if (!context.mounted) {
      await _reject(requestId, 'BRIDGE_CONTEXT_UNAVAILABLE', '当前页面不可用');
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(title?.isNotEmpty == true ? title! : '请确认'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
    await _resolve(requestId, {'confirmed': confirmed});
  }

  Future<void> _getCurrentPosition(String requestId, Object? payload) async {
    final locationService = AppScope.of(context).locationService;
    final l10n = context.l10n;
    if (!await locationService.hasPrivacyConsent()) {
      if (!await _canContinueRequest(requestId)) return;
      final accepted = await _requestLocationPrivacyConsent();
      if (!await _canContinueRequest(requestId)) return;
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

    if (!await _canContinueRequest(requestId)) return;

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
    final nonce = Zone.current[_nonceZoneKey] as String?;
    if (!await _canContinueRequest(requestId)) return;
    final script =
        'window.location.origin === ${jsonEncode(entryUri.origin)} && '
        'window.MERPBridge && window.MERPBridge.$method(${jsonEncode(requestId)}, ${jsonEncode(payload)}, ${jsonEncode(nonce)});';
    try {
      await controller.runJavaScript(script);
    } catch (_) {
      // 页面关闭后的原生回调无需再次向同一个已销毁页面发送错误。
    }
  }

  Future<bool> _canContinueRequest(String requestId) async {
    final nonce = Zone.current[_nonceZoneKey] as String?;
    return _document.canReply(requestId, nonce) &&
        await _canAccessDocument() &&
        _document.canReply(requestId, nonce);
  }
}

class _BridgeException implements Exception {
  const _BridgeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
