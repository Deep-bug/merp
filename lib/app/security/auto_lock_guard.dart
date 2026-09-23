// -----------------------------------------------------------------------------
// 文件：auto_lock_guard.dart
// 作用：将应用生命周期和触摸事件转发给锁屏协调器，并绘制锁屏/隐私遮罩
// 编写时间：2026-07-10
// 维护说明：计时与安全域状态位于 AppLockCoordinator，本文件仅负责 UI
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/security/local_security_controller.dart';
import '../../core/security/unlock_method.dart';
import '../../features/settings/pattern_lock_pad.dart';
import '../../l10n/l10n.dart';
import 'app_lock_coordinator.dart';
import 'app_privacy_shield.dart';

class AutoLockGuard extends StatefulWidget {
  const AutoLockGuard({
    super.key,
    required this.authController,
    required this.securityController,
    required this.child,
  });

  final AuthController authController;
  final LocalSecurityController securityController;
  final Widget child;

  @override
  State<AutoLockGuard> createState() => _AutoLockGuardState();
}

class _AutoLockGuardState extends State<AutoLockGuard>
    with WidgetsBindingObserver {
  late AppLockCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createCoordinator();
  }

  @override
  void didUpdateWidget(covariant AutoLockGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController ||
        oldWidget.securityController != widget.securityController) {
      _coordinator.removeListener(_handleStateChanged);
      _coordinator.dispose();
      _createCoordinator();
    }
  }

  void _createCoordinator() {
    _coordinator = AppLockCoordinator(
      auth: widget.authController,
      security: widget.securityController,
    )..addListener(_handleStateChanged);
    _coordinator.start();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _coordinator.resumeFromBackground();
    } else {
      _coordinator.coverForBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.removeListener(_handleStateChanged);
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _coordinator.recordInteraction(),
      // 移动事件只更新时间戳，不在每个触摸采样点反复创建 Timer。
      onPointerMove: (_) => _coordinator.recordInteraction(reschedule: false),
      onPointerUp: (_) => _coordinator.recordInteraction(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_coordinator.locked)
            _LockOverlay(
              key: ValueKey(widget.securityController.generation),
              securityController: widget.securityController,
              reason: _coordinator.reason,
              requiresEnrollment: _coordinator.requiresEnrollment,
              onUnlocked: _coordinator.unlock,
              onLogout: widget.authController.logout,
            ),
          if (_coordinator.privacyCovered) const AppPrivacyShield(),
        ],
      ),
    );
  }
}

class _LockOverlay extends StatefulWidget {
  const _LockOverlay({
    super.key,
    required this.securityController,
    required this.reason,
    required this.requiresEnrollment,
    required this.onUnlocked,
    required this.onLogout,
  });

  final LocalSecurityController securityController;
  final AppLockReason reason;
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
        widget.securityController.unlockMethod != UnlockMethod.gesture) {
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
    final generation = widget.securityController.generation;
    final ok = await widget.securityController.authenticateWithBiometrics(
      method: widget.securityController.unlockMethod,
    );
    if (!mounted || generation != widget.securityController.generation) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _message =
          widget.securityController.lastBiometricError ??
          context.l10n.biometricFailed;
    });
  }

  Future<void> _verifyGesture(List<int> pattern) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final generation = widget.securityController.generation;
    final ok = await widget.securityController.verifyGesturePassword(pattern);
    if (!mounted || generation != widget.securityController.generation) {
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
      await widget.securityController.clearGesturePassword();
      if (!mounted || generation != widget.securityController.generation) {
        return;
      }
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
    final generation = widget.securityController.generation;
    final saved = await widget.securityController.saveGesturePassword(pattern);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (!saved || generation != widget.securityController.generation) {
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
    final unlockMethod = widget.securityController.unlockMethod;
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
        widget.reason == AppLockReason.coldStart
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
        widget.reason == AppLockReason.coldStart
            ? context.l10n.coldStartLockedMessage
            : context.l10n.gestureAutoLockedMessage,
    };
  }
}
