import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  zhHans('zh-CN', '简体中文'),
  enUs('en-US', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) {
    return values.firstWhere((item) => item.code == code, orElse: () => zhHans);
  }
}

class VersionCheckResult {
  const VersionCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.message,
  });

  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String message;
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
    bool useSecureStorage = true,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _useSecureStorage = useSecureStorage;

  static const autoLockTimeout = Duration(seconds: 10);
  static const _biometricKey = 'merp.settings.biometricEnabled';
  static const _autoLockKey = 'merp.settings.autoLockEnabled';
  static const _languageKey = 'merp.settings.language';
  static const _gestureKey = 'merp.settings.gesturePassword';

  final LocalAuthentication _localAuthentication;
  final FlutterSecureStorage _secureStorage;
  final bool _useSecureStorage;

  SharedPreferences? _preferences;
  String? _memoryGestureHash;
  bool biometricEnabled = false;
  bool autoLockEnabled = false;
  AppLanguage language = AppLanguage.zhHans;
  bool gesturePasswordConfigured = false;
  String? lastBiometricError;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    biometricEnabled = _preferences?.getBool(_biometricKey) ?? false;
    autoLockEnabled = _preferences?.getBool(_autoLockKey) ?? false;
    language = AppLanguage.fromCode(_preferences?.getString(_languageKey));
    gesturePasswordConfigured = await _readGestureHash() != null;
    notifyListeners();
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    lastBiometricError = null;
    if (enabled) {
      final available = await _isBiometricAvailable();
      if (!available) {
        biometricEnabled = false;
        await _preferences?.setBool(_biometricKey, false);
        notifyListeners();
        return false;
      }

      final verified = await authenticateWithBiometrics();
      if (!verified) {
        biometricEnabled = false;
        await _preferences?.setBool(_biometricKey, false);
        notifyListeners();
        return false;
      }
    }

    biometricEnabled = enabled;
    await _preferences?.setBool(_biometricKey, enabled);
    notifyListeners();
    return true;
  }

  Future<void> setAutoLockEnabled(bool enabled) async {
    autoLockEnabled = enabled;
    await _preferences?.setBool(_autoLockKey, enabled);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    await _preferences?.setString(_languageKey, value.code);
    notifyListeners();
  }

  Future<void> saveGesturePassword(List<int> pattern) async {
    await _writeGestureHash(_hashPattern(pattern));
    gesturePasswordConfigured = true;
    notifyListeners();
  }

  Future<bool> verifyGesturePassword(List<int> pattern) async {
    final saved = await _readGestureHash();
    if (saved == null || saved.isEmpty) {
      return false;
    }
    return saved == _hashPattern(pattern);
  }

  Future<VersionCheckResult> checkVersion() async {
    // 当前先保留后端接口接入点。真实环境建议调用 /app/version/check，
    // 返回 latestVersion、downloadUrl、forceUpdate、releaseNotes 等字段。
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const VersionCheckResult(
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      hasUpdate: false,
      message: '当前已经是最新版本',
    );
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: '请验证指纹以解锁 MERP',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (error) {
      lastBiometricError = '无法调起系统指纹验证：$error';
      return false;
    }
  }

  Future<bool> _isBiometricAvailable() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!supported || !canCheck) {
        lastBiometricError = '当前设备没有可用的指纹或生物识别能力';
        return false;
      }
      return true;
    } catch (error) {
      lastBiometricError = '检查指纹能力失败：$error';
      return false;
    }
  }

  String _hashPattern(List<int> pattern) {
    // 手势密码不明文落盘；正式环境可替换为后端盐值或 PBKDF2/Argon2。
    final source = 'merp:${pattern.join('-')}';
    var hash = 0x811c9dc5;
    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<String?> _readGestureHash() async {
    if (!_useSecureStorage) {
      return _memoryGestureHash;
    }
    try {
      return await _secureStorage.read(key: _gestureKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeGestureHash(String value) async {
    if (!_useSecureStorage) {
      _memoryGestureHash = value;
      return;
    }
    await _secureStorage.write(key: _gestureKey, value: value);
  }
}
