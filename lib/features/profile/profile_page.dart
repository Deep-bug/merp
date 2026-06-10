import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              '个人中心',
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
              label: '报表订阅',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('报表订阅功能预留中')));
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
              tooltip: '返回',
              onPressed: () => context.go('/home'),
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
