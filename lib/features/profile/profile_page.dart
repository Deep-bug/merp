// -----------------------------------------------------------------------------
// 文件：profile_page.dart
// 作用：展示当前账号个人中心和用户级功能入口
// 编写时间：2026-07-10
// 维护说明：后续个人资料数据应由独立 Repository 提供
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 68),
            Text(
              context.l10n.profile,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF9B9B9B),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: const Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 24),
            _ProfileMenuItem(
              icon: Icons.assignment_turned_in_outlined,
              label: context.l10n.reportSubscription,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.reportSubscriptionReserved),
                  ),
                );
              },
            ),
          ],
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
      height: 92,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ProfilePage._brandBlue, width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: IconButton(
              tooltip: context.l10n.back,
              onPressed: () => context.go(AppRoute.home),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: ProfilePage._brandBlue,
            ),
          ),
          Text(
            'MERP 2025',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ProfilePage._brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF333333)),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF9B9B9B), size: 38),
          ],
        ),
      ),
    );
  }
}
