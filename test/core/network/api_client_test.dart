// -----------------------------------------------------------------------------
// 文件：api_client_test.dart
// 作用：验证请求头、超时、skipAuth 和并发 401 单飞刷新重试
// 编写时间：2026-07-15
// 维护说明：修改 Dio 拦截器或刷新策略时必须保持这些行为测试通过
// -----------------------------------------------------------------------------

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

void main() {
  test('injects enterprise headers and documented timeouts', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        captured = options;
        return jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'data': {'ok': true},
          },
        });
      });
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: AppLogger(),
      dio: dio,
    );

    final result = await client.get<Map<String, dynamic>>('/protected');

    expect(result['ok'], isTrue);
    expect(captured?.headers['Authorization'], 'Bearer access-1');
    expect(captured?.headers['X-Client'], 'merp-flutter');
    expect(captured?.headers['X-Request-Id'], startsWith('merp-'));
    expect(captured?.connectTimeout, const Duration(seconds: 30));
    expect(captured?.receiveTimeout, const Duration(seconds: 60));
  });

  test('skipAuth omits Authorization header', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        captured = options;
        return jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'data': {'ok': true},
          },
        });
      });
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: MemoryTokenStore(const AuthTokens(accessToken: 'old-access')),
      logger: AppLogger(),
      dio: dio,
    );

    await client.post<Map<String, dynamic>>(
      '/public',
      data: const {'value': 1},
      skipAuth: true,
    );

    expect(captured?.headers.containsKey('Authorization'), isFalse);
  });

  test('concurrent 401 responses share one refresh and retry', () async {
    var refreshCalls = 0;
    final protectedAttempts = <String, int>{};
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/v1/auth/refresh') {
          refreshCalls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return jsonResponse({
            'code': 0,
            'message': 'success',
            'data': {
              'data': {
                'access_token': 'new-access',
                'refresh_token': 'new-refresh',
              },
            },
          });
        }

        protectedAttempts.update(
          options.path,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (options.headers['Authorization'] != 'Bearer new-access') {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return jsonResponse({
            'code': 401,
            'message': 'expired',
            'data': null,
          }, statusCode: 401);
        }
        return jsonResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'data': {'path': options.path},
          },
        });
      });
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'old-access', refreshToken: 'refresh-1'),
    );
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: AppLogger(),
      dio: dio,
    );

    final results = await Future.wait([
      client.get<Map<String, dynamic>>('/protected/one'),
      client.get<Map<String, dynamic>>('/protected/two'),
    ]);

    expect(results.map((item) => item['path']), [
      '/protected/one',
      '/protected/two',
    ]);
    expect(refreshCalls, 1);
    expect(protectedAttempts['/protected/one'], 2);
    expect(protectedAttempts['/protected/two'], 2);
    expect(store.tokens?.accessToken, 'new-access');
    expect(store.tokens?.refreshToken, 'new-refresh');
  });
}
