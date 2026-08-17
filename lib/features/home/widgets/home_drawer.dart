// -----------------------------------------------------------------------------
// 文件：home_drawer.dart
// 作用：展示账号摘要、版本信息、系统设置和退出操作
// 编写时间：2026-07-10
// 维护说明：真实组织与工号数据接入后由用户资料模型提供
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/auth/auth_models.dart';
import '../../../l10n/l10n.dart';
import '../../../routing/app_navigator.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/app_dialog.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.profile,
    required this.brandColor,
  });

  final UserProfile? profile;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).authController;
    //为了取出版本号
    final settings = AppScope.of(context).settingsController;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.62,
      shape: const RoundedRectangleBorder(),
      backgroundColor: brandColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(child: _DrawerLogo(iconColor: brandColor)),
              const SizedBox(height: 28),
              Text(
                profile?.displayName ?? context.l10n.currentUser,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (profile?.id.isNotEmpty == true) ...[
                _DrawerProfileText(profile!.id),
                const SizedBox(height: 10),
              ],
              if (profile?.department.isNotEmpty == true) ...[
                _DrawerProfileText(profile!.department),
                const SizedBox(height: 8),
              ],
              if (profile?.accountName.isNotEmpty == true)
                _DrawerProfileText(profile!.accountName),
              const SizedBox(height: 26),
              AnimatedBuilder(
                animation: settings,
                builder: (context, _) =>
                    _VersionBadge(version: settings.currentVersion),
              ),
              const SizedBox(height: 72),
              _DrawerAction(
                label: context.l10n.systemSettings,
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  AppNavigator.openSecondary(context, AppRoute.settings);
                },
              ),
              const SizedBox(height: 26),
              _DrawerAction(
                label: context.l10n.logout,
                icon: Icons.logout,
                onTap: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AppDialog(
                          tone: AppDialogTone.warning,
                          icon: Icons.logout_rounded,
                          title: context.l10n.logoutConfirmTitle,
                          message: context.l10n.logoutConfirmMessage,
                          secondaryLabel: context.l10n.cancel,
                          onSecondary: () =>
                              Navigator.of(dialogContext).pop(false),
                          primaryLabel: context.l10n.logoutConfirmAction,
                          primaryDestructive: true,
                          onPrimary: () =>
                              Navigator.of(dialogContext).pop(true),
                        ),
                      ) ??
                      false;
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await auth.logout();
                  if (context.mounted) {
                    context.go(AppRoute.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLogo extends StatelessWidget {
  const _DrawerLogo({required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MERP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF4E5B67),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Icon(Icons.cloud_queue, color: iconColor, size: 30),
        ],
      ),
    );
  }
}

class _DrawerProfileText extends StatelessWidget {
  const _DrawerProfileText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.86),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Version : ',
          children: [
            TextSpan(
              text: version,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: const Color(0xFF30333A)),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
