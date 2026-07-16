// -----------------------------------------------------------------------------
// 文件：splash_page.dart
// 作用：承接原生启动图后的 Flutter 品牌加载页，避免冷启动白屏
// 编写时间：2026-07-10
// 维护说明：页面仅展示轻量静态组件，不在 build 中执行初始化任务
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.isBootstrapping = false});

  final bool isBootstrapping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _MerpLaunchMark(size: 108),
                const SizedBox(height: 26),
                Text(
                  'MERP 2025',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF1A67C9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.workbench,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF49657D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  isBootstrapping
                      ? context.l10n.loadingWorkbench
                      : context.l10n.restoringSession,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7D8E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MerpLaunchMark extends StatelessWidget {
  const _MerpLaunchMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F80ED), Color(0xFF38BDF8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A67C9).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -16,
            bottom: -10,
            child: Icon(
              Icons.cloud,
              size: size * 0.58,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MERP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: size * 0.05),
              Container(
                width: size * 0.46,
                height: size * 0.18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * 0.09),
                ),
                child: Text(
                  'ERP',
                  style: TextStyle(
                    color: const Color(0xFF1A67C9),
                    fontSize: size * 0.10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
