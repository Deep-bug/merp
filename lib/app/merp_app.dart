import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../core/config/app_config.dart';
import '../core/device/camera_service.dart';
import '../core/device/location_service.dart';
import '../features/home/data/permission_repository.dart';
import '../features/settings/pattern_lock_pad.dart';
import '../features/settings/settings_controller.dart';
import '../routing/app_router.dart';
import 'app_scope.dart';
import 'theme/app_theme.dart';

class MerpApp extends StatefulWidget {
  const MerpApp({
    super.key,
    required this.config,
    required this.authController,
    required this.permissionRepository,
    required this.settingsController,
    required this.cameraService,
    required this.locationService,
  });

  final AppConfig config;
  final AuthController authController;
  final PermissionRepository permissionRepository;
  final SettingsController settingsController;
  final CameraService cameraService;
  final LocationService locationService;

  @override
  State<MerpApp> createState() => _MerpAppState();
}

class _MerpAppState extends State<MerpApp> {
  late final AppRouter _appRouter = AppRouter(
    authController: widget.authController,
  );

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: widget.config,
      authController: widget.authController,
      permissionRepository: widget.permissionRepository,
      settingsController: widget.settingsController,
      cameraService: widget.cameraService,
      locationService: widget.locationService,
      child: MaterialApp.router(
        title: 'MERP',
        theme: AppTheme.light(),
        routerConfig: _appRouter.router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return _AutoLockGuard(
            authController: widget.authController,
            settingsController: widget.settingsController,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _AutoLockGuard extends StatefulWidget {
  const _AutoLockGuard({
    required this.authController,
    required this.settingsController,
    required this.child,
  });

  final AuthController authController;
  final SettingsController settingsController;
  final Widget child;

  @override
  State<_AutoLockGuard> createState() => _AutoLockGuardState();
}

class _AutoLockGuardState extends State<_AutoLockGuard> {
  Timer? _timer;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_syncTimer);
    widget.settingsController.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _AutoLockGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_syncTimer);
      widget.authController.addListener(_syncTimer);
    }
    if (oldWidget.settingsController != widget.settingsController) {
      oldWidget.settingsController.removeListener(_syncTimer);
      widget.settingsController.addListener(_syncTimer);
    }
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.authController.removeListener(_syncTimer);
    widget.settingsController.removeListener(_syncTimer);
    super.dispose();
  }

  void _syncTimer() {
    final enabled =
        widget.authController.isAuthenticated &&
        widget.settingsController.autoLockEnabled;
    if (!enabled) {
      _timer?.cancel();
      if (_locked && mounted) {
        setState(() => _locked = false);
      }
      return;
    }
    _resetTimer();
  }

  void _resetTimer() {
    if (!widget.authController.isAuthenticated ||
        !widget.settingsController.autoLockEnabled ||
        _locked) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(SettingsController.autoLockTimeout, () {
      if (mounted && widget.authController.isAuthenticated) {
        setState(() => _locked = true);
      }
    });
  }

  void _unlock() {
    setState(() => _locked = false);
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: Stack(
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
      _message = widget.settingsController.lastBiometricError ?? '指纹验证失败';
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
      _message = '手势密码不正确，请重试';
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                    '已自动锁屏',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10 秒未操作，为保护企业数据已锁定当前会话。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                      label: const Text('指纹解锁'),
                    ),
                  if (!hasGesture &&
                      !widget.settingsController.biometricEnabled)
                    FilledButton.icon(
                      onPressed: widget.onUnlocked,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('继续使用'),
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
