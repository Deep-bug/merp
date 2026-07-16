// -----------------------------------------------------------------------------
// 文件：resource_update_demo_page.dart
// 作用：演示运行时静态资源清单更新、缓存、预览和回滚
// 编写时间：2026-07-10
// 维护说明：生产接入必须增加 HTTPS、签名、哈希校验和灰度策略
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/resources/resource_update_controller.dart';
import '../../core/resources/runtime_resource_manifest.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';

class ResourceUpdateDemoPage extends StatefulWidget {
  const ResourceUpdateDemoPage({super.key});

  @override
  State<ResourceUpdateDemoPage> createState() => _ResourceUpdateDemoPageState();
}

class _ResourceUpdateDemoPageState extends State<ResourceUpdateDemoPage> {
  late final TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(
      text: RuntimeResourceManifest.violetDemo().toPrettyJson(),
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task, String successMessage) async {
    try {
      await task();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.resourceUpdateFailed('$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).resourceUpdateController;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final manifest = controller.manifest;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => AppNavigator.backTo(context, AppRoute.settings),
              icon: const Icon(Icons.chevron_left),
            ),
            title: Text(context.l10n.resourceUpdate),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResourcePreview(manifest: manifest),
              const SizedBox(height: 16),
              _InfoTile(
                label: context.l10n.resourceVersion,
                value: manifest.version,
              ),
              _InfoTile(
                label: context.l10n.resourceSource,
                value: _resourceSourceLabel(context, controller.source),
              ),
              _InfoTile(
                label: context.l10n.resourceUpdatedAt,
                value: manifest.updatedAt.millisecondsSinceEpoch == 0
                    ? context.l10n.builtInResource
                    : manifest.updatedAt.toLocal().toString(),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _run(
                      controller.applyEmeraldDemo,
                      context.l10n.emeraldApplied,
                    ),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(context.l10n.applyEmerald),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _run(
                      controller.applyVioletDemo,
                      context.l10n.violetApplied,
                    ),
                    icon: const Icon(Icons.palette_outlined),
                    label: Text(context.l10n.applyViolet),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _run(controller.reset, context.l10n.resourceReset),
                    icon: const Icon(Icons.restore),
                    label: Text(context.l10n.resetResource),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.manualResourceJson,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _jsonController,
                maxLines: 12,
                minLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  helperText: context.l10n.resourceJsonHint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _run(
                        () => controller.applyJson(_jsonController.text),
                        context.l10n.jsonApplied,
                      ),
                      icon: const Icon(Icons.playlist_add_check),
                      label: Text(context.l10n.applyJson),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AppNavigator.goHome(context),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(context.l10n.viewHome),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _resourceSourceLabel(BuildContext context, ResourceSource source) {
  return switch (source) {
    ResourceSource.builtIn => context.l10n.sourceBuiltIn,
    ResourceSource.cache => context.l10n.sourceCache,
    ResourceSource.cacheFallback => context.l10n.sourceCacheFallback,
    ResourceSource.manualJson => context.l10n.sourceManualJson,
    ResourceSource.emeraldDemo => context.l10n.sourceEmerald,
    ResourceSource.violetDemo => context.l10n.sourceViolet,
    ResourceSource.reset => context.l10n.sourceReset,
  };
}

class _ResourcePreview extends StatelessWidget {
  const _ResourcePreview({required this.manifest});

  final RuntimeResourceManifest manifest;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
        color: manifest.bannerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: manifest.bannerDarkColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manifest.bannerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  manifest.bannerSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 28,
            top: 36,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.apps_rounded,
                color: manifest.iconColor,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
