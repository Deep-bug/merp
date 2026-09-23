// -----------------------------------------------------------------------------
// 文件：permission_repository.dart
// 作用：加载、解析和缓存后端功能清单及当前账号权限码
// 编写时间：2026-07-10
// 维护说明：后端分组拍平和排序逻辑只在此维护，页面只消费领域模型
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/session_data_lifecycle.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../domain/feature_item.dart';
import 'feature_resolver.dart';
import 'mock_user_feature_permissions.dart';
import 'platform_feature_catalog.dart';

/// 登录后的功能清单和权限缓存。
///
/// 本地平台目录负责“有哪些功能”，后端菜单只负责“当前用户能用哪些功能”。
class PermissionRepository extends ChangeNotifier
    implements SessionDataLifecycle {
  PermissionRepository({
    required ApiClient apiClient,
    required AppLogger logger,
    FeatureResolver resolver = const FeatureResolver(),
    PlatformFeatureCatalog? platformCatalog,
    MockUserFeaturePermissions mockPermissions =
        const MockUserFeaturePermissions(),
    String Function()? languageCodeProvider,
  }) : _apiClient = apiClient,
       _logger = logger,
       _resolver = resolver,
       _platformCatalog =
           platformCatalog ?? PlatformFeatureCatalog(apiClient.config),
       _mockPermissions = mockPermissions,
       _languageCodeProvider = languageCodeProvider ?? _defaultLanguageCode {
    _allFeatures.addAll(_platformCatalog.features);
  }

  final ApiClient _apiClient;
  final AppLogger _logger;
  final FeatureResolver _resolver;
  final PlatformFeatureCatalog _platformCatalog;
  final MockUserFeaturePermissions _mockPermissions;
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

  @override
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

  /// 开发 Mock 会话不依赖 Token 与后端菜单，使用独立 Mock 用户授权清单。
  @override
  Future<void> loadDevelopmentMockMenu() async {
    final generation = ++_requestGeneration;
    _status = PermissionLoadStatus.loading;
    _loadError = null;
    notifyListeners();
    final snapshot = _mockSnapshot();
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
    _logger.warning('permission', '开发 Mock 模式：已加载平台目录和独立 Mock 用户权限');
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    _requestGeneration += 1;
    _allFeatures
      ..clear()
      ..addAll(_platformCatalog.features);
    _allowedFeatureIds.clear();
    _status = PermissionLoadStatus.idle;
    _loadError = null;
    notifyListeners();
  }

  Future<_PermissionSnapshot> _loadPermissionSnapshotFromBackend(
    AuthSession _,
  ) async {
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
        final platformId = PlatformFeatureCatalog.platformIdForServerCode(
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

    final features = _platformCatalog.features
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
    final features = _platformCatalog.features;
    final platformIds = features.map((feature) => feature.id).toSet();
    final unknownMockIds = _mockPermissions.authorizedFeatureIds.difference(
      platformIds,
    );
    if (unknownMockIds.isNotEmpty) {
      _logger.warning(
        'permission',
        'Mock 权限包含平台目录中不存在的功能',
        fields: {'featureIds': unknownMockIds.toList()..sort()},
      );
    }

    return _PermissionSnapshot(
      features: features,
      authorizedFeatureIds: _mockPermissions.authorizedFeatureIds.where(
        platformIds.contains,
      ),
    );
  }

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
