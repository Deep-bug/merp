// -----------------------------------------------------------------------------
// 文件：app_dependencies.dart
// 作用：集中装配配置、鉴权、网络、权限、设置和设备能力等应用级依赖
// 编写时间：2026-07-10
// 维护说明：新增全局服务必须在此显式声明生命周期，禁止在页面中直接 new 服务
// -----------------------------------------------------------------------------

import '../core/auth/auth_controller.dart';
import '../core/auth/auth_repository.dart';
import '../core/auth/secure_token_store.dart';
import '../core/config/app_config.dart';
import '../core/device/camera_service.dart';
import '../core/device/baidu_privacy_consent_store.dart';
import '../core/device/device_info_service.dart';
import '../core/device/file_service.dart';
import '../core/device/location_service.dart';
import '../core/device/map_sdk_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/api_client.dart';
import '../core/platform/web_data_cleaner.dart';
import '../core/security/local_security_controller.dart';
import '../features/home/data/permission_repository.dart';
import '../features/app_update/app_update_controller.dart';
import '../features/app_update/app_update_platform.dart';
import '../features/app_update/app_update_repository.dart';
import '../features/app_update/mock_app_update_repository.dart';
import '../features/home/data/favorite_feature_controller.dart';
import '../features/home/data/feature_badge_controller.dart';
import '../features/settings/settings_controller.dart';
import 'user_session_data_coordinator.dart';

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
    required this.favoriteFeatureController,
    required this.featureBadgeController,
    required this.appUpdateController,
    required this.webDataCleaner,
    required this.settingsController,
    required this.cameraService,
    required this.fileService,
    required this.deviceInfoService,
    required this.locationService,
    required this.mapSdkService,
    required this.logger,
    this.userSessionDataCoordinator,
  });

  final AppConfig config;
  final TokenStore tokenStore;
  final ApiClient apiClient;
  final AuthController authController;
  final PermissionRepository permissionRepository;
  final FavoriteFeatureController favoriteFeatureController;
  final FeatureBadgeController featureBadgeController;
  final AppUpdateController appUpdateController;
  final WebDataCleaner webDataCleaner;
  final SettingsController settingsController;
  LocalSecurityController get localSecurityController =>
      settingsController.security;
  final CameraService cameraService;
  final FileService fileService;
  final DeviceInfoService deviceInfoService;
  final LocationService locationService;
  final MapSdkService mapSdkService;
  final AppLogger logger;
  final UserSessionDataCoordinator? userSessionDataCoordinator;

  /// 统一启动顺序：
  /// 1. 创建配置和基础服务。
  /// 2. 初始化原生 SDK 占位能力。
  /// 3. 加载本地设置。
  /// 4. 使用 refresh_token 恢复登录态，资料和权限随后在后台并行加载。
  static Future<AppDependencies> bootstrap({
    AppConfig config = const AppConfig(),
    required AppLogger logger,
  }) async {
    final appEnvironment = config.normalizedAppEnvironment;
    final authEnvironment = config.normalizedAuthEnvironment;
    logger.info(
      'bootstrap',
      '开始创建应用依赖',
      fields: {
        'appEnvironment': appEnvironment,
        'authEnvironment': authEnvironment,
        'apiBaseUrl': config.apiBaseUrl,
      },
    );
    final tokenStore = SecureTokenStore(
      logger: logger,
      environment: appEnvironment,
    );
    final settingsController = SettingsController(
      logger: logger,
      environment: appEnvironment,
    );
    final apiClient = ApiClient(
      config: config,
      tokenStore: tokenStore,
      logger: logger,
      localeProvider: () => settingsController.language.code,
    );

    const baiduPrivacyConsentStore = BaiduPrivacyConsentStore();
    final mapSdkService = MapSdkService(
      config: config,
      logger: logger,
      privacyConsentStore: baiduPrivacyConsentStore,
    );
    final permissionRepository = PermissionRepository(
      apiClient: apiClient,
      logger: logger,
      languageCodeProvider: () => settingsController.language.apiCode,
    );
    final favoriteFeatureController = FavoriteFeatureController(logger: logger);
    final featureBadgeController = FeatureBadgeController(logger: logger);
    final isMockAppUpdateEnabled = config.isMockAppUpdateEnabled;
    final appUpdateRepository = isMockAppUpdateEnabled
        ? MockAppUpdateRepository(logger: logger)
        : AppUpdateRepository(
            apiClient: apiClient,
            config: config,
            logger: logger,
          );
    final appUpdateController = AppUpdateController(
      repository: appUpdateRepository,
      platformService: MethodChannelAppUpdatePlatform(),
      logger: logger,
      localeProvider: () => settingsController.language.apiCode,
      isSimulationMode: isMockAppUpdateEnabled,
    );
    final webDataCleaner = WebDataCleaner(logger: logger);

    // 本地设置、地图 SDK 占位初始化互不依赖，可以并行加载。
    // 后续真正接入地图 SDK 时，仍然建议把耗时授权/定位动作放到具体业务页再触发。
    await Future.wait([
      mapSdkService.initialize(),
      settingsController.load(),
      favoriteFeatureController.load(),
    ]);
    // 若旧版本曾保存 HK 选择、但当前构建尚未注入 HK 地址，则安全回退 China。
    if (!config.isApiServerAvailable(settingsController.apiServer)) {
      await settingsController.setApiServer(ApiServer.china);
    }
    final selectedApiBaseUrl = config.apiBaseUrlFor(
      settingsController.apiServer,
    );
    if (selectedApiBaseUrl != config.apiBaseUrl) {
      apiClient.updateBaseUrl(selectedApiBaseUrl);
    }

    // 版本检查只依赖环境、语言和 API 地址，应在登录态恢复之前启动。这样旧版本
    // 即使 refresh_token 已失效，也能优先进入强制升级页。
    // Mock Debug 使用本地仓库模拟接口和下载，其余环境访问真实版本接口。
    // unawaited(appUpdateController.checkAtStartup());

    final authController = AuthController(
      authRepository: AuthRepository(apiClient: apiClient, logger: logger),
      permissionRepository: permissionRepository,
      webDataCleaner: webDataCleaner,
      logger: logger,
    );
    // 网络层只通过回调通知认证状态失效，避免 ApiClient 反向依赖 Controller。
    apiClient.onSessionExpired = authController.handleSessionExpired;
    final userSessionDataCoordinator = UserSessionDataCoordinator(
      auth: authController,
      favorites: favoriteFeatureController,
      badges: featureBadgeController,
      environment: appEnvironment,
      mock: config.isDevelopmentMockEnabled,
    );
    if (config.isDevelopmentMockEnabled) {
      await authController.enterDevelopmentMockSession();
    } else {
      await authController.restoreSession();
    }

    logger.info('bootstrap', '应用依赖初始化完成');
    return AppDependencies(
      config: config,
      tokenStore: apiClient.sessionTokens,
      apiClient: apiClient,
      authController: authController,
      permissionRepository: permissionRepository,
      favoriteFeatureController: favoriteFeatureController,
      featureBadgeController: featureBadgeController,
      appUpdateController: appUpdateController,
      webDataCleaner: webDataCleaner,
      settingsController: settingsController,
      cameraService: CameraService(),
      fileService: FileService(),
      deviceInfoService: DeviceInfoService(),
      locationService: LocationService(
        config: config,
        logger: logger,
        privacyConsentStore: baiduPrivacyConsentStore,
      ),
      mapSdkService: mapSdkService,
      logger: logger,
      userSessionDataCoordinator: userSessionDataCoordinator,
    );
  }

  /// 便于 Widget 测试或热重启场景释放 ChangeNotifier。
  void dispose() {
    userSessionDataCoordinator?.dispose();
    authController.dispose();
    apiClient.sessionTokens.dispose();
    permissionRepository.dispose();
    favoriteFeatureController.dispose();
    featureBadgeController.dispose();
    appUpdateController.dispose();
    webDataCleaner.dispose();
    settingsController.dispose();
  }
}
