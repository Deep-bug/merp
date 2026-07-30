// -----------------------------------------------------------------------------
// 文件：all_features_page.dart
// 作用：展示后端完整功能清单及当前账号授权状态
// 编写时间：2026-07-10
// 维护说明：权限判断统一委托 PermissionRepository，灰色入口不可绕过校验
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../shared/adaptive_feature_grid.dart';
import '../../shared/app_error_view.dart';
import '../home/domain/feature_item.dart';
import '../home/data/favorite_feature_controller.dart';
import '../home/widgets/feature_icon.dart';

class AllFeaturesPage extends StatelessWidget {
  const AllFeaturesPage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);
  static const _enabledBlue = Color(0xFF16A3DE);
  static const _disabledGrey = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    final permissions = AppScope.of(context).permissionRepository;
    final favorites = AppScope.of(context).favoriteFeatureController;

    return AnimatedBuilder(
      animation: Listenable.merge([permissions, favorites]),
      builder: (context, _) {
        final favoriteItems = favorites.favoritesFrom(
          permissions.authorizedFeatures,
        );
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFD),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _AllFeaturesHeader()),
                if (favoriteItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FavoriteSortSection(
                      items: favoriteItems,
                      controller: favorites,
                    ),
                  ),
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
                            final isFavorite = favorites.isFavorite(item.id);
                            return _AllFeatureTile(
                              item: item,
                              enabled: enabled,
                              isFavorite: isFavorite,
                              onFavorite: enabled || isFavorite
                                  ? () => favorites.toggle(item.id)
                                  : null,
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
              onPressed: () => AppNavigator.backToHome(context),
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
  const _AllFeatureTile({
    required this.item,
    required this.enabled,
    required this.isFavorite,
    required this.onFavorite,
  });

  final FeatureItem item;
  final bool enabled;
  final bool isFavorite;
  final VoidCallback? onFavorite;

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

    AppNavigator.openFeature(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled
        ? AllFeaturesPage._enabledBlue
        : AllFeaturesPage._disabledGrey;
    final textColor = enabled
        ? const Color(0xFF2E2F33)
        : const Color(0xFF9A9A9A);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled
                    ? const Color(0xFFF0F5FA)
                    : const Color(0xFFE5E5E5),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(
                            alpha: enabled ? 0.10 : 0.07,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: FeatureIcon(
                          item: item,
                          size: 34,
                          color: iconColor,
                        ),
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
                          color: iconColor.withValues(
                            alpha: enabled ? 0.10 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          enabled
                              ? context.l10n.authorized
                              : context.l10n.unauthorized,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            tooltip: !enabled && !isFavorite
                ? context.l10n.favoriteRequiresPermission
                : isFavorite
                ? context.l10n.unfavoriteFeature
                : context.l10n.favoriteFeature,
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            color: isFavorite
                ? const Color(0xFFFFB300)
                : const Color(0xFF8DA0B3),
            iconSize: 22,
            onPressed: onFavorite,
          ),
        ),
      ],
    );
  }
}

class _FavoriteSortSection extends StatelessWidget {
  const _FavoriteSortSection({required this.items, required this.controller});

  final List<FeatureItem> items;
  final FavoriteFeatureController controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.favoriteFeatureOrder,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.favoriteFeatureOrderHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorderItem: (oldIndex, newIndex) => controller.reorderVisible(
              items.map((item) => item.id).toList(growable: false),
              oldIndex,
              newIndex,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                key: ValueKey(item.id),
                dense: true,
                leading: FeatureIcon(
                  item: item,
                  size: 24,
                  color: AllFeaturesPage._enabledBlue,
                ),
                title: Text(item.title),
                trailing: ReorderableDelayedDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
