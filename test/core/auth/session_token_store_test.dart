import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_models.dart';
import 'package:merp/core/auth/session_token_store.dart';

import '../../helpers/memory_token_store.dart';

void main() {
  const old = AuthTokens(accessToken: 'old', refreshToken: 'old-refresh');
  const fresh = AuthTokens(accessToken: 'new', refreshToken: 'new-refresh');

  test('clear does not depend on reading damaged credentials', () async {
    final storage = _UnreadableStore();
    final session = SessionTokenStore(storage);
    await session.clear();
    expect(storage.clearCount, 1);
    expect(await session.readTokens(), isNull);
  });

  test('revoke still deletes credentials if reading them fails', () async {
    final storage = _UnreadableStore();
    final session = SessionTokenStore(storage);
    await expectLater(session.revoke(), throwsStateError);
    expect(storage.clearCount, 1);
    expect(session.currentTokens, isNull);
  });

  test('late refresh cannot restore a cleared session', () async {
    final storage = MemoryTokenStore(old);
    final session = SessionTokenStore(storage);
    await session.readTokens();
    final generation = session.generation;
    final clearing = session.clear();
    expect(session.currentTokens, isNull);
    expect(session.isCurrent(generation), isFalse);
    expect(await session.saveIfCurrent(fresh, generation), isFalse);
    await clearing;
    expect(await session.readTokens(), isNull);
    expect(storage.tokens, isNull);
  });

  test(
    'clear follows an in-flight disk write and suppresses notification',
    () async {
      final storage = _DelayedStore(old);
      final session = SessionTokenStore(storage);
      await session.readTokens();
      var notifications = 0;
      session.addListener(() => notifications++);
      final saving = session.saveIfCurrent(fresh, session.generation);
      await storage.started.future;
      final clearing = session.clear();
      storage.release.complete();
      expect(await saving, isFalse);
      await clearing;
      expect(storage.tokens, isNull);
      expect(session.currentTokens, isNull);
      expect(notifications, 1); // 只通知撤销，不能再通知旧 Token 写入。
    },
  );

  test('new account survives writes queued by the old account', () async {
    final storage = MemoryTokenStore(old);
    final session = SessionTokenStore(storage);
    final oldGeneration = session.generation;
    await session.clear();
    await session.saveIfCurrent(fresh, session.generation);
    expect(await session.saveIfCurrent(old, oldGeneration), isFalse);
    expect((await session.readTokens())?.accessToken, 'new');
    expect(storage.tokens?.accessToken, 'new');
  });
}

class _DelayedStore extends MemoryTokenStore {
  _DelayedStore(super.tokens);
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> saveTokens(AuthTokens value) async {
    started.complete();
    await release.future;
    await super.saveTokens(value);
  }
}

class _UnreadableStore extends MemoryTokenStore {
  @override
  Future<AuthTokens?> readTokens() async => throw StateError('unreadable');
}
