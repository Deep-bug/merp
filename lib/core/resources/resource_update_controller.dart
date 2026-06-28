import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_resource_manifest.dart';

/// 运行时静态资源控制器。
///
/// Demo 阶段用 SharedPreferences 模拟“手机端已下载并缓存的资源清单”。
/// 真实项目只需要把 applyPreset 替换成 HTTPS 拉取 manifest，再校验版本、
/// hash 和签名后写入本地缓存即可，页面层不用改。
class ResourceUpdateController extends ChangeNotifier {
  ResourceUpdateController({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _manifestKey = 'merp.runtimeResourceManifest';

  SharedPreferences? _preferences;
  RuntimeResourceManifest manifest = RuntimeResourceManifest.defaults();
  String lastSource = '内置默认资源';

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final cached = _preferences?.getString(_manifestKey);
    if (cached == null || cached.isEmpty) {
      manifest = RuntimeResourceManifest.defaults();
      lastSource = '内置默认资源';
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        manifest = RuntimeResourceManifest.fromJson(decoded);
        lastSource = '本地缓存资源';
      }
    } catch (_) {
      manifest = RuntimeResourceManifest.defaults();
      lastSource = '缓存解析失败，已回退默认资源';
    }
    notifyListeners();
  }

  Future<void> applyManifest(
    RuntimeResourceManifest value, {
    required String source,
  }) async {
    _preferences ??= await SharedPreferences.getInstance();
    manifest = value;
    lastSource = source;
    await _preferences?.setString(_manifestKey, jsonEncode(value.toJson()));
    notifyListeners();
  }

  Future<void> applyJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('资源清单必须是 JSON Object');
    }
    await applyManifest(
      RuntimeResourceManifest.fromJson(decoded),
      source: '手动粘贴 JSON',
    );
  }

  Future<void> applyEmeraldDemo() async {
    await applyManifest(
      RuntimeResourceManifest.emeraldDemo(),
      source: '本地模拟绿色资源包',
    );
  }

  Future<void> applyVioletDemo() async {
    await applyManifest(
      RuntimeResourceManifest.violetDemo(),
      source: '本地模拟紫色资源包',
    );
  }

  Future<void> reset() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.remove(_manifestKey);
    manifest = RuntimeResourceManifest.defaults();
    lastSource = '已重置为内置默认资源';
    notifyListeners();
  }
}
