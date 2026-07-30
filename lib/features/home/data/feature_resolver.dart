// -----------------------------------------------------------------------------
// 文件：feature_resolver.dart
// 作用：把后端或 Mock 菜单记录安全地转换成客户端功能模型
// -----------------------------------------------------------------------------

import '../domain/feature_item.dart';
import 'feature_registry.dart';

class FeatureResolver {
  const FeatureResolver();

  FeatureItem resolve(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'code']) ?? 'unknown';
    final requestedMode = _readString(json, const ['launchMode']);
    final isNative = requestedMode == 'native';

    // 原生页面只能使用客户端注册过的 route，拒绝后端注入 route 字符串。
    final nativeRoute = isNative ? FeatureRegistry.nativeRouteFor(id) : null;
    final route = isNative
        ? nativeRoute ?? ''
        : '/legacy/${Uri.encodeComponent(id)}';

    return FeatureItem(
      id: id,
      title: _readString(json, const ['title', 'name']) ?? id,
      description: _readString(json, const ['description']) ?? '',
      group:
          _readString(json, const ['group', 'category', 'moduleGroup']) ?? '',
      icon: FeatureRegistry.iconFor(
        id,
        _readString(json, const ['icon', 'iconName']),
      ),
      iconUrl: _readHttpUrl(json, const ['iconUrl', 'iconURL']),
      permissionCode:
          _readString(json, const ['permissionCode', 'permission']) ?? id,
      launchMode: isNative
          ? FeatureLaunchMode.native
          : FeatureLaunchMode.legacyWeb,
      route: route,
      legacyPath: _readString(json, const ['legacyPath', 'url']),
    );
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String? _readHttpUrl(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return null;
  return uri.scheme == 'http' || uri.scheme == 'https' ? value : null;
}
