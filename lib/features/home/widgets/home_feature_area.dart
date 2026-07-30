// -----------------------------------------------------------------------------
// 文件：home_feature_area.dart
// 作用：展示首页授权功能卡片、更多入口和权限空状态
// 编写时间：2026-07-10
// 维护说明：点击前必须再次校验权限和路由，不能只依赖界面是否显示
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../l10n/l10n.dart';
import '../../../routing/app_navigator.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/adaptive_feature_grid.dart';
import '../../../shared/app_error_view.dart';
import '../data/permission_repository.dart';
import '../domain/feature_item.dart';
import 'feature_icon.dart';

class HomeFeatureArea extends StatelessWidget {
  const HomeFeatureArea({
    super.key,
    required this.features,
    required this.hasAnyFeature,
    required this.hasAuthorizedFeature,
    required this.loadStatus,
    required this.onRetry,
    required this.iconColor,
  });

  final List<FeatureItem> features;
  final bool hasAnyFeature;
  final bool hasAuthorizedFeature;
  final PermissionLoadStatus loadStatus;
  final Future<void> Function() onRetry;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (loadStatus == PermissionLoadStatus.idle ||
        loadStatus == PermissionLoadStatus.loading) {
      return const _FeatureLoadingSkeleton();
    }

    if (loadStatus == PermissionLoadStatus.failed) {
      return AppErrorView(
        icon: Icons.cloud_off_outlined,
        title: context.l10n.pageLoadFailed,
        message: context.l10n.pageLoadFailedMessage,
        primaryLabel: context.l10n.retry,
        onPrimary: onRetry,
      );
    }

    if (features.isEmpty && !hasAnyFeature) {
      return AppErrorView(
        icon: Icons.apps_outlined,
        title: context.l10n.noFeatures,
        message: context.l10n.noFeaturesMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (features.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppErrorView(
              icon: hasAuthorizedFeature
                  ? Icons.star_border_rounded
                  : Icons.lock_outline,
              tone: hasAuthorizedFeature
                  ? AppErrorTone.info
                  : AppErrorTone.warning,
              title: hasAuthorizedFeature
                  ? context.l10n.noFavoriteFeatures
                  : context.l10n.noAuthorizedFeatures,
              message: hasAuthorizedFeature
                  ? context.l10n.noFavoriteFeaturesMessage
                  : context.l10n.noAuthorizedFeaturesMessage,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = AdaptiveFeatureGridMetrics.home(
              context,
              constraints.maxWidth,
            );
            return GridView.builder(
              itemCount: features.length + 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: metrics.spacing,
                crossAxisSpacing: metrics.spacing,
                mainAxisExtent: metrics.mainAxisExtent,
              ),
              itemBuilder: (context, index) => index == features.length
                  ? _MoreFeatureTile(iconColor: iconColor)
                  : _FeatureTile(item: features[index], iconColor: iconColor),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureLoadingSkeleton extends StatelessWidget {
  const _FeatureLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = AdaptiveFeatureGridMetrics.home(
          context,
          constraints.maxWidth,
        );
        return GridView.builder(
          itemCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: metrics.spacing,
            crossAxisSpacing: metrics.spacing,
            mainAxisExtent: metrics.mainAxisExtent,
          ),
          itemBuilder: (_, _) => const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF0F3F7),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item, required this.iconColor});

  final FeatureItem item;
  final Color iconColor;

  void _open(BuildContext context) {
    final permissions = AppScope.of(context).permissionRepository;
    if (!permissions.canOpen(item)) {
      AppNavigator.openSecondary(context, AppRoute.forbidden);
      return;
    }
    if (item.route.trim().isEmpty) {
      _showMissingRouteDialog(context, item.title);
      return;
    }
    AppNavigator.openFeature(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    return HomeFeatureCard(
      item: item,
      label: item.title,
      iconColor: iconColor,
      onTap: () => _open(context),
    );
  }
}

class _MoreFeatureTile extends StatelessWidget {
  const _MoreFeatureTile({required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return HomeFeatureCard(
      icon: Icons.grid_view_rounded,
      label: context.l10n.more,
      iconColor: iconColor,
      onTap: () => AppNavigator.openSecondary(context, AppRoute.features),
    );
  }
}

/// 首页功能方块的统一视觉组件，也供收藏排序网格复用。
class HomeFeatureCard extends StatelessWidget {
  const HomeFeatureCard({
    super.key,
    this.icon,
    this.item,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.compact = false,
  }) : assert(icon != null || item != null);

  final IconData? icon;
  final FeatureItem? item;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = compact ? 36.0 : 54.0;
    final iconSize = compact ? 24.0 : 36.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: compact ? const Color(0xFF8FE4E8) : const Color(0xFFF2F5F8),
          width: compact ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29435C).withValues(alpha: 0.12),
            blurRadius: compact ? 8 : 18,
            offset: Offset(0, compact ? 4 : 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 8,
              vertical: compact ? 6 : 13,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: compact
                      ? null
                      : BoxDecoration(
                          color: iconColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                  child: item == null
                      ? Icon(icon, size: iconSize, color: iconColor)
                      : FeatureIcon(
                          item: item!,
                          size: iconSize,
                          color: iconColor,
                        ),
                ),
                SizedBox(height: compact ? 6 : 12),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF2E2F33),
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        )
                      : Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF2E2F33),
                          fontWeight: FontWeight.w800,
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

void _showMissingRouteDialog(BuildContext context, String title) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.missingRoute),
      content: Text(context.l10n.missingRouteMessage(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.acknowledge),
        ),
      ],
    ),
  );
}
