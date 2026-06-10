/// 应用运行配置。
///
/// 当前先使用常量默认值，真实企业环境建议通过 --dart-define 注入 dev/test/prod。
/// 这样 Android、iOS、Web、Windows 可以共用一套代码，只替换环境变量。
class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'https://api.example.com',
    this.legacyVueBaseUrl = 'https://erp.example.com/mobile',
    this.loginPath = '/auth/login',
    this.menuPath = '/auth/menus',
    this.mapProvider = 'unconfigured',
    this.androidMapApiKey = '请替换为 Android 地图 AK',
    this.iosMapApiKey = '请替换为 iOS 地图 AK',
    this.webMapApiKey = '请替换为 Web 地图 AK',
  });

  /// 后端 API 域名。真实接入时建议按 dev/test/prod 使用 --dart-define 注入。
  final String apiBaseUrl;

  /// 旧 Vue2 移动端入口。每个 legacyPath 会拼接到这个地址后面。
  final String legacyVueBaseUrl;

  final String loginPath;
  final String menuPath;

  /// 地图厂商标识。后续可改成 baidu/amap/tencent 等。
  final String mapProvider;

  /// Android 地图 SDK 密钥填写位置。
  final String androidMapApiKey;

  /// iOS 地图 SDK 密钥填写位置。
  final String iosMapApiKey;

  /// Web 地图 SDK 密钥填写位置。
  final String webMapApiKey;

  bool get usesDemoBackend => apiBaseUrl.contains('example.com');

  Uri legacyUri(String legacyPath) {
    final base = legacyVueBaseUrl.endsWith('/')
        ? legacyVueBaseUrl.substring(0, legacyVueBaseUrl.length - 1)
        : legacyVueBaseUrl;
    final path = legacyPath.startsWith('/') ? legacyPath : '/$legacyPath';
    return Uri.parse('$base$path');
  }
}
