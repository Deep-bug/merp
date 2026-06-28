import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/resources/runtime_resource_manifest.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('资源更新失败：$error')));
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
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.chevron_left),
            ),
            title: const Text('静态资源热更新演示'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResourcePreview(manifest: manifest),
              const SizedBox(height: 16),
              _InfoTile(label: '当前资源版本', value: manifest.version),
              _InfoTile(label: '资源来源', value: controller.lastSource),
              _InfoTile(
                label: '更新时间',
                value: manifest.updatedAt.millisecondsSinceEpoch == 0
                    ? '内置资源'
                    : manifest.updatedAt.toLocal().toString(),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        _run(controller.applyEmeraldDemo, '已应用绿色资源包，返回首页查看变化'),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('应用绿色资源包'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _run(controller.applyVioletDemo, '已应用紫色资源包，返回首页查看变化'),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('应用紫色资源包'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _run(controller.reset, '已恢复内置默认资源'),
                    icon: const Icon(Icons.restore),
                    label: const Text('重置资源'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '手动资源清单 JSON',
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  helperText: '修改颜色值后点击“应用 JSON”，即可模拟后端下发资源清单。',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _run(
                        () => controller.applyJson(_jsonController.text),
                        '已应用 JSON 资源清单，返回首页查看变化',
                      ),
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('应用 JSON'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('查看首页'),
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
