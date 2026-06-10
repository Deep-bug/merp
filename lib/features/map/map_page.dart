import 'package:flutter/material.dart';

import '../../app/app_scope.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context).config;

    return Scaffold(
      appBar: AppBar(title: const Text('地图定位')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '地图 SDK 接口占位',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: '当前厂商', value: config.mapProvider),
                    _InfoRow(
                      label: 'Android Key',
                      value: config.androidMapApiKey,
                    ),
                    _InfoRow(label: 'iOS Key', value: config.iosMapApiKey),
                    _InfoRow(label: 'Web Key', value: config.webMapApiKey),
                    const SizedBox(height: 12),
                    const Text(
                      '后续接入地图时，实现 core/device/map_sdk_service.dart 和 core/device/location_service.dart 即可，业务页面和路由不用跟着第三方插件改。',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
