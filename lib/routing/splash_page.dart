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
    return _SplashLoadingPage(
      message: isBootstrapping
          ? context.l10n.loadingWorkbench
          : context.l10n.restoringSession,
    );
  }
}

class _SplashLoadingPage extends StatefulWidget {
  const _SplashLoadingPage({required this.message});

  final String message;

  @override
  State<_SplashLoadingPage> createState() => _SplashLoadingPageState();
}

class _SplashLoadingPageState extends State<_SplashLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/test.png',
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
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MERP 2026',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFF1768C6),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF49657D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _LoadingDots(
                      animation: _controller,
                      reduceMotion: reduceMotion,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation, required this.reduceMotion});

  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (animation.value + index * 0.22) % 1.0;
            final opacity = 0.35 + phase * 0.65;
            final size = 7.0 + phase * 3.0;
            return Container(
              width: 18,
              alignment: Alignment.center,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF1768C6).withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
