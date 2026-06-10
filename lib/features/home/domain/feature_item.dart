import 'package:flutter/material.dart';

enum FeatureLaunchMode { native, legacyWeb }

class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.permissionCode,
    required this.launchMode,
    required this.route,
    this.legacyPath,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String permissionCode;
  final FeatureLaunchMode launchMode;
  final String route;
  final String? legacyPath;
}
