// -----------------------------------------------------------------------------
// 文件：profile_page.dart
// 作用：展示当前会话从 userInfo 接口取得的个人资料和用户功能入口
// 编写时间：2026-07-15
// 维护说明：页面只消费 AuthSession，不直接请求或解析用户信息接口
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../shared/app_notice.dart';

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
            return Column(
              children: [
                const _ProfileHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    children: [
                      Text(
                        context.l10n.profile,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF273142),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProfileMenuItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: context.l10n.reportSubscription,
                        onTap: () {
                          AppNotice.show(
                            context,
                            message: context.l10n.reportSubscriptionReserved,
                            tone: AppNoticeTone.info,
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
      height: 92,
      width: double.infinity,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: IconButton(
                tooltip: context.l10n.back,
                onPressed: () => AppNavigator.backToHome(context),
                icon: const Icon(Icons.chevron_left, size: 36),
                color: ProfilePage._brandBlue,
              ),
            ),
          ),
          Text(
            'MERP 2026',
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
