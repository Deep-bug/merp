import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'biometric_service.dart';
import 'gesture_credential_store.dart';
import 'unlock_method.dart';

/// 当前设备、环境和登录用户对应的本地解锁状态。
///
/// 本类不负责页面跳转、应用生命周期或无操作计时；这些流程由
/// AppLockCoordinator 统一编排。持久化键保持兼容旧版本。
class LocalSecurityController extends ChangeNotifier {
  LocalSecurityController({
    required AppLogger logger,
    required this.environment,
    required GestureCredentialStore gestureCredentialStore,
    required BiometricService biometricService,
  }) : _logger = logger,
       _gestures = gestureCredentialStore,
       _biometrics = biometricService;

  static const autoLockTimeout = Duration(seconds: 10);
  static const _autoLockKey = 'merp.settings.autoLockEnabled';
  static const _gestureKeyPrefix = 'merp.security.gesture.v2';
  static const _gestureScopeKeyPrefix = 'merp.security.gesture.lastScope';
  static const _unlockMethodKeyPrefix = 'merp.security.unlockMethod.v1';

  final AppLogger _logger;
  final GestureCredentialStore _gestures;
  final BiometricService _biometrics;
  final String environment;

  SharedPreferences? _preferences;
  String _languageCode = 'zh-CN';
  String? _activeGestureKey;
  String? _activeUnlockMethodKey;
  int _generation = 0;
  int _credentialRevision = 0;
  int _methodRevision = 0;
  bool _disposed = false;
  Future<void> _pendingPreferences = Future<void>.value();

  bool autoLockEnabled = false;
  bool gesturePasswordConfigured = false;
  UnlockMethod unlockMethod = UnlockMethod.gesture;
  String? lastBiometricError;

  int get generation => _generation;
  bool get biometricEnabled => unlockMethod != UnlockMethod.gesture;

  Future<void> load({
    required SharedPreferences preferences,
    required String languageCode,
  }) async {
    _preferences = preferences;
    _languageCode = languageCode;
    autoLockEnabled = preferences.getBool(_autoLockKey) ?? false;
    gesturePasswordConfigured = false;
    notifyListeners();
  }

  void updateLanguageCode(String value) {
    _languageCode = value;
  }

  Future<void> setAutoLockEnabled(bool enabled) async {
    autoLockEnabled = enabled;
    await _preferences?.setBool(_autoLockKey, enabled);
    _logger.info('security', '自动锁屏设置已变更', fields: {'enabled': enabled});
    if (!_disposed) notifyListeners();
  }

  Future<bool> setUnlockMethod(UnlockMethod method) async {
    final operationGeneration = _generation;
    final revision = ++_methodRevision;
    final key = _activeUnlockMethodKey;
    bool current() =>
        _isCurrent(operationGeneration) && revision == _methodRevision;
    lastBiometricError = null;
    if (key == null || _disposed) {
      lastBiometricError = _message(
        '尚未绑定当前用户',
        '尚未綁定目前使用者',
        'No user is currently linked',
      );
      return false;
    }
    if (method == UnlockMethod.gesture) {
      if (!gesturePasswordConfigured) {
        lastBiometricError = _message(
          '请先设置图形密码',
          '請先設定圖形密碼',
          'Set a pattern password first',
        );
        return false;
      }
      unawaited(_biometrics.cancel());
    } else if (!await authenticateWithBiometrics(method: method)) {
      return false;
    }
    if (!current()) return false;
    await _writePreference(key, method.code, canCommit: current);
    if (!current()) return false;
    unlockMethod = method;
    notifyListeners();
    _logger.info('security', '解锁方式已变更', fields: {'method': method.code});
    return true;
  }

  Future<bool> saveGesturePassword(List<int> pattern) async {
    final key = _activeGestureKey;
    if (key == null || _disposed) {
      throw StateError('尚未绑定当前用户，不能保存手势密码');
    }
    final operationGeneration = _generation;
    final revision = ++_credentialRevision;
    bool current() =>
        _isCurrent(operationGeneration) && revision == _credentialRevision;
    final saved = await _gestures.save(key, pattern, canCommit: current);
    if (!saved || !current()) return false;
    gesturePasswordConfigured = true;
    notifyListeners();
    return true;
  }

  Future<bool> verifyGesturePassword(List<int> pattern) async {
    final key = _activeGestureKey;
    if (key == null || _disposed) return false;
    final operationGeneration = _generation;
    final revision = _credentialRevision;
    final verified = await _gestures.verify(key, pattern);
    return _isCurrent(operationGeneration) &&
        revision == _credentialRevision &&
        verified;
  }

  Future<void> clearGesturePassword() async {
    final key = _activeGestureKey;
    final methodKey = _activeUnlockMethodKey;
    if (key == null || _disposed) return;
    final operationGeneration = _generation;
    final revision = ++_credentialRevision;
    final methodRevision = ++_methodRevision;
    unawaited(_biometrics.cancel());
    bool current() =>
        _isCurrent(operationGeneration) && revision == _credentialRevision;
    await _gestures.delete(key);
    if (!current()) return;
    gesturePasswordConfigured = false;
    if (methodKey != null) {
      await _writePreference(
        methodKey,
        UnlockMethod.gesture.code,
        canCommit: () => current() && methodRevision == _methodRevision,
      );
    }
    if (!current()) return;
    if (methodRevision == _methodRevision) unlockMethod = UnlockMethod.gesture;
    notifyListeners();
  }

  Future<bool> activateScope({
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
    if (identity.isEmpty) return false;
    return _activateIdentity(identity, persist: persist);
  }

  Future<bool> restoreLastScope() async {
    final identity = _preferences?.getString(_lastScopeKey)?.trim();
    if (identity == null || identity.isEmpty) return false;
    return _activateIdentity(identity, persist: false);
  }

  void clearActiveScope() {
    _invalidateScope();
    lastBiometricError = null;
    _activeGestureKey = null;
    _activeUnlockMethodKey = null;
    gesturePasswordConfigured = false;
    unlockMethod = UnlockMethod.gesture;
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics({UnlockMethod? method}) async {
    final selected = method ?? unlockMethod;
    if (selected == UnlockMethod.gesture ||
        _activeGestureKey == null ||
        _disposed) {
      return false;
    }
    final operationGeneration = _generation;
    final revision = _methodRevision;
    final credentialRevision = _credentialRevision;
    final result = await _biometrics.authenticate(
      method: selected,
      reason: _biometricReason(selected),
    );
    if (!_isCurrent(operationGeneration) ||
        revision != _methodRevision ||
        credentialRevision != _credentialRevision) {
      return false;
    }
    lastBiometricError = switch (result) {
      BiometricResult.verified => null,
      BiometricResult.unavailable => _unavailableMessage(selected),
      BiometricResult.checkFailed => _message(
        '检查生物识别能力失败，请稍后重试',
        '檢查生物辨識能力失敗，請稍後重試',
        'Unable to check biometric availability. Try again later.',
      ),
      BiometricResult.authenticationFailed => _message(
        '无法调起系统生物识别，请稍后重试',
        '無法啟動系統生物辨識，請稍後重試',
        'Unable to start biometric verification. Try again later.',
      ),
      BiometricResult.cancelled => null,
      BiometricResult.busy => _message(
        '正在进行生物识别，请稍候',
        '正在進行生物辨識，請稍候',
        'Biometric verification is in progress. Please wait.',
      ),
      BiometricResult.rejected =>
        selected == UnlockMethod.face
            ? _message('面容验证未通过', '面容驗證未通過', 'Face verification failed')
            : _message('指纹验证未通过', '指紋驗證未通過', 'Fingerprint verification failed'),
    };
    return result == BiometricResult.verified;
  }

  Future<bool> _activateIdentity(
    String identity, {
    required bool persist,
  }) async {
    if (_disposed) return false;
    _invalidateScope();
    final operationGeneration = _generation;
    final namespace = '${environment.trim().toLowerCase()}:$identity';
    final encoded = base64UrlEncode(utf8.encode(namespace)).replaceAll('=', '');
    final gestureKey = '$_gestureKeyPrefix.$encoded';
    final methodKey = '$_unlockMethodKeyPrefix.$encoded';
    _activeGestureKey = gestureKey;
    _activeUnlockMethodKey = methodKey;
    gesturePasswordConfigured = false;
    unlockMethod = UnlockMethod.gesture;
    lastBiometricError = null;
    if (persist) {
      await _writePreference(
        _lastScopeKey,
        identity,
        canCommit: () => _isCurrent(operationGeneration),
      );
    }
    if (!_isCurrent(operationGeneration)) return false;
    final revision = _credentialRevision;
    final methodRevision = _methodRevision;
    final configured = await _gestures.contains(gestureKey);
    if (!_isCurrent(operationGeneration) ||
        revision != _credentialRevision ||
        methodRevision != _methodRevision) {
      return false;
    }
    var selected = UnlockMethod.fromCode(_preferences?.getString(methodKey));
    if (!configured && selected != UnlockMethod.gesture) {
      selected = UnlockMethod.gesture;
      await _writePreference(
        methodKey,
        selected.code,
        canCommit: () =>
            _isCurrent(operationGeneration) &&
            revision == _credentialRevision &&
            methodRevision == _methodRevision,
      );
    }
    if (!_isCurrent(operationGeneration) ||
        revision != _credentialRevision ||
        methodRevision != _methodRevision) {
      return false;
    }
    gesturePasswordConfigured = configured;
    unlockMethod = selected;
    notifyListeners();
    return true;
  }

  Future<void> _writePreference(
    String key,
    String value, {
    required bool Function() canCommit,
  }) {
    final result = _pendingPreferences.then((_) async {
      if (canCommit()) await _preferences?.setString(key, value);
    });
    _pendingPreferences = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  bool _isCurrent(int value) => !_disposed && value == _generation;

  void _invalidateScope() {
    _generation++;
    _credentialRevision++;
    _methodRevision++;
    unawaited(_biometrics.cancel());
  }

  String get _lastScopeKey =>
      '$_gestureScopeKeyPrefix.${environment.trim().toLowerCase()}';

  String _biometricReason(UnlockMethod method) => method == UnlockMethod.face
      ? _message(
          '请验证面容以解锁 MERP',
          '請驗證面容以解鎖 MERP',
          'Verify your face to unlock MERP',
        )
      : _message(
          '请验证指纹以解锁 MERP',
          '請驗證指紋以解鎖 MERP',
          'Verify your fingerprint to unlock MERP',
        );

  String _unavailableMessage(UnlockMethod method) => method == UnlockMethod.face
      ? _message(
          '当前设备没有可用或已录入的面容识别',
          '目前裝置沒有可用或已登錄的面容辨識',
          'Face recognition is unavailable or not enrolled on this device',
        )
      : _message(
          '当前设备没有可用或已录入的指纹识别',
          '目前裝置沒有可用或已登錄的指紋辨識',
          'Fingerprint recognition is unavailable or not enrolled on this device',
        );

  String _message(String simplified, String traditional, String english) =>
      switch (_languageCode) {
        'zh-TW' => traditional,
        'en-US' => english,
        _ => simplified,
      };

  @override
  void dispose() {
    _disposed = true;
    _invalidateScope();
    super.dispose();
  }
}
