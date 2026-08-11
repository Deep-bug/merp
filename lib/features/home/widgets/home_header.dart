// -----------------------------------------------------------------------------
// 文件：home_header.dart
// 作用：展示首页品牌标题、侧边栏入口和个人中心入口
// 编写时间：2026-07-10
// 维护说明：头部保持固定高度，避免中低端设备滚动时反复测量布局
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.brandColor,
    required this.onProfile,
  });

  final Color brandColor;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            child: IconButton(
              tooltip: context.l10n.menu,
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, size: 34),
              color: brandColor,
            ),
          ),
          Text(
            'MERP 2026',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: brandColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Positioned(
            right: 18,
            child: IconButton(
              tooltip: context.l10n.profile,
              onPressed: onProfile,
              icon: const Icon(Icons.person, size: 34),
              color: brandColor,
            ),
          ),
        ],
      ),
    );
  }
}
