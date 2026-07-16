// -----------------------------------------------------------------------------
// 文件：forbidden_page.dart
// 作用：统一承接功能权限拒绝场景并提供安全返回入口
// 编写时间：2026-07-10
// 维护说明：权限拦截必须发生在打开原生页或 WebView 之前
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import 'app_routes.dart';

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.noPermission)),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => context.go(AppRoute.home),
          icon: const Icon(Icons.arrow_back),
          label: Text(context.l10n.returnWorkbench),
        ),
      ),
    );
  }
}
