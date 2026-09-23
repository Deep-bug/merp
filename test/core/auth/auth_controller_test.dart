import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/auth/session_data_lifecycle.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/core/platform/web_data_cleaner.dart';
import 'package:merp/features/home/data/permission_repository.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      authRepository: AuthRepository(apiClient: client, logger: logger),
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

  test('login error keeps diagnostic IDs out of the user message', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => jsonResponse({
          'code': 401,
          'message': '账号或密码错误',
          'traceId': 'backend-trace-secret',
          'data': null,
        }, statusCode: 401),
      );
    final store = MemoryTokenStore();
    final logger = AppLogger();
    final client = ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
      dio: dio,
    );
    final controller = AuthController(
      authRepository: AuthRepository(apiClient: client, logger: logger),
      permissionRepository: PermissionRepository(
        apiClient: client,
        logger: logger,
      ),
      logger: logger,
    );
    controller
      ..status = AuthStatus.unauthenticated
      ..captchaChallenge = CaptchaChallenge(
        captchaId: 'captcha-001',
        imageBytes: Uint8List(0),
      );

    final success = await controller.login(
      account: 'finn',
      password: 'wrong-password',
      captchaCode: 'A7K9',
    );

    expect(success, isFalse);
    expect(controller.lastError, '账号或密码错误');
    expect(controller.lastError, isNot(contains('trace')));
    expect(controller.lastError, isNot(contains('MERP-')));
  });

  test(
    'development Mock refresh uses only the explicit Mock permission path',
    () async {
      final logger = AppLogger();
      final client = ApiClient(
        config: const AppConfig(appEnvironment: 'mock'),
        tokenStore: MemoryTokenStore(),
        logger: logger,
        dio: Dio(),
      );
      final lifecycle = _RecordingSessionDataLifecycle();
      final controller = AuthController(
        authRepository: AuthRepository(apiClient: client, logger: logger),
        permissionRepository: lifecycle,
        logger: logger,
      );

      await controller.enterDevelopmentMockSession();
      await controller.reloadSessionData();

      expect(lifecycle.mockLoads, 2);
      expect(lifecycle.sessionLoads, 0);
    },
  );

  test(
    'logout also clears WebView website data without affecting app logout',
    () async {
      const channel = MethodChannel('com.delta.merpdelta/webview_data');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      MethodCall? capturedCall;
      messenger.setMockMethodCallHandler(channel, (call) async {
        capturedCall = call;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final store = MemoryTokenStore(
        const AuthTokens(accessToken: 'old-access', refreshToken: 'refresh-1'),
      );
      final logger = AppLogger();
      final client = ApiClient(
        config: const AppConfig(),
        tokenStore: store,
        logger: logger,
        dio: Dio()
          ..httpClientAdapter = FakeHttpAdapter(
            (_) => jsonResponse({'code': 0, 'data': null}),
          ),
      );
      final controller = AuthController(
        authRepository: AuthRepository(apiClient: client, logger: logger),
        permissionRepository: PermissionRepository(
          apiClient: client,
          logger: logger,
        ),
        webDataCleaner: WebDataCleaner(
          logger: logger,
          channel: channel,
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        logger: logger,
      );

      await controller.logout();

      expect(capturedCall?.method, 'clearAllWebData');
      expect(store.tokens, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
    },
  );
}

class _RecordingSessionDataLifecycle implements SessionDataLifecycle {
  int sessionLoads = 0;
  int mockLoads = 0;

  @override
  Future<void> loadForSession(AuthSession session) async {
    sessionLoads++;
  }

  @override
  Future<void> loadDevelopmentMockMenu() async {
    mockLoads++;
  }

  @override
  Future<void> clear() async {}
}
