// -----------------------------------------------------------------------------
// 文件：settings_controller.dart
// 作用：管理语言、安全策略、生物识别、手势密码和版本展示等系统设置
// 编写时间：2026-07-10
// 维护说明：持久化键与安全策略集中在此，页面只负责展示和触发意图
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

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

enum UnlockMethod {
  gesture('gesture'),
  fingerprint('fingerprint'),
  face('face');

  const UnlockMethod(this.code);

  final String code;

  static UnlockMethod fromCode(String? code) {
    return values.firstWhere(
      (method) => method.code == code,
      orElse: () => gesture,
    );
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    required AppLogger logger,
    this.environment = 'qas',
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
    bool useSecureStorage = true,
    Future<PackageInfo> Function()? packageInfoProvider,
  }) : _logger = logger,
       _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _useSecureStorage = useSecureStorage,
       _packageInfoProvider = packageInfoProvider ?? PackageInfo.fromPlatform;

  static const autoLockTimeout = Duration(seconds: 10);
  static const _autoLockKey = 'merp.settings.autoLockEnabled';
  static const _languageKey = 'merp.settings.language';
  static const _apiServerKeyPrefix = 'merp.settings.apiServer';
  static const _gestureKeyPrefix = 'merp.security.gesture.v2';
  static const _gestureScopeKeyPrefix = 'merp.security.gesture.lastScope';
  static const _unlockMethodKeyPrefix = 'merp.security.unlockMethod.v1';
  static const _gestureIterations = 120000;

  final LocalAuthentication _localAuthentication;
  final AppLogger _logger;
  final FlutterSecureStorage _secureStorage;
  final bool _useSecureStorage;
  final Future<PackageInfo> Function() _packageInfoProvider;
  final String environment;

  SharedPreferences? _preferences;
  final Map<String, String> _memoryGestureValues = {};
  String? _activeGestureKey;
  String? _activeUnlockMethodKey;
  bool autoLockEnabled = false;
  AppLanguage language = AppLanguage.zhHans;
  ApiServer apiServer = ApiServer.china;
  bool gesturePasswordConfigured = false;
  UnlockMethod unlockMethod = UnlockMethod.gesture;
  String? lastBiometricError;
  String currentVersion = '1.0.0';

  bool get biometricEnabled => unlockMethod != UnlockMethod.gesture;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    autoLockEnabled = _preferences?.getBool(_autoLockKey) ?? false;
    final package = await _packageInfoProvider();
    currentVersion = package.version.trim();
    language = AppLanguage.fromCode(_preferences?.getString(_languageKey));
    apiServer = ApiServer.fromCode(_preferences?.getString(_apiServerKey));
    gesturePasswordConfigured = false;
    _logger.info(
      'settings',
      '本地设置加载完成',
      fields: {
        'language': language.code,
        'apiServer': apiServer.code,
        'autoLock': autoLockEnabled,
        'unlockMethod': unlockMethod.code,
      },
    );
    notifyListeners();
  }

  Future<bool> setUnlockMethod(UnlockMethod method) async {
    lastBiometricError = null;
    if (_activeUnlockMethodKey == null) {
      lastBiometricError = _localizedMessage(
        '尚未绑定当前用户',
        '尚未綁定目前使用者',
        'No user is currently linked',
      );
      return false;
    }
    if (method == UnlockMethod.gesture) {
      if (!gesturePasswordConfigured) {
        lastBiometricError = _localizedMessage(
          '请先设置图形密码',
          '請先設定圖形密碼',
          'Set a pattern password first',
        );
        return false;
      }
      await _persistUnlockMethod(method);
      return true;
    }
    if (!await _isBiometricMethodAvailable(method)) {
      return false;
    }
    if (!await authenticateWithBiometrics(method: method)) {
      return false;
    }
    await _persistUnlockMethod(method);
    _logger.info('settings', '解锁方式已变更', fields: {'method': method.code});
    return true;
  }

  Future<void> _persistUnlockMethod(UnlockMethod method) async {
    unlockMethod = method;
    await _preferences?.setString(_activeUnlockMethodKey!, method.code);
    notifyListeners();
  }

  Future<void> setAutoLockEnabled(bool enabled) async {
    autoLockEnabled = enabled;
    await _preferences?.setBool(_autoLockKey, enabled);
    _logger.info('settings', '自动锁屏设置已变更', fields: {'enabled': enabled});
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
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

  Future<void> saveGesturePassword(List<int> pattern) async {
    final key = _activeGestureKey;
    if (key == null) {
      throw StateError('尚未绑定当前用户，不能保存手势密码');
    }
    final salt = _randomBytes(16);
    final digest = await compute(
      _derivePatternHash,
      _PatternHashRequest(pattern, salt, _gestureIterations),
    );
    final value = jsonEncode({
      'version': 2,
      'iterations': _gestureIterations,
      'salt': base64UrlEncode(salt),
      'hash': base64UrlEncode(digest),
    });
    await _writeGestureValue(key, value);
    gesturePasswordConfigured = true;
    notifyListeners();
  }

  Future<bool> verifyGesturePassword(List<int> pattern) async {
    final key = _activeGestureKey;
    if (key == null) {
      return false;
    }
    final saved = await _readGestureValue(key);
    if (saved == null || saved.isEmpty) {
      return false;
    }
    try {
      final record = jsonDecode(saved) as Map<String, dynamic>;
      if (record['version'] != 2) {
        return false;
      }
      final salt = base64Url.decode(record['salt'] as String);
      final expected = base64Url.decode(record['hash'] as String);
      final iterations = record['iterations'] as int;
      final actual = await compute(
        _derivePatternHash,
        _PatternHashRequest(pattern, salt, iterations),
      );
      return _constantTimeEquals(expected, actual);
    } catch (error, stackTrace) {
      _logger.warning(
        'settings',
        '手势密码记录格式无效',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 清除当前用户的本机手势；下次账号登录成功后会进入首次设置流程。
  Future<void> clearGesturePassword() async {
    final key = _activeGestureKey;
    if (key == null) {
      return;
    }
    await _deleteGestureValue(key);
    gesturePasswordConfigured = false;
    if (_activeUnlockMethodKey != null) {
      await _persistUnlockMethod(UnlockMethod.gesture);
    }
    notifyListeners();
  }

  /// 将手势密码绑定到当前部署环境和当前登录用户。
  Future<bool> activateGestureScope({
    required String userId,
    required String accountName,
    bool persist = true,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedAccount = accountName.trim().toLowerCase();
    final identity = normalizedUserId.isNotEmpty
        ? 'id:$normalizedUserId'
        : normalizedAccount.isNotEmpty
        ? 'account:$normalizedAccount'
        : '';
    if (identity.isEmpty) {
      return false;
    }
    await _activateGestureIdentity(identity, persist: persist);
    return true;
  }

  /// 冷启动恢复会话时，资料接口返回前先沿用本机上次登录用户的安全域。
  Future<bool> restoreLastGestureScope() async {
    final identity = _preferences?.getString(_lastGestureScopeKey)?.trim();
    if (identity == null || identity.isEmpty) {
      return false;
    }
    await _activateGestureIdentity(identity, persist: false);
    return true;
  }

  void clearActiveGestureScope() {
    _activeGestureKey = null;
    _activeUnlockMethodKey = null;
    gesturePasswordConfigured = false;
    unlockMethod = UnlockMethod.gesture;
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics({UnlockMethod? method}) async {
    final selected = method ?? unlockMethod;
    if (selected == UnlockMethod.gesture) {
      return false;
    }
    if (!await _isBiometricMethodAvailable(selected)) {
      return false;
    }
    try {
      final verified = await _localAuthentication.authenticate(
        localizedReason: _biometricReason(selected),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!verified) {
        lastBiometricError = selected == UnlockMethod.face
            ? _localizedMessage(
                '面容验证未通过',
                '面容驗證未通過',
                'Face verification failed',
              )
            : _localizedMessage(
                '指纹验证未通过',
                '指紋驗證未通過',
                'Fingerprint verification failed',
              );
      }
      return verified;
    } catch (error, stackTrace) {
      lastBiometricError = _localizedMessage(
        '无法调起系统生物识别，请稍后重试',
        '無法啟動系統生物辨識，請稍後重試',
        'Unable to start biometric verification. Try again later.',
      );
      _logger.error(
        'biometric',
        '无法调起系统生物识别',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _isBiometricMethodAvailable(UnlockMethod method) async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!supported || !canCheck) {
        lastBiometricError = _unavailableMessage(method);
        return false;
      }
      final types = await _localAuthentication.getAvailableBiometrics();
      final expected = method == UnlockMethod.face
          ? BiometricType.face
          : BiometricType.fingerprint;
      if (!types.contains(expected)) {
        lastBiometricError = _unavailableMessage(method);
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      lastBiometricError = _localizedMessage(
        '检查生物识别能力失败，请稍后重试',
        '檢查生物辨識能力失敗，請稍後重試',
        'Unable to check biometric availability. Try again later.',
      );
      _logger.error(
        'biometric',
        '检查系统生物识别能力失败',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String get _lastGestureScopeKey =>
      '$_gestureScopeKeyPrefix.${environment.trim().toLowerCase()}';

  String get _apiServerKey =>
      '$_apiServerKeyPrefix.${environment.trim().toLowerCase()}';

  Future<void> _activateGestureIdentity(
    String identity, {
    required bool persist,
  }) async {
    final namespace = '${environment.trim().toLowerCase()}:$identity';
    final encoded = base64UrlEncode(utf8.encode(namespace)).replaceAll('=', '');
    _activeGestureKey = '$_gestureKeyPrefix.$encoded';
    _activeUnlockMethodKey = '$_unlockMethodKeyPrefix.$encoded';
    if (persist) {
      await _preferences?.setString(_lastGestureScopeKey, identity);
    }
    gesturePasswordConfigured =
        await _readGestureValue(_activeGestureKey!) != null;
    unlockMethod = UnlockMethod.fromCode(
      _preferences?.getString(_activeUnlockMethodKey!),
    );
    if (!gesturePasswordConfigured && unlockMethod != UnlockMethod.gesture) {
      unlockMethod = UnlockMethod.gesture;
      await _preferences?.setString(
        _activeUnlockMethodKey!,
        UnlockMethod.gesture.code,
      );
    }
    notifyListeners();
  }

  String _biometricReason(UnlockMethod method) {
    if (method == UnlockMethod.face) {
      return _localizedMessage(
        '请验证面容以解锁 MERP',
        '請驗證面容以解鎖 MERP',
        'Verify your face to unlock MERP',
      );
    }
    return _localizedMessage(
      '请验证指纹以解锁 MERP',
      '請驗證指紋以解鎖 MERP',
      'Verify your fingerprint to unlock MERP',
    );
  }

  String _unavailableMessage(UnlockMethod method) {
    if (method == UnlockMethod.face) {
      return _localizedMessage(
        '当前设备没有可用或已录入的面容识别',
        '目前裝置沒有可用或已登錄的面容辨識',
        'Face recognition is unavailable or not enrolled on this device',
      );
    }
    return _localizedMessage(
      '当前设备没有可用或已录入的指纹识别',
      '目前裝置沒有可用或已登錄的指紋辨識',
      'Fingerprint recognition is unavailable or not enrolled on this device',
    );
  }

  String _localizedMessage(
    String simplified,
    String traditional,
    String english,
  ) {
    return switch (language) {
      AppLanguage.zhHans => simplified,
      AppLanguage.zhHant => traditional,
      AppLanguage.english => english,
    };
  }

  Future<String?> _readGestureValue(String key) async {
    if (!_useSecureStorage) {
      return _memoryGestureValues[key];
    }
    try {
      return await _secureStorage.read(key: key);
    } catch (error, stackTrace) {
      _logger.warning(
        'settings',
        '读取手势密码失败',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _writeGestureValue(String key, String value) async {
    if (!_useSecureStorage) {
      _memoryGestureValues[key] = value;
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _deleteGestureValue(String key) async {
    if (!_useSecureStorage) {
      _memoryGestureValues.remove(key);
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

class _PatternHashRequest {
  const _PatternHashRequest(this.pattern, this.salt, this.iterations);

  final List<int> pattern;
  final Uint8List salt;
  final int iterations;
}

Uint8List _derivePatternHash(_PatternHashRequest request) {
  final password = utf8.encode('merp:${request.pattern.join('-')}');
  final hmac = Hmac(sha256, password);
  final block = Uint8List(request.salt.length + 4)
    ..setAll(0, request.salt)
    ..setAll(request.salt.length, const [0, 0, 0, 1]);
  var value = Uint8List.fromList(hmac.convert(block).bytes);
  final result = Uint8List.fromList(value);
  for (var i = 1; i < request.iterations; i++) {
    value = Uint8List.fromList(hmac.convert(value).bytes);
    for (var j = 0; j < result.length; j++) {
      result[j] ^= value[j];
    }
  }
  return result;
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }
  return difference == 0;
}
