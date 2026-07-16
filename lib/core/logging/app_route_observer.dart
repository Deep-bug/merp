// -----------------------------------------------------------------------------
// 文件：app_route_observer.dart
// 作用：记录页面进入、替换和退出事件，便于还原用户报错前的导航路径
// 编写时间：2026-07-10
// 维护说明：仅记录路由名称，不记录页面参数中的敏感业务数据
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';

import 'app_logger.dart';

class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver(this._logger);

  final AppLogger _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _log('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logger.info(
      'route',
      'replace',
      fields: {'from': _routeName(oldRoute), 'to': _routeName(newRoute)},
    );
  }

  void _log(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _logger.info(
      'route',
      action,
      fields: {
        'route': _routeName(route),
        'previous': _routeName(previousRoute),
      },
    );
  }

  String _routeName(Route<dynamic>? route) {
    return route?.settings.name ?? route?.runtimeType.toString() ?? '<none>';
  }
}
