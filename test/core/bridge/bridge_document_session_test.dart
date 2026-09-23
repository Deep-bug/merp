import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/bridge/bridge_document_session.dart';

void main() {
  test('only a valid document nonce can start a request', () {
    final session = BridgeDocumentSession();
    expect(session.accepts('1', null), isFalse);
    final nonce = session.activate(session.revision)!;
    expect(nonce.length, greaterThanOrEqualTo(40));
    expect(session.accepts('1', 'forged'), isFalse);
    expect(session.accepts('1', nonce), isTrue);
    expect(session.accepts('1', nonce), isFalse);
    expect(session.canReply('1', nonce), isTrue);
    session.complete('1', nonce);
    expect(session.canReply('1', nonce), isFalse);
  });

  test('navigation revokes pending callbacks and delayed injection', () {
    final session = BridgeDocumentSession();
    final revision = session.revision;
    final old = session.activate(revision)!;
    session.accepts('id', old);
    session.invalidate();
    expect(session.activate(revision), isNull);
    expect(session.canReply('id', old), isFalse);
    final next = session.activate(session.revision)!;
    expect(next, isNot(old));
    expect(session.accepts('id', old), isFalse);
    expect(session.accepts('id', next), isTrue);
    // 即使新页面碰巧复用了请求 id，旧任务也不能回复或清除它。
    session.complete('id', old);
    expect(session.canReply('id', next), isTrue);
    expect(session.canReply('id', old), isFalse);
  });

  test('disposal permanently prevents injection and calls', () {
    final session = BridgeDocumentSession();
    final nonce = session.activate(session.revision)!;
    session.accepts('1', nonce);
    session.dispose();
    expect(session.activate(session.revision), isNull);
    expect(session.accepts('2', nonce), isFalse);
    expect(session.canReply('1', nonce), isFalse);
  });

  test('limits pending requests without losing accepted requests', () {
    final session = BridgeDocumentSession();
    final nonce = session.activate(session.revision)!;
    for (var i = 0; i < 64; i++) {
      expect(session.accepts('$i', nonce), isTrue);
    }
    expect(session.accepts('overflow', nonce), isFalse);
    expect(session.canReply('0', nonce), isTrue);
    session.complete('0', nonce);
    expect(session.accepts('next', nonce), isTrue);
  });
}
