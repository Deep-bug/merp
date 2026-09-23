import 'dart:convert';
import 'dart:math';

/// 单个网页文档的 Bridge 生命周期，不持有 BuildContext 或插件。
///
/// 顶层注入脚本的闭包持有随机 nonce；没有 nonce 的原始 channel 消息会被
/// 忽略。它是纵深防护，不替代服务端 CSP、XSS 防护或原生 frame-origin 校验。
class BridgeDocumentSession {
  final _random = Random.secure();
  final Map<String, String> _pending = {};
  String? _nonce;
  int _revision = 0;
  bool _disposed = false;

  int get revision => _revision;
  String? get nonce => _nonce;

  void invalidate() {
    _revision++;
    _nonce = null;
    _pending.clear();
  }

  String? activate(int expectedRevision) {
    if (_disposed || expectedRevision != _revision) return null;
    return _nonce ??= base64UrlEncode(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
  }

  bool accepts(String id, Object? nonce) {
    if (_disposed ||
        _nonce == null ||
        nonce != _nonce ||
        id.isEmpty ||
        id.length > 128 ||
        _pending.containsKey(id) ||
        _pending.length >= 64) {
      return false;
    }
    _pending[id] = _nonce!;
    return true;
  }

  bool canReply(String id, String? nonce) =>
      !_disposed && _nonce != null && nonce == _nonce && _pending[id] == nonce;

  void complete(String id, String? nonce) {
    if (_pending[id] == nonce) _pending.remove(id);
  }

  void dispose() {
    _disposed = true;
    invalidate();
  }
}
