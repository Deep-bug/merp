import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
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
                  title: '安全',
                  children: [
                    SwitchListTile(
                      value: settings.biometricEnabled,
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('启用指纹解锁'),
                      subtitle: const Text('用于自动锁屏后的快速解锁'),
                      onChanged: (value) async {
                        final ok = await settings.setBiometricEnabled(value);
                        if (!context.mounted || ok) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              settings.lastBiometricError ?? '当前设备无法启用指纹解锁',
                            ),
                          ),
                        );
                      },
                    ),
                    SwitchListTile(
                      value: settings.autoLockEnabled,
                      secondary: const Icon(Icons.lock_clock_outlined),
                      title: const Text('自动锁屏'),
                      subtitle: const Text('开启后 10 秒未操作自动锁屏'),
                      onChanged: settings.setAutoLockEnabled,
                    ),
                    ListTile(
                      leading: const Icon(Icons.pattern_outlined),
                      title: const Text('修改图形密码'),
                      subtitle: Text(
                        settings.gesturePasswordConfigured
                            ? '已设置手势密码'
                            : '未设置手势密码',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/gesture'),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: '通用',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('设置语言'),
                      subtitle: Text(settings.language.label),
                      trailing: DropdownButton<AppLanguage>(
                        value: settings.language,
                        underline: const SizedBox.shrink(),
                        items: AppLanguage.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
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
                      title: const Text('静态资源热更新演示'),
                      subtitle: const Text('本地模拟资源清单更新首页背景和图标颜色'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/resource-update'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.integration_instructions_outlined,
                      ),
                      title: const Text('WebView Bridge 测试'),
                      subtitle: const Text('验证 Vue/H5 页面调用 Flutter 原生能力'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings/bridge-test'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.system_update_alt_outlined),
                      title: const Text('版本检测'),
                      subtitle: const Text('当前版本 1.0.0'),
                      trailing: OutlinedButton(
                        onPressed: () => _checkVersion(context, settings),
                        child: const Text('检查'),
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
        title: Text(result.hasUpdate ? '发现新版本' : '版本检测'),
        content: Text(
          '${result.message}\n当前版本：${result.currentVersion}\n最新版本：${result.latestVersion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
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
              tooltip: '返回',
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: SettingsPage._brandBlue,
            ),
          ),
          Text(
            '系统设置',
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
