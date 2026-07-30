// -----------------------------------------------------------------------------
// 文件：permission_repository_test.dart
// 作用：验证权限菜单的内存加载状态、失败重试和退出清理行为
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/permission_repository.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

void main() {
  const session = AuthSession(
    tokens: AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    profile: UserProfile(
      id: 'U1',
      accountName: 'admin',
      displayName: '管理员',
      department: '',
    ),
  );

  test('loads permissions into memory and clears them on logout', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'data': {
              'features': [
                {
                  'id': 'map-location',
                  'title': '地图定位',
                  'permissionCode': 'map.location.view',
                  'launchMode': 'native',
                  'route': '/native/map',
                },
              ],
              'permissionCodes': ['map.location.view'],
            },
          },
        }),
      );
    final repository = _repository(dio, mockMenus: false);

    await repository.loadForSession(session);

    expect(repository.status, PermissionLoadStatus.loaded);
    expect(repository.authorizedFeatures.single.id, 'map-location');

    await repository.clear();

    expect(repository.status, PermissionLoadStatus.idle);
    expect(repository.allFeatures, isEmpty);
  });

  test(
    'network failure exposes retry state without demo permissions',
    () async {
      final dio = Dio()
        ..httpClientAdapter = FakeHttpAdapter(
          (_) => jsonResponse({}, statusCode: 500),
        );
      final repository = _repository(dio, mockMenus: false);

      await repository.loadForSession(session);

      expect(repository.status, PermissionLoadStatus.failed);
      expect(repository.loadError, isNotEmpty);
      expect(repository.allFeatures, isEmpty);
    },
  );

  test(
    'mock menus grant every local application without HTTP request',
    () async {
      var requestCount = 0;
      final dio = Dio()
        ..httpClientAdapter = FakeHttpAdapter((_) {
          requestCount += 1;
          return jsonResponse({}, statusCode: 500);
        });
      final repository = _repository(dio);

      await repository.loadForSession(session);

      expect(requestCount, 0);
      expect(repository.status, PermissionLoadStatus.loaded);
      expect(repository.allFeatures, isNotEmpty);
      expect(repository.allFeatures.every(repository.canOpen), isTrue);
      expect(
        repository.allFeatures
            .singleWhere((item) => item.id == 'e-form')
            .legacyPath,
        startsWith('https://mcrmapi.deltaww.com.cn/'),
      );
      expect(
        repository.allFeatures
            .singleWhere((item) => item.id == 'asset-inventory')
            .legacyPath,
        contains('FixedAssetInventory.html#/home'),
      );
    },
  );
}

PermissionRepository _repository(Dio dio, {bool mockMenus = true}) {
  final logger = AppLogger();
  final client = ApiClient(
    config: AppConfig(mockMenus: mockMenus),
    tokenStore: MemoryTokenStore(),
    logger: logger,
    dio: dio,
  );
  return PermissionRepository(apiClient: client, logger: logger);
}
