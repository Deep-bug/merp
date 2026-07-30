import 'package:flutter_test/flutter_test.dart';
import 'package:merp/features/home/data/feature_resolver.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:merp/routing/app_routes.dart';

void main() {
  const resolver = FeatureResolver();

  test('后端展示字段会保留，WebView 内部路由由客户端安全生成', () {
    final item = resolver.resolve({
      'id': 'customer',
      'title': '后端客户中心',
      'description': '后端描述',
      'icon': 'sales',
      'iconUrl': 'https://example.com/customer.png',
      'permissionCode': 'customer.backend.view',
      'launchMode': 'legacyWeb',
      'route': '/native/injected',
      'legacyPath': '/new-customers',
    });

    expect(item.title, '后端客户中心');
    expect(item.permissionCode, 'customer.backend.view');
    expect(item.route, '/legacy/customer');
    expect(item.legacyPath, '/new-customers');
    expect(item.iconUrl, 'https://example.com/customer.png');
  });

  test('原生功能只允许使用客户端注册的可信路由', () {
    final known = resolver.resolve({
      'id': 'map-location',
      'title': '地图',
      'launchMode': 'native',
      'route': '/native/injected',
    });
    final unknown = resolver.resolve({
      'id': 'server-native-module',
      'title': '未知原生模块',
      'launchMode': 'native',
      'route': '/native/injected',
    });

    expect(known.launchMode, FeatureLaunchMode.native);
    expect(known.route, AppRoute.map);
    expect(unknown.route, isEmpty);
  });

  test('非 HTTP 图标地址不会进入图片加载组件', () {
    final item = resolver.resolve({
      'id': 'customer',
      'title': '客户',
      'iconUrl': 'file:///private/icon.png',
    });

    expect(item.iconUrl, isNull);
  });
}
