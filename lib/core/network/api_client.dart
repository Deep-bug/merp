// -----------------------------------------------------------------------------
// 文件：api_client.dart
// 作用：统一执行 HTTP 请求、注入鉴权、刷新 Token、解析响应并转换错误码
// 编写时间：2026-07-15
// 维护说明：Repository 禁止直接创建 Dio，所有请求必须经过此客户端
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../auth/secure_token_store.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'app_error_code.dart';

typedef SessionExpiredCallback = Future<void> Function();

/// 企业统一 HTTP 客户端。
///
/// 业务仓库层只调用 get/post/put/delete，不直接接触 Dio。请求头、超时、
/// Bearer Token、401 刷新、响应解包和异常映射都在这里保持一致。
class ApiClient {
  ApiClient({
    required this.config,
    required TokenStore tokenStore,
    required AppLogger logger,
    String Function()? localeProvider,
    Dio? dio,
  }) : _tokenStore = tokenStore,
       _logger = logger,
       _localeProvider = localeProvider ?? _defaultLocale,
       _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = config.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 60)
      ..sendTimeout = const Duration(seconds: 60)
      ..responseType = ResponseType.json;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra[_skipAuthKey] == true;
          if (skipAuth) {
            options.headers.remove('Authorization');
          } else {
            final tokens = await _tokenStore.readTokens();
            if (tokens != null && tokens.accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            }
          }
          //取包名
          options.headers['X-Client'] = 'merptest';
          options.headers['Accept-Language'] = _localeProvider();
          options.headers['X-Request-Id'] ??= _requestId();
          options.extra[_startedAtKey] = DateTime.now();

          final sensitive = _isSensitiveAuthRequest(options);

          _logger.debug(
            'http',
            '请求开始',
            fields: {
              'method': options.method,
              'url': options.uri.toString(),
              'query': options.queryParameters,
              'headers': sensitive ? '[redacted]' : options.headers,
              'body': sensitive ? '[redacted]' : options.data,
              'requestId': options.headers['X-Request-Id'],
              'skipAuth': skipAuth,
            },
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          var effectiveError = error;

          if (_shouldRefresh(error)) {
            final refreshedTokens = await refreshTokens();
            if (refreshedTokens != null) {
              try {
                // 原请求只允许重放一次，并保留相同 X-Request-Id，便于后端串联日志。
                final original = error.requestOptions;
                original.extra[_retriedAfterRefreshKey] = true;
                original.headers['Authorization'] =
                    'Bearer ${refreshedTokens.accessToken}';
                final retried = await _dio.fetch<Object?>(original);
                handler.resolve(retried);
                return;
              } on DioException catch (retryError) {
                effectiveError = retryError;
              }
            }
          }

          _logger.warning(
            'http',
            '请求未成功',
            error: _isSensitiveAuthRequest(effectiveError.requestOptions)
                ? null
                : effectiveError.error,
            fields: {
              'method': effectiveError.requestOptions.method,
              'url': effectiveError.requestOptions.uri.toString(),
              'statusCode': effectiveError.response?.statusCode,
              'durationMs': _durationMs(effectiveError.requestOptions),
              'requestId':
                  effectiveError.requestOptions.headers['X-Request-Id'],
              'query': effectiveError.requestOptions.queryParameters,
              'requestBody':
                  _isSensitiveAuthRequest(effectiveError.requestOptions)
                  ? '[redacted]'
                  : effectiveError.requestOptions.data,
              'responseBody':
                  _isSensitiveAuthRequest(effectiveError.requestOptions)
                  ? '[redacted]'
                  : effectiveError.response?.data,
            },
          );
          handler.next(effectiveError);
        },
      ),
    );
  }

  static const _skipAuthKey = 'merp.skipAuth';
  static const _retriedAfterRefreshKey = 'merp.retriedAfterRefresh';
  static const _startedAtKey = 'merp.startedAt';

  /// refresh 与 Web 换码响应都可能包含凭证，诊断日志只保留请求元信息。
  bool _isSensitiveAuthRequest(RequestOptions options) =>
      options.path == config.refreshTokenPath ||
      options.path == config.webCodeExchangePath;

  final AppConfig config;
  final TokenStore _tokenStore;
  final AppLogger _logger;
  final String Function() _localeProvider;
  final Dio _dio;

  Completer<AuthTokens?>? _refreshCompleter;

  String get baseUrl => _dio.options.baseUrl;

  /// 后续新建请求使用新的服务地址；已发送的请求保持原地址继续执行。
  void updateBaseUrl(String value) {
    final baseUrl = value.trim();
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(value, 'value', 'API 地址必须是完整的 http 或 https 地址');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(value, 'value', 'API 地址仅支持 http 或 https');
    }
    if (_dio.options.baseUrl == baseUrl) {
      return;
    }
    _dio.options.baseUrl = baseUrl;
    _logger.info('http', 'API 服务地址已切换', fields: {'baseUrl': baseUrl});
  }

  /// 刷新失败后通知认证控制器清理内存会话并触发路由回到登录页。
  SessionExpiredCallback? onSessionExpired;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipAuth = false,
  }) {
    return _send<T>(
      () => _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        options: _withAuthOption(options, skipAuth: skipAuth),
      ),
      path: path,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipAuth = false,
  }) {
    return _send<T>(
      () => _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuthOption(options, skipAuth: skipAuth),
      ),
      path: path,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipAuth = false,
  }) {
    return _send<T>(
      () => _dio.put<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuthOption(options, skipAuth: skipAuth),
      ),
      path: path,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool skipAuth = false,
  }) {
    return _send<T>(
      () => _dio.delete<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withAuthOption(options, skipAuth: skipAuth),
      ),
      path: path,
    );
  }

  /// 下载由后端签发的升级文件。
  ///
  /// 下载地址可能属于独立文件服务器，因此明确跳过 Bearer Token，避免把登录
  /// 凭证发送到非 API 域名。文件完整性和签名仍由平台安装器做最终校验。
  Future<void> downloadFile({
    required Uri url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      await _dio.download(
        url.toString(),
        savePath,
        deleteOnError: true,
        onReceiveProgress: onProgress,
        options: _withAuthOption(
          Options(responseType: ResponseType.bytes),
          skipAuth: true,
        ),
      );
    } on DioException catch (error) {
      final mapped = _fromDioException(error, url.toString());
      final incidentId = _logRequestError(
        mapped,
        error.stackTrace,
        url.toString(),
      );
      throw incidentId == null ? mapped : mapped.withIncidentId(incidentId);
    }
  }

  /// 主动或被 401 触发刷新 Token。
  ///
  /// `_refreshCompleter` 是单飞锁：并发请求同时收到 401 时，只有第一个请求
  /// 真正调用刷新接口，其余请求等待同一个 Future，防止刷新风暴。
  Future<AuthTokens?> refreshTokens() {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) {
      return activeRefresh.future;
    }

    final completer = Completer<AuthTokens?>();
    _refreshCompleter = completer;
    unawaited(_completeTokenRefresh(completer));
    return completer.future.whenComplete(() {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    });
  }

  /// App 冷启动恢复会话时专用的刷新入口。
  ///
  /// 与业务请求遇到 401 后的自动刷新不同，启动恢复需要区分“refresh_token
  /// 明确失效”和“网络/服务端临时不可用”。前者会清理本地令牌并返回 null，
  /// 后者保留 refresh_token 并抛出异常，便于启动页展示可重试状态。
  Future<AuthTokens?> refreshTokensForRestore() {
    return _performTokenRefresh(throwOnRetainedFailure: true);
  }

  Future<void> _completeTokenRefresh(Completer<AuthTokens?> completer) async {
    AuthTokens? result;
    try {
      result = await _performTokenRefresh();
    } catch (error, stackTrace) {
      // 即使安全存储或状态回调自身异常，也必须释放所有等待中的 401 请求。
      _logger.error(
        'auth',
        '刷新流程发生未处理异常',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  Future<AuthTokens?> _performTokenRefresh({
    bool throwOnRetainedFailure = false,
  }) async {
    try {
      final currentTokens = await _tokenStore.readTokens();
      final refreshToken = currentTokens?.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession('本地不存在 refresh_token');
        return null;
      }

      final response = await _dio.post<Object?>(
        config.refreshTokenPath,
        data: {
          'refresh_token': refreshToken,
          'environment': config.normalizedAuthEnvironment,
        },
        options: _withAuthOption(null, skipAuth: true),
      );
      final data = ApiResponse.unwrap<Map<String, dynamic>>(
        response.data,
        path: config.refreshTokenPath,
      );
      final refreshed = AuthTokens.fromJson(
        data,
        previousRefreshToken: refreshToken,
      );
      await _tokenStore.saveTokens(refreshed);
      _logger.info('auth', '访问令牌刷新成功');
      return refreshed;
    } on DioException catch (error) {
      final mapped = _fromDioException(error, config.refreshTokenPath);
      return _handleRefreshFailure(
        mapped,
        error.stackTrace,
        expireSession: _isRefreshTokenRejected(mapped),
        throwOnRetainedFailure: throwOnRetainedFailure,
      );
    } on ApiException catch (error, stackTrace) {
      return _handleRefreshFailure(
        error,
        stackTrace,
        expireSession: _isRefreshTokenRejected(error),
        throwOnRetainedFailure: throwOnRetainedFailure,
      );
    } catch (error, stackTrace) {
      final exception = ApiException(
        errorCode: AppErrorCode.clientUnknown,
        message: error is FormatException ? error.message : '刷新令牌响应解析失败',
        path: config.refreshTokenPath,
        raw: error,
      );
      return _handleRefreshFailure(
        exception,
        stackTrace,
        expireSession: false,
        throwOnRetainedFailure: throwOnRetainedFailure,
      );
    }
  }

  Future<AuthTokens?> _handleRefreshFailure(
    ApiException error,
    StackTrace? stackTrace, {
    required bool expireSession,
    required bool throwOnRetainedFailure,
  }) async {
    if (expireSession) {
      _logger.warning(
        'auth',
        'refresh_token 已失效，登录态将清理',
        error: error,
        stackTrace: stackTrace,
        fields: {'httpStatusCode': error.httpStatusCode},
      );
      await _expireSession('refresh_token 无效或已过期');
      return null;
    }

    _logger.warning(
      'auth',
      '刷新令牌失败，保留本地 refresh_token 等待重试',
      error: error,
      stackTrace: stackTrace,
      fields: {'httpStatusCode': error.httpStatusCode},
    );
    if (throwOnRetainedFailure) {
      throw error;
    }
    return null;
  }

  bool _isRefreshTokenRejected(ApiException error) {
    return switch (error.httpStatusCode) {
      401 || 403 => true,
      // refresh 请求的 400 属于不可重试的客户端/令牌错误；继续保留同一
      // refresh_token 只会让用户永久停留在启动错误页。
      400 => true,
      _ =>
        error.errorCode == AppErrorCode.serverUnauthorized ||
            error.errorCode == AppErrorCode.serverForbidden,
    };
  }

  Future<void> _expireSession(String reason) async {
    await _tokenStore.clear();
    _logger.info('auth', '已清理本地认证令牌', fields: {'reason': reason});
    await onSessionExpired?.call();
  }

  bool _shouldRefresh(DioException error) {
    final options = error.requestOptions;
    return error.response?.statusCode == 401 &&
        options.extra[_skipAuthKey] != true &&
        options.extra[_retriedAfterRefreshKey] != true;
  }

  Options _withAuthOption(Options? options, {required bool skipAuth}) {
    final base = options ?? Options();
    return base.copyWith(extra: {...?base.extra, _skipAuthKey: skipAuth});
  }

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request, {
    required String path,
  }) async {
    try {
      final response = await request();
      return ApiResponse.unwrap<T>(response.data, path: path);
    } on ApiException catch (error, stackTrace) {
      final incidentId = _logRequestError(error, stackTrace, path);
      throw incidentId == null ? error : error.withIncidentId(incidentId);
    } on DioException catch (error) {
      final mapped = _fromDioException(error, path);
      final incidentId = _logRequestError(mapped, error.stackTrace, path);
      throw incidentId == null ? mapped : mapped.withIncidentId(incidentId);
    } catch (error, stackTrace) {
      final exception = ApiException(
        errorCode: AppErrorCode.clientUnknown,
        message: error is FormatException ? error.message : '客户端处理响应时发生未知错误',
        path: path,
        raw: error,
      );
      final incidentId = _logRequestError(exception, stackTrace, path);
      throw incidentId == null
          ? exception
          : exception.withIncidentId(incidentId);
    }
  }

  ApiException _fromDioException(DioException error, String path) {
    final response = error.response;
    if (response != null) {
      return _fromHttpResponse(response, path);
    }

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
    var code = AppErrorCode.fromHttpStatus(statusCode);

    if (data is Map<String, dynamic>) {
      final serverCode = _readString(data, const [
        'code',
        'errorCode',
        'error_code',
      ]);
      message = _readString(data, const ['message', 'msg', 'errorMessage']);
      traceId = _readString(data, const ['traceId', 'requestId', 'request_id']);
      if (statusCode == null && serverCode != null) {
        code = AppErrorCode.fromCode(serverCode);
      }
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

  String _requestId() => 'merp-${DateTime.now().millisecondsSinceEpoch}';

  static String _defaultLocale() => 'zh-CN';

  int? _durationMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    return startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : null;
  }

  void _logResponse(Response<Object?> response) {
    final sensitive = _isSensitiveAuthRequest(response.requestOptions);
    _logger.info(
      'http',
      '请求完成',
      fields: {
        'method': response.requestOptions.method,
        'url': response.requestOptions.uri.toString(),
        'statusCode': response.statusCode,
        'durationMs': _durationMs(response.requestOptions),
        'requestId': response.requestOptions.headers['X-Request-Id'],
        'responseHeaders': response.headers.map,
        'responseBody': sensitive ? '[redacted]' : response.data,
      },
    );
  }

  String? _logRequestError(
    ApiException error,
    StackTrace stackTrace,
    String path,
  ) {
    final sensitive =
        path == config.refreshTokenPath || path == config.webCodeExchangePath;
    final fields = {
      'path': path,
      'errorCode': error.errorCode.code,
      'httpStatusCode': error.httpStatusCode,
      'traceId': error.traceId,
    };
    if (_isRecoverableNetworkError(error.errorCode)) {
      _logger.warning(
        'http',
        sensitive ? '认证接口请求失败' : error.message,
        error: sensitive ? error.errorCode.code : error.raw ?? error,
        stackTrace: stackTrace,
        fields: fields,
      );
      return null;
    }
    return _logger.error(
      'http',
      sensitive ? '认证接口请求失败' : error.message,
      error: sensitive ? error.errorCode.code : error.raw ?? error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  bool _isRecoverableNetworkError(AppErrorCode code) => switch (code) {
    AppErrorCode.clientTimeout ||
    AppErrorCode.clientNetworkUnavailable ||
    AppErrorCode.clientCancelled => true,
    _ => false,
  };
}
