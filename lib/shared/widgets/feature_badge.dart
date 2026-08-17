// -----------------------------------------------------------------------------
// 文件：feature_badge.dart
// 作用：首页和更多功能共用的待办数字角标
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class FeatureBadge extends StatelessWidget {
  const FeatureBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: '$label 个待处理事项',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
