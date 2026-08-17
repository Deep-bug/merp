// -----------------------------------------------------------------------------
// 文件：web_data_cleaner.dart
// 作用：清除 Android/iOS WebView 的网页资源缓存和 H5 本地数据
// 维护说明：只清理 WebView 网站数据，严禁在这里删除 Token、偏好设置或用户数据
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// WebView 网站数据清理服务。
///
/// 旧 Vue2 页面可能会把旧版脚本、样式、Cookie、草稿或离线数据保存在系统
/// WebView 中。不同平台的清理 API 不一致，因此由原生层完成，Flutter 只提供
/// 统一入口与执行状态。
class WebDataCleaner extends ChangeNotifier {
  WebDataCleaner({
    required AppLogger logger,
    MethodChannel? channel,
    TargetPlatform? platform,
    bool? isWeb,
  }) : _logger = logger,
       _channel = channel ?? const MethodChannel(_channelName),
       _platform = platform ?? defaultTargetPlatform,
       _isWeb = isWeb ?? kIsWeb;

  static const _channelName = 'com.delta.merpdelta/webview_data';
  static const _clearMethod = 'clearAllWebData';

  final AppLogger _logger;
  final MethodChannel _channel;
  final TargetPlatform _platform;
  final bool _isWeb;

  bool _isClearing = false;

  /// 页面据此禁用重复点击，避免两个原生清理任务并发执行。
  bool get isClearing => _isClearing;

  /// 清除 WebView 的资源缓存、Cookie 与 H5 本地数据。
  ///
  /// 不会删除 Flutter 安全存储中的 App Token，也不会影响 SharedPreferences 内的
  /// 收藏、语言、服务器、手势及生物识别设置。
  Future<void> clearAllWebData() async {
    if (_isClearing) {
      return;
    }
    if (_isWeb ||
        (_platform != TargetPlatform.android &&
            _platform != TargetPlatform.iOS)) {
      throw UnsupportedError('当前平台不支持清除原生 WebView 数据');
    }

    _isClearing = true;
    notifyListeners();
    _logger.info('web.data', '开始清除 Web 页面与数据');
    try {
      final cleared = await _channel.invokeMethod<bool>(_clearMethod);
      if (cleared != true) {
        throw StateError('原生 WebView 未确认清理完成');
      }
      _logger.info('web.data', 'Web 页面与数据清除完成');
    } catch (error, stackTrace) {
      _logger.error(
        'web.data',
        'Web 页面与数据清除失败',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }
}
