// -----------------------------------------------------------------------------
// 文件：all_features_page.dart
// 作用：展示后端完整功能清单及当前账号授权状态
// 编写时间：2026-07-10
// 维护说明：权限判断统一委托 PermissionRepository，灰色入口不可绕过校验
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../shared/app_error_view.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../shared/adaptive_feature_grid.dart';
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
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorView(
                      icon: Icons.apps_outlined,
                      title: context.l10n.noFeatureList,
                      message: context.l10n.noFeatureListMessage,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final metrics = AdaptiveFeatureGridMetrics.allFeatures(
                          context,
                          constraints.crossAxisExtent,
                        );
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = permissions.allFeatures[index];
                            final enabled = permissions.canOpen(item);
                            return _AllFeatureTile(
                              item: item,
                              enabled: enabled,
                            );
                          }, childCount: permissions.allFeatures.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: metrics.crossAxisCount,
                                mainAxisSpacing: metrics.spacing,
                                crossAxisSpacing: metrics.spacing,
                                mainAxisExtent: metrics.mainAxisExtent,
                              ),
                        );
                      },
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
              tooltip: context.l10n.back,
              onPressed: () => context.go(AppRoute.home),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: AllFeaturesPage._brandBlue,
            ),
          ),
          Text(
            context.l10n.allFeatures,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noFeaturePermission(item.title))),
      );
      return;
    }

    if (item.route.trim().isEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.missingRoute),
          content: Text(context.l10n.missingRouteMessage(item.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.acknowledge),
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
                    enabled
                        ? context.l10n.authorized
                        : context.l10n.unauthorized,
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
