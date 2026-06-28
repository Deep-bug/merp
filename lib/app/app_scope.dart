import 'package:flutter/widgets.dart';

import '../core/auth/auth_controller.dart';
import '../core/config/app_config.dart';
import '../core/device/camera_service.dart';
import '../core/device/location_service.dart';
import '../core/resources/resource_update_controller.dart';
import '../features/home/data/permission_repository.dart';
import '../features/settings/settings_controller.dart';

/// 应用级依赖容器。
///
/// 项目初期用 InheritedWidget 足够轻量；如果后续模块和状态显著增加，
/// 可以平滑替换成 Riverpod、Bloc 或 GetIt，而不用改业务页面构造方式。
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.authController,
    required this.permissionRepository,
    required this.settingsController,
    required this.resourceUpdateController,
    required this.cameraService,
    required this.locationService,
    required super.child,
  });

  final AppConfig config;
  final AuthController authController;
  final PermissionRepository permissionRepository;
  final SettingsController settingsController;
  final ResourceUpdateController resourceUpdateController;
  final CameraService cameraService;
  final LocationService locationService;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 未挂载');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return config != oldWidget.config ||
        authController != oldWidget.authController ||
        permissionRepository != oldWidget.permissionRepository ||
        settingsController != oldWidget.settingsController ||
        resourceUpdateController != oldWidget.resourceUpdateController ||
        cameraService != oldWidget.cameraService ||
        locationService != oldWidget.locationService;
  }
}
