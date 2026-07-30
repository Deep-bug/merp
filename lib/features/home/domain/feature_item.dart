// -----------------------------------------------------------------------------
// 文件：feature_item.dart
// 作用：定义后端功能菜单在 Flutter 中的领域模型和启动模式
// 编写时间：2026-07-10
// 维护说明：模型保持与 Dio 解耦；图标解析统一在 FeatureResolver 完成
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

enum FeatureLaunchMode { native, legacyWeb }

class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    this.group = '',
    required this.icon,
    this.iconUrl,
    required this.permissionCode,
    required this.launchMode,
    required this.route,
    this.legacyPath,
  });

  final String id;
  final String title;
  final String description;
  final String group;
  final IconData icon;
  final String? iconUrl;
  final String permissionCode;
  final FeatureLaunchMode launchMode;
  final String route;
  final String? legacyPath;
}
