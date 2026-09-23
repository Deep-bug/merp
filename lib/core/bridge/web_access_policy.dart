import '../config/app_config.dart';

/// App 配置才是信任来源；菜单 URL、网页参数不能自行扩大白名单。
/// 使用完整 origin（协议、主机、端口）匹配，禁止后缀匹配和 HTTPS 降级。
class WebAccessPolicy {
  WebAccessPolicy({required Iterable<String> trustedUrls})
    : _origins = {
        for (final value in trustedUrls)
          if (_origin(Uri.tryParse(value.trim())) case final String origin)
            origin,
      };

  factory WebAccessPolicy.fromConfig(AppConfig config) => WebAccessPolicy(
    trustedUrls: [
      config.legacyVueBaseUrl,
      config.electronicFormUrl,
      config.assetInventoryUrl,
      config.bridgeTestUrl,
      ...config.trustedWebOrigins,
    ],
  );

  final Set<String> _origins;

  bool trusts(Uri uri) {
    final origin = _origin(uri);
    return origin != null && _origins.contains(origin);
  }

  /// 一次 WebView 访问锁定入口 origin，防止携带 Code/凭证跨域重定向。
  /// 其他可信业务域仍应通过 App 功能入口重新换码打开。
  bool allowsNavigation({required Uri entry, required Uri target}) =>
      trusts(entry) && _origin(entry) == _origin(target);

  static String? _origin(Uri? uri) {
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    // 默认占位地址不应意外成为正式可信站点。
    if (uri.host == 'example.com' || uri.host.endsWith('.example.com')) {
      return null;
    }
    return uri.origin;
  }
}
