// -----------------------------------------------------------------------------
// 文件：home_assistant_button.dart
// 作用：展示首页 AI 助手悬浮入口的独立视觉组件
// 编写时间：2026-07-10
// 维护说明：接入 AI 功能后通过回调触发路由，不在组件内耦合业务服务
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class HomeAssistantButton extends StatelessWidget {
  const HomeAssistantButton({super.key, required this.iconColor, this.onTap});

  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(Icons.smart_toy_outlined, color: iconColor),
      ),
    );
  }
}
