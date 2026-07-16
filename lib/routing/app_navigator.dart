// -----------------------------------------------------------------------------
// 文件：app_navigator.dart
// 作用：统一 MERP 页面跳转语义，避免功能页误用 go 破坏返回栈
// 编写时间：2026-07-16
// 维护说明：登录态切换和回首页使用 go，功能/二级页面入口使用 push
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

abstract final class AppNavigator {
  static Future<T?> openFeature<T>(BuildContext context, String route) {
    return context.push<T>(route);
  }

  static Future<T?> openSecondary<T>(BuildContext context, String route) {
    return context.push<T>(route);
  }

  static void backToHome(BuildContext context) {
    backTo(context, AppRoute.home);
  }

  static void backTo(BuildContext context, String fallbackRoute) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  static void goHome(BuildContext context) {
    context.go(AppRoute.home);
  }
}
