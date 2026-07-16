// -----------------------------------------------------------------------------
// 文件：api_exception.dart
// 作用：定义包含企业错误码、后端追踪号和客户端故障编号的统一网络异常
// 编写时间：2026-07-10
// 维护说明：页面展示 userMessage，不直接解析 DioException
// -----------------------------------------------------------------------------

import 'app_error_code.dart';

class ApiException implements Exception {
  ApiException({
    required this.errorCode,
    String? message,
    this.httpStatusCode,
    this.traceId,
    this.path,
    this.raw,
    this.incidentId,
  }) : message = message ?? errorCode.defaultMessage;

  final AppErrorCode errorCode;
  final String message;
  final int? httpStatusCode;
  final String? traceId;
  final String? path;
  final Object? raw;
  final String? incidentId;

  bool get isAuthError => errorCode == AppErrorCode.serverUnauthorized;

  String get userMessage {
    final references = <String>[
      if (traceId != null && traceId!.isNotEmpty) '追踪号：$traceId',
      if (incidentId != null && incidentId!.isNotEmpty) '故障编号：$incidentId',
    ];
    return references.isEmpty ? message : '$message\n${references.join('\n')}';
  }

  ApiException withIncidentId(String value) {
    return ApiException(
      errorCode: errorCode,
      message: message,
      httpStatusCode: httpStatusCode,
      traceId: traceId,
      path: path,
      raw: raw,
      incidentId: value,
    );
  }

  @override
  String toString() {
    final parts = <String>[
      errorCode.code,
      message,
      if (httpStatusCode != null) 'HTTP $httpStatusCode',
      ?path,
      if (traceId != null) 'traceId=$traceId',
    ];
    return parts.join(' | ');
  }
}
