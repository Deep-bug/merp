import 'package:flutter/material.dart';
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

  test('后端图片地址会被忽略并使用客户端 Material Icons 映射', () {
    final item = resolver.resolve({
      'featureCode': 'wechat-eform',
      'name': '电子表单',
      'icon': 'img/funicon/wechat-eform.png',
      'iconUrl': 'https://example.com/wechat-eform.png',
      'target': 'merp/bpm/index.html',
      'sort': 8,
      'defaultFlag': true,
    });

    expect(item.id, 'wechat-eform');
    expect(item.legacyPath, 'merp/bpm/index.html');
    expect(item.sort, 8);
    expect(item.isDefault, isTrue);
    expect(item.icon, Icons.account_tree_outlined);
  });
}
