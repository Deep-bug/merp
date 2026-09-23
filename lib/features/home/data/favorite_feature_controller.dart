// -----------------------------------------------------------------------------
// 文件：favorite_feature_controller.dart
// 作用：维护首页收藏功能及其本地排序
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/auth/user_data_scope.dart';
import '../domain/feature_item.dart';

class FavoriteFeatureController extends ChangeNotifier {
  FavoriteFeatureController({
    required AppLogger logger,
    SharedPreferences? preferences,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _logger = logger,
       _preferences = preferences,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  // v3 按环境和用户隔离。v2 全局键没有所有者，不自动认领，也不删除。
  static String storageKeyFor(UserDataScope scope) =>
      'merp.home.manualFavoriteFeatureIds.v3.${scope.storageSuffix}';
  final AppLogger _logger;
  final Future<SharedPreferences> Function() _preferencesProvider;
  SharedPreferences? _preferences;
  Future<SharedPreferences>? _loadingPreferences;
  Future<void> _pendingWrites = Future<void>.value();
  Future<void> _activation = Future<void>.value();
  UserDataScope? _scope;
  int _generation = 0;
  bool _ready = false;
  bool _loadingScope = false;
  bool _disposed = false;
  List<String> _ids = [];
  List<String>? _developmentMockIds;

  List<String> get ids => List.unmodifiable(_effectiveIds);
  bool isFavorite(String featureId) => _effectiveIds.contains(featureId);
  bool get isReady => _ready || _developmentMockIds != null;

  /// 启动只初始化偏好存储；身份确认前绝不读取任何用户收藏。
  Future<void> load() async {
    try {
      _preferences ??= await (_loadingPreferences ??= _preferencesProvider());
    } catch (_) {
      _loadingPreferences = null;
      rethrow;
    }
  }

  Future<void> activateScope(
    UserDataScope scope, {
    UserDataScope? migrateFrom,
  }) {
    if (_scope == scope &&
        _developmentMockIds == null &&
        (_ready || _loadingScope)) {
      return _activation;
    }
    final generation = ++_generation;
    _scope = scope;
    _ready = false;
    _loadingScope = true;
    _ids = [];
    _developmentMockIds = null;
    _notify();
    return _activation = _loadScope(scope, generation, migrateFrom);
  }

  Future<void> _loadScope(
    UserDataScope scope,
    int generation,
    UserDataScope? migrateFrom,
  ) async {
    try {
      await load();
      await _pendingWrites;
      if (_disposed || generation != _generation) return;
      final key = storageKeyFor(scope);
      var storedIds = _preferences!.getStringList(key);
      // 只接受应用编排层确认的“同一会话账号补齐 userId”迁移，绝不读全局 v2。
      if (storedIds == null &&
          migrateFrom != null &&
          migrateFrom.isProvisional &&
          !scope.isProvisional &&
          migrateFrom.environment == scope.environment) {
        storedIds = _preferences!.getStringList(storageKeyFor(migrateFrom));
        if (storedIds != null &&
            !await _preferences!.setStringList(key, storedIds)) {
          throw StateError('收藏作用域迁移保存失败');
        }
      }
      if (_disposed || generation != _generation) return;
      _ids = (storedIds ?? const <String>[])
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: true);
      _ready = true;
      _notify();
    } catch (error, stackTrace) {
      if (_disposed || generation != _generation) return;
      _logger.warning(
        'home.features',
        '用户收藏加载失败',
        error: error,
        stackTrace: stackTrace,
      );
      _notify();
    } finally {
      if (generation == _generation) _loadingScope = false;
    }
  }

  /// 同步隐藏内存数据；用户自己的持久化收藏保留，以便下次登录恢复。
  void clearActiveScope() {
    _generation++;
    _scope = null;
    _ready = false;
    _loadingScope = false;
    _ids = [];
    _developmentMockIds = null;
    _notify();
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
    _generation++;
    _scope = null;
    _ids = [];
    _ready = true;
    _developmentMockIds = [];
    _logger.warning('home.features', '开发 Mock 模式：收藏列表已隔离且默认为空');
    _notify();
  }

  Future<void> toggle(String featureId) async {
    if (_scope == null && _developmentMockIds == null) return;
    final generation = _generation;
    if (!isReady) await _activation;
    if (_disposed || generation != _generation || !isReady) return;
    featureId = featureId.trim();
    if (featureId.isEmpty) return;
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
      _notify();
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
    if (!isReady || _disposed) return;
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
      _notify();
      return;
    }

    _ids = updatedIds;
    await _save();
  }

  Future<void> _save() async {
    final scope = _scope;
    if (scope == null) return;
    final generation = _generation;
    final ids = List<String>.of(_ids);
    final key = storageKeyFor(scope);
    // 快速连续收藏/排序按提交顺序写盘，且始终写回发起操作的用户键。
    // 即使写盘期间切换账号，也不会把 A 的列表写进 B 的空间。
    final saving = _pendingWrites.then((_) async {
      await load();
      if (!await _preferences!.setStringList(key, ids)) {
        throw StateError('收藏保存失败');
      }
    });
    var saved = true;
    final completion = saving.catchError((Object error, StackTrace stackTrace) {
      saved = false;
      _logger.warning(
        'home.features',
        '用户收藏保存失败',
        error: error,
        stackTrace: stackTrace,
      );
    });
    _pendingWrites = completion;
    _notify();
    await completion;
    if (!saved || _disposed || generation != _generation) return;
    _logger.info('home.features', '用户手动收藏功能已保存', fields: {'count': ids.length});
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  List<String> get _effectiveIds => _developmentMockIds ?? _ids;
}
