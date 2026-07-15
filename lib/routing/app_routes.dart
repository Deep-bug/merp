// -----------------------------------------------------------------------------
// 文件：app_routes.dart
// 作用：定义 Flutter 原生路由的唯一常量来源
// 编写时间：2026-07-10
// 维护说明：后端菜单 route 与页面导航统一引用这些常量
// -----------------------------------------------------------------------------

abstract final class AppRoute {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const features = '/features';
  static const settings = '/settings';
  static const gesture = '/settings/gesture';
  static const resourceUpdate = '/settings/resource-update';
  static const bridgeTest = '/settings/bridge-test';
  static const logs = '/settings/logs';
  static const map = '/native/map';
  static const forbidden = '/forbidden';
}
