// -----------------------------------------------------------------------------
// 文件：permission_repository.dart
// 作用：加载、解析和缓存后端功能清单及当前账号权限码
// 编写时间：2026-07-10
// 维护说明：后端菜单兼容逻辑只在此维护，页面只调用 canOpen
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/feature_item.dart';

/// 登录后的功能清单和权限缓存。
///
/// 更贴近真实 ERP 后端的推荐返回结构：
/// {
///   "features": [ { "id": "...", "title": "...", "permissionCode": "..." } ],
///   "permissionCodes": [ "form.electronic.view", "field.work.view" ]
/// }
///
/// features 是系统全部功能，permissionCodes 是当前账号被授权的功能权限。
class PermissionRepository extends ChangeNotifier {
  PermissionRepository({
    required ApiClient apiClient,
    required AppLogger logger,
  }) : _apiClient = apiClient,
       _logger = logger;

  final ApiClient _apiClient;
  final AppLogger _logger;
  final List<FeatureItem> _allFeatures = [];
  final Set<String> _allowedCodes = {};

  /// 全部功能：用于“更多/全部功能”页，未授权功能也会展示为灰色。
  List<FeatureItem> get allFeatures => List.unmodifiable(_allFeatures);

  /// 首页常用功能：只展示当前账号有权限的功能，数量控制在首页可快速扫描的范围内。
  List<FeatureItem> get features => _allFeatures
      .where((feature) => canOpen(feature))
      .take(9)
      .toList(growable: false);

  bool canOpen(FeatureItem item) => _allowedCodes.contains(item.permissionCode);

  Future<void> loadForSession(AuthSession session) async {
    final snapshot = await _loadPermissionSnapshotFromBackend(session);
    _allFeatures
      ..clear()
      ..addAll(snapshot.features);
    _allowedCodes
      ..clear()
      ..addAll(snapshot.permissionCodes);
    _logger.info(
      'permission',
      '功能权限加载完成',
      fields: {
        'featureCount': _allFeatures.length,
        'allowedCount': _allowedCodes.length,
      },
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _allFeatures.clear();
    _allowedCodes.clear();
    notifyListeners();
  }

  Future<_PermissionSnapshot> _loadPermissionSnapshotFromBackend(
    AuthSession session,
  ) async {
    try {
      // 真实请求建议返回“全部功能 + 当前用户权限码”。
      // 迁移期如果后端仍直接返回数组，则兼容为“返回的功能全部有权限”。
      final raw = await _apiClient.get<Object?>(_apiClient.config.menuPath);
      return _snapshotFromRaw(raw);
    } catch (error, stackTrace) {
      _logger.warning(
        'permission',
        '菜单接口不可用，已加载本地演示权限',
        error: error,
        stackTrace: stackTrace,
      );
      return _demoSnapshot();
    }
  }

  _PermissionSnapshot _snapshotFromRaw(Object? raw) {
    if (raw is List<dynamic>) {
      final features = raw
          .whereType<Map<String, dynamic>>()
          .map(_featureFromJson)
          .toList(growable: false);
      return _PermissionSnapshot(
        features: features,
        permissionCodes: features.map((feature) => feature.permissionCode),
      );
    }

    if (raw is Map<String, dynamic>) {
      final rows = _readFeatureRows(raw);
      final features = rows.map(_featureFromJson).toList(growable: false);
      final permissionCodes = _readStringList(raw, [
        'permissionCodes',
        'permissions',
        'allowedPermissionCodes',
        'grantedPermissions',
      ]);

      return _PermissionSnapshot(
        features: features,
        permissionCodes: permissionCodes.isEmpty
            ? features.map((feature) => feature.permissionCode)
            : permissionCodes,
      );
    }

    return _demoSnapshot();
  }

  List<Map<String, dynamic>> _readFeatureRows(Map<String, dynamic> raw) {
    for (final key in ['features', 'menus', 'allFeatures', 'items']) {
      final value = raw[key];
      if (value is List<dynamic>) {
        return value.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }
    return const [];
  }

  List<String> _readStringList(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is List<dynamic>) {
        return value
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  FeatureItem _featureFromJson(Map<String, dynamic> json) {
    final mode = json['launchMode'] == 'native'
        ? FeatureLaunchMode.native
        : FeatureLaunchMode.legacyWeb;
    final id = json['id'] as String? ?? json['code'] as String? ?? 'unknown';

    return FeatureItem(
      id: id,
      title: json['title'] as String? ?? id,
      description: json['description'] as String? ?? '',
      icon: _iconFromName(json['icon'] as String?),
      permissionCode: json['permissionCode'] as String? ?? id,
      launchMode: mode,
      route: json['route'] as String? ?? '/legacy/$id',
      legacyPath: json['legacyPath'] as String?,
    );
  }

  IconData _iconFromName(String? name) {
    return switch (name) {
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
      _ => Icons.apps_outlined,
    };
  }

  _PermissionSnapshot _demoSnapshot() {
    // Demo 模拟真实后端：系统返回全部功能，但只授权其中一部分。
    // “全部功能”页会显示灰色未授权入口，方便验证企业权限控制效果。
    const features = [
      FeatureItem(
        id: 'e-form',
        title: '电子表单',
        description: '旧表单中心',
        icon: Icons.account_tree_outlined,
        permissionCode: 'form.electronic.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/e-form',
        legacyPath: '/forms/electronic',
      ),
      FeatureItem(
        id: 'field-work',
        title: '外勤管理2.0',
        description: '外勤签到与定位',
        icon: Icons.location_on_outlined,
        permissionCode: 'field.work.view',
        launchMode: FeatureLaunchMode.native,
        route: '/native/map',
      ),
      FeatureItem(
        id: 'my-task',
        title: '我的任务',
        description: '待办任务',
        icon: Icons.checklist_outlined,
        permissionCode: 'task.mine.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/my-task',
        legacyPath: '/tasks/mine',
      ),
      FeatureItem(
        id: 'service-dispatch',
        title: '服务派工',
        description: '服务工单派发',
        icon: Icons.build_outlined,
        permissionCode: 'service.dispatch.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/service-dispatch',
        legacyPath: '/service/dispatch',
      ),
      FeatureItem(
        id: 'sales-lead',
        title: '线索商机',
        description: '销售线索管理',
        icon: Icons.query_stats_outlined,
        permissionCode: 'sales.lead.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/sales-lead',
        legacyPath: '/sales/leads',
      ),
      FeatureItem(
        id: 'customer',
        title: '客户',
        description: '客户资料',
        icon: Icons.groups_outlined,
        permissionCode: 'customer.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/customer',
        legacyPath: '/customers',
      ),
      FeatureItem(
        id: 'customer-360',
        title: '客户 360',
        description: '客户全景',
        icon: Icons.diversity_3_outlined,
        permissionCode: 'customer.360.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/customer-360',
        legacyPath: '/customers/360',
      ),
      FeatureItem(
        id: 'asset-inventory',
        title: '固资盘点3.0',
        description: '固定资产盘点',
        icon: Icons.home_work_outlined,
        permissionCode: 'asset.inventory.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/asset-inventory',
        legacyPath: '/assets/inventory',
      ),
      FeatureItem(
        id: 'device-history',
        title: '设备履历',
        description: '设备档案履历',
        icon: Icons.article_outlined,
        permissionCode: 'device.history.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/device-history',
        legacyPath: '/devices/history',
      ),
      FeatureItem(
        id: 'faq',
        title: 'FAQ',
        description: '常见问题',
        icon: Icons.help_outline,
        permissionCode: 'faq.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/faq',
        legacyPath: '/faq',
      ),
      FeatureItem(
        id: 'ai-search',
        title: 'AI搜索',
        description: '智能搜索',
        icon: Icons.smart_toy_outlined,
        permissionCode: 'ai.search.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/ai-search',
        legacyPath: '/ai/search',
      ),
      FeatureItem(
        id: 'agent-setting',
        title: '代理人设定',
        description: '代理人配置',
        icon: Icons.group_add_outlined,
        permissionCode: 'agent.setting.view',
        launchMode: FeatureLaunchMode.legacyWeb,
        route: '/legacy/agent-setting',
        legacyPath: '/agents/settings',
      ),
    ];

    return const _PermissionSnapshot(
      features: features,
      permissionCodes: [
        'form.electronic.view',
        'field.work.view',
        'task.mine.view',
        'service.dispatch.view',
        'customer.view',
        'customer.360.view',
        'device.history.view',
        'faq.view',
        'ai.search.view',
      ],
    );
  }
}

class _PermissionSnapshot {
  const _PermissionSnapshot({
    required this.features,
    required this.permissionCodes,
  });

  final List<FeatureItem> features;
  final Iterable<String> permissionCodes;
}
