import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('gesture passwords are isolated by environment and user', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(
      logger: AppLogger(),
      environment: 'qas',
      useSecureStorage: false,
    );
    await settings.load();

    await settings.activateGestureScope(
      userId: 'user-a',
      accountName: 'account-a',
    );
    expect(settings.gesturePasswordConfigured, isFalse);

    const pattern = [0, 1, 2, 5];
    await settings.saveGesturePassword(pattern);
    expect(await settings.verifyGesturePassword(pattern), isTrue);
    expect(await settings.verifyGesturePassword(const [0, 3, 4, 5]), isFalse);

    await settings.activateGestureScope(
      userId: 'user-b',
      accountName: 'account-b',
    );
    expect(settings.gesturePasswordConfigured, isFalse);

    await settings.activateGestureScope(
      userId: 'user-a',
      accountName: 'account-a',
    );
    expect(settings.gesturePasswordConfigured, isTrue);

    await settings.clearGesturePassword();
    expect(settings.gesturePasswordConfigured, isFalse);
    expect(await settings.verifyGesturePassword(pattern), isFalse);
  });

  test('cold start can restore the last gesture scope', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(
      logger: AppLogger(),
      environment: 'prd',
      useSecureStorage: false,
    );
    await settings.load();
    await settings.activateGestureScope(
      userId: 'user-1',
      accountName: 'account-1',
    );
    await settings.saveGesturePassword(const [0, 1, 4, 7]);

    settings.clearActiveGestureScope();
    expect(settings.gesturePasswordConfigured, isFalse);
    expect(await settings.restoreLastGestureScope(), isTrue);
    expect(settings.gesturePasswordConfigured, isTrue);
  });

  test('face-only devices reject fingerprint selection', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(
      logger: AppLogger(),
      environment: 'qas',
      localAuthentication: _FaceOnlyLocalAuthentication(),
      useSecureStorage: false,
    );
    await settings.load();
    await settings.activateGestureScope(
      userId: 'face-user',
      accountName: 'face-account',
    );
    await settings.saveGesturePassword(const [0, 1, 4, 7]);

    expect(await settings.setUnlockMethod(UnlockMethod.fingerprint), isFalse);
    expect(settings.unlockMethod, UnlockMethod.gesture);
    expect(settings.lastBiometricError, contains('指纹'));
  });
}

class _FaceOnlyLocalAuthentication extends LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => const [
    BiometricType.face,
  ];
}
