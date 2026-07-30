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
    List<String> defaultIds = const [],
    this.defaultIdsVersion = 0,
  }) : _logger = logger,
       _preferences = preferences,
       _defaultIds = List.unmodifiable(defaultIds);

  static const _storageKey = 'merp.home.favoriteFeatureIds';
  static const _defaultsVersionKey = 'merp.home.favoriteFeatureDefaultsVersion';
  final AppLogger _logger;
  final List<String> _defaultIds;
  final int defaultIdsVersion;
  SharedPreferences? _preferences;
  List<String> _ids = [];

  List<String> get ids => List.unmodifiable(_ids);
  bool isFavorite(String featureId) => _ids.contains(featureId);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final storedIds = _preferences!.getStringList(_storageKey);
    _ids = (storedIds ?? _defaultIds)
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: true);
    final storedDefaultsVersion =
        _preferences!.getInt(_defaultsVersionKey) ?? 0;
    if (defaultIdsVersion > storedDefaultsVersion) {
      for (final id in _defaultIds) {
        if (!_ids.contains(id)) _ids.add(id);
      }
      await _preferences!.setStringList(_storageKey, _ids);
      await _preferences!.setInt(_defaultsVersionKey, defaultIdsVersion);
    }
    notifyListeners();
  }

  List<FeatureItem> favoritesFrom(Iterable<FeatureItem> items) {
    final byId = {for (final item in items) item.id: item};
    return _ids.map((id) => byId[id]).whereType<FeatureItem>().toList();
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
    _logger.info('home.features', '首页收藏功能已保存', fields: {'count': _ids.length});
    notifyListeners();
  }
}
