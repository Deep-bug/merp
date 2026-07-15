// -----------------------------------------------------------------------------
// 文件：auto_lock_guard.dart
// 作用：统一监听用户操作和前后台状态，执行企业会话自动锁定与解锁
// 编写时间：2026-07-10
// 维护说明：页面不得各自实现锁屏计时，安全策略统一在此维护
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../features/settings/pattern_lock_pad.dart';
import '../../features/settings/settings_controller.dart';
import '../../l10n/l10n.dart';

/// 覆盖在完整路由树外层的自动锁屏守卫。
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

class _AutoLockGuardState extends State<AutoLockGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastInteraction = DateTime.now();
  bool _locked = false;

  bool get _shouldProtectSession =>
      widget.authController.isAuthenticated &&
      widget.settingsController.autoLockEnabled;

  @override
  void initState() {
    super.initState();
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
    if (!_shouldProtectSession || _locked) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final inactiveFor = DateTime.now().difference(_lastInteraction);
      if (inactiveFor >= SettingsController.autoLockTimeout) {
        _lock();
      } else {
        _scheduleLock();
      }
    } else {
      // 后台可能暂停 Dart Timer，因此保留最后操作时间，在恢复时重新计算。
      _timer?.cancel();
    }
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
    if (!_shouldProtectSession) {
      _timer?.cancel();
      if (_locked && mounted) {
        setState(() => _locked = false);
      }
      return;
    }
    _recordInteraction();
  }

  void _recordInteraction() {
    if (!_shouldProtectSession || _locked) {
      return;
    }
    _lastInteraction = DateTime.now();
    _scheduleLock();
  }

  void _scheduleLock() {
    _timer?.cancel();
    _timer = Timer(SettingsController.autoLockTimeout, _lock);
  }

  void _lock() {
    if (mounted && _shouldProtectSession && !_locked) {
      setState(() => _locked = true);
    }
  }

  void _unlock() {
    setState(() => _locked = false);
    _recordInteraction();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordInteraction(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_locked)
            _LockOverlay(
              settingsController: widget.settingsController,
              onUnlocked: _unlock,
            ),
        ],
      ),
    );
  }
}

class _LockOverlay extends StatefulWidget {
  const _LockOverlay({
    required this.settingsController,
    required this.onUnlocked,
  });

  final SettingsController settingsController;
  final VoidCallback onUnlocked;

  @override
  State<_LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<_LockOverlay> {
  var _padKey = 0;
  String? _message;

  Future<void> _unlockWithBiometrics() async {
    final ok = await widget.settingsController.authenticateWithBiometrics();
    if (!mounted) {
      return;
    }
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
    final ok = await widget.settingsController.verifyGesturePassword(pattern);
    if (!mounted) {
      return;
    }
    if (ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _message = context.l10n.gestureIncorrect;
      _padKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasGesture = widget.settingsController.gesturePasswordConfigured;

    return Material(
      color: Colors.white.withValues(alpha: 0.98),
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
                  const Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: Color(0xFF5E93E5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.autoLocked,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.autoLockedMessage,
                    textAlign: TextAlign.center,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ],
                  if (hasGesture) ...[
                    const SizedBox(height: 24),
                    PatternLockPad(
                      key: ValueKey(_padKey),
                      onCompleted: _verifyGesture,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (widget.settingsController.biometricEnabled)
                    FilledButton.icon(
                      onPressed: _unlockWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(context.l10n.biometricUnlock),
                    ),
                  if (!hasGesture &&
                      !widget.settingsController.biometricEnabled)
                    FilledButton.icon(
                      onPressed: widget.onUnlocked,
                      icon: const Icon(Icons.lock_open),
                      label: Text(context.l10n.continueUsing),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
