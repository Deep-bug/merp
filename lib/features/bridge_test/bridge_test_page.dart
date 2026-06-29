import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/bridge/merp_native_bridge.dart';
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
    if (_controller == null) {
      _createController();
    }
  }

  void _createController() {
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
                title: '桥接测试页加载失败',
                message: '无法打开平台上的 Vue3 桥接测试页，请检查网络、端口、防火墙或 HTTP 明文访问配置。',
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
                  title: '桥接测试页返回异常',
                  message: '平台测试页已响应，但 HTTP 状态码不是成功状态。',
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
    setState(() {
      _error = error;
      _progress = 100;
    });
  }

  void _reload() {
    setState(() {
      _error = null;
      _progress = 0;
    });
    _controller?.loadRequest(BridgeTestPage.testUri);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.chevron_left),
        ),
        title: const Text('WebView Bridge 测试'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: error != null
          ? AppErrorView(
              icon: Icons.integration_instructions_outlined,
              title: error.title,
              message: error.message,
              detail: error.detail,
              primaryLabel: '重新加载',
              onPrimary: _reload,
              secondaryLabel: '返回设置',
              onSecondary: () => context.go('/settings'),
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
  });

  final String title;
  final String message;
  final String detail;
}
