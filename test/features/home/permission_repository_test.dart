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
import 'package:merp/features/home/data/mock_user_feature_permissions.dart';

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
    RequestOptions? capturedRequest;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        capturedRequest = options;
        return jsonResponse({
          'code': 200,
          'message': 'success',
          'data': {
            'groups': [
              {
                'groupCode': 'group_cs',
                'groupName': 'Customer Service',
                'groupSort': 3,
                'items': [
                  {
                    'featureCode': 'wechat-csinventory',
                    'name': '备件库存',
                    'icon': 'img/funicon/wechat-csinventory.png',
                    'target': 'cs_inventory/inventory.html',
                    'sort': 999,
                    'defaultFlag': false,
                  },
                ],
              },
              {
                'groupCode': 'group_sales',
                'groupName': 'Sales',
                'groupSort': 2,
                'items': [
                  {
                    'featureCode': 'wechat-salesreport',
                    'name': '销售报表',
                    'icon': 'img/funicon/wechat-salesreport.png',
                    'target': 'bw_report/bw/index.html',
                    'sort': 999,
                    'defaultFlag': false,
                  },
                  {
                    'featureCode': 'wechat-eform',
                    'name': '电子表单',
                    'icon': 'img/funicon/wechat-eform.png',
                    'target': 'merp/bpm/index.html',
                    'sort': 0,
                    'defaultFlag': true,
                  },
                ],
              },
            ],
          },
        });
      });
    final repository = _repository(
      dio,
      mockEnvironment: false,
      languageCodeProvider: () => 'zh-TW',
    );

    await repository.loadForSession(session);

    expect(repository.status, PermissionLoadStatus.loaded);
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.path, '/api/v1/app/features');
    expect(capturedRequest?.headers['Authorization'], 'Bearer access-1');
    expect(capturedRequest?.data, {
      'appId': 'merp',
      'lang': 'zh_TW',
      'sys_app_features': 'at',
    });
    expect(repository.allFeatures, hasLength(25));
    expect(repository.authorizedFeatures.map((item) => item.id), [
      'e-form',
      'sales-report',
      'spare-parts-inventory',
    ]);
    final eform = repository.allFeatures.singleWhere(
      (item) => item.id == 'e-form',
    );
    expect(eform.group, 'Sales');
    expect(eform.groupCode, isEmpty);
    expect(eform.groupSort, 0);
    expect(eform.sort, 0);
    expect(eform.isDefault, isTrue);
    expect(eform.legacyPath, 'merp/bpm/index.html');
    expect(repository.canOpen(eform), isTrue);
    expect(
      repository.canOpen(
        repository.allFeatures.singleWhere((item) => item.id == 'customer'),
      ),
      isFalse,
    );

    await repository.clear();

    expect(repository.status, PermissionLoadStatus.idle);
    expect(repository.allFeatures, hasLength(25));
    expect(repository.authorizedFeatures, isEmpty);
  });

  test(
    'network failure exposes retry state without demo permissions',
    () async {
      final dio = Dio()
        ..httpClientAdapter = FakeHttpAdapter(
          (_) => jsonResponse({}, statusCode: 500),
        );
      final repository = _repository(dio, mockEnvironment: false);

      await repository.loadForSession(session);

      expect(repository.status, PermissionLoadStatus.failed);
      expect(repository.loadError, isNotEmpty);
      expect(repository.allFeatures, hasLength(25));
      expect(repository.authorizedFeatures, isEmpty);
    },
  );

  test(
    'explicit Mock authorization grants configured ids without HTTP request',
    () async {
      var requestCount = 0;
      final dio = Dio()
        ..httpClientAdapter = FakeHttpAdapter((_) {
          requestCount += 1;
          return jsonResponse({}, statusCode: 500);
        });
      final repository = _repository(dio);

      await repository.loadDevelopmentMockMenu();

      expect(requestCount, 0);
      expect(repository.status, PermissionLoadStatus.loaded);
      expect(repository.allFeatures, hasLength(25));
      expect(repository.allFeatures.every(repository.canOpen), isTrue);
      expect(
        {
          for (final group in [
            'Marketing',
            'Sales',
            'Customer Service',
            'Admin',
          ])
            group: repository.allFeatures
                .where((item) => item.group == group)
                .length,
        },
        {'Marketing': 2, 'Sales': 12, 'Customer Service': 6, 'Admin': 5},
      );
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

  test(
    'normal session loading never switches to Mock permissions implicitly',
    () async {
      var requestCount = 0;
      final dio = Dio()
        ..httpClientAdapter = FakeHttpAdapter((_) {
          requestCount += 1;
          return jsonResponse({}, statusCode: 500);
        });
      final repository = _repository(dio);

      await repository.loadForSession(session);

      expect(requestCount, 1);
      expect(repository.status, PermissionLoadStatus.failed);
      expect(repository.authorizedFeatures, isEmpty);
    },
  );

  test(
    'Mock user authorization can be narrower than the platform catalog',
    () async {
      final repository = _repository(
        Dio(),
        mockPermissions: const MockUserFeaturePermissions(
          authorizedFeatureIds: {'e-form', 'my-task'},
        ),
      );

      await repository.loadDevelopmentMockMenu();

      expect(repository.allFeatures, hasLength(25));
      expect(repository.authorizedFeatures.map((item) => item.id), [
        'e-form',
        'my-task',
      ]);
    },
  );
}

PermissionRepository _repository(
  Dio dio, {
  bool mockEnvironment = true,
  String Function()? languageCodeProvider,
  MockUserFeaturePermissions mockPermissions =
      const MockUserFeaturePermissions(),
}) {
  final logger = AppLogger();
  final client = ApiClient(
    config: AppConfig(appEnvironment: mockEnvironment ? 'mock' : 'qas'),
    tokenStore: MemoryTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    ),
    logger: logger,
    dio: dio,
  );
  return PermissionRepository(
    apiClient: client,
    logger: logger,
    mockPermissions: mockPermissions,
    languageCodeProvider: languageCodeProvider,
  );
}
