import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/security/gesture_credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'merp.security.gesture.v2.cWFzOmlkOnVzZXItYQ';
  // 独立 PBKDF2 实现生成的旧 v2 记录，不通过待测试服务生成。
  const legacyRecord =
      '{"version":2,"iterations":120000,'
      '"salt":"AAECAwQFBgcICQoLDA0ODw==",'
      '"hash":"cUlqboHQWj2kfbzkJ2YFuOob6IYCSOnFZEqL4xWs054="}';
  const storage = FlutterSecureStorage();
  late GestureCredentialStore gestures;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({key: legacyRecord});
    gestures = GestureCredentialStore(logger: AppLogger());
  });

  test('reads existing v2 records without migration', () async {
    expect(await gestures.contains(key), isTrue);
    expect(await gestures.verify(key, [0, 1, 4, 7]), isTrue);
    expect(await gestures.verify(key, [0, 1, 4, 8]), isFalse);
  });

  test('new records retain format and use a new random salt', () async {
    final pattern = [0, 1, 4, 7];
    expect(await gestures.save(key, pattern, canCommit: () => true), isTrue);
    final first = jsonDecode((await storage.read(key: key))!) as Map;
    expect(
      first.keys,
      unorderedEquals(['version', 'iterations', 'salt', 'hash']),
    );
    expect(first['version'], 2);
    expect(first['iterations'], 120000);
    expect(base64Url.decode(first['salt'] as String), hasLength(16));
    expect(base64Url.decode(first['hash'] as String), hasLength(32));
    await gestures.save(key, pattern, canCommit: () => true);
    final second = jsonDecode((await storage.read(key: key))!) as Map;
    expect(second['salt'], isNot(first['salt']));
    expect(await gestures.verify(key, pattern), isTrue);
  });

  test('discarded save cannot recreate a deleted credential', () async {
    var active = true;
    final saving = gestures.save(key, [0, 1, 2, 3], canCommit: () => active);
    active = false;
    await gestures.delete(key);
    expect(await saving, isFalse);
    expect(await gestures.contains(key), isFalse);
  });

  test('verification snapshots caller input before awaiting storage', () async {
    final pattern = [0, 1, 4, 7];
    final verifying = gestures.verify(key, pattern);
    pattern[0] = 8;
    expect(await verifying, isTrue);
  });

  test('delete waits for an already-started native write', () async {
    final native = _DelayedStorage();
    final store = GestureCredentialStore(
      logger: AppLogger(),
      secureStorage: native,
    );
    final saving = store.save(key, [0, 1, 4, 7], canCommit: () => true);
    await native.started.future;
    final deleting = store.delete(key);
    expect(native.deleted, isFalse);
    native.release.complete();
    await saving;
    await deleting;
    expect(native.deleted, isTrue);
    expect(await store.contains(key), isFalse);
  });

  test('storage failure does not poison later queued operations', () async {
    final native = _DelayedStorage()..failWrite = true;
    final store = GestureCredentialStore(
      logger: AppLogger(),
      secureStorage: native,
    );
    final saving = store.save(key, [0, 1, 4, 7], canCommit: () => true);
    final failure = expectLater(saving, throwsStateError);
    await native.started.future;
    final deleting = store.delete(key);
    native.release.complete();
    await failure;
    await deleting;
    expect(native.deleted, isTrue);
  });

  test(
    'missing, corrupt and excessive-iteration records fail closed',
    () async {
      expect(await gestures.verify('missing', [0, 1, 4, 7]), isFalse);
      for (final value in [
        'invalid json',
        '{}',
        legacyRecord.replaceFirst('120000', '0'),
        legacyRecord.replaceFirst('120000', '1000001'),
        legacyRecord.replaceFirst('"version":2', '"version":3'),
      ]) {
        await storage.write(key: key, value: value);
        expect(await gestures.verify(key, [0, 1, 4, 7]), isFalse);
      }
    },
  );
}

class _DelayedStorage extends FlutterSecureStorage {
  final started = Completer<void>();
  final release = Completer<void>();
  bool failWrite = false;
  bool deleted = false;
  String? record;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    started.complete();
    await release.future;
    if (failWrite) throw StateError('unavailable');
    record = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deleted = true;
    record = null;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => record;
}
