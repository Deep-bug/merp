// -----------------------------------------------------------------------------
// 文件：mock_user_feature_permissions.dart
// 作用：仅定义开发 Mock 用户被授予的功能 ID，不定义平台功能内容
// -----------------------------------------------------------------------------

class MockUserFeaturePermissions {
  const MockUserFeaturePermissions({this.authorizedFeatureIds = fullAccessIds});

  final Set<String> authorizedFeatureIds;

  /// 显式维护，防止平台新增功能时 Mock 用户在无人审查的情况下自动获得权限。
  static const fullAccessIds = <String>{
    'survey-analysis',
    'exhibition-survey',
    'e-form',
    'sales-lead',
    'sales-lead-rt',
    'customer',
    'customer-360',
    'inventory-query',
    'order-query',
    'sales-report',
    'dealer-price-query',
    'list-price-query',
    'permission-price',
    'agent-setting',
    'my-task',
    'service-dispatch',
    'service-calendar',
    'service-report',
    'device-history',
    'spare-parts-inventory',
    'field-work',
    'asset-inventory',
    'faq',
    'field-report',
    'ai-search',
  };
}
