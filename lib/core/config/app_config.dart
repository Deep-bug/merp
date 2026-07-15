// -----------------------------------------------------------------------------
// 文件：app_config.dart
// 作用：集中定义 API、旧 Vue、地图厂商和环境注入配置
// 编写时间：2026-07-10
// 维护说明：生产值使用 --dart-define 注入，禁止把真实密钥提交到仓库
// -----------------------------------------------------------------------------

/// 应用运行配置。
///
/// 当前先使用常量默认值，真实企业环境建议通过 --dart-define 注入 dev/test/prod。
/// 这样 Android、iOS、Web、Windows 可以共用一套代码，只替换环境变量。
class AppConfig {
  const AppConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.146.152.51:31234',
    ),
    this.legacyVueBaseUrl = 'https://erp.example.com/mobile',
    this.loginPath = '/api/v1/auth/login',
    this.refreshTokenPath = '/api/v1/auth/refresh',
    this.logoutPath = '/api/v1/auth/logout',
    this.userInfoPath = '/api/v1/user/userInfo',
    this.menuPath = '/auth/menus',
    this.mapProvider = 'baidu',
    this.androidMapApiKey = const String.fromEnvironment(
      'BAIDU_MAP_ANDROID_AK',
      defaultValue: '',
    ),
    this.iosMapApiKey = const String.fromEnvironment(
      'BAIDU_MAP_IOS_AK',
      defaultValue: '',
    ),
    this.webMapApiKey = const String.fromEnvironment(
      'BAIDU_MAP_WEB_AK',
      defaultValue: '',
    ),
  });

  /// 后端 API 域名。真实接入时建议按 dev/test/prod 使用 --dart-define 注入。
  final String apiBaseUrl;

  /// 旧 Vue2 移动端入口。每个 legacyPath 会拼接到这个地址后面。
  final String legacyVueBaseUrl;

  final String loginPath;

  /// 使用 refresh_token 换取新访问令牌的接口。
  final String refreshTokenPath;

  /// 服务端注销 refresh_token 的接口。
  final String logoutPath;

  /// 当前登录用户的完整资料接口。
  final String userInfoPath;

  /// 菜单权限接口尚未包含在本次后端文档中，继续保留独立配置入口。
  final String menuPath;

  /// 地图厂商标识。后续可改成 baidu/amap/tencent 等。
  final String mapProvider;

  /// Android 地图 SDK 密钥填写位置。
  final String androidMapApiKey;

  /// iOS 地图 SDK 密钥填写位置。
  final String iosMapApiKey;

  /// Web 地图 SDK 密钥填写位置。
  final String webMapApiKey;

  Uri legacyUri(String legacyPath) {
    final base = legacyVueBaseUrl.endsWith('/')
        ? legacyVueBaseUrl.substring(0, legacyVueBaseUrl.length - 1)
        : legacyVueBaseUrl;
    final path = legacyPath.startsWith('/') ? legacyPath : '/$legacyPath';
    return Uri.parse('$base$path');
  }
}
