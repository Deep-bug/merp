// -----------------------------------------------------------------------------
// 文件：legacy_web_page.dart
// 作用：承载旧 Vue 业务页并统一处理权限、URL、网络和 Bridge 生命周期
// 编写时间：2026-07-10
// 维护说明：迁移期功能统一经过此容器，禁止业务模块自行创建 WebView
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/app_scope.dart';
import '../../core/auth/web_code_url.dart';
import '../../core/bridge/merp_native_bridge.dart';
import '../../core/bridge/web_access_policy.dart';
import '../../core/platform/webview_diagnostics.dart';
import '../../core/platform/webview_support.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_error_view.dart';

class LegacyWebPage extends StatefulWidget {
  const LegacyWebPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  State<LegacyWebPage> createState() => _LegacyWebPageState();
}

class _LegacyWebPageState extends State<LegacyWebPage> {
  WebViewController? _controller;
  MerpNativeBridge? _bridge;
  Uri? _currentUri;
  _LegacyError? _error;
  var _progress = 0;
  var _configured = false;
  var _loadingExchange = false;
  var _loadGeneration = 0;

  @override
  void dispose() {
    _loadGeneration++;
    _bridge?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_configured) {
      _configured = true;
      unawaited(_configureAndLoad());
    }
  }

  Future<void> _configureAndLoad() async {
    final generation = ++_loadGeneration;
    try {
      await _configurePage(generation);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      _showError(
        _LegacyError(
          title: context.l10n.pageLoadFailed,
          message: context.l10n.pageLoadFailedMessage,
          detail: WebCodeUrl.redact(error.toString()),
        ),
      );
    }
  }

  Future<void> _configurePage(int generation) async {
    final scope = AppScope.of(context);
    final moduleId = widget.moduleId.trim();

    if (!WebViewSupport.isSupported) {
      _showError(
        _LegacyError(
          title: context.l10n.webViewUnsupported,
          message: context.l10n.legacyMobileOnly,
          detail: WebViewSupport.unsupportedDetail,
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    if (moduleId.isEmpty) {
      _showError(
        _LegacyError(
          title: context.l10n.moduleMissing,
          message: context.l10n.moduleMissingMessage,
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final feature = scope.permissionRepository.allFeatures
        .where((item) => item.id == moduleId)
        .firstOrNull;
    if (feature == null) {
      _showError(
        _LegacyError(
          title: context.l10n.featureNotFound,
          message: context.l10n.featureNotFoundMessage,
          detail: 'moduleId=$moduleId',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    if (!scope.permissionRepository.canOpen(feature)) {
      _showError(
        _LegacyError(
          title: context.l10n.noPermission,
          message: context.l10n.legacyForbiddenMessage,
          detail: 'permissionCode=${feature.permissionCode}',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final legacyPath = feature.legacyPath?.trim();
    if (legacyPath == null || legacyPath.isEmpty) {
      _showError(
        _LegacyError(
          title: context.l10n.urlMissing,
          message: context.l10n.urlMissingMessage,
          detail: '功能：${feature.title}\n建议：请后端在菜单中返回 legacyPath。',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final parsedLegacyPath = Uri.tryParse(legacyPath);
    final usesAbsoluteUrl =
        parsedLegacyPath != null &&
        parsedLegacyPath.hasScheme &&
        (parsedLegacyPath.scheme == 'http' ||
            parsedLegacyPath.scheme == 'https');
    final legacyBaseUrl = scope.config.legacyVueBaseUrl.trim();
    if (!usesAbsoluteUrl &&
        (legacyBaseUrl.isEmpty || legacyBaseUrl.contains('example.com'))) {
      _showError(
        _LegacyError(
          title: context.l10n.featureNotIntegrated,
          message: context.l10n.featureNotIntegratedMessage,
          detail: 'legacyVueBaseUrl=$legacyBaseUrl',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final uri = scope.config.legacyUri(legacyPath);
    final accessPolicy = WebAccessPolicy.fromConfig(scope.config);
    if (!accessPolicy.trusts(uri)) {
      _showError(
        _LegacyError(
          title: context.l10n.invalidUrl,
          message: context.l10n.invalidUrlMessage,
          detail: WebCodeUrl.redact(uri.toString()),
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    _currentUri = uri;
    _progress = 0;
    _error = null;
    final sessionGeneration = scope.apiClient.sessionTokens.generation;
    bool isActive() =>
        mounted &&
        _error == null &&
        generation == _loadGeneration &&
        scope.authController.isAuthenticated &&
        scope.apiClient.sessionTokens.isCurrent(sessionGeneration) &&
        scope.permissionRepository.canOpen(feature);

    bool allowsUrl(String url) {
      final target = Uri.tryParse(url);
      return target != null &&
          accessPolicy.allowsNavigation(entry: uri, target: target);
    }

    void blockNavigation() {
      if (!isActive()) return;
      _showError(
        _LegacyError(
          title: context.l10n.invalidUrl,
          message: context.l10n.invalidUrlMessage,
          detail: 'WEB_ORIGIN_NOT_ALLOWED',
          tone: AppErrorTone.warning,
        ),
      );
    }

    // 换码必须发生在创建/加载 WebView 之前；失败时不打开旧页面。
    // 页面显式重试会再次进入这里，因此不会复用一次性 Code。
    _loadingExchange = true;
    late final Uri pageUri;
    try {
      final code = await scope.authController.exchangeWebCode();
      if (!isActive()) return;
      pageUri = WebCodeUrl.append(uri, code);
    } catch (error) {
      if (mounted && generation == _loadGeneration) {
        _showError(
          _LegacyError(
            title: context.l10n.pageLoadFailed,
            message: context.l10n.pageLoadFailedMessage,
            detail: WebCodeUrl.redact(error.toString()),
          ),
        );
      }
      return;
    } finally {
      if (generation == _loadGeneration) _loadingExchange = false;
    }

    if (!mounted || !isActive()) return;
    final controller = WebViewController();
    final bridge = MerpNativeBridge(
      context: context,
      controller: controller,
      entryUri: uri,
      accessPolicy: accessPolicy,
      isSessionActive: isActive,
    );
    _bridge = bridge;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (!isActive()) return NavigationDecision.prevent;
          if (!allowsUrl(request.url)) {
            if (request.isMainFrame) blockNavigation();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          if (!isActive()) return;
          bridge.navigationStarted();
          if (!allowsUrl(url)) {
            unawaited(
              controller
                  .runJavaScript('window.stop();')
                  .catchError((Object _) {}),
            );
            blockNavigation();
          }
        },
        onProgress: (progress) {
          if (isActive()) {
            setState(() => _progress = progress);
          }
        },
        onPageFinished: (url) async {
          if (!isActive() || !allowsUrl(url)) return;
          await bridge.inject();
          await WebViewDiagnostics.inspect(
            controller: controller,
            logger: scope.logger,
            page: 'legacy:$moduleId',
          );
        },
        onWebResourceError: (error) {
          if (!isActive()) return;
          if (WebViewDiagnostics.enabled) {
            scope.logger.warning(
              'webview',
              'WebView resource load failed',
              fields: {
                'page': 'legacy:$moduleId',
                'resourceType': WebViewDiagnostics.resourceType(error),
                'errorCode': error.errorCode,
                'description': WebCodeUrl.redact(error.description),
              },
            );
          }
          if (error.isForMainFrame == false) {
            return;
          }
          _showError(
            _LegacyError(
              title: context.l10n.pageLoadFailed,
              message: context.l10n.pageLoadFailedMessage,
              detail:
                  'URL: ${WebCodeUrl.redact((_currentUri ?? uri).toString())}\n错误码: ${error.errorCode}\n原因: ${WebCodeUrl.redact(error.description)}',
            ),
          );
        },
        onHttpError: (error) {
          if (!isActive()) return;
          final statusCode = error.response?.statusCode;
          _showError(
            _LegacyError(
              title: context.l10n.serverError,
              message: statusCode == 404
                  ? context.l10n.legacyNotFoundMessage
                  : context.l10n.legacyServerErrorMessage,
              detail:
                  'URL: ${WebCodeUrl.redact((_currentUri ?? uri).toString())}\nHTTP 状态码: $statusCode',
            ),
          );
        },
      ),
    );

    await WebViewDiagnostics.attach(
      controller: controller,
      logger: scope.logger,
      page: 'legacy:$moduleId',
    );

    await controller.addJavaScriptChannel(
      MerpNativeBridge.channelName,
      onMessageReceived: (message) => bridge.handleMessage(message.message),
    );

    if (!isActive()) {
      bridge.dispose();
      return;
    }
    setState(() => _controller = controller);
    await controller.loadRequest(pageUri, headers: _requestHeaders(scope));
  }

  void _showError(_LegacyError error) {
    if (!mounted) {
      return;
    }
    _bridge?.dispose();
    final incidentId = AppScope.of(context).logger.error(
      'webview',
      error.message,
      fields: {'moduleId': widget.moduleId, 'detail': error.detail},
    );
    setState(() {
      _error = error.withIncidentId(incidentId);
      _progress = 100;
    });
  }

  void _retry() {
    if (_loadingExchange) return;
    _bridge?.dispose();
    setState(() {
      _controller = null;
      _bridge = null;
      _error = null;
      _progress = 0;
    });
    unawaited(_configureAndLoad());
  }

  Map<String, String> _requestHeaders(AppScope scope) {
    final token = scope.authController.session?.accessToken ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Accept-Language': scope.settingsController.language.code,
    };
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final controller = _controller;

    return Scaffold(
      body: SafeArea(
        child: error != null
            ? AppErrorView(
                icon: Icons.cloud_off_outlined,
                tone: error.tone,
                title: error.title,
                message: error.message,
                detail: error.detail,
                referenceId: error.incidentId,
                primaryLabel: context.l10n.retry,
                onPrimary: _retry,
                secondaryLabel: context.l10n.returnWorkbench,
                onSecondary: () => context.go(AppRoute.home),
              )
            : controller == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (_progress < 100)
                    LinearProgressIndicator(value: _progress / 100),
                ],
              ),
      ),
    );
  }
}

class _LegacyError {
  const _LegacyError({
    required this.title,
    required this.message,
    this.detail,
    this.tone = AppErrorTone.error,
    this.incidentId,
  });

  final String title;
  final String message;
  final String? detail;
  final AppErrorTone tone;
  final String? incidentId;

  _LegacyError withIncidentId(String value) {
    return _LegacyError(
      title: title,
      message: message,
      detail: detail,
      tone: tone,
      incidentId: value,
    );
  }
}
