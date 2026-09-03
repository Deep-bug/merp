import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/platform/local_network_access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/local-network');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android does not require the iOS local-network gate', () async {
    final service = LocalNetworkAccessService(
      channel: channel,
      platform: TargetPlatform.android,
    );

    final result = await service.check('http://10.146.152.51:31234');

    expect(result.status, LocalNetworkAccessStatus.notRequired);
  });

  test('public iOS API does not require the local-network gate', () async {
    final service = LocalNetworkAccessService(
      channel: channel,
      platform: TargetPlatform.iOS,
    );

    final result = await service.check('https://api.example.com');

    expect(result.status, LocalNetworkAccessStatus.notRequired);
  });

  test('private iOS API delegates the access check to native code', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'checkAccess');
          expect(call.arguments, {'host': '10.146.152.51', 'port': 31234});
          return {'status': 'denied', 'message': 'policy denied'};
        });
    final service = LocalNetworkAccessService(
      channel: channel,
      platform: TargetPlatform.iOS,
    );

    final result = await service.check('http://10.146.152.51:31234');

    expect(result.status, LocalNetworkAccessStatus.denied);
    expect(result.detail, 'policy denied');
  });
}
