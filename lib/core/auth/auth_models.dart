// -----------------------------------------------------------------------------
// 文件：auth_models.dart
// 作用：定义认证令牌、用户资料和登录会话的领域数据结构
// 编写时间：2026-07-15
// 维护说明：后端认证字段变更统一在此映射，页面不得直接解析接口 JSON
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';

/// 一次验证码挑战；图片与 captchaId 必须始终成对更新和提交。
class CaptchaChallenge {
  const CaptchaChallenge({required this.captchaId, required this.imageBytes});

  final String captchaId;
  final Uint8List imageBytes;

  factory CaptchaChallenge.fromJson(Map<String, dynamic> json) {
    final captchaId = _readString(json, const ['captchaId']);
    if (captchaId == null) {
      throw const FormatException('验证码响应缺少 captchaId');
    }

    final rawImage = _readString(json, const ['imagebase64']);
    if (rawImage == null) {
      throw const FormatException('验证码响应缺少 imagebase64');
    }

    final commaIndex = rawImage.indexOf(',');
    final encoded = commaIndex >= 0
        ? rawImage.substring(commaIndex + 1)
        : rawImage;
    try {
      return CaptchaChallenge(
        captchaId: captchaId,
        imageBytes: base64Decode(encoded.replaceAll(RegExp(r'\s'), '')),
      );
    } on FormatException {
      throw const FormatException('验证码图片不是有效的 Base64');
    }
  }
}

/// 后端登录与刷新接口返回的令牌对。
class AuthTokens {
  const AuthTokens({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  factory AuthTokens.fromJson(
    Map<String, dynamic> json, {
    String? previousRefreshToken,
  }) {
    final accessToken = _readString(json, const ['access_token']);
    if (accessToken == null) {
      throw const FormatException('认证响应缺少 access_token');
    }

    return AuthTokens(
      accessToken: accessToken,
      // 刷新接口允许不返回新 refresh_token，此时继续使用旧令牌。
      refreshToken:
          _readString(json, const ['refresh_token']) ?? previousRefreshToken,
    );
  }
}

/// `/api/v1/user/userInfo` 返回的用户资料。
class UserProfile {
  const UserProfile({
    required this.id,
    required this.accountName,
    required this.displayName,
    required this.department,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String accountName;
  final String displayName;
  final String department;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    String fallbackAccountName = '',
    String fallbackDisplayName = '',
  }) {
    final accountName =
        _readString(json, const ['accountName', 'userName', 'username']) ??
        fallbackAccountName;
    final displayName =
        _readString(json, const ['displayName']) ??
        accountName.ifEmpty(fallbackDisplayName);

    return UserProfile(
      id: _readString(json, const ['id']) ?? '',
      accountName: accountName,
      displayName: displayName.ifEmpty(accountName),
      department: _readString(json, const ['department']) ?? '',
      email: _readString(json, const ['email']),
      phone: _readString(json, const ['phone']),
      avatarUrl: _readString(json, const ['avatarUrl']),
    );
  }

  /// 用户资料接口暂时失败时，登录仍可使用登录响应中的账号信息。
  factory UserProfile.fromLoginResponse(
    Map<String, dynamic> json, {
    required String fallbackAccountName,
  }) {
    return UserProfile.fromJson(
      json,
      fallbackAccountName: fallbackAccountName,
      fallbackDisplayName: fallbackAccountName,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'accountName': accountName,
      'displayName': displayName,
      'department': department,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Flutter 运行期会话，只在内存中组合令牌与用户资料。
class AuthSession {
  const AuthSession({required this.tokens, required this.profile});

  final AuthTokens tokens;
  final UserProfile profile;

  String get accessToken => tokens.accessToken;
  String get userName => profile.displayName;

  AuthSession copyWith({AuthTokens? tokens, UserProfile? profile}) {
    return AuthSession(
      tokens: tokens ?? this.tokens,
      profile: profile ?? this.profile,
    );
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
