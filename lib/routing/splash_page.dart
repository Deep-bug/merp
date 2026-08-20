// -----------------------------------------------------------------------------
// 文件：splash_page.dart
// 作用：承接原生启动图后的 Flutter 品牌加载页，避免冷启动白屏
// 编写时间：2026-07-10
// 维护说明：页面仅展示轻量静态组件，不在 build 中执行初始化任务
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../core/auth/auth_controller.dart';
import '../l10n/l10n.dart';
import '../shared/app_error_view.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.isBootstrapping = false});

  final bool isBootstrapping;

  @override
  Widget build(BuildContext context) {
    if (!isBootstrapping) {
      final auth = AppScope.of(context).authController;
      return AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          if (auth.status == AuthStatus.restoreFailed) {
            return Scaffold(
              backgroundColor: const Color(0xFFEAF4FF),
              body: SafeArea(
                child: AppErrorView(
                  icon: Icons.wifi_off_outlined,
                  title: context.l10n.startupFailed,
                  message: context.l10n.startupFailedMessage,
                  detail: auth.lastError,
                  secondaryLabel: context.l10n.clearSessionAndLogin,
                  onSecondary: auth.discardStoredSession,
                  primaryLabel: context.l10n.retry,
                  onPrimary: auth.retryRestoreSession,
                ),
              ),
            );
          }
          return _buildLoadingPage(context);
        },
      );
    }
    return _buildLoadingPage(context);
  }

  Widget _buildLoadingPage(BuildContext context) {
    return const _SplashLoadingPage();
  }
}

class _SplashLoadingPage extends StatelessWidget {
  const _SplashLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/splash_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x55FFFFFF),
                ],
              ),
            ),
          ),
          const SafeArea(
            child: Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
