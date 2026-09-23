import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'auth_models.dart';

/// 用户偏好的命名空间，不包含 Token，也不按 China/HK 服务器拆分同域数据。
class UserDataScope {
  const UserDataScope._(this.environment, this.kind, this.identity);

  static UserDataScope? fromProfile(String environment, UserProfile profile) {
    final id = profile.id.trim();
    final account = profile.accountName.trim();
    if (id.isEmpty && account.isEmpty) return null;
    return UserDataScope._(
      environment.trim().toLowerCase(),
      id.isNotEmpty ? 'id' : 'account',
      id.isNotEmpty ? id : account,
    );
  }

  final String environment;
  final String kind;
  final String identity;
  bool get isProvisional => kind == 'account';

  // Hash 仅防止把工号/账号直接写进偏好键名，不代表对偏好数据加密。
  String get storageSuffix => sha256
      .convert(utf8.encode(jsonEncode([environment, kind, identity])))
      .toString();

  @override
  bool operator ==(Object other) =>
      other is UserDataScope &&
      environment == other.environment &&
      kind == other.kind &&
      identity == other.identity;

  @override
  int get hashCode => Object.hash(environment, kind, identity);
}
