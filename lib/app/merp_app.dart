// -----------------------------------------------------------------------------
// 文件：merp_app.dart
// 作用：装配主题、路由、国际化和全局安全守卫等应用级 UI 能力
// 编写时间：2026-07-10
// 维护说明：业务页面不得直接堆入此文件，应按 features 模块独立维护
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../features/app_update/app_update_gate.dart';
import '../routing/app_router.dart';
import 'app_dependencies.dart';
import 'app_scope.dart';
import 'security/auto_lock_guard.dart';
import 'theme/app_theme.dart';

class MerpApp extends StatefulWidget {
  const MerpApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MerpApp> createState() => _MerpAppState();
}

class _MerpAppState extends State<MerpApp> {
  late final AppRouter _appRouter = AppRouter(
    authController: widget.dependencies.authController,
    logger: widget.dependencies.logger,
  );

  @override
  void dispose() {
    _appRouter.dispose();
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;

    return AppScope(
      config: dependencies.config,
      apiClient: dependencies.apiClient,
      authController: dependencies.authController,
      permissionRepository: dependencies.permissionRepository,
      favoriteFeatureController: dependencies.favoriteFeatureController,
      featureBadgeController: dependencies.featureBadgeController,
      appUpdateController: dependencies.appUpdateController,
      webDataCleaner: dependencies.webDataCleaner,
      settingsController: dependencies.settingsController,
      cameraService: dependencies.cameraService,
      fileService: dependencies.fileService,
      deviceInfoService: dependencies.deviceInfoService,
      locationService: dependencies.locationService,
      mapSdkService: dependencies.mapSdkService,
      logger: dependencies.logger,
      child: AnimatedBuilder(
        animation: dependencies.settingsController,
        builder: (context, _) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light(),
            locale: dependencies.settingsController.language.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _appRouter.router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AutoLockGuard(
                authController: dependencies.authController,
                securityController: dependencies.localSecurityController,
                child: AppUpdateGate(
                  controller: dependencies.appUpdateController,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
