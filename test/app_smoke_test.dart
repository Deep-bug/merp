// -----------------------------------------------------------------------------
// 文件：app_smoke_test.dart
// 作用：验证未登录启动流程与简繁体语言切换的核心界面行为
// 编写时间：2026-07-10
// 维护说明：测试依赖显式装配，禁止访问真实后端和设备安全存储
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/app_dependencies.dart';
import 'package:merp/app/merp_app.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/auth/secure_token_store.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/device/camera_service.dart';
import 'package:merp/core/device/device_info_service.dart';
import 'package:merp/core/device/file_service.dart';
import 'package:merp/core/device/location_service.dart';
import 'package:merp/core/device/map_sdk_service.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/core/resources/resource_update_controller.dart';
import 'package:merp/features/home/data/permission_repository.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login and switches between Simplified and Traditional', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const config = AppConfig();
    final logger = AppLogger();
    final tokenStore = SecureTokenStore();
    final apiClient = ApiClient(
      config: config,
      tokenStore: tokenStore,
      logger: logger,
    );
    final permissions = PermissionRepository(
      apiClient: apiClient,
      logger: logger,
    );
    final settings = SettingsController(
      logger: logger,
      useSecureStorage: false,
    );
    await settings.load();
    final resources = ResourceUpdateController(logger: logger);
    await resources.load();
    final auth = AuthController(
      authRepository: AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
        logger: logger,
      ),
      permissionRepository: permissions,
      logger: logger,
    );
    auth.status = AuthStatus.unauthenticated;

    final dependencies = AppDependencies(
      config: config,
      tokenStore: tokenStore,
      apiClient: apiClient,
      authController: auth,
      permissionRepository: permissions,
      settingsController: settings,
      resourceUpdateController: resources,
      cameraService: CameraService(),
      fileService: FileService(),
      deviceInfoService: DeviceInfoService(),
      locationService: LocationService(config: config, logger: logger),
      mapSdkService: MapSdkService(config: config, logger: logger),
      logger: logger,
    );

    await tester.pumpWidget(MerpApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('MERP'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);

    await settings.setLanguage(AppLanguage.zhHant);
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsOneWidget);
  });
}
