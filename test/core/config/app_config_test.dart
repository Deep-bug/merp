import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';

void main() {
  test('normalizes supported application environments', () {
    expect(
      const AppConfig(appEnvironment: ' QAS ').normalizedAppEnvironment,
      'qas',
    );
    expect(
      const AppConfig(appEnvironment: 'PRD').normalizedAppEnvironment,
      'prd',
    );
  });

  test('rejects unsupported application environment', () {
    expect(
      () => const AppConfig(appEnvironment: 'dev').normalizedAppEnvironment,
      throwsStateError,
    );
  });

  test('uses independent token namespaces for qas and prd', () {
    expect(
      const AppConfig(appEnvironment: 'qas').tokenStorageNamespace,
      'merp_qas_auth',
    );
    expect(
      const AppConfig(appEnvironment: 'prd').tokenStorageNamespace,
      'merp_prd_auth',
    );
  });

  test('legacyUri accepts an absolute electronic form URL', () {
    const url = 'https://example.test/eform.html#/home?task=1';
    expect(const AppConfig().legacyUri(url).toString(), url);
  });
}
