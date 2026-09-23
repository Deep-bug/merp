// -----------------------------------------------------------------------------
// 文件：settings_controller.dart
// 作用：管理语言、服务器和版本等普通设置，并兼容转发本地安全设置
// 编写时间：2026-07-10
// 维护说明：安全状态归 LocalSecurityController；新安全代码不要继续堆入本类
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/gesture_credential_store.dart';
import '../../core/security/local_security_controller.dart';
import '../../core/security/unlock_method.dart';

export '../../core/security/unlock_method.dart';

enum AppLanguage {
  zhHans('zh-CN', 'zh_CN', Locale('zh')),
  zhHant('zh-TW', 'zh_TW', Locale('zh', 'TW')),
  english('en-US', 'en_US', Locale('en', 'US'));

  const AppLanguage(this.code, this.apiCode, this.locale);

  final String code;
  final String apiCode;
  final Locale locale;

  static AppLanguage fromCode(String? code) {
    return values.firstWhere((item) => item.code == code, orElse: () => zhHans);
  }
}

/// 普通应用设置的控制器。
///
/// 旧页面仍可通过本类访问安全方法；这些兼容代理最终都落到独立的 [security]，
/// 以便后续页面逐步迁移而不改变已发布行为。
class SettingsController extends ChangeNotifier {
  SettingsController({
    required AppLogger logger,
    this.environment = 'qas',
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
    bool useSecureStorage = true,
    GestureCredentialStore? gestureCredentialStore,
    BiometricService? biometricService,
    LocalSecurityController? localSecurityController,
    Future<PackageInfo> Function()? packageInfoProvider,
  }) : _logger = logger,
       _packageInfoProvider = packageInfoProvider ?? PackageInfo.fromPlatform,
       security =
           localSecurityController ??
           LocalSecurityController(
             logger: logger,
             environment: environment,
             gestureCredentialStore:
                 gestureCredentialStore ??
                 GestureCredentialStore(
                   logger: logger,
                   secureStorage: secureStorage,
                   useSecureStorage: useSecureStorage,
                 ),
             biometricService:
                 biometricService ??
                 BiometricService(
                   logger: logger,
                   localAuthentication: localAuthentication,
                 ),
           ) {
    security.addListener(_forwardSecurityChange);
  }

  static const autoLockTimeout = LocalSecurityController.autoLockTimeout;
  static const _languageKey = 'merp.settings.language';
  static const _apiServerKeyPrefix = 'merp.settings.apiServer';

  final AppLogger _logger;
  final Future<PackageInfo> Function() _packageInfoProvider;
  final String environment;
  final LocalSecurityController security;

  SharedPreferences? _preferences;
  AppLanguage language = AppLanguage.zhHans;
  ApiServer apiServer = ApiServer.china;
  String currentVersion = '1.0.0';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    final package = await _packageInfoProvider();
    currentVersion = package.version.trim();
    language = AppLanguage.fromCode(preferences.getString(_languageKey));
    apiServer = ApiServer.fromCode(preferences.getString(_apiServerKey));
    await security.load(preferences: preferences, languageCode: language.code);
    _logger.info(
      'settings',
      '本地设置加载完成',
      fields: {
        'language': language.code,
        'apiServer': apiServer.code,
        'autoLock': security.autoLockEnabled,
        'unlockMethod': security.unlockMethod.code,
      },
    );
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    security.updateLanguageCode(value.code);
    await _preferences?.setString(_languageKey, value.code);
    _logger.info('settings', '应用语言已变更', fields: {'locale': value.code});
    notifyListeners();
  }

  Future<void> setApiServer(ApiServer value) async {
    apiServer = value;
    await _preferences?.setString(_apiServerKey, value.code);
    _logger.info('settings', 'API 服务器设置已变更', fields: {'server': value.code});
    notifyListeners();
  }

  String get _apiServerKey =>
      '$_apiServerKeyPrefix.${environment.trim().toLowerCase()}';

  // 以下为兼容代理。新安全页面应直接依赖 LocalSecurityController。
  bool get autoLockEnabled => security.autoLockEnabled;
  bool get gesturePasswordConfigured => security.gesturePasswordConfigured;
  UnlockMethod get unlockMethod => security.unlockMethod;
  String? get lastBiometricError => security.lastBiometricError;
  bool get biometricEnabled => security.biometricEnabled;
  int get securityGeneration => security.generation;

  Future<void> setAutoLockEnabled(bool enabled) =>
      security.setAutoLockEnabled(enabled);

  Future<bool> setUnlockMethod(UnlockMethod method) =>
      security.setUnlockMethod(method);

  Future<bool> saveGesturePassword(List<int> pattern) =>
      security.saveGesturePassword(pattern);

  Future<bool> verifyGesturePassword(List<int> pattern) =>
      security.verifyGesturePassword(pattern);

  Future<void> clearGesturePassword() => security.clearGesturePassword();

  Future<bool> activateGestureScope({
    required String userId,
    required String accountName,
    bool persist = true,
  }) => security.activateScope(
    userId: userId,
    accountName: accountName,
    persist: persist,
  );

  Future<bool> restoreLastGestureScope() => security.restoreLastScope();

  void clearActiveGestureScope() => security.clearActiveScope();

  Future<bool> authenticateWithBiometrics({UnlockMethod? method}) =>
      security.authenticateWithBiometrics(method: method);

  void _forwardSecurityChange() => notifyListeners();

  @override
  void dispose() {
    security.removeListener(_forwardSecurityChange);
    security.dispose();
    super.dispose();
  }
}
