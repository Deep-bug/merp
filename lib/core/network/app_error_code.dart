/// 前端统一错误码。
///
/// 分段规则：
/// C = 客户端错误，A = 认证授权错误，B = 业务错误，S = 服务端/网关错误。
/// 后端如果已有自己的 code，可以在 fromCode 里继续扩展映射关系。
enum AppErrorCode {
  success('000000', '请求成功'),

  // Client side errors.
  clientUnknown('C00001', '客户端未知错误'),
  clientBadResponse('C00002', '响应格式错误'),
  clientCancelled('C00003', '请求已取消'),
  clientNetworkUnavailable('C00004', '网络连接不可用'),
  clientTimeout('C00005', '请求超时'),
  clientInvalidConfig('C00006', '客户端配置错误'),

  // Authentication and authorization.
  authUnauthenticated('A00001', '登录已过期，请重新登录'),
  authForbidden('A00002', '没有访问权限'),
  authTokenExpired('A00003', '登录凭证已过期'),

  // Business layer.
  businessValidationFailed('B00001', '业务校验失败'),
  businessNotFound('B00002', '数据不存在'),
  businessConflict('B00003', '数据状态已变化，请刷新后重试'),
  businessRateLimited('B00004', '操作过于频繁，请稍后重试'),

  // Server side errors.
  serverBadRequest('S00400', '请求参数错误'),
  serverUnauthorized('S00401', '未登录或登录已过期'),
  serverForbidden('S00403', '没有访问权限'),
  serverNotFound('S00404', '服务地址不存在'),
  serverConflict('S00409', '资源冲突'),
  serverTooManyRequests('S00429', '请求过于频繁'),
  serverInternal('S00500', '服务器内部错误'),
  serverBadGateway('S00502', '网关错误'),
  serverUnavailable('S00503', '服务暂不可用'),
  serverGatewayTimeout('S00504', '网关超时');

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
    if (code.startsWith('A')) {
      return authUnauthenticated;
    }
    if (code.startsWith('B')) {
      return businessValidationFailed;
    }
    if (code.startsWith('S')) {
      return serverInternal;
    }
    return clientUnknown;
  }

  static AppErrorCode fromHttpStatus(int? statusCode) {
    return switch (statusCode) {
      400 => serverBadRequest,
      401 => authUnauthenticated,
      403 => authForbidden,
      404 => serverNotFound,
      409 => serverConflict,
      429 => serverTooManyRequests,
      500 => serverInternal,
      502 => serverBadGateway,
      503 => serverUnavailable,
      504 => serverGatewayTimeout,
      _ => serverInternal,
    };
  }
}
