// -----------------------------------------------------------------------------
// 文件：feature_badge_controller.dart
// 作用：维护各功能入口统一的待办数字角标
// 维护说明：后端角标接口接入后只替换本类的数据加载方法，页面不直接请求接口
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';

class FeatureBadgeController extends ChangeNotifier {
  FeatureBadgeController({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  Map<String, int> _countsByFeatureId = const {};

  int countFor(String featureId) => _countsByFeatureId[featureId] ?? 0;

  /// 接收后端聚合接口的 `{featureId: count}` 数据；非法或 0 数值自动忽略。
  void replaceCounts(Map<String, int> values) {
    _countsByFeatureId = Map.unmodifiable({
      for (final entry in values.entries)
        if (entry.key.trim().isNotEmpty && entry.value > 0)
          entry.key.trim(): entry.value,
    });
    notifyListeners();
  }

  /// 无内网时用于验证首页与更多功能的角标同步效果，不发起网络请求。
  void enableDevelopmentMockCounts() {
    replaceCounts(const {
      'e-form': 6,
      'my-task': 2,
      'service-dispatch': 1,
      'sales-lead': 12,
    });
    _logger.warning('feature.badge', '开发 Mock 模式：已加载功能待办角标');
  }

  void clear() => replaceCounts(const {});
}
