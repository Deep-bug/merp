import '../core/auth/auth_controller.dart';
import '../core/auth/auth_repository.dart';
import '../core/auth/secure_token_store.dart';
import '../core/config/app_config.dart';
import '../core/device/camera_service.dart';
import '../core/device/location_service.dart';
import '../core/device/map_sdk_service.dart';
import '../core/network/api_client.dart';
import '../core/resources/resource_update_controller.dart';
import '../features/home/data/permission_repository.dart';
import '../features/settings/settings_controller.dart';

/// 应用级依赖容器。
///
/// 当前项目处在“Flutter 外壳 + 旧 Vue2 迁移”的阶段，依赖数量还不多，
/// 用一个显式容器比过早引入复杂 DI 框架更清晰。后续如果模块数量明显增加，
/// 可以把这里平滑迁移成 Riverpod Provider 或 GetIt 注册表。
class AppDependencies {
  const AppDependencies({
    required this.config,
    required this.tokenStore,
    required this.apiClient,
    required this.authController,
    required this.permissionRepository,
    required this.settingsController,
    required this.resourceUpdateController,
    required this.cameraService,
    required this.locationService,
  });

  final AppConfig config;
  final SecureTokenStore tokenStore;
  final ApiClient apiClient;
  final AuthController authController;
  final PermissionRepository permissionRepository;
  final SettingsController settingsController;
  final ResourceUpdateController resourceUpdateController;
  final CameraService cameraService;
  final LocationService locationService;

  /// 统一启动顺序：
  /// 1. 创建配置和基础服务。
  /// 2. 初始化原生 SDK 占位能力。
  /// 3. 加载本地设置。
  /// 4. 恢复登录态并拉取菜单权限。
  static Future<AppDependencies> bootstrap({
    AppConfig config = const AppConfig(),
  }) async {
    final tokenStore = SecureTokenStore();
    final apiClient = ApiClient(config: config, tokenStore: tokenStore);

    // 当前只保留地图 SDK 对接边界；正式接百度地图时在 MapSdkService 内部替换实现。
    await MapSdkService(config: config).initialize();

    final permissionRepository = PermissionRepository(apiClient: apiClient);
    final settingsController = SettingsController();
    await settingsController.load();
    final resourceUpdateController = ResourceUpdateController();
    await resourceUpdateController.load();

    final authController = AuthController(
      authRepository: AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      ),
      permissionRepository: permissionRepository,
    );
    await authController.restoreSession();

    return AppDependencies(
      config: config,
      tokenStore: tokenStore,
      apiClient: apiClient,
      authController: authController,
      permissionRepository: permissionRepository,
      settingsController: settingsController,
      resourceUpdateController: resourceUpdateController,
      cameraService: CameraService(),
      locationService: LocationService(config: config),
    );
  }

  /// 便于 Widget 测试或热重启场景释放 ChangeNotifier。
  void dispose() {
    authController.dispose();
    permissionRepository.dispose();
    settingsController.dispose();
    resourceUpdateController.dispose();
  }
}
