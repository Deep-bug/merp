import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('无访问权限')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('返回工作台'),
        ),
      ),
    );
  }
}
