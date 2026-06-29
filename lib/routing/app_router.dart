import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../features/all_features/all_features_page.dart';
import '../features/bridge_test/bridge_test_page.dart';
import '../features/home/home_page.dart';
import '../features/legacy/legacy_web_page.dart';
import '../features/login/login_page.dart';
import '../features/map/map_page.dart';
import '../features/profile/profile_page.dart';
import '../features/resources/resource_update_demo_page.dart';
import '../features/settings/gesture_password_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/app_error_view.dart';
import 'forbidden_page.dart';
import 'splash_page.dart';

class AppRouter {
  AppRouter({required AuthController authController})
    : router = GoRouter(
        initialLocation: '/home',
        refreshListenable: authController,
        redirect: (context, state) {
          final isLoggingIn = state.uri.path == '/login';
          final isBooting = authController.status == AuthStatus.booting;

          if (isBooting) {
            return state.uri.path == '/splash' ? null : '/splash';
          }
          if (!authController.isAuthenticated) {
            return isLoggingIn ? null : '/login';
          }
          if (isLoggingIn || state.uri.path == '/splash') {
            return '/home';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/features',
            builder: (context, state) => const AllFeaturesPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/gesture',
            builder: (context, state) => const GesturePasswordPage(),
          ),
          GoRoute(
            path: '/settings/resource-update',
            builder: (context, state) => const ResourceUpdateDemoPage(),
          ),
          GoRoute(
            path: '/settings/bridge-test',
            builder: (context, state) => const BridgeTestPage(),
          ),
          GoRoute(
            path: '/legacy/:moduleId',
            builder: (context, state) =>
                LegacyWebPage(moduleId: state.pathParameters['moduleId'] ?? ''),
          ),
          GoRoute(
            path: '/native/map',
            builder: (context, state) => const MapPage(),
          ),
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => const ForbiddenPage(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('页面不存在')),
          body: AppErrorView(
            icon: Icons.travel_explore_outlined,
            title: '页面不存在',
            message: '当前路由没有对应页面，请检查后端菜单 route 配置。',
            detail: state.error.toString(),
            primaryLabel: '返回工作台',
            onPrimary: () => context.go('/home'),
          ),
        ),
      );

  final GoRouter router;
}
