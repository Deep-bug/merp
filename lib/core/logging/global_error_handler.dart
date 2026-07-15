// -----------------------------------------------------------------------------
// 文件：global_error_handler.dart
// 作用：统一捕获 Flutter 框架、平台线程和页面渲染异常并生成故障编号
// 编写时间：2026-07-10
// 维护说明：新增错误采集平台时在此适配，避免各页面重复 try/catch 上报
// -----------------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_logger.dart';

/// 安装应用级异常捕获钩子。
class GlobalErrorHandler {
  const GlobalErrorHandler._();

  static void install(AppLogger logger) {
    final previousFlutterHandler = FlutterError.onError;

    FlutterError.onError = (details) {
      logger.error(
        'flutter',
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
        fields: {'library': details.library ?? 'unknown'},
      );
      previousFlutterHandler?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      logger.fatal(
        'platform',
        '未处理的平台异步异常',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    };

    // 构建树发生异常时显示稳定的企业错误界面，避免用户只看到红屏或空白页。
    ErrorWidget.builder = (details) {
      final incidentId = logger.error(
        'render',
        '页面渲染失败',
        error: details.exception,
        stackTrace: details.stack,
      );
      return _RenderErrorFallback(
        incidentId: incidentId,
        detail: kDebugMode ? details.exceptionAsString() : null,
      );
    };
  }

  static void handleZoneError(
    AppLogger logger,
    Object error,
    StackTrace stackTrace,
  ) {
    logger.fatal(
      'zone',
      '未处理的 Dart 异步异常',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class _RenderErrorFallback extends StatelessWidget {
  const _RenderErrorFallback({required this.incidentId, this.detail});

  final String incidentId;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF4F2),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFB3261E),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  '页面渲染异常 / Page render error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '故障编号 / Incident: $incidentId',
                  textAlign: TextAlign.center,
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  SelectableText(detail!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
