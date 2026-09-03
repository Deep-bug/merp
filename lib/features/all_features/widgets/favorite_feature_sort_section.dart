// -----------------------------------------------------------------------------
// 文件：favorite_feature_sort_section.dart
// 作用：组合收藏功能的标题、业务卡片和通用拖拽网格
// 维护说明：收藏业务只在这里把 FeatureItem 转换为可拖动卡片
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/adaptive_feature_grid.dart';
import '../../../shared/widgets/smooth_reorderable_grid.dart';
import '../../home/domain/feature_item.dart';
import 'feature_catalog_card.dart';

class FavoriteFeatureSortSection extends StatelessWidget {
  const FavoriteFeatureSortSection({
    super.key,
    required this.items,
    required this.onReorder,
  });

  final List<FeatureItem> items;
  final SmoothReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      // 与上方功能选择网格使用相同的左右边界，确保卡片宽度完全一致。
      margin: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
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
              return SmoothReorderableGrid<FeatureItem>(
                items: items,
                itemId: (item) => item.id,
                metrics: metrics,
                onReorder: onReorder,
                itemBuilder: (context, item) => FeatureCatalogCard(
                  item: item,
                  enabled: true,
                  isFavorite: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
