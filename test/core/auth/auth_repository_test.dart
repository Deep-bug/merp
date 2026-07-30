// -----------------------------------------------------------------------------
// 文件：auth_repository_test.dart
// 作用：验证登录请求体、Token 保存、用户资料获取和登出请求契约
// 编写时间：2026-07-15
// 维护说明：认证接口路径或字段变更时必须同步更新本测试
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

void main() {
  test('captcha follows backend contract without Authorization', () async {
    RequestOptions? captchaRequest;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        captchaRequest = options;
        return jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'data': {
              'captchaId': 'captcha-001',
              'imagebase64': 'data:image/png;base64,AQIDBA==',
            },
          },
        });
      });
    final store = MemoryTokenStore();
    final logger = AppLogger();
    final repository = AuthRepository(
      apiClient: ApiClient(
        config: const AppConfig(),
        tokenStore: store,
        logger: logger,
        dio: dio,
      ),
      tokenStore: store,
      logger: logger,
    );

    final challenge = await repository.fetchCaptcha();

    expect(captchaRequest?.method, 'GET');
    expect(captchaRequest?.path, '/api/v1/auth/captcha');
    expect(captchaRequest?.headers.containsKey('Authorization'), isFalse);
    expect(challenge.captchaId, 'captcha-001');
    expect(challenge.imageBytes, [1, 2, 3, 4]);
  });

  test('login follows backend contract and loads complete userInfo', () async {
    RequestOptions? loginRequest;
    RequestOptions? userInfoRequest;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        if (options.path == '/api/v1/auth/login') {
          loginRequest = options;
          return jsonResponse({
            'code': 0,
            'message': 'success',
            'data': {
              'data': {
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
                'accountName': 'admin',
                'displayName': '管理员',
              },
            },
          });
        }
        if (options.path == '/api/v1/user/userInfo') {
          userInfoRequest = options;
          return jsonResponse({
            'code': 0,
            'message': 'success',
            'data': {
              'data': {
                'id': 'U10001',
                'accountName': 'admin',
                'displayName': '管理员',
                'department': '信息技术部',
                'email': 'admin@company.com',
                'phone': '13800138000',
                'avatarUrl': 'https://cdn.company.com/avatar/admin.png',
              },
            },
          });
        }
        return jsonResponse({}, statusCode: 404);
      });
    final store = MemoryTokenStore();
    final logger = AppLogger();
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
      dio: dio,
    );
    final repository = AuthRepository(
      apiClient: client,
      tokenStore: store,
      logger: logger,
    );

    final session = await repository.login(
      account: '  admin  ',
      password: '123456',
      captchaId: 'captcha-001',
      captchaCode: ' A7K9 ',
    );

    expect(loginRequest?.data, {
      'username': 'admin',
      'password': '123456',
      'captchaId': 'captcha-001',
      'captchaCode': 'A7K9',
      'appId': 'merp',
      'source': 1,
      'environment': 'merp',
    });
    expect(loginRequest?.headers.containsKey('Authorization'), isFalse);
    expect(userInfoRequest?.headers['Authorization'], 'Bearer access-1');
    expect(store.tokens?.refreshToken, 'refresh-1');
    expect(session.profile.id, 'U10001');
    expect(session.profile.department, '信息技术部');
  });

  test('logout sends refreshToken and always clears local tokens', () async {
    RequestOptions? logoutRequest;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        logoutRequest = options;
        return jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {'data': null},
        });
      });
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final logger = AppLogger();
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
      dio: dio,
    );
    final repository = AuthRepository(
      apiClient: client,
      tokenStore: store,
      logger: logger,
    );

    await repository.logout();

    expect(logoutRequest?.path, '/api/v1/auth/logout');
    expect(logoutRequest?.data, {'refreshToken': 'refresh-1'});
    expect(logoutRequest?.headers.containsKey('Authorization'), isFalse);
    expect(store.tokens, isNull);
  });

  test('restore refreshes tokens without loading user profile', () async {
    RequestOptions? refreshRequest;
    var userInfoCalls = 0;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        if (options.path == '/api/v1/auth/refresh') {
          refreshRequest = options;
          return jsonResponse({
            'code': 0,
            'message': 'success',
            'data': {
              'data': {'access_token': 'access-2'},
            },
          });
        }
        if (options.path == '/api/v1/user/userInfo') {
          userInfoCalls += 1;
        }
        return jsonResponse({}, statusCode: 404);
      });
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final logger = AppLogger();
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
      dio: dio,
    );
    final repository = AuthRepository(
      apiClient: client,
      tokenStore: store,
      logger: logger,
    );

    final session = await repository.restore();

    expect(refreshRequest?.path, '/api/v1/auth/refresh');
    expect(refreshRequest?.data, {
      'refresh_token': 'refresh-1',
      'environment': 'merp',
    });
    expect(userInfoCalls, 0);
    expect(session?.accessToken, 'access-2');
    expect(session?.tokens.refreshToken, 'refresh-1');
    expect(session?.profile.displayName, '当前用户');
    expect(store.tokens?.accessToken, 'access-2');
    expect(store.tokens?.refreshToken, 'refresh-1');
  });
}
