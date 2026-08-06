// -----------------------------------------------------------------------------
// 文件：all_features_page.dart
// 作用：展示平台完整功能清单及当前账号授权状态
// 编写时间：2026-07-10
// 维护说明：权限判断统一委托 PermissionRepository，灰色入口不可绕过校验
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../shared/adaptive_feature_grid.dart';
import '../../shared/app_error_view.dart';
import '../home/domain/feature_item.dart';
import '../home/widgets/feature_icon.dart';
import 'widgets/favorite_feature_sort_section.dart';

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
        final groupedFeatures = <String, List<FeatureItem>>{};
        for (final item in permissions.allFeatures) {
          groupedFeatures
              .putIfAbsent(
                item.group.trim().isEmpty ? 'Other' : item.group.trim(),
                () => [],
              )
              .add(item);
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 92,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  leadingWidth: 70,
                  leading: IconButton(
                    tooltip: context.l10n.back,
                    onPressed: () => AppNavigator.backToHome(context),
                    icon: const Icon(Icons.chevron_left, size: 42),
                    color: AllFeaturesPage._brandBlue,
                  ),
                  centerTitle: true,
                  title: Text(
                    'MERP 2025',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AllFeaturesPage._brandBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AllFeaturesPage._brandBlue,
                    ),
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
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                      child: Text(
                        context.l10n.manageMyApps,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF999999),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  for (final group in groupedFeatures.entries) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        child: Text(
                          group.key,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF252525),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final metrics =
                              AdaptiveFeatureGridMetrics.allFeatures(
                                context,
                                constraints.crossAxisExtent,
                              );
                          return SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = group.value[index];
                              final enabled = permissions.canOpen(item);
                              final isFavorite = favorites.isFavorite(item.id);
                              return _AllFeatureTile(
                                item: item,
                                enabled: enabled,
                                isFavorite: isFavorite,
                                onFavorite: () {
                                  if (!enabled) {
                                    _showPermissionDeniedDialog(context);
                                    return;
                                  }
                                  favorites.toggle(item.id);
                                },
                              );
                            }, childCount: group.value.length),
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
                  if (favoriteItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FavoriteFeatureSortSection(
                        items: favoriteItems,
                        onReorder: favorites.reorderVisible,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 34)),
                ],
              ],
            ),
          ),
        );
      },
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
  final VoidCallback onFavorite;

  void _open(BuildContext context) {
    if (!enabled) {
      _showPermissionDeniedDialog(context);
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
    final displayedAsFavorite = enabled && isFavorite;
    final labelWeight = defaultTargetPlatform == TargetPlatform.iOS
        ? FontWeight.w600
        : FontWeight.w800;
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
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: FeatureIcon(
                          item: item,
                          size: 32,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textColor,
                          fontWeight: labelWeight,
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
            tooltip: !enabled
                ? context.l10n.favoriteRequiresPermission
                : displayedAsFavorite
                ? context.l10n.unfavoriteFeature
                : context.l10n.favoriteFeature,
            icon: Icon(displayedAsFavorite ? Icons.star : Icons.star_border),
            color: displayedAsFavorite
                ? const Color(0xFF00E837)
                : const Color(0xFFD6D6D6),
            iconSize: 22,
            onPressed: onFavorite,
          ),
        ),
      ],
    );
  }
}

Future<void> _showPermissionDeniedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(context.l10n.featurePermissionDenied),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.acknowledge),
        ),
      ],
    ),
  );
}
