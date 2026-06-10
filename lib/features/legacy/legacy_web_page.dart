import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/app_scope.dart';
import '../../shared/app_error_view.dart';

class LegacyWebPage extends StatefulWidget {
  const LegacyWebPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  State<LegacyWebPage> createState() => _LegacyWebPageState();
}

class _LegacyWebPageState extends State<LegacyWebPage> {
  WebViewController? _controller;
  Uri? _currentUri;
  _LegacyError? _error;
  var _progress = 0;
  var _title = '旧系统页面';
  var _configured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_configured) {
      _configured = true;
      _configureAndLoad();
    }
  }

  void _configureAndLoad() {
    final scope = AppScope.of(context);
    final moduleId = widget.moduleId.trim();

    // 第一层校验：路由必须带 moduleId，否则无法反查后端返回的菜单权限。
    if (moduleId.isEmpty) {
      _showError(
        const _LegacyError(
          title: '功能参数缺失',
          message: '当前功能没有传入模块编号，请检查菜单 route 配置。',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    // 第二层校验：只允许打开登录后后端返回的菜单，避免手动拼路由越权访问。
    final feature = scope.permissionRepository.features
        .where((item) => item.id == moduleId)
        .firstOrNull;
    if (feature == null) {
      _showError(
        _LegacyError(
          title: '功能不存在',
          message: '后端菜单中没有找到这个功能，可能是菜单已下线或权限数据过期。',
          detail: 'moduleId=$moduleId',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    _title = feature.title;

    // 第三层校验：即使用户知道 URL，也要经过前端权限缓存再拦一次。
    if (!scope.permissionRepository.canOpen(feature)) {
      _showError(
        _LegacyError(
          title: '无访问权限',
          message: '当前账号没有打开该功能的权限，请联系管理员调整角色或菜单授权。',
          detail: 'permissionCode=${feature.permissionCode}',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    // 第四层校验：旧 Vue2 页面必须由后端菜单返回 legacyPath，方便后续逐步替换原生页。
    final legacyPath = feature.legacyPath?.trim();
    if (legacyPath == null || legacyPath.isEmpty) {
      _showError(
        _LegacyError(
          title: '页面地址未配置',
          message: '该功能还没有配置旧 Vue2 页面 URL，暂时无法打开。',
          detail: '功能：${feature.title}\n建议：请后端在菜单中返回 legacyPath。',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    // 当前库存管理属于 legacyWeb 功能；如果根地址仍是 example.com，就只提示“未接入”。
    final legacyBaseUrl = scope.config.legacyVueBaseUrl.trim();
    if (legacyBaseUrl.isEmpty || legacyBaseUrl.contains('example.com')) {
      _showError(
        _LegacyError(
          title: '功能暂未接入',
          message: '当前旧 Vue2 系统根地址还是占位地址，所以库存、销售等旧页面还不能打开。',
          detail: 'legacyVueBaseUrl=$legacyBaseUrl',
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    final uri = scope.config.legacyUri(legacyPath);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showError(
        _LegacyError(
          title: '页面地址格式错误',
          message: '旧系统页面地址必须是 http 或 https 地址。',
          detail: uri.toString(),
          tone: AppErrorTone.warning,
        ),
      );
      return;
    }

    _currentUri = uri;
    _progress = 0;
    _error = null;

    final token = scope.authController.session?.token ?? '';
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // 进度只表示 WebView 加载过程，不代表旧系统业务接口已经成功。
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onWebResourceError: (error) {
            // 图片、字体等子资源失败不阻断业务页；主框架失败才展示整页错误。
            if (error.isForMainFrame == false) {
              return;
            }
            _showError(
              _LegacyError(
                title: '页面加载失败',
                message: '网络连接失败、服务器不可达，或旧系统页面暂时不可用。',
                detail:
                    'URL: ${_currentUri ?? uri}\n错误码: ${error.errorCode}\n原因: ${error.description}',
              ),
            );
          },
          onHttpError: (error) {
            final statusCode = error.response?.statusCode;
            _showError(
              _LegacyError(
                title: '服务器返回错误',
                message: statusCode == 404
                    ? '旧系统没有找到该页面，请检查菜单 URL 是否正确。'
                    : '旧系统服务器返回异常状态，请稍后重试或联系管理员。',
                detail: 'URL: ${_currentUri ?? uri}\nHTTP 状态码: $statusCode',
              ),
            );
          },
        ),
      )
      // 旧 Vue2 页面优先通过 Authorization Header 拿 token。
      // 如果旧系统只能读 URL 参数，建议后端换成短期 ticket，避免长 token 暴露在地址栏。
      ..loadRequest(uri, headers: {'Authorization': 'Bearer $token'});

    setState(() => _controller = controller);
  }

  void _showError(_LegacyError error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = error;
      _progress = 100;
    });
  }

  void _retry() {
    final uri = _currentUri;
    if (uri == null || _controller == null) {
      setState(() {
        _configured = false;
        _error = null;
      });
      _configureAndLoad();
      return;
    }

    final token = AppScope.of(context).authController.session?.token ?? '';
    setState(() {
      _error = null;
      _progress = 0;
    });
    _controller!.loadRequest(uri, headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: error != null
          ? AppErrorView(
              icon: Icons.cloud_off_outlined,
              tone: error.tone,
              title: error.title,
              message: error.message,
              detail: error.detail,
              primaryLabel: '重试',
              onPrimary: _retry,
              secondaryLabel: '返回工作台',
              onSecondary: () => context.go('/home'),
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

class _LegacyError {
  const _LegacyError({
    required this.title,
    required this.message,
    this.detail,
    this.tone = AppErrorTone.error,
  });

  final String title;
  final String message;
  final String? detail;
  final AppErrorTone tone;
}
