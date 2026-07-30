// -----------------------------------------------------------------------------
// 文件：permission_repository.dart
// 作用：加载、解析和缓存后端功能清单及当前账号权限码
// 编写时间：2026-07-10
// 维护说明：后端菜单兼容逻辑只在此维护，页面只调用 canOpen
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/feature_item.dart';
import 'feature_resolver.dart';
import 'mock_feature_menu.dart';

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
    FeatureResolver resolver = const FeatureResolver(),
  }) : _apiClient = apiClient,
       _logger = logger,
       _resolver = resolver;

  final ApiClient _apiClient;
  final AppLogger _logger;
  final FeatureResolver _resolver;
  final List<FeatureItem> _allFeatures = [];
  final Set<String> _allowedCodes = {};
  PermissionLoadStatus _status = PermissionLoadStatus.idle;
  String? _loadError;
  int _requestGeneration = 0;

  PermissionLoadStatus get status => _status;
  String? get loadError => _loadError;

  /// 全部功能：用于“更多/全部功能”页，未授权功能也会展示为灰色。
  List<FeatureItem> get allFeatures => List.unmodifiable(_allFeatures);

  /// 当前账号全部可打开的功能；首页再根据本地收藏 id 进行筛选和排序。
  List<FeatureItem> get authorizedFeatures =>
      _allFeatures.where((feature) => canOpen(feature)).toList(growable: false);

  bool canOpen(FeatureItem item) => _allowedCodes.contains(item.permissionCode);

  Future<void> loadForSession(AuthSession session) async {
    final generation = ++_requestGeneration;
    _status = PermissionLoadStatus.loading;
    _loadError = null;
    notifyListeners();
    try {
      final snapshot = await _loadPermissionSnapshotFromBackend(session);
      if (generation != _requestGeneration) {
        return;
      }
      _allFeatures
        ..clear()
        ..addAll(snapshot.features);
      _allowedCodes
        ..clear()
        ..addAll(snapshot.permissionCodes);
      _status = PermissionLoadStatus.loaded;
      _logger.info(
        'permission',
        '功能权限加载完成',
        fields: {
          'featureCount': _allFeatures.length,
          'allowedCount': _allowedCodes.length,
        },
      );
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) {
        return;
      }
      _status = PermissionLoadStatus.failed;
      _loadError = error.toString();
      _logger.warning(
        'permission',
        '菜单权限加载失败，等待用户重试',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (generation == _requestGeneration) {
        notifyListeners();
      }
    }
  }

  Future<void> clear() async {
    _requestGeneration += 1;
    _allFeatures.clear();
    _allowedCodes.clear();
    _status = PermissionLoadStatus.idle;
    _loadError = null;
    notifyListeners();
  }

  Future<_PermissionSnapshot> _loadPermissionSnapshotFromBackend(
    AuthSession session,
  ) async {
    if (_apiClient.config.mockMenus) {
      _logger.info('permission', '使用本地 Mock 菜单，默认授予全部应用权限');
      return _mockSnapshot();
    }
    // 迁移期如果后端仍直接返回数组，则兼容为“返回的功能全部有权限”。
    final raw = await _apiClient.get<Object?>(_apiClient.config.menuPath);
    return _snapshotFromRaw(raw);
  }

  _PermissionSnapshot _snapshotFromRaw(Object? raw) {
    if (raw is List<dynamic>) {
      final features = raw
          .whereType<Map<String, dynamic>>()
          .map(_resolver.resolve)
          .toList(growable: false);
      return _PermissionSnapshot(
        features: features,
        permissionCodes: features.map((feature) => feature.permissionCode),
      );
    }

    if (raw is Map<String, dynamic>) {
      final rows = _readFeatureRows(raw);
      final features = rows.map(_resolver.resolve).toList(growable: false);
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

    throw const FormatException('菜单权限响应格式不正确');
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

  _PermissionSnapshot _mockSnapshot() {
    final features = MockFeatureMenu.rows(
      _apiClient.config,
    ).map(_resolver.resolve).toList(growable: false);

    return _PermissionSnapshot(
      features: features,
      permissionCodes: features.map((feature) => feature.permissionCode),
    );
  }
}

enum PermissionLoadStatus { idle, loading, loaded, failed }

class _PermissionSnapshot {
  const _PermissionSnapshot({
    required this.features,
    required this.permissionCodes,
  });

  final List<FeatureItem> features;
  final Iterable<String> permissionCodes;
}
