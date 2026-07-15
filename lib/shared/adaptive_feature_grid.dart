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

  /// 首页卡片只有图标与标题，高度可相对紧凑。
  factory AdaptiveFeatureGridMetrics.home(
    BuildContext context,
    double availableWidth,
  ) {
    return _resolve(
      context,
      availableWidth,
      baseExtent: 138,
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
      baseExtent: 164,
      extentPerScaleStep: 48,
      maxExtent: 212,
    );
  }

  static AdaptiveFeatureGridMetrics _resolve(
    BuildContext context,
    double availableWidth, {
    required double baseExtent,
    required double extentPerScaleStep,
    required double maxExtent,
  }) {
    final scaledBodySize = MediaQuery.textScalerOf(context).scale(14);
    final textScale = (scaledBodySize / 14).clamp(1.0, 2.0);

    // 绝大多数手机保持三列；可用宽度低于 270dp 时切为两列，避免图标和标题被挤压。
    final columns = availableWidth < 270 ? 2 : 3;
    final spacing = availableWidth < 320 ? 12.0 : 18.0;
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
