// -----------------------------------------------------------------------------
// 文件：app_privacy_shield.dart
// 作用：应用离开前台时覆盖敏感内容，避免暴露在系统任务缩略图中
// 维护说明：此页只做隐私遮挡，不承载手势、人脸或指纹验证逻辑
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// 静态且完全不透明的后台隐私遮罩。
///
/// 不使用动画，是为了确保系统立即生成后台快照时，遮罩已经完整覆盖内容。
class AppPrivacyShield extends StatelessWidget {
  const AppPrivacyShield({super.key});

  static const overlayKey = ValueKey<String>('app-privacy-shield');

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: Material(
        key: overlayKey,
        color: const Color(0xFFF4F8FD),
        child: const SafeArea(
          child: Center(
            child: ExcludeSemantics(
              child: Image(
                image: AssetImage('assets/branding/splash_logo.png'),
                width: 92,
                height: 92,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
