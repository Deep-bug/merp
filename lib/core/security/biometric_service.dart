import 'package:local_auth/local_auth.dart';

import '../logging/app_logger.dart';
import 'unlock_method.dart';

/// 平台服务只返回结果；用户提示及语言由上层决定。
enum BiometricResult {
  verified,
  rejected,
  unavailable,
  checkFailed,
  authenticationFailed,
  cancelled,
  busy,
}

class BiometricService {
  BiometricService({
    required AppLogger logger,
    LocalAuthentication? localAuthentication,
  }) : _logger = logger,
       _authentication = localAuthentication ?? LocalAuthentication();

  final AppLogger _logger;
  final LocalAuthentication _authentication;
  int _revision = 0;
  bool _busy = false;
  bool _promptOpen = false;
  Future<void> _pendingCancellation = Future<void>.value();

  Future<BiometricResult> authenticate({
    required UnlockMethod method,
    required String reason,
  }) async {
    if (method == UnlockMethod.gesture) return BiometricResult.unavailable;
    if (_busy) return BiometricResult.busy;
    _busy = true;
    final revision = _revision;
    try {
      final result = await _authenticate(method, reason, revision);
      _promptOpen = false;
      // 等旧系统弹窗取消完成后再接受下一次认证，避免取消指令误伤新弹窗。
      await _pendingCancellation;
      return revision == _revision ? result : BiometricResult.cancelled;
    } finally {
      _promptOpen = false;
      _busy = false;
    }
  }

  Future<BiometricResult> _authenticate(
    UnlockMethod method,
    String reason,
    int revision,
  ) async {
    final available = await _checkAvailability(method);
    // 切换用户时，即使能力检测稍后才结束，也不能再弹出旧用户的验证。
    if (revision != _revision) return BiometricResult.cancelled;
    if (available != null) return available;
    _promptOpen = true;
    try {
      final verified = await _authentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return verified ? BiometricResult.verified : BiometricResult.rejected;
    } catch (error, stackTrace) {
      if (revision != _revision) return BiometricResult.cancelled;
      _logger.error(
        'biometric',
        '无法调起系统生物识别',
        error: error,
        stackTrace: stackTrace,
      );
      return BiometricResult.authenticationFailed;
    }
  }

  Future<BiometricResult?> _checkAvailability(UnlockMethod method) async {
    try {
      final supported = await _authentication.isDeviceSupported();
      final canCheck = await _authentication.canCheckBiometrics;
      if (!supported || !canCheck) return BiometricResult.unavailable;
      final types = await _authentication.getAvailableBiometrics();
      final expected = method == UnlockMethod.face
          ? BiometricType.face
          : BiometricType.fingerprint;
      return types.contains(expected) ? null : BiometricResult.unavailable;
    } catch (error, stackTrace) {
      _logger.error(
        'biometric',
        '检查系统生物识别能力失败',
        error: error,
        stackTrace: stackTrace,
      );
      return BiometricResult.checkFailed;
    }
  }

  /// 立即使旧结果失效；系统取消失败也不能让旧验证放行新会话。
  Future<void> cancel() {
    _revision++;
    if (!_promptOpen) return Future<void>.value();
    _pendingCancellation = _pendingCancellation.then(
      (_) => _stopAuthentication(),
    );
    return _pendingCancellation;
  }

  Future<void> _stopAuthentication() async {
    try {
      await _authentication.stopAuthentication();
    } catch (error, stackTrace) {
      _logger.warning(
        'biometric',
        '取消系统生物识别失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
