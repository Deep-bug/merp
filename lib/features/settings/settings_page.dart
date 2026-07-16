// -----------------------------------------------------------------------------
// 文件：settings_page.dart
// 作用：展示企业安全、语言、资源更新、Bridge、版本和诊断日志设置入口
// 编写时间：2026-07-10
// 维护说明：设置状态由 SettingsController 维护，本页面不直接读写本地存储
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';
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
                      value: settings.biometricEnabled,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(context.l10n.enableBiometric),
                      subtitle: Text(context.l10n.biometricSubtitle),
                      onChanged: (value) async {
                        final ok = await settings.setBiometricEnabled(value);
                        if (!context.mounted || ok) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              settings.lastBiometricError ??
                                  context.l10n.biometricUnavailable,
                            ),
                          ),
                        );
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
                      onTap: () =>
                          AppNavigator.openSecondary(context, AppRoute.gesture),
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
                      leading: const Icon(Icons.dynamic_feed_outlined),
                      title: Text(context.l10n.resourceUpdate),
                      subtitle: Text(context.l10n.resourceUpdateSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppNavigator.openSecondary(
                        context,
                        AppRoute.resourceUpdate,
                      ),
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
                      subtitle: Text(context.l10n.currentVersion('1.0.0')),
                      trailing: OutlinedButton(
                        onPressed: () => _checkVersion(context, settings),
                        child: Text(context.l10n.check),
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

  Future<void> _checkVersion(
    BuildContext context,
    SettingsController settings,
  ) async {
    final result = await settings.checkVersion();
    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.hasUpdate
              ? context.l10n.newVersion
              : context.l10n.versionCheck,
        ),
        content: Text(
          context.l10n.versionResult(
            result.message,
            result.currentVersion,
            result.latestVersion,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.acknowledge),
          ),
        ],
      ),
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
