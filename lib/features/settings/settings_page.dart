// -----------------------------------------------------------------------------
// 文件：settings_page.dart
// 作用：展示企业安全、语言、资源更新、Bridge、版本和诊断日志设置入口
// 编写时间：2026-07-10
// 维护说明：设置状态由 SettingsController 维护，本页面不直接读写本地存储
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/config/app_config.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_dialog.dart';
import '../../shared/app_notice.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settingsController;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: ListView(
              children: [
                const _SettingsHeader(),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: context.l10n.security,
                  children: [
                    SwitchListTile(
                      value: settings.unlockMethod == UnlockMethod.gesture,
                      secondary: const Icon(Icons.pattern_outlined),
                      title: Text(context.l10n.gestureUnlock),
                      subtitle: Text(context.l10n.gestureUnlockSubtitle),
                      onChanged: (enabled) {
                        if (enabled) {
                          _selectUnlockMethod(
                            context,
                            settings,
                            UnlockMethod.gesture,
                          );
                        }
                      },
                    ),
                    SwitchListTile(
                      value: settings.unlockMethod == UnlockMethod.fingerprint,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(context.l10n.fingerprintUnlock),
                      subtitle: Text(context.l10n.fingerprintUnlockSubtitle),
                      onChanged: (enabled) {
                        if (enabled) {
                          _selectUnlockMethod(
                            context,
                            settings,
                            UnlockMethod.fingerprint,
                          );
                        }
                      },
                    ),
                    SwitchListTile(
                      value: settings.unlockMethod == UnlockMethod.face,
                      secondary: const Icon(Icons.face_outlined),
                      title: Text(context.l10n.faceUnlock),
                      subtitle: Text(context.l10n.faceUnlockSubtitle),
                      onChanged: (enabled) {
                        if (enabled) {
                          _selectUnlockMethod(
                            context,
                            settings,
                            UnlockMethod.face,
                          );
                        }
                      },
                    ),
                    SwitchListTile(
                      value: settings.autoLockEnabled,
                      secondary: const Icon(Icons.lock_clock_outlined),
                      title: Text(context.l10n.autoLock),
                      subtitle: Text(context.l10n.autoLockSubtitle),
                      onChanged: settings.setAutoLockEnabled,
                    ),
                    ListTile(
                      leading: const Icon(Icons.pattern_outlined),
                      title: Text(context.l10n.changeGesturePassword),
                      subtitle: Text(
                        settings.gesturePasswordConfigured
                            ? context.l10n.gestureConfigured
                            : context.l10n.gestureNotConfigured,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppNavigator.openSecondary(
                        context,
                        settings.gesturePasswordConfigured
                            ? AppRoute.gesture
                            : AppRoute.gestureEnrollment,
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: context.l10n.general,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: Text(context.l10n.language),
                      subtitle: Text(
                        _languageLabel(context, settings.language),
                      ),
                      trailing: DropdownButton<AppLanguage>(
                        value: settings.language,
                        underline: const SizedBox.shrink(),
                        items: AppLanguage.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(_languageLabel(context, item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settings.setLanguage(value);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: Text(context.l10n.switchServer),
                      subtitle: Text(
                        context.l10n.currentServer(
                          _apiServerLabel(context, settings.apiServer),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectApiServer(context, settings),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.integration_instructions_outlined,
                      ),
                      title: Text(context.l10n.bridgeTest),
                      subtitle: Text(context.l10n.bridgeTestSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppNavigator.openSecondary(
                        context,
                        AppRoute.bridgeTest,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(context.l10n.diagnosticLogs),
                      subtitle: Text(context.l10n.diagnosticLogsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          AppNavigator.openSecondary(context, AppRoute.logs),
                    ),
                    ListTile(
                      leading: const Icon(Icons.system_update_alt_outlined),
                      title: Text(context.l10n.versionCheck),
                      subtitle: Text(
                        context.l10n.currentVersion(settings.currentVersion),
                      ),
                      trailing: OutlinedButton(
                        onPressed: settings.isVersionChecking
                            ? null
                            : () => _checkVersion(context, settings),
                        child: settings.isVersionChecking
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.check),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _selectUnlockMethod(
    BuildContext context,
    SettingsController settings,
    UnlockMethod method,
  ) async {
    if (settings.unlockMethod == method) {
      return;
    }
    final ok = await settings.setUnlockMethod(method);
    if (!context.mounted || ok) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        tone: AppDialogTone.warning,
        icon: method == UnlockMethod.face
            ? Icons.face_outlined
            : Icons.fingerprint,
        title: context.l10n.biometricUnavailableTitle,
        message:
            settings.lastBiometricError ?? context.l10n.biometricUnavailable,
        primaryLabel: context.l10n.acknowledge,
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _checkVersion(
    BuildContext context,
    SettingsController settings,
  ) async {
    final scope = AppScope.of(context);
    VersionCheckResult result;
    try {
      result = await settings.checkVersion(
        apiClient: scope.apiClient,
        versionCheckPath: scope.config.versionCheckPath,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      AppNotice.show(
        context,
        message: context.l10n.versionCheckFailed,
        tone: AppNoticeTone.error,
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (!result.hasUpdate) {
      AppNotice.show(
        context,
        message: context.l10n.alreadyLatestVersion(result.currentVersion),
        tone: AppNoticeTone.success,
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        tone: AppDialogTone.info,
        icon: Icons.system_update_alt_rounded,
        title: context.l10n.newVersion,
        message: context.l10n.versionResult(
          result.message,
          result.currentVersion,
          result.latestVersion,
        ),
        primaryLabel: context.l10n.acknowledge,
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _selectApiServer(
    BuildContext context,
    SettingsController settings,
  ) async {
    final scope = AppScope.of(context);
    final config = scope.config;
    var selected = settings.apiServer;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.selectServer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<ApiServer>(
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selected = value);
                  }
                },
                child: Column(
                  children: ApiServer.values.map((server) {
                    final available = config.isApiServerAvailable(server);
                    return RadioListTile<ApiServer>(
                      value: server,
                      title: Text(_apiServerLabel(context, server)),
                      enabled: available,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == settings.apiServer) {
      return;
    }

    final apiBaseUrl = config.apiBaseUrlFor(selected);
    try {
      scope.apiClient.updateBaseUrl(apiBaseUrl);
      await settings.setApiServer(selected);
    } on ArgumentError {
      if (!context.mounted) {
        return;
      }
      AppNotice.show(
        context,
        message: context.l10n.serverConfigurationInvalid,
        tone: AppNoticeTone.error,
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    AppNotice.show(
      context,
      message: context.l10n.serverSwitched(_apiServerLabel(context, selected)),
      tone: AppNoticeTone.success,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SettingsPage._brandBlue)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: IconButton(
              tooltip: context.l10n.back,
              onPressed: () => AppNavigator.backToHome(context),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: SettingsPage._brandBlue,
            ),
          ),
          Text(
            context.l10n.systemSettings,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: SettingsPage._brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _languageLabel(BuildContext context, AppLanguage language) {
  return switch (language) {
    AppLanguage.zhHans => context.l10n.simplifiedChinese,
    AppLanguage.zhHant => context.l10n.traditionalChinese,
  };
}

String _apiServerLabel(BuildContext context, ApiServer server) {
  return switch (server) {
    ApiServer.china => context.l10n.chinaDmz,
    ApiServer.hk => context.l10n.hkDmz,
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF8A8A8A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
