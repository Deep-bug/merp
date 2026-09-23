// -----------------------------------------------------------------------------
// 文件：feature_icon.dart
// 作用：统一展示客户端平台功能目录定义的 Material 图标
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../domain/feature_item.dart';

class FeatureIcon extends StatelessWidget {
  const FeatureIcon({
    super.key,
    required this.item,
    required this.size,
    required this.color,
  });

  final FeatureItem item;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(item.icon, size: size, color: color);
  }
}
