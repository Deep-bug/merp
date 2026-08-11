// -----------------------------------------------------------------------------
// 文件：app_dialog.dart
// 作用：统一应用内信息、成功、警告、错误和确认弹窗的视觉与交互
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppDialogTone { info, success, warning, error }

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.referenceId,
    this.referenceLabel = '故障编号',
    this.primaryDestructive = false,
  });

  final AppDialogTone tone;
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? referenceId;
  final String referenceLabel;
  final bool primaryDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = switch (tone) {
      AppDialogTone.info => const Color(0xFF246BCE),
      AppDialogTone.success => const Color(0xFF16835B),
      AppDialogTone.warning => const Color(0xFFC46A00),
      AppDialogTone.error => colors.error,
    };
    final reference = referenceId?.trim();

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: toneColor.withValues(alpha: 0.11),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 28, color: toneColor),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF202A36),
          fontWeight: FontWeight.w700,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5A6674),
                  height: 1.5,
                ),
              ),
              if (reference != null && reference.isNotEmpty) ...[
                const SizedBox(height: 16),
                Material(
                  color: const Color(0xFFF3F6F9),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Clipboard.setData(ClipboardData(text: reference)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$referenceLabel：$reference',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (secondaryLabel != null && onSecondary != null)
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ),
        SizedBox(
          height: 46,
          child: FilledButton(
            style: primaryDestructive
                ? FilledButton.styleFrom(backgroundColor: colors.error)
                : FilledButton.styleFrom(backgroundColor: toneColor),
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
