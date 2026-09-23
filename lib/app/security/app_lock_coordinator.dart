import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth/security_session_state.dart';
import '../../core/security/local_security_controller.dart';

enum AppLockReason { coldStart, inactivity }

/// 统一编排账号安全域、冷启动验证、无操作计时与后台隐私遮罩。
///
/// 它不依赖 BuildContext，也不绘制界面。Widget 只把生命周期和触摸事件转发
/// 进来，再根据这里的状态显示锁屏或纯色遮罩。
class AppLockCoordinator extends ChangeNotifier {
  AppLockCoordinator({
    required SecuritySessionState auth,
    required LocalSecurityController security,
    DateTime Function()? clock,
  }) : _auth = auth,
       _security = security,
       _clock = clock ?? DateTime.now,
       _coldStartPending = auth.isAuthenticated,
       _hadAuthenticatedSession = auth.isAuthenticated;

  final SecuritySessionState _auth;
  final LocalSecurityController _security;
  final DateTime Function() _clock;

  Timer? _timer;
  late DateTime _lastInteraction = _clock();
  bool _started = false;
  bool _disposed = false;
  bool _syncingScope = false;
  bool _coldStartPending;
  bool _hadAuthenticatedSession;
  int? _boundSessionGeneration;

  bool privacyCovered = false;
  bool locked = false;
  bool requiresEnrollment = false;
  bool scopeReady = false;
  AppLockReason reason = AppLockReason.inactivity;

  bool get shouldTrackInactivity =>
      _auth.isAuthenticated &&
      !_auth.gestureEnrollmentRequired &&
      scopeReady &&
      _security.autoLockEnabled;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _auth.addListener(_synchronizePolicy);
    _security.addListener(_synchronizePolicy);
    _synchronizePolicy();
  }

  /// inactive 早于 paused/hidden；收到任一非 resumed 状态都应立即遮挡。
  void coverForBackground() {
    if (_disposed) return;
    _timer?.cancel();
    if (privacyCovered) return;
    privacyCovered = true;
    notifyListeners();
  }

  void resumeFromBackground() {
    if (_disposed) return;
    final inactiveFor = _clock().difference(_lastInteraction);
    final shouldLock =
        !locked &&
        shouldTrackInactivity &&
        inactiveFor >= LocalSecurityController.autoLockTimeout;
    var changed = privacyCovered;
    privacyCovered = false;
    if (shouldLock) {
      locked = true;
      reason = AppLockReason.inactivity;
      requiresEnrollment = !_security.gesturePasswordConfigured;
      changed = true;
    }
    if (changed) notifyListeners();
    if (locked || !shouldTrackInactivity) return;
    final remaining = LocalSecurityController.autoLockTimeout - inactiveFor;
    _scheduleLock(remaining.isNegative ? Duration.zero : remaining);
  }

  void recordInteraction({bool reschedule = true}) {
    if (!shouldTrackInactivity || locked || _disposed) return;
    _lastInteraction = _clock();
    if (reschedule) _scheduleLock();
  }

  void unlock() {
    if (_disposed || !locked) return;
    locked = false;
    requiresEnrollment = false;
    _lastInteraction = _clock();
    if (shouldTrackInactivity) _scheduleLock();
    notifyListeners();
  }

  void _synchronizePolicy() {
    unawaited(_synchronizePolicyAsync());
  }

  Future<void> _synchronizePolicyAsync() async {
    if (_disposed) return;
    final sessionGeneration = _auth.sessionGeneration;
    if (!_auth.isAuthenticated) {
      _timer?.cancel();
      _boundSessionGeneration = null;
      if (_hadAuthenticatedSession) {
        _hadAuthenticatedSession = false;
        scopeReady = false;
        _coldStartPending = false;
        _security.clearActiveScope();
      }
      if (locked) {
        locked = false;
        requiresEnrollment = false;
        notifyListeners();
      }
      return;
    }

    _hadAuthenticatedSession = true;
    if (_boundSessionGeneration != null &&
        _boundSessionGeneration != sessionGeneration) {
      scopeReady = false;
      // clearActiveScope 会同步通知监听者，先解除旧绑定可避免重入时重复清理。
      _boundSessionGeneration = null;
      _security.clearActiveScope();
    }
    if (!scopeReady) {
      if (_syncingScope) return;
      _syncingScope = true;
      try {
        final profile = _auth.session!.profile;
        var activated = await _security.activateScope(
          userId: profile.id,
          accountName: profile.accountName,
        );
        if (!_isCurrentSession(sessionGeneration)) return;
        if (!activated && _coldStartPending) {
          activated = await _security.restoreLastScope();
        }
        if (!activated || !_isCurrentSession(sessionGeneration)) return;
        scopeReady = true;
        _boundSessionGeneration = sessionGeneration;
      } finally {
        _syncingScope = false;
        if (!_disposed && sessionGeneration != _auth.sessionGeneration) {
          scheduleMicrotask(_synchronizePolicy);
        }
      }
    }

    if (_coldStartPending) {
      _coldStartPending = false;
      _timer?.cancel();
      locked = true;
      reason = AppLockReason.coldStart;
      requiresEnrollment = !_security.gesturePasswordConfigured;
      notifyListeners();
      return;
    }

    if (shouldTrackInactivity) {
      recordInteraction();
    } else {
      _timer?.cancel();
    }
  }

  bool _isCurrentSession(int generation) =>
      !_disposed &&
      _auth.isAuthenticated &&
      generation == _auth.sessionGeneration;

  void _scheduleLock([
    Duration delay = LocalSecurityController.autoLockTimeout,
  ]) {
    _timer?.cancel();
    _timer = Timer(delay, _handleInactivityDeadline);
  }

  void _handleInactivityDeadline() {
    if (!shouldTrackInactivity || locked || _disposed) return;
    final inactiveFor = _clock().difference(_lastInteraction);
    if (inactiveFor >= LocalSecurityController.autoLockTimeout) {
      locked = true;
      reason = AppLockReason.inactivity;
      requiresEnrollment = !_security.gesturePasswordConfigured;
      notifyListeners();
      return;
    }
    _scheduleLock(LocalSecurityController.autoLockTimeout - inactiveFor);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    if (_started) {
      _auth.removeListener(_synchronizePolicy);
      _security.removeListener(_synchronizePolicy);
    }
    super.dispose();
  }
}
