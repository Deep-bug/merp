// -----------------------------------------------------------------------------
// 文件：app_error_code.dart
// 作用：定义客户端、鉴权、业务和服务端错误码的企业分段规范
// 编写时间：2026-07-10
// 维护说明：新增错误码不得复用既有 code，需同步后端和监控平台
// -----------------------------------------------------------------------------

/// 客户端统一错误码，与当前后端接口文档中的关键字保持一致。
enum AppErrorCode {
  success('success', '请求成功'),
  clientTimeout('clientTimeout', '请求超时'),
  clientNetworkUnavailable('clientNetworkUnavailable', '网络连接失败'),
  clientCancelled('clientCancelled', '请求已取消'),
  clientInvalidConfig('clientInvalidConfig', '证书或客户端配置异常'),
  serverUnauthorized('serverUnauthorized', '登录已过期，请重新登录'),
  serverForbidden('serverForbidden', '账号无此操作权限'),
  serverNotFound('serverNotFound', '请求的资源不存在'),
  serverValidation('serverValidation', '请求参数校验失败'),
  serverError('serverError', '服务端内部错误'),
  clientUnknown('clientUnknown', '未知错误');

  const AppErrorCode(this.code, this.defaultMessage);

  final String code;
  final String defaultMessage;

  static AppErrorCode fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return clientUnknown;
    }
    for (final item in values) {
      if (item.code == code) {
        return item;
      }
    }
    return switch (code) {
      '0' || '200' || '000000' => success,
      '400' => serverValidation,
      '401' => serverUnauthorized,
      '403' => serverForbidden,
      '404' => serverNotFound,
      _ => serverError,
    };
  }

  static AppErrorCode fromHttpStatus(int? statusCode) {
    final status = statusCode ?? 0;
    return switch (status) {
      400 => serverValidation,
      401 => serverUnauthorized,
      403 => serverForbidden,
      404 => serverNotFound,
      >= 500 && <= 599 => serverError,
      _ => clientUnknown,
    };
  }
}
