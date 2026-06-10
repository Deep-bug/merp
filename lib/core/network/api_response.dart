import 'api_exception.dart';
import 'app_error_code.dart';

/// 统一响应壳解析器。
///
/// 推荐后端返回：
/// `{ "code": "000000", "message": "success", "data": {}, "traceId": "..." }`
/// 兼容旧接口直接返回数组或对象，便于 Cordova/Vue2 迁移期逐步改造。
class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.success = true,
    this.traceId,
    this.raw,
  });

  final String code;
  final String message;
  final T data;
  final bool success;
  final String? traceId;
  final Object? raw;

  static bool isSuccessCode(String? code) {
    return code == null ||
        code.isEmpty ||
        code == AppErrorCode.success.code ||
        code == '0' ||
        code == '200';
  }

  static T unwrap<T>(Object? raw, {required String path}) {
    if (raw is Map<String, dynamic>) {
      final traceId = _readString(raw, ['traceId', 'requestId', 'request_id']);
      final code = _readString(raw, ['code', 'errorCode', 'error_code']);
      final message = _readString(raw, ['message', 'msg', 'errorMessage']);
      final success = raw['success'] as bool?;
      final hasEnvelope =
          raw.containsKey('data') ||
          raw.containsKey('code') ||
          raw.containsKey('success') ||
          raw.containsKey('message') ||
          raw.containsKey('msg');

      if (hasEnvelope) {
        // success 字段优先；没有 success 时，再按 code 判断是否成功。
        final ok = success ?? isSuccessCode(code);
        if (!ok) {
          final mapped = AppErrorCode.fromCode(code);
          throw ApiException(
            errorCode: mapped,
            message: message ?? mapped.defaultMessage,
            traceId: traceId,
            path: path,
            raw: raw,
          );
        }
        return raw['data'] as T;
      }
    }

    // Some legacy endpoints return a raw list/object without an envelope.
    return raw as T;
  }

  static String? _readString(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
  }
}
