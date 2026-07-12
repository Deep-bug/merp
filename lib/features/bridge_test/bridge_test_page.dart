// -----------------------------------------------------------------------------
// 文件：bridge_test_page.dart
// 作用：加载 Vue3 测试页并验证 WebView 到 Flutter 原生能力通信
// 编写时间：2026-07-10
// 维护说明：测试地址与生产业务 WebView 分离，便于独立排查 Bridge 协议
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/app_scope.dart';
import '../../core/bridge/merp_native_bridge.dart';
import '../../core/platform/webview_support.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_error_view.dart';

class BridgeTestPage extends StatefulWidget {
  const BridgeTestPage({super.key});

  static final testUri = Uri.parse(
    'http://42.192.127.131:8088/merp-bridge-test',
  );

  @override
  State<BridgeTestPage> createState() => _BridgeTestPageState();
}

class _BridgeTestPageState extends State<BridgeTestPage> {
  WebViewController? _controller;
  MerpNativeBridge? _bridge;
  _BridgePageError? _error;
  var _progress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && _error == null) {
      _createController();
    }
  }

  void _createController() {
    if (!WebViewSupport.isSupported) {
      _showError(
        _BridgePageError(
          title: context.l10n.webViewUnsupported,
          message: context.l10n.bridgeMobileOnly,
          detail: WebViewSupport.unsupportedDetail,
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _error = null;
                _progress = 0;
              });
            }
          },
          onPageFinished: (_) => _bridge?.inject(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) {
              return;
            }
            _showError(
              _BridgePageError(
                title: context.l10n.bridgeLoadFailed,
                message: context.l10n.bridgeLoadFailedMessage,
                detail:
                    'URL: ${BridgeTestPage.testUri}\n错误码: ${error.errorCode}\n原因: ${error.description}',
              ),
            );
          },
          onHttpError: (error) {
            final statusCode = error.response?.statusCode;
            if (statusCode != null && statusCode >= 400) {
              _showError(
                _BridgePageError(
                  title: context.l10n.bridgeHttpError,
                  message: context.l10n.bridgeHttpErrorMessage,
                  detail:
                      'URL: ${BridgeTestPage.testUri}\nHTTP 状态码: $statusCode',
                ),
              );
            }
          },
        ),
      );

    final bridge = MerpNativeBridge(context: context, controller: controller);
    controller
      ..addJavaScriptChannel(
        MerpNativeBridge.channelName,
        onMessageReceived: (message) => bridge.handleMessage(message.message),
      )
      ..loadRequest(BridgeTestPage.testUri);

    _bridge = bridge;
    _controller = controller;
  }

  void _showError(_BridgePageError error) {
    if (!mounted) {
      return;
    }
    final incidentId = AppScope.of(context).logger.error(
      'webview',
      error.message,
      fields: {'detail': error.detail, 'page': 'bridge-test'},
    );
    setState(() {
      _error = error.withIncidentId(incidentId);
      _progress = 100;
    });
  }

  void _reload() {
    setState(() {
      _error = null;
      _progress = 0;
    });
    if (!WebViewSupport.isSupported) {
      _createController();
      return;
    }
    _controller?.loadRequest(BridgeTestPage.testUri);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoute.settings),
          icon: const Icon(Icons.chevron_left),
        ),
        title: Text(context.l10n.bridgeTest),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: error != null
          ? AppErrorView(
              icon: Icons.integration_instructions_outlined,
              tone: error.tone,
              title: error.title,
              message: error.message,
              detail: error.detail,
              referenceId: error.incidentId,
              primaryLabel: context.l10n.reload,
              onPrimary: _reload,
              secondaryLabel: context.l10n.backToSettings,
              onSecondary: () => context.go(AppRoute.settings),
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
    );
  }
}

class _BridgePageError {
  const _BridgePageError({
    required this.title,
    required this.message,
    required this.detail,
    this.tone = AppErrorTone.error,
    this.incidentId,
  });

  final String title;
  final String message;
  final String detail;
  final AppErrorTone tone;
  final String? incidentId;

  _BridgePageError withIncidentId(String value) {
    return _BridgePageError(
      title: title,
      message: message,
      detail: detail,
      tone: tone,
      incidentId: value,
    );
  }
}
