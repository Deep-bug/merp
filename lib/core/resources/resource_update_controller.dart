// -----------------------------------------------------------------------------
// 文件：resource_update_controller.dart
// 作用：加载、验证、缓存、应用和回滚运行时静态资源清单
// 编写时间：2026-07-10
// 维护说明：生产下载实现应替换演示预设，但保持控制器对页面的接口稳定
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'runtime_resource_manifest.dart';

/// 资源来源使用枚举表达，避免 Controller 保存某一种语言的展示文案。
enum ResourceSource {
  builtIn,
  cache,
  cacheFallback,
  manualJson,
  emeraldDemo,
  violetDemo,
  reset,
}

/// 运行时静态资源控制器。
///
/// Demo 阶段用 SharedPreferences 模拟“手机端已下载并缓存的资源清单”。
/// 真实项目只需要把 applyPreset 替换成 HTTPS 拉取 manifest，再校验版本、
/// hash 和签名后写入本地缓存即可，页面层不用改。
class ResourceUpdateController extends ChangeNotifier {
  ResourceUpdateController({
    required AppLogger logger,
    SharedPreferences? preferences,
  }) : _logger = logger,
       _preferences = preferences;

  static const _manifestKey = 'merp.runtimeResourceManifest';

  SharedPreferences? _preferences;
  final AppLogger _logger;
  RuntimeResourceManifest manifest = RuntimeResourceManifest.defaults();
  ResourceSource source = ResourceSource.builtIn;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final cached = _preferences?.getString(_manifestKey);
    if (cached == null || cached.isEmpty) {
      manifest = RuntimeResourceManifest.defaults();
      source = ResourceSource.builtIn;
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        manifest = RuntimeResourceManifest.fromJson(decoded);
        source = ResourceSource.cache;
      }
    } catch (error, stackTrace) {
      manifest = RuntimeResourceManifest.defaults();
      source = ResourceSource.cacheFallback;
      _logger.warning(
        'resource',
        '运行时资源缓存解析失败，已回退默认资源',
        error: error,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> applyManifest(
    RuntimeResourceManifest value, {
    required ResourceSource source,
  }) async {
    _preferences ??= await SharedPreferences.getInstance();
    manifest = value;
    this.source = source;
    await _preferences?.setString(_manifestKey, jsonEncode(value.toJson()));
    _logger.info(
      'resource',
      '运行时资源清单已应用',
      fields: {'version': value.version, 'source': source.name},
    );
    notifyListeners();
  }

  Future<void> applyJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('资源清单必须是 JSON Object');
    }
    await applyManifest(
      RuntimeResourceManifest.fromJson(decoded),
      source: ResourceSource.manualJson,
    );
  }

  Future<void> applyEmeraldDemo() async {
    await applyManifest(
      RuntimeResourceManifest.emeraldDemo(),
      source: ResourceSource.emeraldDemo,
    );
  }

  Future<void> applyVioletDemo() async {
    await applyManifest(
      RuntimeResourceManifest.violetDemo(),
      source: ResourceSource.violetDemo,
    );
  }

  Future<void> reset() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.remove(_manifestKey);
    manifest = RuntimeResourceManifest.defaults();
    source = ResourceSource.reset;
    _logger.info('resource', '运行时资源已重置');
    notifyListeners();
  }
}
