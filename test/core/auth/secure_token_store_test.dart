import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/auth/secure_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bundleKey = 'merp.qas.auth.tokens.v2';
  const accessKey = 'merp.qas.auth.access_token';
  const refreshKey = 'merp.qas.auth.refresh_token';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('saves access and refresh token as one atomic bundle', () async {
    const rawStorage = FlutterSecureStorage();
    final store = SecureTokenStore(storage: rawStorage);

    await store.saveTokens(
      const AuthTokens(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );

    final encoded = await rawStorage.read(key: bundleKey);
    expect(jsonDecode(encoded!), {
      'access_token': 'access-2',
      'refresh_token': 'refresh-2',
    });
    expect(await rawStorage.read(key: accessKey), isNull);
    expect(await rawStorage.read(key: refreshKey), isNull);

    final restored = await store.readTokens();
    expect(restored?.accessToken, 'access-2');
    expect(restored?.refreshToken, 'refresh-2');
  });

  test('migrates legacy split keys into the atomic bundle', () async {
    FlutterSecureStorage.setMockInitialValues({
      accessKey: 'legacy-access',
      refreshKey: 'legacy-refresh',
    });
    const rawStorage = FlutterSecureStorage();
    final store = SecureTokenStore(storage: rawStorage);

    final restored = await store.readTokens();

    expect(restored?.accessToken, 'legacy-access');
    expect(restored?.refreshToken, 'legacy-refresh');
    expect(await rawStorage.read(key: bundleKey), isNotNull);
    expect(await rawStorage.read(key: accessKey), isNull);
    expect(await rawStorage.read(key: refreshKey), isNull);
  });

  test('corrupt bundle falls back to a logged-out state', () async {
    FlutterSecureStorage.setMockInitialValues({bundleKey: '{invalid'});
    const rawStorage = FlutterSecureStorage();
    final store = SecureTokenStore(storage: rawStorage);

    expect(await store.readTokens(), isNull);
    expect(await rawStorage.read(key: bundleKey), isNull);
  });
}
