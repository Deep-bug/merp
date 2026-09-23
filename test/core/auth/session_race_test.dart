import 'dart:async';

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
  const old = AuthTokens(accessToken: 'old', refreshToken: 'old-refresh');
  const next = AuthTokens(accessToken: 'user-b', refreshToken: 'b-refresh');
  const profile = UserProfile(
    id: 'a',
    accountName: 'a',
    displayName: 'A',
    department: '',
  );

  for (final reject in [false, true]) {
    test(
      'old refresh ${reject ? 'failure' : 'success'} cannot affect new login',
      () async {
        final started = Completer<void>();
        final reply = Completer<ResponseBody>();
        final storage = MemoryTokenStore(old);
        final client = _client(storage, (options) {
          started.complete();
          return reply.future;
        });
        var expired = 0;
        client.onSessionExpired = () async => expired++;
        final refreshing = client.refreshTokens();
        await started.future;
        await client.sessionTokens.clear();
        await client.sessionTokens.saveTokens(next);
        reply.complete(
          reject
              ? jsonResponse({
                  'code': 401,
                  'message': 'expired',
                }, statusCode: 401)
              : _tokensResponse('late-user-a'),
        );
        expect(await refreshing, isNull);
        expect(storage.tokens?.accessToken, 'user-b');
        expect(expired, 0);
      },
    );
  }

  test('old 401 is not replayed with the next user credentials', () async {
    final started = Completer<void>();
    final reply = Completer<ResponseBody>();
    var calls = 0;
    final client = _client(MemoryTokenStore(old), (_) {
      calls++;
      started.complete();
      return reply.future;
    });
    final request = client.get<Object?>('/protected');
    final expectation = expectLater(request, throwsA(isA<Object>()));
    await started.future;
    await client.sessionTokens.clear();
    await client.sessionTokens.saveTokens(next);
    reply.complete(jsonResponse({'code': 401}, statusCode: 401));
    await expectation;
    expect(calls, 1);
  });

  test('late login response cannot restore a logged-out account', () async {
    final started = Completer<void>();
    final reply = Completer<ResponseBody>();
    final storage = MemoryTokenStore();
    final client = _client(storage, (_) {
      started.complete();
      return reply.future;
    });
    final repository = AuthRepository(apiClient: client, logger: AppLogger());
    final login = repository.login(
      account: 'a',
      password: 'test',
      captchaId: '1',
      captchaCode: '1234',
    );
    final expectation = expectLater(login, throwsA(isA<AuthException>()));
    await started.future;
    await repository.clearLocalSession();
    reply.complete(_tokensResponse('late-login'));
    await expectation;
    expect(storage.tokens, isNull);
  });

  test(
    'refresh updates controller token without invalidating pending handoff',
    () async {
      final started = Completer<void>();
      final handoff = Completer<ResponseBody>();
      final client = _client(MemoryTokenStore(old), (options) {
        if (options.path.endsWith('/handoff')) {
          started.complete();
          return handoff.future;
        }
        return _tokensResponse('fresh');
      });
      final logger = AppLogger();
      final controller = AuthController(
        authRepository: AuthRepository(apiClient: client, logger: logger),
        permissionRepository: PermissionRepository(
          apiClient: client,
          logger: logger,
        ),
        logger: logger,
      );
      addTearDown(controller.dispose);
      controller.session = const AuthSession(tokens: old, profile: profile);
      controller.status = AuthStatus.authenticated;
      final code = controller.exchangeWebCode();
      await started.future;
      await client.refreshTokens();
      expect(controller.session?.accessToken, 'fresh');
      // 与后台资料更新一样，copyWith 会替换对象，但不应被误认为换了账号。
      controller.session = controller.session!.copyWith(profile: profile);
      handoff.complete(
        jsonResponse({
          'code': 200,
          'data': {'code': 'one-time'},
        }),
      );
      expect(await code, 'one-time');
    },
  );

  test('pending handoff is rejected immediately after logout starts', () async {
    final started = Completer<void>();
    final handoff = Completer<ResponseBody>();
    final logout = Completer<ResponseBody>();
    final client = _client(MemoryTokenStore(old), (options) {
      if (options.path.endsWith('/handoff')) {
        started.complete();
        return handoff.future;
      }
      return logout.future;
    });
    final logger = AppLogger();
    final controller = AuthController(
      authRepository: AuthRepository(apiClient: client, logger: logger),
      permissionRepository: PermissionRepository(
        apiClient: client,
        logger: logger,
      ),
      logger: logger,
    );
    addTearDown(controller.dispose);
    controller.session = const AuthSession(tokens: old, profile: profile);
    controller.status = AuthStatus.authenticated;
    final expectation = expectLater(
      controller.exchangeWebCode(),
      throwsA(isA<AuthException>()),
    );
    await started.future;
    final signingOut = controller.logout();
    expect(controller.isAuthenticated, isFalse);
    expect(controller.session, isNull);
    handoff.complete(
      jsonResponse({
        'code': 200,
        'data': {'code': 'stale'},
      }),
    );
    await expectation;
    logout.complete(jsonResponse({'code': 200, 'data': null}));
    await signingOut;
    expect(controller.status, AuthStatus.unauthenticated);
  });
}

ApiClient _client(MemoryTokenStore storage, FakeRequestHandler handler) =>
    ApiClient(
      config: const AppConfig(),
      tokenStore: storage,
      logger: AppLogger(),
      dio: Dio()..httpClientAdapter = FakeHttpAdapter(handler),
    );

ResponseBody _tokensResponse(String access) => jsonResponse({
  'code': 200,
  'data': {'access_token': access, 'refresh_token': '$access-refresh'},
});
