import 'dart:async';

import '../core/auth/auth_controller.dart';
import '../core/auth/user_data_scope.dart';
import '../features/home/data/favorite_feature_controller.dart';
import '../features/home/data/feature_badge_controller.dart';

/// 跨功能的登录生命周期编排放在 app 层，登录域不反向依赖收藏/角标模块。
class UserSessionDataCoordinator {
  UserSessionDataCoordinator({
    required AuthController auth,
    required FavoriteFeatureController favorites,
    required FeatureBadgeController badges,
    required String environment,
    bool mock = false,
  }) : _auth = auth,
       _favorites = favorites,
       _badges = badges,
       _environment = environment,
       _mock = mock {
    _auth.addListener(_synchronize);
    _synchronize();
  }

  final AuthController _auth;
  final FavoriteFeatureController _favorites;
  final FeatureBadgeController _badges;
  final String _environment;
  final bool _mock;
  UserDataScope? _scope;
  int? _sessionGeneration;
  bool _active = false;
  Future<void> _settled = Future<void>.value();

  Future<void> get settled => _settled;

  void _synchronize() {
    final session = _auth.session;
    final active =
        session != null &&
        (_auth.isAuthenticated ||
            _auth.status == AuthStatus.authenticatedPendingSecurity);
    final generation = _auth.sessionGeneration;
    final newSession = _sessionGeneration != generation || _active != active;
    _sessionGeneration = generation;
    _active = active;
    if (newSession) {
      _scope = null;
      _favorites.clearActiveScope();
      _badges.clear();
    }
    if (!active) return;
    if (_mock) {
      if (newSession) {
        _favorites.enableDevelopmentMockMode();
        _badges.enableDevelopmentMockCounts();
      }
      return;
    }
    final next = UserDataScope.fromProfile(_environment, session.profile);
    if (next == _scope && (next == null || _favorites.isReady)) return;
    final previous = _scope;
    _scope = next;
    if (next == null) {
      _favorites.clearActiveScope();
      _badges.clear();
      return;
    }
    // 登录响应可能只有账号，后台资料随后补齐 userId。只有同一轮已验证的
    // 登录、且账号一致时才迁移临时域，绝不跨账号认领旧收藏。
    final canMigrate =
        !newSession &&
        previous?.isProvisional == true &&
        !next.isProvisional &&
        previous!.identity == session.profile.accountName.trim();
    if (previous != null && previous != next && !canMigrate) _badges.clear();
    _settled = _favorites.activateScope(
      next,
      migrateFrom: canMigrate ? previous : null,
    );
    unawaited(_settled);
  }

  void dispose() => _auth.removeListener(_synchronize);
}
