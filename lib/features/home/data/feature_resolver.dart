// -----------------------------------------------------------------------------
// 文件：feature_resolver.dart
// 作用：把后端或 Mock 菜单记录安全地转换成客户端功能模型
// -----------------------------------------------------------------------------

import '../domain/feature_item.dart';
import 'feature_registry.dart';

class FeatureResolver {
  const FeatureResolver();

  FeatureItem resolve(Map<String, dynamic> json) {
    final id =
        _readString(json, const ['id', 'code', 'featureCode']) ?? 'unknown';
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
      groupCode: _readString(json, const ['groupCode']) ?? '',
      groupSort: _readInt(json, const ['groupSort']) ?? 0,
      sort: _readInt(json, const ['sort']) ?? 0,
      isDefault: _readBool(json, const ['defaultFlag']) ?? false,
      // 菜单接口的图片地址暂不使用，统一按 featureCode 读取客户端图标映射。
      icon: FeatureRegistry.iconFor(id, null),
      permissionCode:
          _readString(json, const ['permissionCode', 'permission']) ?? id,
      launchMode: isNative
          ? FeatureLaunchMode.native
          : FeatureLaunchMode.legacyWeb,
      route: route,
      legacyPath: _readString(json, const ['legacyPath', 'url', 'target']),
    );
  }
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
  }
  return null;
}

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') return true;
      if (value.toLowerCase() == 'false' || value == '0') return false;
    }
  }
  return null;
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
