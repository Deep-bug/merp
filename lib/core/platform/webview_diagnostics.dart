import 'package:webview_flutter/webview_flutter.dart';

import '../logging/app_logger.dart';

/// Opt-in WebView diagnostics for controlled device troubleshooting.
class WebViewDiagnostics {
  const WebViewDiagnostics._();

  static const enabled = bool.fromEnvironment('WEBVIEW_DIAGNOSTICS');

  static Future<void> attach({
    required WebViewController controller,
    required AppLogger logger,
    required String page,
  }) async {
    if (!enabled) {
      return;
    }
    await controller.setOnConsoleMessage((message) {
      logger.warning(
        'webview',
        'JavaScript console message',
        fields: {
          'page': page,
          'level': message.level.name,
          'message': message.message,
        },
      );
    });
  }

  static Future<void> inspect({
    required WebViewController controller,
    required AppLogger logger,
    required String page,
  }) async {
    if (!enabled) {
      return;
    }
    try {
      final result = await controller.runJavaScriptReturningResult('''
(function () {
  var root = document.getElementById('app');
  return JSON.stringify({
    readyState: document.readyState,
    userAgent: navigator.userAgent,
    appExists: !!root,
    appChildCount: root ? root.childNodes.length : -1,
    bodyTextLength: document.body ? document.body.innerText.length : -1,
    scriptCount: document.scripts ? document.scripts.length : -1,
    scriptSources: document.scripts ? Array.prototype.map.call(
      document.scripts,
      function (script) { return script.src || '<inline>'; }
    ) : []
  });
})()
''');
      logger.info(
        'webview',
        'WebView DOM inspection completed',
        fields: {'page': page, 'result': result.toString()},
      );
    } catch (error, stackTrace) {
      logger.warning(
        'webview',
        'WebView DOM inspection failed',
        error: error,
        stackTrace: stackTrace,
        fields: {'page': page},
      );
    }
  }

  static String resourceType(WebResourceError error) {
    return error.isForMainFrame == true ? 'mainFrame' : 'subresource';
  }
}
