// -----------------------------------------------------------------------------
// 文件：app_router.dart
// 作用：集中定义 MERP 路由表、登录守卫、导航日志和未知路由错误页
// 编写时间：2026-07-10
// 维护说明：新增业务页面需使用 AppRoute 常量，禁止在页面散落字符串路径
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../core/logging/app_logger.dart';
import '../core/logging/app_route_observer.dart';
import '../features/all_features/all_features_page.dart';
import '../features/bridge_test/bridge_test_page.dart';
import '../features/home/home_page.dart';
import '../features/legacy/legacy_web_page.dart';
import '../features/login/login_page.dart';
import '../features/map/map_page.dart';
import '../features/profile/profile_page.dart';
import '../features/resources/resource_update_demo_page.dart';
import '../features/settings/gesture_password_page.dart';
import '../features/settings/log_console_page.dart';
import '../features/settings/settings_page.dart';
import '../l10n/l10n.dart';
import '../shared/app_error_view.dart';
import 'app_routes.dart';
import 'forbidden_page.dart';
import 'splash_page.dart';

class AppRouter {
  AppRouter({required AuthController authController, required AppLogger logger})
    : router = GoRouter(
        initialLocation: AppRoute.home,
        refreshListenable: authController,
        observers: [AppRouteObserver(logger)],
        redirect: (context, state) {
          final isLoggingIn = state.uri.path == AppRoute.login;
          final shouldStayOnSplash =
              authController.status == AuthStatus.booting ||
              authController.status == AuthStatus.restoreFailed;

          if (shouldStayOnSplash) {
            return state.uri.path == AppRoute.splash ? null : AppRoute.splash;
          }
          if (!authController.isAuthenticated) {
            return isLoggingIn ? null : AppRoute.login;
          }
          if (isLoggingIn || state.uri.path == AppRoute.splash) {
            return AppRoute.home;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: AppRoute.splash,
            name: 'splash',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: AppRoute.login,
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: AppRoute.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoute.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoute.features,
            name: 'features',
            builder: (context, state) => const AllFeaturesPage(),
          ),
          GoRoute(
            path: AppRoute.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoute.gesture,
            name: 'gesture-password',
            builder: (context, state) => const GesturePasswordPage(),
          ),
          GoRoute(
            path: AppRoute.resourceUpdate,
            name: 'resource-update',
            builder: (context, state) => const ResourceUpdateDemoPage(),
          ),
          GoRoute(
            path: AppRoute.bridgeTest,
            name: 'bridge-test',
            builder: (context, state) => const BridgeTestPage(),
          ),
          GoRoute(
            path: AppRoute.logs,
            name: 'diagnostic-logs',
            builder: (context, state) => const LogConsolePage(),
          ),
          GoRoute(
            path: '/legacy/:moduleId',
            name: 'legacy-web',
            builder: (context, state) =>
                LegacyWebPage(moduleId: state.pathParameters['moduleId'] ?? ''),
          ),
          GoRoute(
            path: AppRoute.map,
            name: 'native-map',
            builder: (context, state) => const MapPage(),
          ),
          GoRoute(
            path: AppRoute.forbidden,
            name: 'forbidden',
            builder: (context, state) => const ForbiddenPage(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.pageNotFound)),
          body: AppErrorView(
            icon: Icons.travel_explore_outlined,
            title: context.l10n.pageNotFound,
            message: context.l10n.pageNotFoundMessage,
            detail: state.error.toString(),
            primaryLabel: context.l10n.returnWorkbench,
            onPrimary: () => context.go(AppRoute.home),
          ),
        ),
      );

  final GoRouter router;

  void dispose() => router.dispose();
}
