import 'package:flutter/material.dart';

import 'app/merp_app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/secure_token_store.dart';
import 'core/config/app_config.dart';
import 'core/device/camera_service.dart';
import 'core/device/location_service.dart';
import 'core/device/map_sdk_service.dart';
import 'core/network/api_client.dart';
import 'features/home/data/permission_repository.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig();
  final tokenStore = SecureTokenStore();
  final apiClient = ApiClient(config: config, tokenStore: tokenStore);

  // 当前阶段只保留地图 SDK 对接入口，不加载具体原生插件。
  await MapSdkService(config: config).initialize();

  final permissionRepository = PermissionRepository(apiClient: apiClient);
  final settingsController = SettingsController();
  await settingsController.load();

  final authController = AuthController(
    authRepository: AuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    ),
    permissionRepository: permissionRepository,
  );

  // 先恢复本地 token，成功后再请求菜单权限，避免首页闪到登录页。
  await authController.restoreSession();

  runApp(
    MerpApp(
      config: config,
      authController: authController,
      permissionRepository: permissionRepository,
      settingsController: settingsController,
      cameraService: CameraService(),
      locationService: LocationService(config: config),
    ),
  );
}
