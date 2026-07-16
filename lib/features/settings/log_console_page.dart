// -----------------------------------------------------------------------------
// 文件：log_console_page.dart
// 作用：向测试、运维和研发展示设备端结构化诊断日志及故障编号
// 编写时间：2026-07-10
// 维护说明：页面只读 AppLogger 缓冲区，不在此实现日志采集规则
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../core/logging/app_logger.dart';
import '../../l10n/l10n.dart';

class LogConsolePage extends StatelessWidget {
  const LogConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppScope.of(context).logger;

    return AnimatedBuilder(
      animation: logger,
      builder: (context, _) {
        final entries = logger.entries.reversed.toList(growable: false);
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.logConsole),
            actions: [
              IconButton(
                tooltip: context.l10n.copyLogs,
                onPressed: entries.isEmpty
                    ? null
                    : () => _copy(context, logger),
                icon: const Icon(Icons.copy_all_outlined),
              ),
              IconButton(
                tooltip: context.l10n.clearLogs,
                onPressed: entries.isEmpty ? null : logger.clear,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: entries.isEmpty
              ? Center(child: Text(context.l10n.logEmpty))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _LogEntryTile(entry: entries[index]),
                ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, AppLogger logger) async {
    await Clipboard.setData(ClipboardData(text: logger.exportText()));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.logsCopied)));
    }
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final AppLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      AppLogLevel.debug => const Color(0xFF64748B),
      AppLogLevel.info => const Color(0xFF0F6CBD),
      AppLogLevel.warning => const Color(0xFFB26A00),
      AppLogLevel.error || AppLogLevel.fatal => const Color(0xFFB3261E),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.level.name.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _formatTime(entry.timestamp),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(entry.message),
            if (entry.incidentId != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                context.l10n.errorReference(entry.incidentId!),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
            if (entry.fields.isNotEmpty) ...[
              const SizedBox(height: 6),
              SelectableText(
                entry.fields.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (entry.error != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                entry.error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}
