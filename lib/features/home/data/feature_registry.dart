// -----------------------------------------------------------------------------
// 文件：feature_registry.dart
// 作用：注册只能由 Flutter 客户端决定的功能能力
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../routing/app_routes.dart';

class ClientFeatureDefinition {
  const ClientFeatureDefinition({required this.fallbackIcon, this.nativeRoute});

  /// 后端未返回可识别图标时使用的本地图标。
  final IconData fallbackIcon;

  /// 受客户端路由表保护的原生页面。后端不能注入任意原生 route。
  final String? nativeRoute;
}

abstract final class FeatureRegistry {
  static const Map<String, ClientFeatureDefinition> definitions = {
    'e-form': ClientFeatureDefinition(
      fallbackIcon: Icons.account_tree_outlined,
    ),
    'field-work': ClientFeatureDefinition(
      fallbackIcon: Icons.location_on_outlined,
    ),
    'my-task': ClientFeatureDefinition(fallbackIcon: Icons.checklist_outlined),
    'map-location': ClientFeatureDefinition(
      fallbackIcon: Icons.map_outlined,
      nativeRoute: AppRoute.map,
    ),
    'service-dispatch': ClientFeatureDefinition(
      fallbackIcon: Icons.build_outlined,
    ),
    'sales-lead': ClientFeatureDefinition(
      fallbackIcon: Icons.query_stats_outlined,
    ),
    'customer': ClientFeatureDefinition(fallbackIcon: Icons.groups_outlined),
    'customer-360': ClientFeatureDefinition(
      fallbackIcon: Icons.diversity_3_outlined,
    ),
    'asset-inventory': ClientFeatureDefinition(
      fallbackIcon: Icons.home_work_outlined,
    ),
    'device-history': ClientFeatureDefinition(
      fallbackIcon: Icons.article_outlined,
    ),
    'faq': ClientFeatureDefinition(fallbackIcon: Icons.help_outline),
    'ai-search': ClientFeatureDefinition(
      fallbackIcon: Icons.smart_toy_outlined,
    ),
    'agent-setting': ClientFeatureDefinition(
      fallbackIcon: Icons.group_add_outlined,
    ),
  };

  static IconData iconFor(String featureId, String? iconName) {
    return _iconFromName(iconName) ??
        definitions[featureId]?.fallbackIcon ??
        Icons.apps_outlined;
  }

  static String? nativeRouteFor(String featureId) {
    return definitions[featureId]?.nativeRoute;
  }

  static IconData? _iconFromName(String? name) {
    return switch (name?.trim().toLowerCase()) {
      'form' => Icons.account_tree_outlined,
      'field' => Icons.location_on_outlined,
      'task' => Icons.checklist_outlined,
      'service' => Icons.build_outlined,
      'opportunity' => Icons.query_stats_outlined,
      'customer' => Icons.groups_outlined,
      'customer360' => Icons.diversity_3_outlined,
      'asset' => Icons.home_work_outlined,
      'device' => Icons.article_outlined,
      'faq' => Icons.help_outline,
      'ai' => Icons.smart_toy_outlined,
      'agent' => Icons.group_add_outlined,
      'camera' => Icons.photo_camera_outlined,
      'map' => Icons.map_outlined,
      'inventory' => Icons.inventory_2_outlined,
      'approval' => Icons.fact_check_outlined,
      'sales' => Icons.point_of_sale_outlined,
      _ => null,
    };
  }
}
