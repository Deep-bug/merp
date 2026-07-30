// -----------------------------------------------------------------------------
// 文件：mock_feature_menu.dart
// 作用：在后端菜单未接通时提供与后端契约一致的本地开发数据
// -----------------------------------------------------------------------------

import '../../../core/config/app_config.dart';

abstract final class MockFeatureMenu {
  static List<Map<String, dynamic>> rows(AppConfig config) => [
    _web(
      id: 'e-form',
      title: '电子表单',
      description: '旧表单中心',
      icon: 'form',
      permissionCode: 'form.electronic.view',
      legacyPath: config.electronicFormUrl,
    ),
    _web(
      id: 'field-work',
      title: '外勤管理2.0',
      description: '外勤签到与定位',
      icon: 'field',
      permissionCode: 'field.work.view',
      legacyPath: '/field-work',
    ),
    _web(
      id: 'my-task',
      title: '我的任务',
      description: '待办任务',
      icon: 'task',
      permissionCode: 'task.mine.view',
      legacyPath: '/tasks/mine',
    ),
    {
      'id': 'map-location',
      'title': '地图定位',
      'description': '百度基础地图',
      'icon': 'map',
      'permissionCode': 'map.location.view',
      'launchMode': 'native',
    },
    _web(
      id: 'service-dispatch',
      title: '服务派工',
      description: '服务工单派发',
      icon: 'service',
      permissionCode: 'service.dispatch.view',
      legacyPath: '/service/dispatch',
    ),
    _web(
      id: 'sales-lead',
      title: '线索商机',
      description: '销售线索管理',
      icon: 'opportunity',
      permissionCode: 'sales.lead.view',
      legacyPath: '/sales/leads',
    ),
    _web(
      id: 'customer',
      title: '客户',
      description: '客户资料',
      icon: 'customer',
      permissionCode: 'customer.view',
      legacyPath: '/customers',
    ),
    _web(
      id: 'customer-360',
      title: '客户 360',
      description: '客户全景',
      icon: 'customer360',
      permissionCode: 'customer.360.view',
      legacyPath: '/customers/360',
    ),
    _web(
      id: 'asset-inventory',
      title: '固资盘点3.0',
      description: '固定资产盘点',
      icon: 'asset',
      permissionCode: 'asset.inventory.view',
      legacyPath: config.assetInventoryUrl,
    ),
    _web(
      id: 'device-history',
      title: '设备履历',
      description: '设备档案履历',
      icon: 'device',
      permissionCode: 'device.history.view',
      legacyPath: '/devices/history',
    ),
    _web(
      id: 'faq',
      title: 'FAQ',
      description: '常见问题',
      icon: 'faq',
      permissionCode: 'faq.view',
      legacyPath: '/faq',
    ),
    _web(
      id: 'ai-search',
      title: 'AI搜索',
      description: '智能搜索',
      icon: 'ai',
      permissionCode: 'ai.search.view',
      legacyPath: '/ai/search',
    ),
    _web(
      id: 'agent-setting',
      title: '代理人设定',
      description: '代理人配置',
      icon: 'agent',
      permissionCode: 'agent.setting.view',
      legacyPath: '/agents/settings',
    ),
  ];

  static Map<String, dynamic> _web({
    required String id,
    required String title,
    required String description,
    required String icon,
    required String permissionCode,
    required String legacyPath,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'permissionCode': permissionCode,
      'launchMode': 'legacyWeb',
      'legacyPath': legacyPath,
    };
  }
}
