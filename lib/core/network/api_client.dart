import 'package:dio/dio.dart';

import '../auth/secure_token_store.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'app_error_code.dart';

/// 企业统一 HTTP 客户端。
///
/// 业务仓库层只调用 get/post/put/delete，不直接接触 Dio。
/// 这样 token 注入、错误码转换、响应壳解析都能在一个地方维护。
class ApiClient {
  ApiClient({required this.config, required SecureTokenStore tokenStore})
    : _tokenStore = tokenStore,
      _dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 所有接口请求统一从安全存储读取 token，并写入 Authorization Header。
          // 后续如果要改成刷新 token、设备指纹、租户 ID，也都从这里扩展。
          final token = await _tokenStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Client'] = 'merp-flutter';
          options.headers['X-Request-Id'] ??= _requestId();
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 代表登录态失效，先清理本地 token，路由守卫会把用户带回登录页。
          if (error.response?.statusCode == 401) {
            await _tokenStore.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  final AppConfig config;
  final SecureTokenStore _tokenStore;
  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send<T>(
      () => _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      path: path,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send<T>(
      () => _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      path: path,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send<T>(
      () => _dio.put<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      path: path,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _send<T>(
      () => _dio.delete<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      path: path,
    );
  }

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request, {
    required String path,
  }) async {
    try {
      // 所有 HTTP 方法最终都进入这里，统一处理 HTTP 状态码和业务响应壳。
      final response = await request();
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw _fromHttpResponse(response, path);
      }
      return ApiResponse.unwrap<T>(response.data, path: path);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _fromDioException(error, path);
    } catch (error) {
      throw ApiException(
        errorCode: AppErrorCode.clientUnknown,
        message: '客户端处理响应时发生未知错误',
        path: path,
        raw: error,
      );
    }
  }

  ApiException _fromDioException(DioException error, String path) {
    final response = error.response;
    if (response != null) {
      return _fromHttpResponse(response, path);
    }

    // 没有 HTTP 响应时，说明请求还没到达业务网关或连接过程就失败了。
    // 这里统一归类为客户端错误，方便页面给出“检查网络/配置”的提示。
    final code = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => AppErrorCode.clientTimeout,
      DioExceptionType.cancel => AppErrorCode.clientCancelled,
      DioExceptionType.connectionError => AppErrorCode.clientNetworkUnavailable,
      DioExceptionType.badCertificate => AppErrorCode.clientInvalidConfig,
      _ => AppErrorCode.clientUnknown,
    };

    return ApiException(
      errorCode: code,
      message: _messageForDioException(error, code),
      path: path,
      raw: error,
    );
  }

  ApiException _fromHttpResponse(Response<Object?> response, String path) {
    final statusCode = response.statusCode;
    final data = response.data;
    String? message;
    String? traceId;
    AppErrorCode code = AppErrorCode.fromHttpStatus(statusCode);

    // 后端如果返回了企业错误码，就优先使用后端 code/message/traceId。
    // 如果没有返回，则按 HTTP 状态码映射为前端标准错误码。
    if (data is Map<String, dynamic>) {
      final serverCode = _readString(data, ['code', 'errorCode', 'error_code']);
      final serverMessage = _readString(data, [
        'message',
        'msg',
        'errorMessage',
      ]);
      traceId = _readString(data, ['traceId', 'requestId', 'request_id']);
      if (serverCode != null) {
        code = AppErrorCode.fromCode(serverCode);
      }
      message = serverMessage;
    }

    return ApiException(
      errorCode: code,
      message: message ?? code.defaultMessage,
      httpStatusCode: statusCode,
      traceId: traceId,
      path: path,
      raw: data,
    );
  }

  String _messageForDioException(DioException error, AppErrorCode code) {
    return switch (code) {
      AppErrorCode.clientTimeout => '请求超时，请检查网络后重试',
      AppErrorCode.clientCancelled => '请求已取消',
      AppErrorCode.clientNetworkUnavailable => '网络连接失败，请检查网络或服务器地址',
      AppErrorCode.clientInvalidConfig => '网络证书或客户端配置异常',
      _ => error.message ?? code.defaultMessage,
    };
  }

  String? _readString(Map<String, dynamic> raw, List<String> keys) {
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

  String _requestId() {
    return 'merp-${DateTime.now().microsecondsSinceEpoch}';
  }
}
