import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';

/// 只处理指定 key 的凭证，不持有「当前用户」，避免异步任务写入其他账号。
/// 保留旧版 v2 JSON 与 PBKDF2-HMAC-SHA256（120000 次）的字节格式。
class GestureCredentialStore {
  GestureCredentialStore({
    required AppLogger logger,
    FlutterSecureStorage? secureStorage,
    bool useSecureStorage = true,
  }) : _logger = logger,
       _storage = secureStorage ?? const FlutterSecureStorage(),
       _useSecureStorage = useSecureStorage;

  static const _iterations = 120000;
  final AppLogger _logger;
  final FlutterSecureStorage _storage;
  final bool _useSecureStorage;
  final Map<String, String> _memoryValues = {};
  Future<void> _pendingStorage = Future<void>.value();

  Future<bool> contains(String key) async => await _read(key) != null;

  /// 哈希在 isolate 中计算；提交前再次确认调用方的账号/操作仍有效。
  /// 已交给原生存储的写入无法撤销，因此读写删除排队，保证后续删除最后落盘。
  Future<bool> save(
    String key,
    List<int> pattern, {
    required bool Function() canCommit,
  }) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final digest = await compute(
      _derivePatternHash,
      _PatternHashRequest(List<int>.of(pattern), salt, _iterations),
    );
    final record = jsonEncode({
      'version': 2,
      'iterations': _iterations,
      'salt': base64UrlEncode(salt),
      'hash': base64UrlEncode(digest),
    });
    return _enqueue(() async {
      if (!canCommit()) return false;
      if (_useSecureStorage) {
        await _storage.write(key: key, value: record);
      } else {
        _memoryValues[key] = record;
      }
      return true;
    });
  }

  Future<bool> verify(String key, List<int> pattern) async {
    final snapshot = List<int>.of(pattern);
    final saved = await _read(key);
    if (saved == null || saved.isEmpty) return false;
    try {
      final record = jsonDecode(saved) as Map<String, dynamic>;
      if (record['version'] != 2) return false;
      final salt = base64Url.decode(record['salt'] as String);
      final expected = base64Url.decode(record['hash'] as String);
      final iterations = record['iterations'] as int;
      // 损坏的数据不能触发无界计算，也不能通过空摘要放行。
      if (salt.length != 16 ||
          expected.length != 32 ||
          iterations < 1 ||
          iterations > 1000000) {
        return false;
      }
      final actual = await compute(
        _derivePatternHash,
        _PatternHashRequest(snapshot, salt, iterations),
      );
      return _constantTimeEquals(expected, actual);
    } catch (_) {
      // 不记录原始记录或解析异常，避免日志包含凭证材料。
      _logger.warning('security.gesture', '手势密码记录格式无效');
      return false;
    }
  }

  Future<void> delete(String key) => _enqueue(() async {
    if (_useSecureStorage) {
      await _storage.delete(key: key);
    } else {
      _memoryValues.remove(key);
    }
  });

  Future<String?> _read(String key) => _enqueue(() async {
    if (!_useSecureStorage) return _memoryValues[key];
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      _logger.warning(
        'security.gesture',
        '读取手势密码失败',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pendingStorage.then((_) => operation());
    // 本次错误仍交给调用者，但不能使后续存储操作永久失败。
    _pendingStorage = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}

class _PatternHashRequest {
  const _PatternHashRequest(this.pattern, this.salt, this.iterations);

  final List<int> pattern;
  final Uint8List salt;
  final int iterations;
}

Uint8List _derivePatternHash(_PatternHashRequest request) {
  final password = utf8.encode('merp:${request.pattern.join('-')}');
  final hmac = Hmac(sha256, password);
  final block = Uint8List(request.salt.length + 4)
    ..setAll(0, request.salt)
    ..setAll(request.salt.length, const [0, 0, 0, 1]);
  var value = Uint8List.fromList(hmac.convert(block).bytes);
  final result = Uint8List.fromList(value);
  for (var i = 1; i < request.iterations; i++) {
    value = Uint8List.fromList(hmac.convert(value).bytes);
    for (var j = 0; j < result.length; j++) {
      result[j] ^= value[j];
    }
  }
  return result;
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }
  return difference == 0;
}
