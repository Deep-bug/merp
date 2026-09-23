// -----------------------------------------------------------------------------
// 文件：platform_feature_catalog.dart
// 作用：定义客户端支持的完整平台功能目录、可信路由和后端编码兼容关系
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../routing/app_routes.dart';
import '../domain/feature_item.dart';

enum PlatformLegacyTarget { electronicForm, assetInventory }

class PlatformFeatureDefinition {
  const PlatformFeatureDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
    required this.icon,
    required this.permissionCode,
    required this.legacyPath,
    this.serverAliases = const [],
    this.configuredTarget,
  });

  final String id;
  final String title;
  final String description;
  final String group;
  final IconData icon;
  final String permissionCode;
  final String legacyPath;
  final List<String> serverAliases;
  final PlatformLegacyTarget? configuredTarget;

  FeatureItem build(AppConfig config) => FeatureItem(
    id: id,
    title: title,
    description: description,
    group: group,
    icon: icon,
    permissionCode: permissionCode,
    launchMode: FeatureLaunchMode.legacyWeb,
    route: '/legacy/${Uri.encodeComponent(id)}',
    legacyPath: switch (configuredTarget) {
      PlatformLegacyTarget.electronicForm => config.electronicFormUrl,
      PlatformLegacyTarget.assetInventory => config.assetInventoryUrl,
      null => legacyPath,
    },
  );
}

/// 客户端发布版本所支持的功能白名单。
///
/// 后端决定当前用户获准使用哪些 ID，但不能增加客户端未知功能、替换 Material
/// 图标或注入原生路由。目录顺序同时也是“全部功能”页面的稳定展示顺序。
class PlatformFeatureCatalog {
  PlatformFeatureCatalog(this.config)
    : features = List.unmodifiable(
        definitions.map((definition) => definition.build(config)),
      );

  final AppConfig config;
  final List<FeatureItem> features;

  static const definitions = <PlatformFeatureDefinition>[
    PlatformFeatureDefinition(
      id: 'survey-analysis',
      title: '问卷分析',
      description: '营销问卷分析',
      group: 'Marketing',
      icon: Icons.analytics_outlined,
      permissionCode: 'marketing.survey.analysis.view',
      legacyPath: '/marketing/survey-analysis',
    ),
    PlatformFeatureDefinition(
      id: 'exhibition-survey',
      title: '展会问卷',
      description: '展会问卷管理',
      group: 'Marketing',
      icon: Icons.edit_note_outlined,
      permissionCode: 'marketing.exhibition.survey.view',
      legacyPath: '/marketing/exhibition-survey',
    ),
    PlatformFeatureDefinition(
      id: 'e-form',
      title: '电子表单',
      description: '旧表单中心',
      group: 'Sales',
      icon: Icons.account_tree_outlined,
      permissionCode: 'form.electronic.view',
      legacyPath: '',
      serverAliases: ['wechat-eform'],
      configuredTarget: PlatformLegacyTarget.electronicForm,
    ),
    PlatformFeatureDefinition(
      id: 'sales-lead',
      title: '线索商机',
      description: '销售线索管理',
      group: 'Sales',
      icon: Icons.query_stats_outlined,
      permissionCode: 'sales.lead.view',
      legacyPath: '/sales/leads',
    ),
    PlatformFeatureDefinition(
      id: 'sales-lead-rt',
      title: '线索商机(RT)',
      description: '实时销售线索管理',
      group: 'Sales',
      icon: Icons.manage_search_outlined,
      permissionCode: 'sales.lead.rt.view',
      legacyPath: '/sales/leads/rt',
    ),
    PlatformFeatureDefinition(
      id: 'customer',
      title: '客户',
      description: '客户资料',
      group: 'Sales',
      icon: Icons.groups_outlined,
      permissionCode: 'customer.view',
      legacyPath: '/customers',
    ),
    PlatformFeatureDefinition(
      id: 'customer-360',
      title: '客户 360',
      description: '客户全景',
      group: 'Sales',
      icon: Icons.diversity_3_outlined,
      permissionCode: 'customer.360.view',
      legacyPath: '/customers/360',
    ),
    PlatformFeatureDefinition(
      id: 'inventory-query',
      title: '库存查询',
      description: '库存信息查询',
      group: 'Sales',
      icon: Icons.warehouse_outlined,
      permissionCode: 'inventory.query.view',
      legacyPath: '/sales/inventory',
    ),
    PlatformFeatureDefinition(
      id: 'order-query',
      title: '订单查询',
      description: '销售订单查询',
      group: 'Sales',
      icon: Icons.assignment_turned_in_outlined,
      permissionCode: 'sales.order.query.view',
      legacyPath: '/sales/orders',
    ),
    PlatformFeatureDefinition(
      id: 'sales-report',
      title: '销售报表',
      description: '销售数据报表',
      group: 'Sales',
      icon: Icons.insert_chart_outlined,
      permissionCode: 'sales.report.view',
      legacyPath: '/sales/reports',
      serverAliases: ['wechat-salesreport'],
    ),
    PlatformFeatureDefinition(
      id: 'dealer-price-query',
      title: '经销价查询',
      description: '经销价格查询',
      group: 'Sales',
      icon: Icons.group_work_outlined,
      permissionCode: 'price.dealer.view',
      legacyPath: '/sales/prices/dealer',
    ),
    PlatformFeatureDefinition(
      id: 'list-price-query',
      title: '牌价查询',
      description: '产品牌价查询',
      group: 'Sales',
      icon: Icons.price_check_outlined,
      permissionCode: 'price.list.view',
      legacyPath: '/sales/prices/list',
    ),
    PlatformFeatureDefinition(
      id: 'permission-price',
      title: '权限价格',
      description: '权限价格查询',
      group: 'Sales',
      icon: Icons.admin_panel_settings_outlined,
      permissionCode: 'price.permission.view',
      legacyPath: '/sales/prices/permission',
    ),
    PlatformFeatureDefinition(
      id: 'agent-setting',
      title: '代理人设定',
      description: '代理人配置',
      group: 'Sales',
      icon: Icons.group_add_outlined,
      permissionCode: 'agent.setting.view',
      legacyPath: '/agents/settings',
    ),
    PlatformFeatureDefinition(
      id: 'my-task',
      title: '我的任务',
      description: '待办任务',
      group: 'Customer Service',
      icon: Icons.checklist_outlined,
      permissionCode: 'task.mine.view',
      legacyPath: '/tasks/mine',
    ),
    PlatformFeatureDefinition(
      id: 'service-dispatch',
      title: '服务派工',
      description: '服务工单派发',
      group: 'Customer Service',
      icon: Icons.build_outlined,
      permissionCode: 'service.dispatch.view',
      legacyPath: '/service/dispatch',
    ),
    PlatformFeatureDefinition(
      id: 'service-calendar',
      title: '服务日历',
      description: '服务工作日历',
      group: 'Customer Service',
      icon: Icons.calendar_month_outlined,
      permissionCode: 'service.calendar.view',
      legacyPath: '/service/calendar',
    ),
    PlatformFeatureDefinition(
      id: 'service-report',
      title: '服务报表',
      description: '客户服务报表',
      group: 'Customer Service',
      icon: Icons.assignment_outlined,
      permissionCode: 'service.report.view',
      legacyPath: '/service/reports',
    ),
    PlatformFeatureDefinition(
      id: 'device-history',
      title: '设备履历',
      description: '设备档案履历',
      group: 'Customer Service',
      icon: Icons.article_outlined,
      permissionCode: 'device.history.view',
      legacyPath: '/devices/history',
    ),
    PlatformFeatureDefinition(
      id: 'spare-parts-inventory',
      title: '备件库存',
      description: '服务备件库存',
      group: 'Customer Service',
      icon: Icons.other_houses_outlined,
      permissionCode: 'service.spare.inventory.view',
      legacyPath: '/service/spare-parts',
      serverAliases: ['wechat-csinventory'],
    ),
    PlatformFeatureDefinition(
      id: 'field-work',
      title: '外勤管理2.0',
      description: '外勤签到与定位',
      group: 'Admin',
      icon: Icons.location_on_outlined,
      permissionCode: 'field.work.view',
      legacyPath: '/field-work',
    ),
    PlatformFeatureDefinition(
      id: 'asset-inventory',
      title: '固资盘点3.0',
      description: '固定资产盘点',
      group: 'Admin',
      icon: Icons.home_work_outlined,
      permissionCode: 'asset.inventory.view',
      legacyPath: '',
      configuredTarget: PlatformLegacyTarget.assetInventory,
    ),
    PlatformFeatureDefinition(
      id: 'faq',
      title: 'FAQ',
      description: '常见问题',
      group: 'Admin',
      icon: Icons.help_outline,
      permissionCode: 'faq.view',
      legacyPath: '/faq',
    ),
    PlatformFeatureDefinition(
      id: 'field-report',
      title: '外勤报表',
      description: '外勤数据报表',
      group: 'Admin',
      icon: Icons.bar_chart_outlined,
      permissionCode: 'field.report.view',
      legacyPath: '/field-work/reports',
    ),
    PlatformFeatureDefinition(
      id: 'ai-search',
      title: 'AI搜索',
      description: '智能搜索',
      group: 'Admin',
      icon: Icons.smart_toy_outlined,
      permissionCode: 'ai.search.view',
      legacyPath: '/ai/search',
    ),
  ];

  static final Map<String, PlatformFeatureDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };

  static final Map<String, String> _platformIdByServerCode = {
    for (final definition in definitions) ...{
      definition.id: definition.id,
      for (final alias in definition.serverAliases) alias: definition.id,
    },
  };

  static String? platformIdForServerCode(String serverCode) =>
      _platformIdByServerCode[serverCode.trim().toLowerCase()];

  static IconData iconForCode(String featureCode) {
    final platformId = platformIdForServerCode(featureCode);
    return _byId[platformId]?.icon ??
        _trustedNativeIcons[featureCode.trim().toLowerCase()] ??
        Icons.apps_outlined;
  }

  /// 原生路由是独立的受控能力表，不等于“全部功能”目录。
  static String? nativeRouteFor(String featureCode) =>
      _trustedNativeRoutes[featureCode.trim().toLowerCase()];

  static const _trustedNativeRoutes = {'map-location': AppRoute.map};
  static const _trustedNativeIcons = {'map-location': Icons.map_outlined};
}
