import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/local_network_startup_gate.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/core/platform/local_network_access_service.dart';
import 'package:merp/features/home/data/permission_repository.dart';
import 'package:merp/l10n/generated/app_localizations.dart';

import '../helpers/memory_token_store.dart';

void main() {
  testWidgets('denied local-network access keeps login content hidden', (
    tester,
  ) async {
    final auth = _RecordingAuthController();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      _testApp(
        auth: auth,
        access: const _FakeNetworkAccess(LocalNetworkAccessStatus.denied),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('需要本地网络权限'), findsOneWidget);
    expect(find.text('login content'), findsNothing);
    expect(auth.restoreCalled, isFalse);
  });

  testWidgets('allowed access restores session and preloads captcha first', (
    tester,
  ) async {
    final auth = _RecordingAuthController();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      _testApp(
        auth: auth,
        access: const _FakeNetworkAccess(LocalNetworkAccessStatus.allowed),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.restoreCalled, isTrue);
    expect(auth.captchaCalled, isTrue);
    expect(find.text('login content'), findsOneWidget);
  });
}

Widget _testApp({
  required AuthController auth,
  required LocalNetworkAccessChecking access,
}) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LocalNetworkStartupGate(
      apiBaseUrl: 'http://10.146.152.51:31234',
      authController: auth,
      networkAccess: access,
      logger: AppLogger(),
      child: const Text('login content'),
    ),
  );
}

class _FakeNetworkAccess implements LocalNetworkAccessChecking {
  const _FakeNetworkAccess(this.status);

  final LocalNetworkAccessStatus status;

  @override
  Future<LocalNetworkAccessResult> check(String apiBaseUrl) async {
    return LocalNetworkAccessResult(status);
  }

  @override
  Future<bool> openAppSettings() async => true;
}

class _RecordingAuthController extends AuthController {
  _RecordingAuthController()
    : super(
        authRepository: _buildAuthRepository(),
        permissionRepository: _buildPermissionRepository(),
        logger: AppLogger(),
      );

  bool restoreCalled = false;
  bool captchaCalled = false;

  @override
  Future<void> restoreSession() async {
    restoreCalled = true;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  Future<void> refreshCaptcha() async {
    captchaCalled = true;
  }
}

AuthRepository _buildAuthRepository() {
  final logger = AppLogger();
  final store = MemoryTokenStore();
  return AuthRepository(
    apiClient: ApiClient(
      config: const AppConfig(),
      tokenStore: store,
      logger: logger,
    ),
    tokenStore: store,
    logger: logger,
  );
}

PermissionRepository _buildPermissionRepository() {
  final logger = AppLogger();
  return PermissionRepository(
    apiClient: ApiClient(
      config: const AppConfig(),
      tokenStore: MemoryTokenStore(),
      logger: logger,
    ),
    logger: logger,
  );
}
