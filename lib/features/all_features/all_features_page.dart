import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../shared/app_error_view.dart';
import '../home/domain/feature_item.dart';

class AllFeaturesPage extends StatelessWidget {
  const AllFeaturesPage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);
  static const _enabledBlue = Color(0xFF16A3DE);
  static const _disabledGrey = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    final permissions = AppScope.of(context).permissionRepository;

    return AnimatedBuilder(
      animation: permissions,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFD),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _AllFeaturesHeader()),
                if (permissions.allFeatures.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorView(
                      icon: Icons.apps_outlined,
                      title: '暂无功能清单',
                      message: '后端没有返回全部功能数据，请检查菜单权限接口。',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = permissions.allFeatures[index];
                        final enabled = permissions.canOpen(item);
                        return _AllFeatureTile(item: item, enabled: enabled);
                      }, childCount: permissions.allFeatures.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 0.86,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AllFeaturesHeader extends StatelessWidget {
  const _AllFeaturesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: IconButton(
              tooltip: '返回',
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: AllFeaturesPage._brandBlue,
            ),
          ),
          Text(
            '全部功能',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AllFeaturesPage._brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllFeatureTile extends StatelessWidget {
  const _AllFeatureTile({required this.item, required this.enabled});

  final FeatureItem item;
  final bool enabled;

  void _open(BuildContext context) {
    if (!enabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('当前账号没有“${item.title}”的访问权限')));
      return;
    }

    if (item.route.trim().isEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('功能路由未配置'),
          content: Text('功能“${item.title}”没有配置 route，请联系管理员检查菜单配置。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    context.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled
        ? AllFeaturesPage._enabledBlue
        : AllFeaturesPage._disabledGrey;
    final textColor = enabled
        ? const Color(0xFF2E2F33)
        : const Color(0xFF9A9A9A);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? const Color(0xFFF0F5FA) : const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: const Color(0xFF29435C).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: enabled ? 0.10 : 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 34, color: iconColor),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: enabled ? 0.10 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    enabled ? '已授权' : '未授权',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
