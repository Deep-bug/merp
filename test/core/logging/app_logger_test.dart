// -----------------------------------------------------------------------------
// 文件：app_logger_test.dart
// 作用：验证日志环形缓冲、故障编号和敏感字段脱敏行为
// 编写时间：2026-07-10
// 维护说明：新增日志输出适配器时必须保留这些安全约束
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';

void main() {
  test('keeps bounded entries and redacts sensitive values', () {
    final logger = AppLogger(maxEntries: 2);

    logger.info('test', 'first');
    logger.info('test', 'second', fields: {'token': 'secret-token'});
    final incidentId = logger.error(
      'test',
      'Bearer secret-token failed',
      fields: {'password': '123456'},
    );

    expect(logger.entries, hasLength(2));
    expect(incidentId, startsWith('MERP-'));
    expect(logger.exportText(), isNot(contains('secret-token')));
    expect(logger.exportText(), isNot(contains('123456')));
    expect(logger.exportText(), contains('<redacted>'));
  });
}
