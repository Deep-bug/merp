import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:local_auth/local_auth.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PackageInfo> _testPackageInfo() async => PackageInfo(
  appName: 'MERP',
  packageName: 'com.example.merp',
  version: '2.0.1',
  buildNumber: '202001',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gesture passwords are isolated by environment and user', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(
      logger: AppLogger(),
      environment: 'qas',
      useSecureStorage: false,
      packageInfoProvider: _testPackageInfo,
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
      packageInfoProvider: _testPackageInfo,
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
      packageInfoProvider: _testPackageInfo,
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

  test(
    'persists the selected API server independently per environment',
    () async {
      SharedPreferences.setMockInitialValues({});
      final qasSettings = SettingsController(
        logger: AppLogger(),
        environment: 'qas',
        useSecureStorage: false,
        packageInfoProvider: _testPackageInfo,
      );
      await qasSettings.load();
      expect(qasSettings.apiServer, ApiServer.china);

      await qasSettings.setApiServer(ApiServer.hk);

      final restoredQasSettings = SettingsController(
        logger: AppLogger(),
        environment: 'qas',
        useSecureStorage: false,
        packageInfoProvider: _testPackageInfo,
      );
      await restoredQasSettings.load();
      expect(restoredQasSettings.apiServer, ApiServer.hk);

      final prdSettings = SettingsController(
        logger: AppLogger(),
        environment: 'prd',
        useSecureStorage: false,
        packageInfoProvider: _testPackageInfo,
      );
      await prdSettings.load();
      expect(prdSettings.apiServer, ApiServer.china);
    },
  );
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
