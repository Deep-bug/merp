// -----------------------------------------------------------------------------
// 文件：app_scope.dart
// 作用：向 Widget 树提供有明确生命周期的应用级依赖
// 编写时间：2026-07-10
// 维护说明：业务页面通过 AppScope 读取服务，避免隐式全局单例
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';

import '../core/auth/auth_controller.dart';
import '../core/config/app_config.dart';
import '../core/device/camera_service.dart';
import '../core/device/device_info_service.dart';
import '../core/device/file_service.dart';
import '../core/device/location_service.dart';
import '../core/device/map_sdk_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/api_client.dart';
import '../features/home/data/permission_repository.dart';
import '../features/home/data/favorite_feature_controller.dart';
import '../features/settings/settings_controller.dart';

/// 应用级依赖容器。
///
/// 项目初期用 InheritedWidget 足够轻量；如果后续模块和状态显著增加，
/// 可以平滑替换成 Riverpod、Bloc 或 GetIt，而不用改业务页面构造方式。
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.apiClient,
    required this.authController,
    required this.permissionRepository,
    required this.favoriteFeatureController,
    required this.settingsController,
    required this.cameraService,
    required this.fileService,
    required this.deviceInfoService,
    required this.locationService,
    required this.mapSdkService,
    required this.logger,
    required super.child,
  });

  final AppConfig config;
  final ApiClient apiClient;
  final AuthController authController;
  final PermissionRepository permissionRepository;
  final FavoriteFeatureController favoriteFeatureController;
  final SettingsController settingsController;
  final CameraService cameraService;
  final FileService fileService;
  final DeviceInfoService deviceInfoService;
  final LocationService locationService;
  final MapSdkService mapSdkService;
  final AppLogger logger;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 未挂载');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return config != oldWidget.config ||
        apiClient != oldWidget.apiClient ||
        authController != oldWidget.authController ||
        permissionRepository != oldWidget.permissionRepository ||
        favoriteFeatureController != oldWidget.favoriteFeatureController ||
        settingsController != oldWidget.settingsController ||
        cameraService != oldWidget.cameraService ||
        fileService != oldWidget.fileService ||
        deviceInfoService != oldWidget.deviceInfoService ||
        locationService != oldWidget.locationService ||
        mapSdkService != oldWidget.mapSdkService ||
        logger != oldWidget.logger;
  }
}
