// -----------------------------------------------------------------------------
// 文件：baidu_privacy_consent_store.dart
// 作用：统一保存百度地图与定位 SDK 的隐私协议同意状态
// 编写时间：2026-07-15
// 维护说明：隐私协议内容或版本变化时必须升级缓存键版本并重新征得同意
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

class BaiduPrivacyConsentStore {
  const BaiduPrivacyConsentStore();

  static const preferenceKey = 'merp.baidu_sdk.privacy_accepted.v1';

  Future<bool> hasConsent() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(preferenceKey) ?? false;
  }

  Future<void> accept() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, true);
  }
}
