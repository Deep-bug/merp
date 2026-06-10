import 'app_error_code.dart';

class ApiException implements Exception {
  ApiException({
    required this.errorCode,
    String? message,
    this.httpStatusCode,
    this.traceId,
    this.path,
    this.raw,
  }) : message = message ?? errorCode.defaultMessage;

  final AppErrorCode errorCode;
  final String message;
  final int? httpStatusCode;
  final String? traceId;
  final String? path;
  final Object? raw;

  bool get isAuthError =>
      errorCode == AppErrorCode.authUnauthenticated ||
      errorCode == AppErrorCode.authTokenExpired ||
      errorCode == AppErrorCode.serverUnauthorized;

  String get userMessage {
    if (traceId == null || traceId!.isEmpty) {
      return message;
    }
    return '$message\n追踪号：$traceId';
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
