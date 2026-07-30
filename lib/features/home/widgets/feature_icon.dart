// -----------------------------------------------------------------------------
// 文件：feature_icon.dart
// 作用：统一展示后端图标图片，并在失败时回退到本地 Material 图标
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
    final imageUrl = item.iconUrl;
    if (imageUrl == null) {
      return Icon(item.icon, size: size, color: color);
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(item.icon, size: size, color: color),
      ),
    );
  }
}
