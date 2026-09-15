/// 旧 Vue2 地址中的一次性 Code 只属于本次页面加载，不持久化、不复用。
class WebCodeUrl {
  const WebCodeUrl._();

  /// Uri 会将查询参数放在 # 路由之前，并负责对 Code 做 URL 编码。
  static Uri append(Uri page, String code) =>
      page.replace(queryParameters: {...page.queryParameters, 'code': code});

  /// 仅用于诊断日志；避免 WebView 异常文本携带页面 URL 时泄露 Code。
  static String redact(String value) => value.replaceAllMapped(
    RegExp(r'([?&]code=)[^&#\s]+', caseSensitive: false),
    (match) => '${match.group(1)}[redacted]',
  );
}
