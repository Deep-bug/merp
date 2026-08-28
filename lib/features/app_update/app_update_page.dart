// -----------------------------------------------------------------------------
// 文件：app_update_page.dart
// 作用：展示不可关闭的强制升级、Android 下载进度和 iOS 企业安装入口
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'app_update_controller.dart';

class AppUpdatePage extends StatelessWidget {
  const AppUpdatePage({super.key, required this.controller});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.updateInfo;
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.system_update_alt_rounded,
                            size: 34,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.forceUpdateTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.forceUpdateMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                        if (info != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F6FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.updateVersion(
                                    info.latestVersionName,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.l10n.updateNotes,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  info.releaseNotes,
                                  style: const TextStyle(height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (controller.isDownloading) ...[
                          const SizedBox(height: 24),
                          _DownloadProgress(controller: controller),
                        ],
                        if (controller.status == AppUpdateStatus.failed) ...[
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.updateFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (controller.status ==
                            AppUpdateStatus.permissionRequired) ...[
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.installPermissionHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                        if (controller.status ==
                            AppUpdateStatus.simulatedDownloadComplete) ...[
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF1B8F4D),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.l10n.mockDownloadComplete,
                                  style: const TextStyle(
                                    color: Color(0xFF176B3A),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!controller.isDownloading &&
                            controller.status !=
                                AppUpdateStatus.simulatedDownloadComplete) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed:
                                  controller.status == AppUpdateStatus.checking
                                  ? null
                                  : controller.status == AppUpdateStatus.failed
                                  ? controller.retry
                                  : controller.startUpdate,
                              icon: const Icon(Icons.download_rounded),
                              label: Text(_actionLabel(context)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _actionLabel(BuildContext context) {
    return switch (controller.status) {
      AppUpdateStatus.failed => context.l10n.retryDownload,
      AppUpdateStatus.permissionRequired => context.l10n.continueInstall,
      AppUpdateStatus.installerOpened => context.l10n.openInstallAgain,
      _ =>
        controller.isIos ? context.l10n.updateNow : context.l10n.downloadUpdate,
    };
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.controller});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.downloadProgress;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.downloadingUpdate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (progress != null) Text('${(progress * 100).floor()}%'),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            controller.totalBytes > 0
                ? '${_formatBytes(controller.receivedBytes)} / '
                      '${_formatBytes(controller.totalBytes)}'
                : context.l10n.downloadedSize(
                    _formatBytes(controller.receivedBytes),
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
