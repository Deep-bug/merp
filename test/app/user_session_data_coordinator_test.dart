import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/user_session_data_coordinator.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/auth/session_data_lifecycle.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/favorite_feature_controller.dart';
import 'package:merp/features/home/data/feature_badge_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/memory_token_store.dart';

void main() {
  test(
    'fallback migration never overwrites existing stable-user favorites',
    () async {
      final fixture = _Fixture();
      fixture.auth.publish(_profile('a', account: 'account-a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('stable');
      await fixture.auth.logout();
      fixture.auth.publish(_profile('', account: 'account-a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('provisional');
      fixture.auth.publish(_profile('a', account: 'account-a'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, ['stable']);
    },
  );

  test(
    'A logout clears memory; B and then A recover only their own favorites',
    () async {
      final fixture = _Fixture();
      fixture.auth.publish(_profile('a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('e-form');
      final generation = fixture.badges.generation;
      fixture.badges.replaceCounts({'e-form': 6}, generation: generation);

      final logout = fixture.auth.logout();
      expect(fixture.favorites.ids, isEmpty);
      expect(fixture.badges.countFor('e-form'), 0);
      await logout;
      fixture.auth.publish(_profile('b'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, isEmpty);
      fixture.badges.replaceCounts({'e-form': 99}, generation: generation);
      expect(fixture.badges.countFor('e-form'), 0);
      await fixture.favorites.toggle('my-task');

      await fixture.auth.logout();
      fixture.auth.publish(_profile('a'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, ['e-form']);
    },
  );

  test('token/profile updates preserve current favorites and badges', () async {
    final fixture = _Fixture();
    fixture.auth.publish(_profile('a'));
    await fixture.coordinator.settled;
    await fixture.favorites.toggle('e-form');
    fixture.badges.replaceCounts({
      'e-form': 6,
    }, generation: fixture.badges.generation);
    fixture.auth.publish(_profile('a'), accessToken: 'refreshed');
    await fixture.coordinator.settled;
    expect(fixture.favorites.ids, ['e-form']);
    expect(fixture.badges.countFor('e-form'), 6);
  });

  test(
    'same login can migrate an account fallback when user id arrives',
    () async {
      final fixture = _Fixture();
      fixture.auth.publish(_profile('', account: 'account-a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('e-form');
      fixture.auth.publish(_profile('a', account: 'account-a'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, ['e-form']);

      await fixture.auth.logout();
      fixture.auth.publish(_profile('a', account: 'account-a'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, ['e-form']);
    },
  );

  test(
    'fallback favorites cannot migrate across a logout or different account',
    () async {
      final fixture = _Fixture();
      fixture.auth.publish(_profile('', account: 'account-a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('private-a');
      await fixture.auth.logout();
      fixture.auth.publish(_profile('b', account: 'account-b'));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, isEmpty);
    },
  );

  test(
    'unknown restored identity exposes no previously saved favorites',
    () async {
      final fixture = _Fixture();
      fixture.auth.publish(_profile('a'));
      await fixture.coordinator.settled;
      await fixture.favorites.toggle('private-a');
      await fixture.auth.logout();
      fixture.auth.publish(_profile('', account: ''));
      await fixture.coordinator.settled;
      expect(fixture.favorites.ids, isEmpty);
      expect(fixture.favorites.isReady, isFalse);
    },
  );

  test('mock data stays in memory and is cleared on sign out', () async {
    final fixture = _Fixture(mock: true);
    fixture.auth.publish(_profile('mock'));
    await fixture.favorites.toggle('e-form');
    expect(fixture.badges.countFor('e-form'), 6);
    await fixture.auth.logout();
    expect(fixture.favorites.ids, isEmpty);
    expect(fixture.badges.countFor('e-form'), 0);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}

UserProfile _profile(String id, {String? account}) => UserProfile(
  id: id,
  accountName: account ?? id,
  displayName: 'Test',
  department: '',
);

class _Fixture {
  _Fixture({bool mock = false}) {
    SharedPreferences.setMockInitialValues({});
    final logger = AppLogger();
    final api = ApiClient(
      config: const AppConfig(),
      tokenStore: MemoryTokenStore(),
      logger: logger,
    );
    auth = _AuthHarness(
      authRepository: AuthRepository(apiClient: api, logger: logger),
      permissionRepository: _NoopSessionData(),
      logger: logger,
    );
    favorites = FavoriteFeatureController(logger: logger);
    badges = FeatureBadgeController(logger: logger);
    coordinator = UserSessionDataCoordinator(
      auth: auth,
      favorites: favorites,
      badges: badges,
      environment: 'qas',
      mock: mock,
    );
    addTearDown(() {
      coordinator.dispose();
      auth.dispose();
      favorites.dispose();
      badges.dispose();
      api.sessionTokens.dispose();
    });
  }
  late final _AuthHarness auth;
  late final FavoriteFeatureController favorites;
  late final FeatureBadgeController badges;
  late final UserSessionDataCoordinator coordinator;
}

class _AuthHarness extends AuthController {
  _AuthHarness({
    required super.authRepository,
    required super.permissionRepository,
    required super.logger,
  });
  void publish(UserProfile profile, {String accessToken = 'test-token'}) {
    session = AuthSession(
      tokens: AuthTokens(accessToken: accessToken),
      profile: profile,
    );
    status = AuthStatus.authenticated;
    notifyListeners();
  }
}

class _NoopSessionData implements SessionDataLifecycle {
  @override
  Future<void> clear() async {}
  @override
  Future<void> loadDevelopmentMockMenu() async {}
  @override
  Future<void> loadForSession(AuthSession session) async {}
}
