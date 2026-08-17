import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/platform/web_data_cleaner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.delta.merpdelta/webview_data');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('clears website data through the native WebView channel', () async {
    MethodCall? capturedCall;
    messenger.setMockMethodCallHandler(channel, (call) async {
      capturedCall = call;
      return true;
    });
    final cleaner = WebDataCleaner(
      logger: AppLogger(),
      channel: channel,
      platform: TargetPlatform.android,
      isWeb: false,
    );

    await cleaner.clearAllWebData();

    expect(capturedCall?.method, 'clearAllWebData');
    expect(cleaner.isClearing, isFalse);
  });

  test('restores its state when native clearing fails', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'WEB_DATA_CLEAR_FAILED');
    });
    final cleaner = WebDataCleaner(
      logger: AppLogger(),
      channel: channel,
      platform: TargetPlatform.iOS,
      isWeb: false,
    );

    await expectLater(
      cleaner.clearAllWebData(),
      throwsA(isA<PlatformException>()),
    );

    expect(cleaner.isClearing, isFalse);
  });
}
