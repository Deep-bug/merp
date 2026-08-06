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
    this.appEnvironment = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'qas',
    ),
    this.authEnvironment = const String.fromEnvironment(
      'AUTH_ENVIRONMENT',
      defaultValue: 'merp',
    ),
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.146.152.51:31234',
    ),
    this.legacyVueBaseUrl = 'https://erp.example.com/mobile',
    this.bridgeTestUrl = const String.fromEnvironment(
      'BRIDGE_TEST_URL',
      defaultValue:
          'https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/flutter_test.html#/home',
    ),
    this.electronicFormUrl = const String.fromEnvironment(
      'ELECTRONIC_FORM_URL',
      defaultValue:
          'https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/eform.html#/home',
    ),
    this.assetInventoryUrl = const String.fromEnvironment(
      'ASSET_INVENTORY_URL',
      defaultValue:
          'https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/FixedAssetInventory.html#/home',
    ),
    this.loginPath = '/api/v1/auth/login',
    this.captchaPath = '/api/v1/auth/captcha',
    this.refreshTokenPath = '/api/v1/auth/refresh',
    this.logoutPath = '/api/v1/auth/logout',
    this.userInfoPath = '/api/v1/user/userInfo',
    this.menuPath = '/api/v1/app/features',
    this.menuAppId = const String.fromEnvironment(
      'MENU_APP_ID',
      defaultValue: 'merp',
    ),
    this.menuFeatureScope = const String.fromEnvironment(
      'MENU_FEATURE_SCOPE',
      defaultValue: 'at',
    ),
    this.mockMenus = const bool.fromEnvironment(
      'MOCK_MENUS',
      defaultValue: false,
    ),
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

  static const supportedEnvironments = {'qas', 'prd'};

  /// 部署环境，只允许 qas 或 prd。
  final String appEnvironment;

  /// 后端认证接口的业务环境标识，当前默认固定为 merp。
  final String authEnvironment;

  String get normalizedAppEnvironment {
    final value = appEnvironment.trim().toLowerCase();
    if (!supportedEnvironments.contains(value)) {
      throw StateError('APP_ENV 只支持 qas 或 prd，当前值：$appEnvironment');
    }
    return value;
  }

  String get normalizedAuthEnvironment {
    final value = authEnvironment.trim();
    if (value.isEmpty) {
      throw StateError('AUTH_ENVIRONMENT 不能为空');
    }
    return value;
  }

  String get tokenStorageNamespace => 'merp_${normalizedAppEnvironment}_auth';

  /// 后端 API 域名。真实接入时建议按 dev/test/prod 使用 --dart-define 注入。
  final String apiBaseUrl;

  /// 旧 Vue2 移动端入口。每个 legacyPath 会拼接到这个地址后面。
  final String legacyVueBaseUrl;

  /// Vue2 原生能力验证页地址，可按环境通过 dart-define 覆盖。
  final String bridgeTestUrl;

  /// 电子表单 WebView 地址；带人员、表单和票据参数的值只允许本地注入。
  final String electronicFormUrl;

  /// 固资盘点 WebView 地址；带人员和票据参数的值只允许本地注入。
  final String assetInventoryUrl;

  final String loginPath;

  /// 获取登录验证码图片和对应 captchaId。
  final String captchaPath;

  /// 使用 refresh_token 换取新访问令牌的接口。
  final String refreshTokenPath;

  /// 服务端注销 refresh_token 的接口。
  final String logoutPath;

  /// 当前登录用户的完整资料接口。
  final String userInfoPath;

  /// 当前登录用户的功能菜单接口。
  final String menuPath;

  /// 菜单接口所属应用标识。
  final String menuAppId;

  /// 后端菜单范围参数 `sys_app_features`。
  final String menuFeatureScope;

  /// 本地开发兜底开关；QAS/生产环境应关闭并读取真实用户菜单。
  final bool mockMenus;

  /// 地图厂商标识。后续可改成 baidu/amap/tencent 等。
  final String mapProvider;

  /// Android 地图 SDK 密钥填写位置。
  final String androidMapApiKey;

  /// iOS 地图 SDK 密钥填写位置。
  final String iosMapApiKey;

  /// Web 地图 SDK 密钥填写位置。
  final String webMapApiKey;

  Uri legacyUri(String legacyPath) {
    final directUri = Uri.tryParse(legacyPath.trim());
    if (directUri != null &&
        directUri.hasScheme &&
        (directUri.scheme == 'http' || directUri.scheme == 'https')) {
      return directUri;
    }
    final base = legacyVueBaseUrl.endsWith('/')
        ? legacyVueBaseUrl.substring(0, legacyVueBaseUrl.length - 1)
        : legacyVueBaseUrl;
    final path = legacyPath.startsWith('/') ? legacyPath : '/$legacyPath';
    return Uri.parse('$base$path');
  }
}
