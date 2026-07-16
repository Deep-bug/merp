// -----------------------------------------------------------------------------
// 文件：main.dart
// 作用：MERP 进程入口，安装全局异常捕获并尽快渲染首帧
// 编写时间：2026-07-10
// 维护说明：此文件只负责进程启动，业务初始化统一放入 AppDependencies
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

import 'app/merp_bootstrap_app.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/global_error_handler.dart';

void main() {
  final logger = AppLogger();

  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.install(logger);
      logger.info('lifecycle', 'MERP 进程启动');

      // 先输出 Flutter 首帧，再在品牌启动页中并行初始化依赖，缩短冷启动空白期。
      runApp(MerpBootstrapApp(logger: logger));
    },
    (error, stackTrace) =>
        GlobalErrorHandler.handleZoneError(logger, error, stackTrace),
  );
}
