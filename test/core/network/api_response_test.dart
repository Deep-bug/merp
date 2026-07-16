// -----------------------------------------------------------------------------
// 文件：api_response_test.dart
// 作用：验证统一响应的一层、两层 data 解包和业务失败转换
// 编写时间：2026-07-15
// 维护说明：所有 Repository 共用此响应契约，禁止在业务层重复解包
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/network/api_exception.dart';
import 'package:merp/core/network/api_response.dart';
import 'package:merp/core/network/app_error_code.dart';

void main() {
  test('unwraps one data layer', () {
    final result = ApiResponse.unwrap<Map<String, dynamic>>({
      'code': 0,
      'message': 'success',
      'data': {'id': 'U10001'},
    }, path: '/one-layer');

    expect(result['id'], 'U10001');
  });

  test('unwraps two data layers', () {
    final result = ApiResponse.unwrap<Map<String, dynamic>>({
      'code': 0,
      'message': 'success',
      'data': {
        'data': {'access_token': 'token'},
      },
    }, path: '/two-layers');

    expect(result['access_token'], 'token');
  });

  test('converts non-zero response code to ApiException', () {
    expect(
      () => ApiResponse.unwrap<Object?>({
        'code': 50001,
        'message': '业务处理失败',
        'data': null,
      }, path: '/failed'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.errorCode,
              'errorCode',
              AppErrorCode.serverError,
            )
            .having((error) => error.message, 'message', '业务处理失败'),
      ),
    );
  });
}
