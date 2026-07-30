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
import '../home/widgets/home_feature_area.dart';

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
                                onFavorite: enabled || isFavorite
                                    ? () => favorites.toggle(item.id)
                                    : null,
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
                      child: _FavoriteSortSection(
                        items: favoriteItems,
                        controller: favorites,
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
                          fontWeight: FontWeight.w800,
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

class _FavoriteSortSection extends StatefulWidget {
  const _FavoriteSortSection({required this.items, required this.controller});

  final List<FeatureItem> items;
  final FavoriteFeatureController controller;

  @override
  State<_FavoriteSortSection> createState() => _FavoriteSortSectionState();
}

class _FavoriteSortSectionState extends State<_FavoriteSortSection> {
  late List<FeatureItem> _displayItems;
  List<String> _originalIds = const [];
  String? _draggedId;

  @override
  void initState() {
    super.initState();
    _displayItems = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant _FavoriteSortSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggedId == null) {
      _displayItems = List.of(widget.items);
    }
  }

  void _startDrag(String id) {
    setState(() {
      _draggedId = id;
      _originalIds = widget.items
          .map((item) => item.id)
          .toList(growable: false);
      _displayItems = List.of(widget.items);
    });
  }

  bool _moveDraggedItemTo(String targetId) {
    final draggedId = _draggedId;
    if (draggedId == null || draggedId == targetId) return false;
    final oldIndex = _displayItems.indexWhere((item) => item.id == draggedId);
    final newIndex = _displayItems.indexWhere((item) => item.id == targetId);
    if (oldIndex < 0 || newIndex < 0) return false;

    setState(() {
      final movedItem = _displayItems.removeAt(oldIndex);
      _displayItems.insert(newIndex, movedItem);
    });
    return true;
  }

  void _finishDrag() {
    final draggedId = _draggedId;
    if (draggedId == null) return;
    final oldIndex = _originalIds.indexOf(draggedId);
    final newIndex = _displayItems.indexWhere((item) => item.id == draggedId);
    final shouldSave = oldIndex >= 0 && newIndex >= 0 && oldIndex != newIndex;

    setState(() => _draggedId = null);
    if (shouldSave) {
      widget.controller.reorderVisible(_originalIds, oldIndex, newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_displayItems.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 32, 18, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.favoriteFeatureOrder}'
            '(${context.l10n.favoriteFeatureOrderHint})',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF999999),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = AdaptiveFeatureGridMetrics.favoriteSort(
                context,
                constraints.maxWidth,
              );
              final tileWidth =
                  (constraints.maxWidth -
                      metrics.spacing * (metrics.crossAxisCount - 1)) /
                  metrics.crossAxisCount;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _displayItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: metrics.crossAxisCount,
                  mainAxisSpacing: metrics.spacing,
                  crossAxisSpacing: metrics.spacing,
                  mainAxisExtent: metrics.mainAxisExtent,
                ),
                itemBuilder: (context, index) {
                  final item = _displayItems[index];
                  final isDragging = item.id == _draggedId;
                  final card = HomeFeatureCard(
                    item: item,
                    label: item.title,
                    iconColor: AllFeaturesPage._enabledBlue,
                    onTap: () {},
                    compact: true,
                  );
                  return RepaintBoundary(
                    child: DragTarget<String>(
                      key: ValueKey(item.id),
                      onWillAcceptWithDetails: (details) {
                        if (details.data == item.id) return false;
                        return _moveDraggedItemTo(item.id);
                      },
                      onAcceptWithDetails: (_) {},
                      builder: (context, candidateData, rejectedData) {
                        return LongPressDraggable<String>(
                          data: item.id,
                          delay: const Duration(milliseconds: 220),
                          maxSimultaneousDrags: 1,
                          hapticFeedbackOnStart: true,
                          onDragStarted: () => _startDrag(item.id),
                          onDragEnd: (_) => _finishDrag(),
                          feedback: Theme(
                            data: Theme.of(context),
                            child: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: tileWidth,
                                height: metrics.mainAxisExtent,
                                child: Transform.scale(
                                  scale: 1.04,
                                  child: card,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.24,
                            child: Transform.scale(scale: 0.94, child: card),
                          ),
                          child: AnimatedScale(
                            scale: isDragging ? 0.94 : 1,
                            duration: const Duration(milliseconds: 120),
                            child: card,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
