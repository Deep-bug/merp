// -----------------------------------------------------------------------------
// 文件：app_error_view.dart
// 作用：统一展示错误、警告、空状态、详情和恢复操作
// 编写时间：2026-07-10
// 维护说明：业务页面传入语义信息，颜色和布局统一在此维护
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

enum AppErrorTone { info, warning, error }

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = AppErrorTone.error,
    this.detail,
    this.referenceId,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final AppErrorTone tone;
  final String? detail;
  final String? referenceId;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toneColor = switch (tone) {
      AppErrorTone.info => colorScheme.primary,
      AppErrorTone.warning => const Color(0xFFB26A00),
      AppErrorTone.error => colorScheme.error,
    };

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 统一错误/提示页入口：业务页面只传标题、提示文案和按钮，
                    // 具体排版、颜色和详情样式都在这里集中维护。
                    Icon(icon, size: 48, color: toneColor),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (detail != null && detail!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          detail!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                    if (referenceId != null && referenceId!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SelectableText(
                        '故障编号 / Incident: $referenceId',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: toneColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (referenceId != null && referenceId!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SelectableText(
                        '故障编号 / Incident: $referenceId',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: toneColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (secondaryLabel != null && onSecondary != null)
                          OutlinedButton(
                            onPressed: onSecondary,
                            child: Text(secondaryLabel!),
                          ),
                        if (primaryLabel != null && onPrimary != null)
                          FilledButton(
                            onPressed: onPrimary,
                            child: Text(primaryLabel!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
