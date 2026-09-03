// -----------------------------------------------------------------------------
// 文件：local_network_startup_gate.dart
// 作用：在登录页出现前完成 iOS 本地网络授权、会话恢复和验证码预取
// 维护说明：系统静态 LaunchScreen 不能申请权限，门禁必须运行在 Flutter 首帧后
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/local_network_access_service.dart';
import '../l10n/l10n.dart';

enum _StartupGateStatus { checking, denied, unavailable, complete }

class LocalNetworkStartupGate extends StatefulWidget {
  const LocalNetworkStartupGate({
    super.key,
    required this.apiBaseUrl,
    required this.authController,
    required this.networkAccess,
    required this.logger,
    required this.child,
  });

  final String apiBaseUrl;
  final AuthController authController;
  final LocalNetworkAccessChecking networkAccess;
  final AppLogger logger;
  final Widget child;

  @override
  State<LocalNetworkStartupGate> createState() =>
      _LocalNetworkStartupGateState();
}

class _LocalNetworkStartupGateState extends State<LocalNetworkStartupGate>
    with WidgetsBindingObserver {
  _StartupGateStatus _status = _StartupGateStatus.checking;
  bool _isRunning = false;
  bool _returningFromSettings = false;
  String? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromSettings) {
      _returningFromSettings = false;
      _runStartup();
    }
  }

  Future<void> _runStartup() async {
    if (!mounted || _isRunning || _status == _StartupGateStatus.complete) {
      return;
    }

    // Widget 测试、Mock模式或外部显式完成认证状态时不重复编排启动流程。
    if (widget.authController.status != AuthStatus.booting) {
      setState(() => _status = _StartupGateStatus.complete);
      return;
    }

    setState(() {
      _isRunning = true;
      _status = _StartupGateStatus.checking;
      _detail = null;
    });

    final access = await widget.networkAccess.check(widget.apiBaseUrl);
    if (!mounted) return;
    if (access.status == LocalNetworkAccessStatus.denied) {
      widget.logger.warning('network.permission', 'iOS 本地网络访问被用户拒绝');
      setState(() {
        _isRunning = false;
        _status = _StartupGateStatus.denied;
        _detail = access.detail;
      });
      return;
    }
    if (access.status == LocalNetworkAccessStatus.unavailable) {
      widget.logger.warning(
        'network.permission',
        'iOS 本地网络检查未通过',
        fields: {'detail': access.detail},
      );
      setState(() {
        _isRunning = false;
        _status = _StartupGateStatus.unavailable;
        _detail = access.detail;
      });
      return;
    }

    // 权限通过后才允许恢复 Token；未登录时在门禁内预取验证码，因此登录页
    // 首次显示时不会再与系统权限弹窗竞争。
    await widget.authController.restoreSession();
    if (!mounted) return;
    if (widget.authController.status == AuthStatus.unauthenticated &&
        widget.authController.captchaChallenge == null) {
      await widget.authController.refreshCaptcha();
    }
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _status = _StartupGateStatus.complete;
    });
  }

  Future<void> _openSettings() async {
    _returningFromSettings = true;
    final opened = await widget.networkAccess.openAppSettings();
    if (!opened) {
      _returningFromSettings = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _StartupGateStatus.complete) return widget.child;

    final denied = _status == _StartupGateStatus.denied;
    final unavailable = _status == _StartupGateStatus.unavailable;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!denied && !unavailable)
                    const SizedBox.square(
                      dimension: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else
                    Icon(
                      denied ? Icons.lan_outlined : Icons.cloud_off_outlined,
                      size: 54,
                      color: const Color(0xFF3978B7),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    denied
                        ? context.l10n.localNetworkRequiredTitle
                        : unavailable
                        ? context.l10n.localNetworkUnavailableTitle
                        : context.l10n.localNetworkChecking,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (denied || unavailable) ...[
                    const SizedBox(height: 10),
                    Text(
                      denied
                          ? context.l10n.localNetworkRequiredMessage
                          : context.l10n.localNetworkUnavailableMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_detail != null && _detail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _detail!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (denied)
                          OutlinedButton.icon(
                            onPressed: _openSettings,
                            icon: const Icon(Icons.settings_outlined),
                            label: Text(context.l10n.openSystemSettings),
                          ),
                        FilledButton.icon(
                          onPressed: _isRunning ? null : _runStartup,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
