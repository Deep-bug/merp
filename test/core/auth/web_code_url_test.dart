import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/web_code_url.dart';

void main() {
  test(
    'places encoded code before Vue hash route and preserves other fields',
    () {
      final page = Uri.parse(
        'https://example.com/eform.html?lang=zh_CN#/home?item=1',
      );

      final result = WebCodeUrl.append(page, 'new code+1');

      expect(result.queryParameters, {'lang': 'zh_CN', 'code': 'new code+1'});
      expect(result.fragment, '/home?item=1');
      expect(result.toString(), contains('code=new+code%2B1#'));
    },
  );

  test('replaces stale code and redacts code from diagnostic text', () {
    final page = Uri.parse('https://example.com/page?code=old&lang=en_US');
    final result = WebCodeUrl.append(page, 'fresh');

    expect(result.queryParameters['code'], 'fresh');
    expect(
      WebCodeUrl.redact('failed: $result'),
      'failed: https://example.com/page?code=[redacted]&lang=en_US',
    );
  });
}
