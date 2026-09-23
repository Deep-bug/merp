import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/security/biometric_service.dart';
import 'package:merp/core/security/gesture_credential_store.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _key(String prefix, String identity, {String environment = 'qas'}) =>
    '$prefix.${base64UrlEncode(utf8.encode('$environment:$identity')).replaceAll('=', '')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Gestures gestures;
  late _Biometrics biometrics;
  late SettingsController settings;
  const gesturePrefix = 'merp.security.gesture.v2';
  const methodPrefix = 'merp.security.unlockMethod.v1';
  final keyA = _key(gesturePrefix, 'id:a');
  final keyB = _key(gesturePrefix, 'id:b');

  Future<bool> activate(String id) =>
      settings.activateGestureScope(userId: id, accountName: 'account-$id');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    gestures = _Gestures();
    biometrics = _Biometrics();
    settings = SettingsController(
      logger: AppLogger(),
      gestureCredentialStore: gestures,
      biometricService: biometrics,
      packageInfoProvider: () async => PackageInfo(
        appName: 'MERP',
        packageName: 'test',
        version: '1.0.0',
        buildNumber: '10000',
      ),
    );
    await settings.load();
  });
  tearDown(() => settings.dispose());

  test(
    'pending credential save does not notify a disposed controller',
    () async {
      final transient = SettingsController(
        logger: AppLogger(),
        gestureCredentialStore: gestures,
        biometricService: biometrics,
      );
      await transient.activateGestureScope(
        userId: 'a',
        accountName: 'a',
        persist: false,
      );
      var notifications = 0;
      transient.addListener(() => notifications++);
      gestures.saveGate = Completer<void>();
      final save = transient.saveGesturePassword([0, 1, 4, 7]);
      transient.dispose();
      gestures.saveGate!.complete();
      expect(await save, isFalse);
      expect(notifications, 0);
    },
  );

  test(
    'preserves old namespace, unlock preference and last-scope identity',
    () async {
      final prefs = await SharedPreferences.getInstance();
      gestures.present.add(keyA);
      await prefs.setString(_key(methodPrefix, 'id:a'), 'face');
      expect(await activate('a'), isTrue);
      expect(settings.gesturePasswordConfigured, isTrue);
      expect(settings.unlockMethod, UnlockMethod.face);
      expect(prefs.getString('merp.security.gesture.lastScope.qas'), 'id:a');
      settings.clearActiveGestureScope();
      expect(await settings.restoreLastGestureScope(), isTrue);
      expect(settings.unlockMethod, UnlockMethod.face);

      await settings.activateGestureScope(
        userId: '',
        accountName: ' ACCOUNT-A ',
      );
      expect(gestures.lastRead, _key(gesturePrefix, 'account:account-a'));
    },
  );

  test('late scope load cannot overwrite a new user', () async {
    gestures.delayedKey = keyA;
    gestures.readGate = Completer<bool>();
    final old = activate('a');
    await gestures.readStarted.future;
    expect(await activate('b'), isTrue);
    gestures.readGate!.complete(true);
    expect(await old, isFalse);
    expect(settings.gesturePasswordConfigured, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'merp.security.gesture.lastScope.qas',
      ),
      'id:b',
    );
  });

  test(
    'old biometric success cannot select unlock method for the next user',
    () async {
      await activate('a');
      final selecting = settings.setUnlockMethod(UnlockMethod.face);
      await biometrics.started.future;
      await activate('b');
      biometrics.result.complete(BiometricResult.verified);
      expect(await selecting, isFalse);
      expect(settings.unlockMethod, UnlockMethod.gesture);
      expect(settings.lastBiometricError, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key(methodPrefix, 'id:a')), isNull);
      expect(prefs.getString(_key(methodPrefix, 'id:b')), isNull);
    },
  );

  test(
    'late gesture verification cannot unlock after scope is cleared',
    () async {
      await activate('a');
      gestures.verifyGate = Completer<bool>();
      final verification = settings.verifyGesturePassword([0, 1, 4, 7]);
      settings.clearActiveGestureScope();
      gestures.verifyGate!.complete(true);
      expect(await verification, isFalse);
    },
  );

  test(
    'save after account switch is discarded without configuring the new user',
    () async {
      await activate('a');
      gestures.saveGate = Completer<void>();
      final save = settings.saveGesturePassword([0, 1, 4, 7]);
      await activate('b');
      gestures.saveGate!.complete();
      expect(await save, isFalse);
      expect(settings.gesturePasswordConfigured, isFalse);
      expect(gestures.present, isNot(contains(keyA)));
      expect(gestures.present, isNot(contains(keyB)));
    },
  );

  test('clear wins over a pending save for the same user', () async {
    await activate('a');
    gestures.saveGate = Completer<void>();
    final save = settings.saveGesturePassword([0, 1, 4, 7]);
    await settings.clearGesturePassword();
    gestures.saveGate!.complete();
    expect(await save, isFalse);
    expect(settings.gesturePasswordConfigured, isFalse);
    expect(gestures.present, isEmpty);
  });

  test(
    'late deletion only targets its original user and leaves new settings intact',
    () async {
      gestures.present.addAll([keyA, keyB]);
      await (await SharedPreferences.getInstance()).setString(
        _key(methodPrefix, 'id:b'),
        'face',
      );
      await activate('a');
      gestures.deleteGate = Completer<void>();
      final deleting = settings.clearGesturePassword();
      await activate('b');
      gestures.deleteGate!.complete();
      await deleting;
      expect(settings.gesturePasswordConfigured, isTrue);
      expect(settings.unlockMethod, UnlockMethod.face);
      expect(gestures.present, contains(keyB));
      expect(gestures.present, isNot(contains(keyA)));
    },
  );
}

class _Gestures extends GestureCredentialStore {
  _Gestures() : super(logger: AppLogger(), useSecureStorage: false);
  final Set<String> present = {};
  final readStarted = Completer<void>();
  String? delayedKey;
  String? lastRead;
  Completer<bool>? readGate;
  Completer<bool>? verifyGate;
  Completer<void>? saveGate;
  Completer<void>? deleteGate;

  @override
  Future<bool> contains(String key) async {
    lastRead = key;
    if (key == delayedKey && readGate != null) {
      readStarted.complete();
      return readGate!.future;
    }
    return present.contains(key);
  }

  @override
  Future<bool> save(
    String key,
    List<int> pattern, {
    required bool Function() canCommit,
  }) async {
    await saveGate?.future;
    if (!canCommit()) return false;
    present.add(key);
    return true;
  }

  @override
  Future<bool> verify(String key, List<int> pattern) async =>
      verifyGate?.future ?? present.contains(key);
  @override
  Future<void> delete(String key) async {
    await deleteGate?.future;
    present.remove(key);
  }
}

class _Biometrics extends BiometricService {
  _Biometrics() : super(logger: AppLogger());
  final started = Completer<void>();
  final result = Completer<BiometricResult>();
  @override
  Future<BiometricResult> authenticate({
    required UnlockMethod method,
    required String reason,
  }) async {
    started.complete();
    return result.future;
  }

  @override
  Future<void> cancel() async {}
}
