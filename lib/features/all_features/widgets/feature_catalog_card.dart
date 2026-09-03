// -----------------------------------------------------------------------------
// 文件：feature_catalog_card.dart
// 作用：统一全部功能选择区与收藏拖拽区的功能卡片视觉
// 维护说明：卡片尺寸由 AdaptiveFeatureGridMetrics 控制，本组件只负责内容样式
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_badge.dart';
import '../../home/domain/feature_item.dart';
import '../../home/widgets/feature_icon.dart';

/// “全部功能”和“收藏排序”共用的紧凑功能卡片。
class FeatureCatalogCard extends StatelessWidget {
  const FeatureCatalogCard({
    super.key,
    required this.item,
    required this.enabled,
    required this.isFavorite,
    this.badgeCount = 0,
    this.onTap,
    this.onFavorite,
    this.favoriteTooltip,
  });

  static const _enabledBlue = Color(0xFF16A3DE);
  static const _disabledGrey = Color(0xFFB8B8B8);

  final FeatureItem item;
  final bool enabled;
  final bool isFavorite;
  final int badgeCount;
  final VoidCallback? onTap;

  /// 选择区传入回调后星标可点击；拖拽区不传回调，只展示已收藏状态。
  final VoidCallback? onFavorite;
  final String? favoriteTooltip;

  @override
  Widget build(BuildContext context) {
    final displayedAsFavorite = enabled && isFavorite;
    final labelWeight = defaultTargetPlatform == TargetPlatform.iOS
        ? FontWeight.w600
        : FontWeight.w800;
    final iconColor = enabled ? _enabledBlue : _disabledGrey;
    final textColor = enabled
        ? const Color(0xFF2E2F33)
        : const Color(0xFF9A9A9A);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFEAF1F7)
                  : const Color(0xFFE5E5E5),
            ),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: const Color(0xFF29435C).withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: FeatureIcon(
                        item: item,
                        size: 27,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: textColor,
                          height: 1.12,
                          fontSize: 13,
                          fontWeight: labelWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: onFavorite == null
              ? SizedBox.square(
                  dimension: 36,
                  child: Icon(
                    displayedAsFavorite ? Icons.star : Icons.star_border,
                    color: displayedAsFavorite
                        ? const Color(0xFF00E837)
                        : const Color(0xFFD6D6D6),
                    size: 20,
                  ),
                )
              : IconButton(
                  tooltip: favoriteTooltip,
                  icon: Icon(
                    displayedAsFavorite ? Icons.star : Icons.star_border,
                  ),
                  color: displayedAsFavorite
                      ? const Color(0xFF00E837)
                      : const Color(0xFFD6D6D6),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onFavorite,
                ),
        ),
        Positioned(top: 4, right: 4, child: FeatureBadge(count: badgeCount)),
      ],
    );
  }
}
