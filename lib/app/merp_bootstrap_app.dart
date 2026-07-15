// -----------------------------------------------------------------------------
// 文件：merp_bootstrap_app.dart
// 作用：在品牌启动页中异步装配依赖，并提供可识别的启动失败界面
// 编写时间：2026-07-10
// 维护说明：耗时初始化放入 AppDependencies，禁止阻塞 main.dart 首帧
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../core/logging/app_logger.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';
import '../routing/splash_page.dart';
import '../shared/app_error_view.dart';
import 'app_dependencies.dart';
import 'merp_app.dart';
import 'theme/app_theme.dart';

/// 应用启动容器。
///
/// 以前 `main()` 会等待 `AppDependencies.bootstrap()` 完成后才 `runApp()`，
/// 如果本地存储、权限接口或资源初始化稍慢，Android 原生窗口就会先露出白屏。
/// 这里改成先渲染 MERP 品牌启动页，再异步创建依赖，能明显缩短“空白首屏”时间。
class MerpBootstrapApp extends StatefulWidget {
  const MerpBootstrapApp({super.key, required this.logger});

  final AppLogger logger;

  @override
  State<MerpBootstrapApp> createState() => _MerpBootstrapAppState();
}

class _MerpBootstrapAppState extends State<MerpBootstrapApp> {
  late final Future<AppDependencies> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<AppDependencies> _bootstrap() async {
    try {
      return await AppDependencies.bootstrap(logger: widget.logger);
    } catch (error, stackTrace) {
      widget.logger.fatal(
        'bootstrap',
        '应用依赖初始化失败',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MerpApp(dependencies: snapshot.requireData);
        }

        if (snapshot.hasError) {
          return MaterialApp(
            title: 'MERP',
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) => Scaffold(
                body: SafeArea(
                  child: AppErrorView(
                    icon: Icons.error_outline,
                    title: context.l10n.startupFailed,
                    message: context.l10n.startupFailedMessage,
                    detail: snapshot.error.toString(),
                  ),
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'MERP',
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: const SplashPage(isBootstrapping: true),
        );
      },
    );
  }
}
