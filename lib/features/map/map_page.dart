// -----------------------------------------------------------------------------
// 文件：map_page.dart
// 作用：展示地图与定位能力的稳定业务入口和厂商 SDK 对接边界
// 编写时间：2026-07-10
// 维护说明：页面不直接引用百度、高德等插件类型，统一通过设备服务适配
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context).config;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.mapLocation)),
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
                          context.l10n.mapPlaceholder,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: context.l10n.currentProvider,
                      value: config.mapProvider,
                    ),
                    _InfoRow(
                      label: 'Android Key',
                      value: config.androidMapApiKey,
                    ),
                    _InfoRow(label: 'iOS Key', value: config.iosMapApiKey),
                    _InfoRow(label: 'Web Key', value: config.webMapApiKey),
                    const SizedBox(height: 12),
                    Text(context.l10n.mapIntegrationHint),
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
