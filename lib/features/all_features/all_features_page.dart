// -----------------------------------------------------------------------------
// 文件：all_features_page.dart
// 作用：展示平台完整功能清单及当前账号授权状态
// 编写时间：2026-07-10
// 维护说明：权限判断统一委托 PermissionRepository，灰色入口不可绕过校验
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../shared/adaptive_feature_grid.dart';
import '../../shared/app_dialog.dart';
import '../../shared/app_error_view.dart';
import '../home/domain/feature_item.dart';
import 'widgets/favorite_feature_sort_section.dart';
import 'widgets/feature_catalog_card.dart';

class AllFeaturesPage extends StatelessWidget {
  const AllFeaturesPage({super.key});

  static const _brandBlue = Color(0xFF5E93E5);

  @override
  Widget build(BuildContext context) {
    final permissions = AppScope.of(context).permissionRepository;
    final favorites = AppScope.of(context).favoriteFeatureController;
    final badges = AppScope.of(context).featureBadgeController;

    return AnimatedBuilder(
      animation: Listenable.merge([permissions, favorites, badges]),
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
                      tone: AppErrorTone.info,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                badgeCount: enabled
                                    ? badges.countFor(item.id)
                                    : 0,
                                onFavorite: () {
                                  if (!enabled) {
                                    _showPermissionDeniedDialog(
                                      context,
                                      item: item,
                                      forFavorite: true,
                                    );
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
    required this.badgeCount,
    required this.onFavorite,
  });

  final FeatureItem item;
  final bool enabled;
  final bool isFavorite;
  final int badgeCount;
  final VoidCallback onFavorite;

  void _open(BuildContext context) {
    if (!enabled) {
      _showPermissionDeniedDialog(context, item: item);
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
    return FeatureCatalogCard(
      item: item,
      enabled: enabled,
      isFavorite: isFavorite,
      badgeCount: badgeCount,
      onTap: () => _open(context),
      onFavorite: onFavorite,
      favoriteTooltip: !enabled
          ? context.l10n.favoriteRequiresPermission
          : isFavorite
          ? context.l10n.unfavoriteFeature
          : context.l10n.favoriteFeature,
    );
  }
}

Future<void> _showPermissionDeniedDialog(
  BuildContext context, {
  required FeatureItem item,
  bool forFavorite = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialog(
      tone: AppDialogTone.warning,
      icon: Icons.lock_person_outlined,
      title: context.l10n.permissionDialogTitle,
      message: forFavorite
          ? context.l10n.favoritePermissionDeniedMessage(item.title)
          : context.l10n.featurePermissionDeniedMessage(item.title),
      primaryLabel: context.l10n.acknowledge,
      onPrimary: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
