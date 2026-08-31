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
  List<String>? _developmentMockIds;

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

  /// Mock 只跳过登录和提供菜单权限；收藏仍必须由用户主动点击。
  ///
  /// 使用独立的内存列表，避免 Mock 读取或改写正常 QAS 收藏。
  void enableDevelopmentMockMode() {
    if (_developmentMockIds != null) {
      return;
    }
    _developmentMockIds = [];
    _logger.warning('home.features', '开发 Mock 模式：收藏列表已隔离且默认为空');
    notifyListeners();
  }

  Future<void> toggle(String featureId) async {
    final developmentIds = _developmentMockIds;
    if (developmentIds != null) {
      if (developmentIds.contains(featureId)) {
        developmentIds.remove(featureId);
      } else {
        developmentIds.add(featureId);
      }
      _logger.info(
        'home.features',
        '开发 Mock 模式：已更新内存收藏',
        fields: {'featureId': featureId, 'count': developmentIds.length},
      );
      notifyListeners();
      return;
    }

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

    final sourceIds = _developmentMockIds ?? _ids;
    final visibleSet = visibleIds.toSet();
    var visibleIndex = 0;
    final updatedIds = [
      for (final id in sourceIds)
        if (visibleSet.contains(id)) reordered[visibleIndex++] else id,
    ];

    if (_developmentMockIds != null) {
      _developmentMockIds = updatedIds;
      _logger.info(
        'home.features',
        '开发 Mock 模式：已更新内存收藏排序',
        fields: {'count': updatedIds.length},
      );
      notifyListeners();
      return;
    }

    _ids = updatedIds;
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

  List<String> get _effectiveIds => _developmentMockIds ?? _ids;
}
