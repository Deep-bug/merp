// -----------------------------------------------------------------------------
// 文件：favorite_feature_controller.dart
// 作用：维护首页收藏功能及其本地排序
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/feature_item.dart';

class FavoriteFeatureController extends ChangeNotifier {
  FavoriteFeatureController({
    required AppLogger logger,
    SharedPreferences? preferences,
  }) : _logger = logger,
       _preferences = preferences;

  // v2 只保存用户主动点击星标产生的收藏。
  // 不迁移旧键，避免旧版自动写入的默认首页应用继续进入拖动区域。
  static const _storageKey = 'merp.home.manualFavoriteFeatureIds.v2';
  final AppLogger _logger;
  SharedPreferences? _preferences;
  List<String> _ids = [];
  bool _developmentMockEnabled = false;
  static const _developmentDefaultIds = [
    'e-form',
    'my-task',
    'service-dispatch',
    'sales-report',
    'customer',
    'field-work',
  ];

  List<String> get ids => List.unmodifiable(_effectiveIds);
  bool isFavorite(String featureId) => _effectiveIds.contains(featureId);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final storedIds = _preferences!.getStringList(_storageKey);
    _ids = (storedIds ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: true);
    notifyListeners();
  }

  List<FeatureItem> favoritesFrom(Iterable<FeatureItem> items) {
    final byId = {for (final item in items) item.id: item};
    return _effectiveIds
        .map((id) => byId[id])
        .whereType<FeatureItem>()
        .toList();
  }

  /// 仅为当前进程提供首页示例，不写入用户真实收藏记录。
  void enableDevelopmentMockDefaults() {
    if (_developmentMockEnabled) {
      return;
    }
    _developmentMockEnabled = true;
    _logger.warning('home.features', '开发 Mock 模式：已启用首页默认功能');
    notifyListeners();
  }

  Future<void> toggle(String featureId) async {
    if (_ids.contains(featureId)) {
      _ids.remove(featureId);
    } else {
      _ids.add(featureId);
    }
    await _save();
  }

  /// 对当前可见的收藏项排序；已下架功能的旧收藏记录不影响顺序。
  Future<void> reorderVisible(
    List<String> visibleIds,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < 0 ||
        oldIndex >= visibleIds.length ||
        newIndex < 0 ||
        newIndex > visibleIds.length) {
      return;
    }
    final reordered = List<String>.of(visibleIds);
    final movedId = reordered.removeAt(oldIndex);
    reordered.insert(newIndex.clamp(0, reordered.length), movedId);

    final visibleSet = visibleIds.toSet();
    var visibleIndex = 0;
    _ids = [
      for (final id in _ids)
        if (visibleSet.contains(id)) reordered[visibleIndex++] else id,
    ];
    await _save();
  }

  Future<void> _save() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(_storageKey, _ids);
    _logger.info(
      'home.features',
      '用户手动收藏功能已保存',
      fields: {'count': _ids.length},
    );
    notifyListeners();
  }

  List<String> get _effectiveIds => [
    if (_developmentMockEnabled) ..._developmentDefaultIds,
    ..._ids.where((id) => !_developmentDefaultIds.contains(id)),
  ];
}
