// -----------------------------------------------------------------------------
// 文件：adaptive_feature_grid.dart
// 作用：统一计算首页与全部功能页在窄屏、大字体下的网格尺寸
// 编写时间：2026-07-11
// 维护说明：功能网格统一使用固定主轴高度，禁止恢复为容易溢出的宽高比
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';

/// 企业功能网格的响应式尺寸结果。
class AdaptiveFeatureGridMetrics {
  const AdaptiveFeatureGridMetrics({
    required this.crossAxisCount,
    required this.spacing,
    required this.mainAxisExtent,
  });

  final int crossAxisCount;
  final double spacing;
  final double mainAxisExtent;

  /// 把网格内的手指坐标映射到最近的功能格子。
  ///
  /// 以相邻格子中心线作为换位边界，比“刚进入卡片边缘就换位”更稳定；最后一行
  /// 不满时会限制到最后一个真实功能，避免拖进空白格产生越界索引。
  int nearestIndexForPosition({
    required Offset localPosition,
    required double availableWidth,
    required int itemCount,
  }) {
    if (itemCount <= 0) return -1;

    final tileWidth =
        (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
    final horizontalStride = tileWidth + spacing;
    final verticalStride = mainAxisExtent + spacing;
    final column = ((localPosition.dx - tileWidth / 2) / horizontalStride)
        .round()
        .clamp(0, crossAxisCount - 1)
        .toInt();
    final maxRow = (itemCount - 1) ~/ crossAxisCount;
    final row = ((localPosition.dy - mainAxisExtent / 2) / verticalStride)
        .round()
        .clamp(0, maxRow)
        .toInt();

    return (row * crossAxisCount + column).clamp(0, itemCount - 1);
  }

  /// 首页卡片只有图标与标题，高度可相对紧凑。
  factory AdaptiveFeatureGridMetrics.home(
    BuildContext context,
    double availableWidth,
  ) {
    return _resolve(
      context,
      availableWidth,
      baseExtent: 116,
      extentPerScaleStep: 40,
      maxExtent: 182,
    );
  }

  /// 全部功能卡片还包含权限状态，高度需要比首页更充足。
  factory AdaptiveFeatureGridMetrics.allFeatures(
    BuildContext context,
    double availableWidth,
  ) {
    return _resolve(
      context,
      availableWidth,
      baseExtent: 116,
      extentPerScaleStep: 38,
      maxExtent: 154,
      narrowSpacing: 10,
      wideSpacing: 12,
    );
  }

  /// 收藏排序只展示图标和标题，进一步压缩高度以减少页面滚动。
  factory AdaptiveFeatureGridMetrics.favoriteSort(
    BuildContext context,
    double availableWidth,
  ) {
    return _resolve(
      context,
      availableWidth,
      baseExtent: 94,
      extentPerScaleStep: 28,
      maxExtent: 122,
      narrowSpacing: 8,
      wideSpacing: 10,
      narrowCrossAxisCount: 3,
      wideCrossAxisCount: 3,
    );
  }

  static AdaptiveFeatureGridMetrics _resolve(
    BuildContext context,
    double availableWidth, {
    required double baseExtent,
    required double extentPerScaleStep,
    required double maxExtent,
    double narrowSpacing = 12,
    double wideSpacing = 18,
    int narrowCrossAxisCount = 2,
    int wideCrossAxisCount = 3,
  }) {
    final scaledBodySize = MediaQuery.textScalerOf(context).scale(14);
    final textScale = (scaledBodySize / 14).clamp(1.0, 2.0);

    // 绝大多数手机保持三列；可用宽度低于 270dp 时切为两列，避免图标和标题被挤压。
    final columns = availableWidth < 270
        ? narrowCrossAxisCount
        : wideCrossAxisCount;
    final spacing = availableWidth < 320 ? narrowSpacing : wideSpacing;
    final extent = (baseExtent + (textScale - 1) * extentPerScaleStep).clamp(
      baseExtent,
      maxExtent,
    );

    return AdaptiveFeatureGridMetrics(
      crossAxisCount: columns,
      spacing: spacing,
      mainAxisExtent: extent,
    );
  }
}
