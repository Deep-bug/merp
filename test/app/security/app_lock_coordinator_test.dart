import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/security/app_lock_coordinator.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/auth/security_session_state.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/security/biometric_service.dart';
import 'package:merp/core/security/gesture_credential_store.dart';
import 'package:merp/core/security/local_security_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _SessionState session;
  late LocalSecurityController security;
  late AppLockCoordinator coordinator;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = _SessionState();
    security = LocalSecurityController(
      logger: AppLogger(),
      environment: 'qas',
      gestureCredentialStore: GestureCredentialStore(
        logger: AppLogger(),
        useSecureStorage: false,
      ),
      biometricService: BiometricService(logger: AppLogger()),
    );
    await security.load(
      preferences: await SharedPreferences.getInstance(),
      languageCode: 'zh-CN',
    );
    now = DateTime(2026, 9, 23, 9);
  });

  tearDown(() {
    coordinator.dispose();
    security.dispose();
    session.dispose();
  });

  AppLockCoordinator createCoordinator() {
    coordinator = AppLockCoordinator(
      auth: session,
      security: security,
      clock: () => now,
    );
    coordinator.start();
    return coordinator;
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'cold restored session is locked only after its security scope is ready',
    () async {
      session.signIn();
      createCoordinator();
      expect(coordinator.locked, isFalse);
      await settle();
      expect(coordinator.scopeReady, isTrue);
      expect(coordinator.locked, isTrue);
      expect(coordinator.reason, AppLockReason.coldStart);
      expect(coordinator.requiresEnrollment, isTrue);
    },
  );

  test(
    'background always covers content even without a login session',
    () async {
      createCoordinator();
      coordinator.coverForBackground();
      expect(coordinator.privacyCovered, isTrue);
      coordinator.resumeFromBackground();
      expect(coordinator.privacyCovered, isFalse);
      expect(coordinator.locked, isFalse);
    },
  );

  test(
    'interactive session locks after ten seconds away from the app',
    () async {
      createCoordinator();
      await security.setAutoLockEnabled(true);
      session.signIn();
      await settle();
      expect(coordinator.scopeReady, isTrue);
      expect(coordinator.locked, isFalse);

      coordinator.recordInteraction();
      coordinator.coverForBackground();
      now = now.add(const Duration(seconds: 11));
      coordinator.resumeFromBackground();
      expect(coordinator.privacyCovered, isFalse);
      expect(coordinator.locked, isTrue);
      expect(coordinator.reason, AppLockReason.inactivity);
    },
  );

  test('short background stay restores content without locking', () async {
    createCoordinator();
    await security.setAutoLockEnabled(true);
    session.signIn();
    await settle();
    coordinator.recordInteraction();
    coordinator.coverForBackground();
    now = now.add(const Duration(seconds: 9));
    coordinator.resumeFromBackground();
    expect(coordinator.locked, isFalse);
    expect(coordinator.privacyCovered, isFalse);
  });

  test(
    'logout removes lock and invalidates the active user security scope',
    () async {
      session.signIn();
      createCoordinator();
      await settle();
      final generation = security.generation;
      expect(coordinator.locked, isTrue);

      session.signOut();
      await settle();
      expect(coordinator.locked, isFalse);
      expect(coordinator.scopeReady, isFalse);
      expect(security.generation, greaterThan(generation));
    },
  );

  test('switching authenticated users rebinds security scope once', () async {
    session.signIn();
    createCoordinator();
    await settle();
    coordinator.unlock();
    final oldGeneration = security.generation;

    session.signIn();
    await settle();
    expect(coordinator.scopeReady, isTrue);
    expect(coordinator.locked, isFalse);
    expect(security.generation, greaterThan(oldGeneration));
  });
}

class _SessionState extends ChangeNotifier implements SecuritySessionState {
  @override
  bool gestureEnrollmentRequired = false;
  @override
  int sessionGeneration = 0;
  @override
  AuthSession? session;
  @override
  bool get isAuthenticated => session != null;

  void signIn() {
    sessionGeneration++;
    session = AuthSession(
      tokens: const AuthTokens(accessToken: 'test-token'),
      profile: UserProfile(
        id: 'user-$sessionGeneration',
        accountName: 'account-$sessionGeneration',
        displayName: 'Test',
        department: 'QA',
      ),
    );
    notifyListeners();
  }

  void signOut() {
    sessionGeneration++;
    session = null;
    notifyListeners();
  }
}
