// -----------------------------------------------------------------------------
// 文件：app_notice.dart
// 作用：统一应用内轻量信息、成功、警告和错误浮动提示
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

enum AppNoticeTone { info, success, warning, error }

abstract final class AppNotice {
  static void show(
    BuildContext context, {
    required String message,
    AppNoticeTone tone = AppNoticeTone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final (background, icon) = switch (tone) {
      AppNoticeTone.info => (const Color(0xFF245FAD), Icons.info_outline),
      AppNoticeTone.success => (
        const Color(0xFF197653),
        Icons.check_circle_outline,
      ),
      AppNoticeTone.warning => (
        const Color(0xFF9A5800),
        Icons.warning_amber_rounded,
      ),
      AppNoticeTone.error => (
        const Color(0xFFB3261E),
        Icons.error_outline_rounded,
      ),
    };
    final duration = switch (tone) {
      AppNoticeTone.info || AppNoticeTone.success => const Duration(seconds: 2),
      AppNoticeTone.warning ||
      AppNoticeTone.error => const Duration(seconds: 4),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          backgroundColor: background,
          elevation: 8,
          duration: duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ),
            ],
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}
