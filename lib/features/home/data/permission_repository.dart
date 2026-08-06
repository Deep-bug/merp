// -----------------------------------------------------------------------------
// 文件：permission_repository.dart
// 作用：加载、解析和缓存后端功能清单及当前账号权限码
// 编写时间：2026-07-10
// 维护说明：后端分组拍平和排序逻辑只在此维护，页面只消费领域模型
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/feature_item.dart';
import 'feature_registry.dart';
import 'feature_resolver.dart';
import 'mock_feature_menu.dart';

/// 登录后的功能清单和权限缓存。
///
/// 本地平台目录负责“有哪些功能”，后端菜单只负责“当前用户能用哪些功能”。
class PermissionRepository extends ChangeNotifier {
  PermissionRepository({
    required ApiClient apiClient,
    required AppLogger logger,
    FeatureResolver resolver = const FeatureResolver(),
    String Function()? languageCodeProvider,
  }) : _apiClient = apiClient,
       _logger = logger,
       _resolver = resolver,
       _languageCodeProvider = languageCodeProvider ?? _defaultLanguageCode {
    _allFeatures.addAll(_platformFeatures());
  }

  final ApiClient _apiClient;
  final AppLogger _logger;
  final FeatureResolver _resolver;
  final String Function() _languageCodeProvider;
  final List<FeatureItem> _allFeatures = [];
  final Set<String> _allowedFeatureIds = {};
  PermissionLoadStatus _status = PermissionLoadStatus.idle;
  String? _loadError;
  int _requestGeneration = 0;

  PermissionLoadStatus get status => _status;
  String? get loadError => _loadError;

  /// 平台全部功能，不随当前用户权限变化。
  List<FeatureItem> get allFeatures => List.unmodifiable(_allFeatures);

  /// 当前账号全部可打开的功能；首页再根据本地收藏 id 进行筛选和排序。
  List<FeatureItem> get authorizedFeatures =>
      _allFeatures.where((feature) => canOpen(feature)).toList(growable: false);

  bool canOpen(FeatureItem item) => _allowedFeatureIds.contains(item.id);

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
      _allowedFeatureIds
        ..clear()
        ..addAll(snapshot.authorizedFeatureIds);
      _status = PermissionLoadStatus.loaded;
      _logger.info(
        'permission',
        '功能权限加载完成',
        fields: {
          'featureCount': _allFeatures.length,
          'allowedCount': _allowedFeatureIds.length,
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
    _allFeatures
      ..clear()
      ..addAll(_platformFeatures());
    _allowedFeatureIds.clear();
    _status = PermissionLoadStatus.idle;
    _loadError = null;
    notifyListeners();
  }

  Future<_PermissionSnapshot> _loadPermissionSnapshotFromBackend(
    AuthSession _,
  ) async {
    if (_apiClient.config.mockMenus) {
      _logger.info('permission', '使用本地 Mock 菜单，默认授予全部应用权限');
      return _mockSnapshot();
    }
    final raw = await _apiClient.post<Map<String, dynamic>>(
      _apiClient.config.menuPath,
      data: {
        'appId': _apiClient.config.menuAppId,
        'lang': _normalizedLanguageCode(_languageCodeProvider()),
        'sys_app_features': _apiClient.config.menuFeatureScope,
      },
    );
    return _snapshotFromFeatureGroups(raw);
  }

  _PermissionSnapshot _snapshotFromFeatureGroups(Map<String, dynamic> raw) {
    final rawGroups = raw['groups'];
    if (rawGroups is! List<dynamic>) {
      throw const FormatException('功能菜单缺少 groups 数组');
    }

    final groups =
        rawGroups.whereType<Map<String, dynamic>>().toList(growable: false)
          ..sort(
            (left, right) => _sortValue(
              left['groupSort'],
            ).compareTo(_sortValue(right['groupSort'])),
          );
    final authorizedByPlatformId = <String, FeatureItem>{};

    for (final group in groups) {
      final groupCode = _stringValue(group['groupCode']);
      final groupName = _stringValue(group['groupName']);
      final groupSort = _sortValue(group['groupSort']);
      final rawItems = group['items'];
      if (rawItems is! List<dynamic>) continue;

      final items =
          rawItems.whereType<Map<String, dynamic>>().toList(growable: false)
            ..sort(
              (left, right) =>
                  _sortValue(left['sort']).compareTo(_sortValue(right['sort'])),
            );
      for (final item in items) {
        final row = <String, dynamic>{
          ...item,
          'group': groupName,
          'groupCode': groupCode,
          'groupSort': groupSort,
          'permissionCode': item['featureCode'],
          'launchMode': 'legacyWeb',
        };
        final serverFeature = _resolver.resolve(row);
        final platformId = FeatureRegistry.platformIdForServerCode(
          serverFeature.id,
        );
        if (platformId == null) {
          _logger.warning(
            'permission',
            '权限菜单包含客户端尚未登记的功能编码',
            fields: {'featureCode': serverFeature.id},
          );
          continue;
        }
        authorizedByPlatformId[platformId] = serverFeature;
      }
    }

    final features = _platformFeatures()
        .map(
          (platformFeature) => _mergeAuthorizedFeature(
            platformFeature,
            authorizedByPlatformId[platformFeature.id],
          ),
        )
        .toList(growable: false);
    return _PermissionSnapshot(
      features: features,
      authorizedFeatureIds: authorizedByPlatformId.keys,
    );
  }

  _PermissionSnapshot _mockSnapshot() {
    final features = _platformFeatures();

    return _PermissionSnapshot(
      features: features,
      authorizedFeatureIds: features.map((feature) => feature.id),
    );
  }

  List<FeatureItem> _platformFeatures() => MockFeatureMenu.rows(
    _apiClient.config,
  ).map(_resolver.resolve).toList(growable: false);

  FeatureItem _mergeAuthorizedFeature(
    FeatureItem platformFeature,
    FeatureItem? serverFeature,
  ) {
    if (serverFeature == null) return platformFeature;
    return FeatureItem(
      id: platformFeature.id,
      title: serverFeature.title,
      description: platformFeature.description,
      group: platformFeature.group,
      groupCode: platformFeature.groupCode,
      groupSort: platformFeature.groupSort,
      sort: platformFeature.sort,
      isDefault: serverFeature.isDefault,
      icon: platformFeature.icon,
      permissionCode: platformFeature.permissionCode,
      launchMode: platformFeature.launchMode,
      route: platformFeature.route,
      legacyPath: serverFeature.legacyPath ?? platformFeature.legacyPath,
    );
  }
}

String _defaultLanguageCode() => 'zh_CN';

String _normalizedLanguageCode(String value) {
  return switch (value.trim().replaceAll('-', '_').toLowerCase()) {
    'zh_tw' => 'zh_TW',
    'en_us' => 'en_US',
    _ => 'zh_CN',
  };
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

int _sortValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

enum PermissionLoadStatus { idle, loading, loaded, failed }

class _PermissionSnapshot {
  const _PermissionSnapshot({
    required this.features,
    required this.authorizedFeatureIds,
  });

  final List<FeatureItem> features;
  final Iterable<String> authorizedFeatureIds;
}
