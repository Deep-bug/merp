// -----------------------------------------------------------------------------
// 文件：webview_support.dart
// 作用：判断当前平台是否具备已注册的 WebView 实现
// 编写时间：2026-07-10
// 维护说明：创建 WebViewController 前必须经过此能力判断
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// WebView 平台能力判断。
///
/// `webview_flutter` 在 Android/iOS 有平台实现；Flutter Web、Windows、macOS、
/// Linux 默认没有注册对应实现。非移动端如果直接创建 WebViewController，
/// 会触发 `WebViewPlatform.instance != null` 断言红屏。
class WebViewSupport {
  const WebViewSupport._();

  static bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get platformLabel {
    if (kIsWeb) {
      return 'Flutter Web';
    }
    return defaultTargetPlatform.name;
  }

  static String get unsupportedDetail {
    return '当前平台：$platformLabel\n'
        'webview_flutter 当前项目只配置了 Android/iOS WebView。\n'
        '请使用 Android 真机、Android 模拟器或 iOS 设备验证 Vue 页面调用 Flutter Bridge。';
  }
}
