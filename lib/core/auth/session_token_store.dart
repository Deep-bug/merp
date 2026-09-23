import 'package:flutter/foundation.dart';

import 'auth_models.dart';
import 'secure_token_store.dart';

/// 运行期唯一的令牌入口：串行持久化，并拒绝上一轮会话的异步结果。
///
/// generation 只在登录/退出等身份边界变化，刷新 Token 不改变身份。
/// 安全存储仍由底层 TokenStore 负责，本类不增加任何明文持久化。
class SessionTokenStore extends ChangeNotifier implements TokenStore {
  SessionTokenStore(this._storage);

  final TokenStore _storage;
  Future<void> _pending = Future<void>.value();
  AuthTokens? _tokens;
  bool _loaded = false;
  int _generation = 0;

  int get generation => _generation;
  AuthTokens? get currentTokens => _tokens;
  bool isCurrent(int generation) => generation == _generation;

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    // 一个存储操作失败不能阻塞后续清理/重试；错误仍交给原调用方。
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<AuthTokens?> readTokens() {
    final generation = _generation;
    return _serial(() async {
      if (!isCurrent(generation)) return null;
      if (!_loaded) {
        final stored = await _storage.readTokens();
        if (!isCurrent(generation)) return null;
        _tokens = stored;
        _loaded = true;
      }
      return _tokens;
    });
  }

  /// 请求发送前捕获 generation，响应回来后必须携带它写入。
  Future<bool> saveIfCurrent(AuthTokens tokens, int generation) {
    return _serial(() async {
      if (!isCurrent(generation)) return false;
      await _storage.saveTokens(tokens);
      if (!isCurrent(generation)) return false;
      _tokens = tokens;
      _loaded = true;
      notifyListeners();
      return true;
    });
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    await saveIfCurrent(tokens, _generation);
  }

  @override
  Future<void> clear() async {
    await _invalidate(retrievePrevious: false);
  }

  /// 原子撤销，并把旧凭证仅交给后端登出请求；从未加载过时在队列中读取。
  Future<AuthTokens?> revoke() => _invalidate(retrievePrevious: true);

  Future<AuthTokens?> _invalidate({required bool retrievePrevious}) {
    final previous = _tokens;
    final wasLoaded = _loaded;
    // 必须在第一个 await 前撤销身份。已在执行的写盘随后由串行清理覆盖，
    // 尚未开始写盘的旧请求则直接被 generation 拦截。
    _generation += 1;
    _tokens = null;
    _loaded = true;
    notifyListeners();
    return _serial(() async {
      try {
        if (!retrievePrevious) return null;
        return wasLoaded ? previous : await _storage.readTokens();
      } finally {
        // 读取旧凭证失败也必须尝试删除；普通 clear 完全不依赖读盘成功。
        await _storage.clear();
      }
    });
  }
}
