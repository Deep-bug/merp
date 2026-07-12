// -----------------------------------------------------------------------------
// 文件：runtime_resource_manifest.dart
// 作用：定义可在不更新 Dart 代码时变更的受控静态资源模型
// 编写时间：2026-07-10
// 维护说明：只允许视觉资源和文案配置，禁止承载可执行逻辑
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';

/// 运行时资源清单。
///
/// Flutter 官方支持开发期 hot reload，但生产环境不能热更新 Dart 代码。
/// 对首页背景、图标颜色、文案、远程图片 URL 这类“静态资源”，推荐用后端下发
/// manifest，再缓存在本地；页面只读取 manifest 渲染，就能做到无需发版更新资源。
class RuntimeResourceManifest {
  const RuntimeResourceManifest({
    required this.version,
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.bannerColor,
    required this.bannerDarkColor,
    required this.brandColor,
    required this.iconColor,
    required this.updatedAt,
  });

  final String version;
  final String bannerTitle;
  final String bannerSubtitle;
  final Color bannerColor;
  final Color bannerDarkColor;
  final Color brandColor;
  final Color iconColor;
  final DateTime updatedAt;

  static RuntimeResourceManifest defaults() {
    return RuntimeResourceManifest(
      version: 'local-default',
      bannerTitle: 'MERP 移动工作台',
      bannerSubtitle: '旧系统与 Flutter 原生能力并行升级',
      bannerColor: const Color(0xFF4DA9D7),
      bannerDarkColor: const Color(0xFF439BC7),
      brandColor: const Color(0xFF5E93E5),
      iconColor: const Color(0xFF16A3DE),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static RuntimeResourceManifest emeraldDemo() {
    return RuntimeResourceManifest(
      version: 'local-emerald-demo',
      bannerTitle: 'MERP 资源热更新',
      bannerSubtitle: '本地模拟后端下发绿色资源包',
      bannerColor: const Color(0xFF1AAE8F),
      bannerDarkColor: const Color(0xFF0F8F77),
      brandColor: const Color(0xFF168C73),
      iconColor: const Color(0xFF00A884),
      updatedAt: DateTime.now(),
    );
  }

  static RuntimeResourceManifest violetDemo() {
    return RuntimeResourceManifest(
      version: 'local-violet-demo',
      bannerTitle: 'MERP 主题资源包',
      bannerSubtitle: '本地模拟节日/活动资源变更',
      bannerColor: const Color(0xFF6A72E8),
      bannerDarkColor: const Color(0xFF5159C8),
      brandColor: const Color(0xFF5961D6),
      iconColor: const Color(0xFF6670F0),
      updatedAt: DateTime.now(),
    );
  }

  factory RuntimeResourceManifest.fromJson(Map<String, dynamic> json) {
    final fallback = RuntimeResourceManifest.defaults();
    return RuntimeResourceManifest(
      version: json['version']?.toString() ?? fallback.version,
      bannerTitle: json['bannerTitle']?.toString() ?? fallback.bannerTitle,
      bannerSubtitle:
          json['bannerSubtitle']?.toString() ?? fallback.bannerSubtitle,
      bannerColor: _colorFromHex(json['bannerColor'], fallback.bannerColor),
      bannerDarkColor: _colorFromHex(
        json['bannerDarkColor'],
        fallback.bannerDarkColor,
      ),
      brandColor: _colorFromHex(json['brandColor'], fallback.brandColor),
      iconColor: _colorFromHex(json['iconColor'], fallback.iconColor),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'bannerTitle': bannerTitle,
      'bannerSubtitle': bannerSubtitle,
      'bannerColor': _colorToHex(bannerColor),
      'bannerDarkColor': _colorToHex(bannerDarkColor),
      'brandColor': _colorToHex(brandColor),
      'iconColor': _colorToHex(iconColor),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  static Color _colorFromHex(Object? raw, Color fallback) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return fallback;
    }
    final normalized = value.replaceFirst('#', '').replaceFirst('0x', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }
}
