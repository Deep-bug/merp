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
  /// 后端菜单编码与客户端平台功能 ID 的兼容映射。
  ///
  /// 平台完整功能清单使用稳定的客户端 ID；权限接口可能继续返回旧微信端编码。
  /// 新接口出现新的 featureCode 时，只需在这里补充一条映射。
  static const Map<String, String> platformIdByServerCode = {
    'wechat-eform': 'e-form',
    'wechat-salesreport': 'sales-report',
    'wechat-csinventory': 'spare-parts-inventory',
  };

  static const Map<String, ClientFeatureDefinition> definitions = {
    'survey-analysis': ClientFeatureDefinition(
      fallbackIcon: Icons.analytics_outlined,
    ),
    'exhibition-survey': ClientFeatureDefinition(
      fallbackIcon: Icons.edit_note_outlined,
    ),
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
    'sales-lead-rt': ClientFeatureDefinition(
      fallbackIcon: Icons.manage_search_outlined,
    ),
    'customer': ClientFeatureDefinition(fallbackIcon: Icons.groups_outlined),
    'customer-360': ClientFeatureDefinition(
      fallbackIcon: Icons.diversity_3_outlined,
    ),
    'inventory-query': ClientFeatureDefinition(
      fallbackIcon: Icons.warehouse_outlined,
    ),
    'order-query': ClientFeatureDefinition(
      fallbackIcon: Icons.assignment_turned_in_outlined,
    ),
    'sales-report': ClientFeatureDefinition(
      fallbackIcon: Icons.insert_chart_outlined,
    ),
    'dealer-price-query': ClientFeatureDefinition(
      fallbackIcon: Icons.group_work_outlined,
    ),
    'list-price-query': ClientFeatureDefinition(
      fallbackIcon: Icons.price_check_outlined,
    ),
    'permission-price': ClientFeatureDefinition(
      fallbackIcon: Icons.admin_panel_settings_outlined,
    ),
    'asset-inventory': ClientFeatureDefinition(
      fallbackIcon: Icons.home_work_outlined,
    ),
    'device-history': ClientFeatureDefinition(
      fallbackIcon: Icons.article_outlined,
    ),
    'service-calendar': ClientFeatureDefinition(
      fallbackIcon: Icons.calendar_month_outlined,
    ),
    'service-report': ClientFeatureDefinition(
      fallbackIcon: Icons.assignment_outlined,
    ),
    'spare-parts-inventory': ClientFeatureDefinition(
      fallbackIcon: Icons.other_houses_outlined,
    ),
    'faq': ClientFeatureDefinition(fallbackIcon: Icons.help_outline),
    'ai-search': ClientFeatureDefinition(
      fallbackIcon: Icons.smart_toy_outlined,
    ),
    'field-report': ClientFeatureDefinition(
      fallbackIcon: Icons.bar_chart_outlined,
    ),
    'agent-setting': ClientFeatureDefinition(
      fallbackIcon: Icons.group_add_outlined,
    ),
    'wechat-eform': ClientFeatureDefinition(
      fallbackIcon: Icons.account_tree_outlined,
    ),
    'wechat-salesreport': ClientFeatureDefinition(
      fallbackIcon: Icons.insert_chart_outlined,
    ),
    'wechat-csinventory': ClientFeatureDefinition(
      fallbackIcon: Icons.other_houses_outlined,
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

  static String? platformIdForServerCode(String serverCode) {
    final normalized = serverCode.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final mapped = platformIdByServerCode[normalized];
    if (mapped != null) return mapped;
    if (definitions.containsKey(normalized)) return normalized;
    return null;
  }

  static IconData? _iconFromName(String? name) {
    return switch (name?.trim().toLowerCase()) {
      'survey-analysis' => Icons.analytics_outlined,
      'exhibition-survey' => Icons.edit_note_outlined,
      'form' => Icons.account_tree_outlined,
      'field' => Icons.location_on_outlined,
      'task' => Icons.checklist_outlined,
      'service' => Icons.build_outlined,
      'opportunity' => Icons.query_stats_outlined,
      'opportunity-rt' => Icons.manage_search_outlined,
      'customer' => Icons.groups_outlined,
      'customer360' => Icons.diversity_3_outlined,
      'inventory-query' => Icons.warehouse_outlined,
      'order-query' => Icons.assignment_turned_in_outlined,
      'sales-report' => Icons.insert_chart_outlined,
      'dealer-price' => Icons.group_work_outlined,
      'list-price' => Icons.price_check_outlined,
      'permission-price' => Icons.admin_panel_settings_outlined,
      'asset' => Icons.home_work_outlined,
      'device' => Icons.article_outlined,
      'calendar' => Icons.calendar_month_outlined,
      'service-report' => Icons.assignment_outlined,
      'spare-parts' => Icons.other_houses_outlined,
      'faq' => Icons.help_outline,
      'ai' => Icons.smart_toy_outlined,
      'field-report' => Icons.bar_chart_outlined,
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
