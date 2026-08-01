import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/permission_repository.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

void main() {
  test('restore failure can discard local session and enter login', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => jsonResponse({
          'code': 500,
          'message': 'temporary unavailable',
          'data': null,
        }, statusCode: 500),
      );
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'old-access', refreshToken: 'refresh-1'),
    );
    final logger = AppLogger();
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
      dio: dio,
    );
    final permissions = PermissionRepository(apiClient: client, logger: logger);
    final controller = AuthController(
      authRepository: AuthRepository(
        apiClient: client,
        tokenStore: store,
        logger: logger,
      ),
      permissionRepository: permissions,
      logger: logger,
    );

    await controller.restoreSession();
    expect(controller.status, AuthStatus.restoreFailed);
    expect(store.tokens?.refreshToken, 'refresh-1');

    await controller.discardStoredSession();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.session, isNull);
    expect(controller.lastError, isNull);
    expect(store.tokens, isNull);
    expect(store.clearCount, 1);
  });
}
