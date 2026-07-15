// -----------------------------------------------------------------------------
// 文件：memory_token_store.dart
// 作用：为认证与网络单元测试提供不依赖平台插件的内存 Token 存储
// 编写时间：2026-07-15
// 维护说明：仅测试使用，不得在生产依赖装配中替换安全存储
// -----------------------------------------------------------------------------

import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/auth/secure_token_store.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.tokens]);

  AuthTokens? tokens;
  var clearCount = 0;

  @override
  Future<AuthTokens?> readTokens() async => tokens;

  @override
  Future<void> saveTokens(AuthTokens value) async {
    tokens = value;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    tokens = null;
  }
}
