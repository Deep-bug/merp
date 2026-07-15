// -----------------------------------------------------------------------------
// 文件：app_logger.dart
// 作用：提供轻量、结构化、可脱敏且可在应用内查看的统一日志能力
// 编写时间：2026-07-10
// 维护说明：业务代码只记录必要上下文，严禁写入密码、Token、图片 Base64
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 日志级别按严重程度递增，便于终端和后续日志平台筛选。
enum AppLogLevel { debug, info, warning, error, fatal }

/// 单条结构化日志。
class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    required this.fields,
    this.incidentId,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String category;
  final String message;
  final Map<String, Object?> fields;
  final String? incidentId;
  final Object? error;
  final StackTrace? stackTrace;

  /// 输出为一行便于复制给研发或接入 ELK、Sentry 等平台。
  String toText() {
    final buffer = StringBuffer()
      ..write(timestamp.toIso8601String())
      ..write(' [${level.name.toUpperCase()}]')
      ..write(' [$category] ')
      ..write(message);
    if (incidentId != null) {
      buffer.write(' incidentId=$incidentId');
    }
    if (fields.isNotEmpty) {
      buffer.write(' fields=${jsonEncode(fields)}');
    }
    if (error != null) {
      buffer.write(' error=$error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// MERP 统一日志门面。
///
/// 当前版本同时写入 Flutter/Android 调试终端与内存环形缓冲区。缓冲区固定为
/// 200 条，能够在中低端设备上控制内存占用；未来接入远程日志平台时，只需在
/// [_emit] 增加上报适配器，业务模块无需修改。
class AppLogger extends ChangeNotifier {
  AppLogger({this.maxEntries = 200}) : assert(maxEntries > 0);

  final int maxEntries;
  final List<AppLogEntry> _entries = <AppLogEntry>[];
  var _incidentSequence = 0;

  List<AppLogEntry> get entries => List<AppLogEntry>.unmodifiable(_entries);

  void debug(
    String category,
    String message, {
    Map<String, Object?> fields = const {},
  }) {
    _record(AppLogLevel.debug, category, message, fields: fields);
  }

  void info(
    String category,
    String message, {
    Map<String, Object?> fields = const {},
  }) {
    _record(AppLogLevel.info, category, message, fields: fields);
  }

  void warning(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    _record(
      AppLogLevel.warning,
      category,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  /// 记录错误并返回可展示给用户或客服的故障编号。
  String error(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    return _record(
      AppLogLevel.error,
      category,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
      createIncident: true,
    )!;
  }

  /// 记录会影响应用继续运行的致命异常，并返回故障编号。
  String fatal(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    return _record(
      AppLogLevel.fatal,
      category,
      message,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
      createIncident: true,
    )!;
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportText() => _entries.map((entry) => entry.toText()).join('\n\n');

  String? _record(
    AppLogLevel level,
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
    bool createIncident = false,
  }) {
    final now = DateTime.now();
    final incidentId = createIncident ? _nextIncidentId(now) : null;
    final entry = AppLogEntry(
      timestamp: now,
      level: level,
      category: category,
      message: _truncate(_redactText(message), 2000),
      fields: _sanitizeFields(fields),
      incidentId: incidentId,
      error: error == null
          ? null
          : _truncate(_redactText(error.toString()), 4000),
      stackTrace: stackTrace == null
          ? null
          : StackTrace.fromString(_truncate(stackTrace.toString(), 8000)),
    );

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    _emit(entry);
    notifyListeners();
    return incidentId;
  }

  void _emit(AppLogEntry entry) {
    developer.log(
      entry.message,
      name: 'MERP.${entry.category}',
      level: _developerLevel(entry.level),
      error: entry.error,
      stackTrace: entry.stackTrace,
      time: entry.timestamp,
      sequenceNumber: _incidentSequence,
    );
  }

  int _developerLevel(AppLogLevel level) => switch (level) {
    AppLogLevel.debug => 500,
    AppLogLevel.info => 800,
    AppLogLevel.warning => 900,
    AppLogLevel.error => 1000,
    AppLogLevel.fatal => 1200,
  };

  String _nextIncidentId(DateTime now) {
    _incidentSequence = (_incidentSequence + 1) % 10000;
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'MERP-$date-$time-${_incidentSequence.toString().padLeft(4, '0')}';
  }

  Map<String, Object?> _sanitizeFields(Map<String, Object?> fields) {
    return fields.map((key, value) {
      if (_sensitiveKey.hasMatch(key)) {
        return MapEntry(key, '<redacted>');
      }
      return MapEntry(key, _sanitizeValue(value));
    });
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is Iterable<Object?>) {
      return value.take(20).map(_sanitizeValue).toList(growable: false);
    }
    if (value is Map<Object?, Object?>) {
      return value.map((key, item) {
        final textKey = key.toString();
        return MapEntry(
          textKey,
          _sensitiveKey.hasMatch(textKey) ? '<redacted>' : _sanitizeValue(item),
        );
      });
    }
    return _truncate(_redactText(value.toString()), 2000);
  }

  String _redactText(String value) {
    return value
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+'),
          'Bearer <redacted>',
        )
        .replaceAll(
          RegExp(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]+'),
          '<image-data>',
        );
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}\n<truncated>';
  }

  static final RegExp _sensitiveKey = RegExp(
    r'(authorization|token|password|secret|base64|cookie)',
    caseSensitive: false,
  );
}
