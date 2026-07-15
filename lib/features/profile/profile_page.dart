// -----------------------------------------------------------------------------
// 文件：profile_page.dart
// 作用：展示当前会话从 userInfo 接口取得的个人资料和用户功能入口
// 编写时间：2026-07-15
// 维护说明：页面只消费 AuthSession，不直接请求或解析用户信息接口
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/auth/auth_models.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).authController;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: auth,
          builder: (context, _) {
            final profile = auth.session?.profile;
            return Column(
              children: [
                const _ProfileHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    children: [
                      _ProfileSummary(profile: profile),
                      const SizedBox(height: 22),
                      _ProfileDetails(profile: profile),
                      const SizedBox(height: 18),
                      _ProfileMenuItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: context.l10n.reportSubscription,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.reportSubscriptionReserved,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              tooltip: context.l10n.back,
              onPressed: () => context.go(AppRoute.home),
              icon: const Icon(Icons.chevron_left, size: 36),
              color: ProfilePage._brandBlue,
            ),
          ),
          Text(
            context.l10n.profile,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF273142),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileAvatar(profile: profile),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.displayName ?? context.l10n.currentUser,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF202A3A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile?.department.isNotEmpty == true
                    ? profile!.department
                    : context.l10n.departmentNotProvided,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D7788)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    return ClipOval(
      child: SizedBox.square(
        dimension: 72,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFFE6EEFC),
                child: Icon(
                  Icons.person,
                  size: 42,
                  color: ProfilePage._brandBlue,
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE6EEFC),
                  child: Icon(
                    Icons.person,
                    size: 42,
                    color: ProfilePage._brandBlue,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.badge_outlined,
            label: context.l10n.userId,
            value: _displayValue(context, profile?.id),
          ),
          _DetailRow(
            icon: Icons.account_circle_outlined,
            label: context.l10n.account,
            value: _displayValue(context, profile?.accountName),
          ),
          _DetailRow(
            icon: Icons.mail_outline,
            label: context.l10n.email,
            value: _displayValue(context, profile?.email),
          ),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: context.l10n.phone,
            value: _displayValue(context, profile?.phone),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  String _displayValue(BuildContext context, String? value) {
    return value == null || value.isEmpty ? context.l10n.notProvided : value;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: ProfilePage._brandBlue),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF697386),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 52, color: Color(0xFFE9EDF3)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF333333)),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Color(0xFF9B9B9B)),
            ],
          ),
        ),
      ),
    );
  }
}
