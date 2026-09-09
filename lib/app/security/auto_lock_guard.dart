// -----------------------------------------------------------------------------
// 文件：auto_lock_guard.dart
// 作用：统一处理后台隐私遮罩、冷启动验证和 10 秒无操作自动锁屏
// 编写时间：2026-07-10
// 维护说明：页面不得各自实现锁屏计时，所有业务页面都位于本守卫下方
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../features/settings/pattern_lock_pad.dart';
import '../../features/settings/settings_controller.dart';
import '../../l10n/l10n.dart';
import 'app_privacy_shield.dart';

class AutoLockGuard extends StatefulWidget {
  const AutoLockGuard({
    super.key,
    required this.authController,
    required this.settingsController,
    required this.child,
  });

  final AuthController authController;
  final SettingsController settingsController;
  final Widget child;

  @override
  State<AutoLockGuard> createState() => _AutoLockGuardState();
}

enum _LockReason { coldStart, inactivity }

class _AutoLockGuardState extends State<AutoLockGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastInteraction = DateTime.now();
  bool _privacyCovered = false;
  bool _locked = false;
  bool _requiresEnrollment = false;
  bool _scopeReady = false;
  bool _syncingScope = false;
  late bool _coldStartPending;
  late bool _hadAuthenticatedSession;
  _LockReason _lockReason = _LockReason.inactivity;

  bool get _shouldTrackInactivity =>
      widget.authController.isAuthenticated &&
      !widget.authController.gestureEnrollmentRequired &&
      _scopeReady &&
      widget.settingsController.autoLockEnabled;

  @override
  void initState() {
    super.initState();
    _coldStartPending = widget.authController.isAuthenticated;
    _hadAuthenticatedSession = widget.authController.isAuthenticated;
    WidgetsBinding.instance.addObserver(this);
    widget.authController.addListener(_synchronizePolicy);
    widget.settingsController.addListener(_synchronizePolicy);
    _synchronizePolicy();
  }

  @override
  void didUpdateWidget(covariant AutoLockGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_synchronizePolicy);
      widget.authController.addListener(_synchronizePolicy);
    }
    if (oldWidget.settingsController != widget.settingsController) {
      oldWidget.settingsController.removeListener(_synchronizePolicy);
      widget.settingsController.addListener(_synchronizePolicy);
    }
    _synchronizePolicy();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleForegroundResume();
      return;
    }

    // inactive 会早于 paused/hidden 到达，必须在这里立即遮挡，
    // 避免 iOS/Android 为应用切换器生成快照时暴露业务页面。
    _timer?.cancel();
    if (!_privacyCovered && mounted) {
      setState(() => _privacyCovered = true);
    }
  }

  void _handleForegroundResume() {
    if (!mounted) {
      return;
    }

    final inactiveFor = DateTime.now().difference(_lastInteraction);
    final shouldLock =
        !_locked &&
        _shouldTrackInactivity &&
        inactiveFor >= SettingsController.autoLockTimeout;

    // 在同一帧里决定“恢复内容”或“进入解锁”，避免先撤掉遮罩
    // 再显示锁屏造成的敏感内容闪现。
    setState(() {
      _privacyCovered = false;
      if (shouldLock) {
        _locked = true;
        _lockReason = _LockReason.inactivity;
        _requiresEnrollment =
            !widget.settingsController.gesturePasswordConfigured;
      }
    });

    if (_locked || !_shouldTrackInactivity) {
      return;
    }
    _scheduleLock(SettingsController.autoLockTimeout - inactiveFor);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    widget.authController.removeListener(_synchronizePolicy);
    widget.settingsController.removeListener(_synchronizePolicy);
    super.dispose();
  }

  void _synchronizePolicy() {
    unawaited(_synchronizePolicyAsync());
  }

  Future<void> _synchronizePolicyAsync() async {
    final auth = widget.authController;
    if (!auth.isAuthenticated) {
      _timer?.cancel();
      if (_hadAuthenticatedSession) {
        _hadAuthenticatedSession = false;
        _scopeReady = false;
        _coldStartPending = false;
        widget.settingsController.clearActiveGestureScope();
      }
      if (_locked && mounted) {
        setState(() => _locked = false);
      }
      return;
    }

    _hadAuthenticatedSession = true;
    if (!_scopeReady) {
      if (_syncingScope) {
        return;
      }
      _syncingScope = true;
      try {
        final profile = auth.session!.profile;
        var activated = await widget.settingsController.activateGestureScope(
          userId: profile.id,
          accountName: profile.accountName,
        );
        if (!activated && _coldStartPending) {
          activated = await widget.settingsController.restoreLastGestureScope();
        }
        if (!activated || !mounted || !auth.isAuthenticated) {
          return;
        }
        _scopeReady = true;
      } finally {
        _syncingScope = false;
      }
    }

    if (_coldStartPending) {
      _coldStartPending = false;
      _timer?.cancel();
      setState(() {
        _locked = true;
        _lockReason = _LockReason.coldStart;
        _requiresEnrollment =
            !widget.settingsController.gesturePasswordConfigured;
      });
      return;
    }

    if (_shouldTrackInactivity) {
      _recordInteraction();
    } else {
      _timer?.cancel();
    }
  }

  void _recordInteraction({bool reschedule = true}) {
    if (!_shouldTrackInactivity || _locked) {
      return;
    }
    _lastInteraction = DateTime.now();
    if (reschedule) {
      _scheduleLock();
    }
  }

  void _scheduleLock([Duration delay = SettingsController.autoLockTimeout]) {
    _timer?.cancel();
    _timer = Timer(delay, _handleInactivityDeadline);
  }

  void _handleInactivityDeadline() {
    if (!_shouldTrackInactivity || _locked) {
      return;
    }
    final inactiveFor = DateTime.now().difference(_lastInteraction);
    if (inactiveFor >= SettingsController.autoLockTimeout) {
      _lock(_LockReason.inactivity);
      return;
    }
    _scheduleLock(SettingsController.autoLockTimeout - inactiveFor);
  }

  void _lock(_LockReason reason) {
    if (!mounted || !_shouldTrackInactivity || _locked) {
      return;
    }
    setState(() {
      _locked = true;
      _lockReason = reason;
      _requiresEnrollment =
          !widget.settingsController.gesturePasswordConfigured;
    });
  }

  void _unlock() {
    if (!mounted) {
      return;
    }
    setState(() {
      _locked = false;
      _requiresEnrollment = false;
    });
    _lastInteraction = DateTime.now();
    if (_shouldTrackInactivity) {
      _scheduleLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordInteraction(),
      // 移动事件只更新时间戳，不在每个触摸采样点反复取消和创建 Timer。
      onPointerMove: (_) => _recordInteraction(reschedule: false),
      onPointerUp: (_) => _recordInteraction(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_locked)
            _LockOverlay(
              settingsController: widget.settingsController,
              reason: _lockReason,
              requiresEnrollment: _requiresEnrollment,
              onUnlocked: _unlock,
              onLogout: widget.authController.logout,
            ),
          if (_privacyCovered) const AppPrivacyShield(),
        ],
      ),
    );
  }
}

class _LockOverlay extends StatefulWidget {
  const _LockOverlay({
    required this.settingsController,
    required this.reason,
    required this.requiresEnrollment,
    required this.onUnlocked,
    required this.onLogout,
  });

  final SettingsController settingsController;
  final _LockReason reason;
  final bool requiresEnrollment;
  final VoidCallback onUnlocked;
  final Future<void> Function() onLogout;

  @override
  State<_LockOverlay> createState() => _LockOverlayState();
}

enum _EnrollmentStep { drawNew, tooShort, confirm, mismatch }

class _LockOverlayState extends State<_LockOverlay> {
  var _padKey = 0;
  String? _message;
  List<int>? _firstPattern;
  _EnrollmentStep _enrollmentStep = _EnrollmentStep.drawNew;
  bool _busy = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.requiresEnrollment &&
        widget.settingsController.unlockMethod != UnlockMethod.gesture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _unlockWithBiometrics();
        }
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.settingsController.authenticateWithBiometrics(
      method: widget.settingsController.unlockMethod,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _message =
          widget.settingsController.lastBiometricError ??
          context.l10n.biometricFailed;
    });
  }

  Future<void> _verifyGesture(List<int> pattern) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.settingsController.verifyGesturePassword(pattern);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      widget.onUnlocked();
      return;
    }
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      setState(() => _busy = true);
      await widget.settingsController.clearGesturePassword();
      await widget.onLogout();
      return;
    }
    setState(() {
      _message = context.l10n.gestureIncorrect;
      _padKey++;
    });
  }

  Future<void> _handleEnrollment(List<int> pattern) async {
    if (_busy) {
      return;
    }
    if (pattern.length < 4) {
      setState(() {
        _enrollmentStep = _EnrollmentStep.tooShort;
        _padKey++;
      });
      return;
    }
    final first = _firstPattern;
    if (first == null) {
      setState(() {
        _firstPattern = pattern;
        _enrollmentStep = _EnrollmentStep.confirm;
        _padKey++;
      });
      return;
    }
    if (!_samePattern(first, pattern)) {
      setState(() {
        _firstPattern = null;
        _enrollmentStep = _EnrollmentStep.mismatch;
        _padKey++;
      });
      return;
    }
    setState(() => _busy = true);
    await widget.settingsController.saveGesturePassword(pattern);
    if (!mounted) {
      return;
    }
    widget.onUnlocked();
  }

  bool _samePattern(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  String _enrollmentMessage(BuildContext context) => switch (_enrollmentStep) {
    _EnrollmentStep.drawNew => context.l10n.gestureDrawNew,
    _EnrollmentStep.tooShort => context.l10n.gestureTooShort,
    _EnrollmentStep.confirm => context.l10n.gestureConfirm,
    _EnrollmentStep.mismatch => context.l10n.gestureMismatch,
  };

  @override
  Widget build(BuildContext context) {
    final enrollment = widget.requiresEnrollment;
    final unlockMethod = widget.settingsController.unlockMethod;
    final usesBiometric = !enrollment && unlockMethod != UnlockMethod.gesture;
    final title = _title(context, enrollment, unlockMethod);
    final description = _description(context, enrollment, unlockMethod);

    return Material(
      color: Colors.white.withValues(alpha: 0.985),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    enrollment || unlockMethod == UnlockMethod.gesture
                        ? Icons.pattern_outlined
                        : unlockMethod == UnlockMethod.face
                        ? Icons.face_outlined
                        : Icons.fingerprint,
                    size: 56,
                    color: const Color(0xFF5E93E5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    enrollment ? _enrollmentMessage(context) : (_message ?? ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enrollment || _message == null
                          ? const Color(0xFF60646C)
                          : const Color(0xFFB3261E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!usesBiometric)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 328),
                        child: IgnorePointer(
                          ignoring: _busy,
                          child: PatternLockPad(
                            key: ValueKey(_padKey),
                            onCompleted: enrollment
                                ? _handleEnrollment
                                : _verifyGesture,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (usesBiometric)
                    FilledButton.icon(
                      onPressed: _busy ? null : _unlockWithBiometrics,
                      icon: Icon(
                        unlockMethod == UnlockMethod.face
                            ? Icons.face_outlined
                            : Icons.fingerprint,
                      ),
                      label: Text(
                        unlockMethod == UnlockMethod.face
                            ? context.l10n.faceUnlock
                            : context.l10n.fingerprintUnlock,
                      ),
                    ),
                  TextButton(
                    onPressed: _busy ? null : widget.onLogout,
                    child: Text(context.l10n.logout),
                  ),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(
    BuildContext context,
    bool enrollment,
    UnlockMethod unlockMethod,
  ) {
    if (enrollment) {
      return context.l10n.setGesturePassword;
    }
    return switch (unlockMethod) {
      UnlockMethod.face => context.l10n.faceVerificationTitle,
      UnlockMethod.fingerprint => context.l10n.fingerprintVerificationTitle,
      UnlockMethod.gesture =>
        widget.reason == _LockReason.coldStart
            ? context.l10n.coldStartLocked
            : context.l10n.autoLocked,
    };
  }

  String _description(
    BuildContext context,
    bool enrollment,
    UnlockMethod unlockMethod,
  ) {
    if (enrollment) {
      return context.l10n.gestureRequiredMessage;
    }
    return switch (unlockMethod) {
      UnlockMethod.face => context.l10n.faceVerificationMessage,
      UnlockMethod.fingerprint => context.l10n.fingerprintVerificationMessage,
      UnlockMethod.gesture =>
        widget.reason == _LockReason.coldStart
            ? context.l10n.coldStartLockedMessage
            : context.l10n.gestureAutoLockedMessage,
    };
  }
}
