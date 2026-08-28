// -----------------------------------------------------------------------------
// 文件：app_update_gate.dart
// 作用：在登录、手势锁和业务页面之前拦截强制升级
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../routing/splash_page.dart';
import 'app_update_controller.dart';
import 'app_update_page.dart';

class AppUpdateGate extends StatelessWidget {
  const AppUpdateGate({
    super.key,
    required this.controller,
    required this.child,
  });

  final AppUpdateController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.blocksApplication &&
            controller.status == AppUpdateStatus.checking) {
          return const SplashPage(isBootstrapping: true);
        }
        if (controller.isForceUpdateActive) {
          return AppUpdatePage(controller: controller);
        }
        return child;
      },
    );
  }
}
