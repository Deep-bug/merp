// -----------------------------------------------------------------------------
// 文件：auth_models_test.dart
// 作用：验证认证令牌和用户资料严格映射后端字段及兼容账号别名
// 编写时间：2026-07-15
// 维护说明：接口字段调整时先更新此契约测试，再修改生产模型
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_models.dart';

void main() {
  test('parses captcha id and data-uri image as one challenge', () {
    final challenge = CaptchaChallenge.fromJson({
      'captchaId': 'captcha-001',
      'imagebase64': 'data:image/png;base64,AQIDBA==',
    });

    expect(challenge.captchaId, 'captcha-001');
    expect(challenge.imageBytes, [1, 2, 3, 4]);
  });

  test('rejects incomplete captcha response', () {
    expect(
      () => CaptchaChallenge.fromJson({'imagebase64': 'AQIDBA=='}),
      throwsFormatException,
    );
    expect(
      () => CaptchaChallenge.fromJson({
        'captchaId': 'captcha-001',
        'imagebase64': 'not-base64',
      }),
      throwsFormatException,
    );
  });

  test('parses login tokens and keeps previous refresh token', () {
    final loginTokens = AuthTokens.fromJson({
      'access_token': 'access-1',
      'refresh_token': 'refresh-1',
    });
    final refreshed = AuthTokens.fromJson({
      'access_token': 'access-2',
    }, previousRefreshToken: loginTokens.refreshToken);

    expect(refreshed.accessToken, 'access-2');
    expect(refreshed.refreshToken, 'refresh-1');
  });

  test('parses complete userInfo response', () {
    final profile = UserProfile.fromJson({
      'id': 'U10001',
      'accountName': 'admin',
      'displayName': '管理员',
      'department': '信息技术部',
      'email': 'admin@company.com',
      'phone': '13800138000',
      'avatarUrl': 'https://cdn.company.com/avatar/admin.png',
    });

    expect(profile.id, 'U10001');
    expect(profile.accountName, 'admin');
    expect(profile.displayName, '管理员');
    expect(profile.department, '信息技术部');
    expect(profile.email, 'admin@company.com');
    expect(profile.phone, '13800138000');
  });

  test('accepts username alias and login fallback', () {
    final profile = UserProfile.fromLoginResponse({
      'username': 'operator',
    }, fallbackAccountName: 'fallback');

    expect(profile.accountName, 'operator');
    expect(profile.displayName, 'operator');
  });
}
