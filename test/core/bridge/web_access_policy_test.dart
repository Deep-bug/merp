import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/bridge/web_access_policy.dart';
import 'package:merp/core/config/app_config.dart';

void main() {
  final policy = WebAccessPolicy(
    trustedUrls: [
      'https://h5.company.test/app',
      'http://10.1.2.3:8080',
      'https://other.company.test',
    ],
  );
  final entry = Uri.parse('https://h5.company.test/index.html?code=abc#/home');

  test('same origin paths, query and Vue hash routes are allowed', () {
    for (final target in [
      'https://h5.company.test/next.html',
      'https://h5.company.test:443/index.html?x=1#/form',
      'https://H5.COMPANY.TEST/index.html',
    ]) {
      expect(
        policy.allowsNavigation(entry: entry, target: Uri.parse(target)),
        isTrue,
      );
    }
  });

  test(
    'rejects lookalike hosts, user info, different ports and scheme downgrade',
    () {
      for (final target in [
        'https://h5.company.test.attacker.test/',
        'https://h5.company.test@attacker.test/',
        'https://attacker@h5.company.test/',
        'https://h5.company.test:8443/',
        'http://h5.company.test/',
        'javascript:alert(1)',
        'file:///private/data',
        'data:text/html,test',
        '//h5.company.test/path',
        'about:blank',
      ]) {
        expect(
          policy.allowsNavigation(entry: entry, target: Uri.parse(target)),
          isFalse,
          reason: target,
        );
      }
    },
  );

  test('a different trusted origin still requires a new app entry', () {
    final other = Uri.parse('https://other.company.test/');
    expect(policy.trusts(other), isTrue);
    expect(policy.allowsNavigation(entry: entry, target: other), isFalse);
  });

  test('HTTP QAS origin must be explicitly configured with matching port', () {
    expect(policy.trusts(Uri.parse('http://10.1.2.3:8080/app')), isTrue);
    expect(policy.trusts(Uri.parse('http://10.1.2.3/app')), isFalse);
    expect(policy.trusts(Uri.parse('http://10.1.2.4:8080/app')), isFalse);
  });

  test(
    'config trusts first-party web entries, not arbitrary menu or API URLs',
    () {
      final configured = WebAccessPolicy.fromConfig(
        const AppConfig(
          apiBaseUrl: 'https://api.company.test',
          trustedWebOrigins: ['https://additional.company.test'],
        ),
      );
      expect(
        configured.trusts(Uri.parse('https://mcrmapi.deltaww.com.cn/page')),
        isTrue,
      );
      expect(
        configured.trusts(Uri.parse('https://additional.company.test/page')),
        isTrue,
      );
      expect(
        configured.trusts(Uri.parse('https://api.company.test/page')),
        isFalse,
      );
      expect(
        configured.trusts(Uri.parse('https://menu-url.company.test/page')),
        isFalse,
      );
      expect(
        configured.trusts(Uri.parse('https://erp.example.com/mobile')),
        isFalse,
      );
    },
  );
}
