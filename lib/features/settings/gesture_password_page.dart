// -----------------------------------------------------------------------------
// 文件：gesture_password_page.dart
// 作用：处理首次设置和修改手势密码，两种场景共享同一套绘制确认流程
// 编写时间：2026-07-10
// 维护说明：修改密码必须先验证旧手势；首次设置禁止返回或跳过
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_notice.dart';
import 'pattern_lock_pad.dart';

enum GesturePasswordMode { enrollment, change }

class GesturePasswordPage extends StatefulWidget {
  const GesturePasswordPage({
    super.key,
    this.mode = GesturePasswordMode.change,
  });

  static const brandBlue = Color(0xFF5E93E5);

  final GesturePasswordMode mode;

  @override
  State<GesturePasswordPage> createState() => _GesturePasswordPageState();
}

class _GesturePasswordPageState extends State<GesturePasswordPage> {
  List<int>? _firstPattern;
  var _padKey = 0;
  late _GestureStep _step;
  bool _saving = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == GesturePasswordMode.change
        ? _GestureStep.verifyCurrent
        : _GestureStep.drawNew;
  }

  Future<void> _handlePattern(List<int> pattern) async {
    if (_saving) {
      return;
    }
    if (_step == _GestureStep.verifyCurrent) {
      final security = AppScope.of(context).localSecurityController;
      final generation = security.generation;
      final verified = await security.verifyGesturePassword(pattern);
      if (!mounted || generation != security.generation) {
        return;
      }
      if (!verified) {
        _failedAttempts++;
      }
      if (_failedAttempts >= 5) {
        setState(() => _saving = true);
        await security.clearGesturePassword();
        if (!mounted || generation != security.generation) {
          return;
        }
        await AppScope.of(context).authController.logout();
        return;
      }
      setState(() {
        _step = verified ? _GestureStep.drawNew : _GestureStep.currentIncorrect;
        _padKey++;
      });
      return;
    }
    if (_step == _GestureStep.currentIncorrect) {
      setState(() => _step = _GestureStep.verifyCurrent);
      await _handlePattern(pattern);
      return;
    }
    if (pattern.length < 4) {
      setState(() {
        _step = _GestureStep.tooShort;
        _padKey++;
      });
      return;
    }

    final first = _firstPattern;
    if (first == null) {
      setState(() {
        _firstPattern = pattern;
        _step = _GestureStep.confirm;
        _padKey++;
      });
      return;
    }
    if (!_samePattern(first, pattern)) {
      setState(() {
        _firstPattern = null;
        _step = _GestureStep.mismatch;
        _padKey++;
      });
      return;
    }
    await _save(pattern);
  }

  Future<void> _save(List<int> pattern) async {
    setState(() => _saving = true);
    final security = AppScope.of(context).localSecurityController;
    final generation = security.generation;
    var saved = false;
    try {
      saved = await security.saveGesturePassword(pattern);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
    if (!mounted || !saved || generation != security.generation) {
      return;
    }
    AppNotice.show(
      context,
      message: context.l10n.gestureUpdated,
      tone: AppNoticeTone.success,
    );
    if (widget.mode == GesturePasswordMode.enrollment) {
      AppScope.of(context).authController.completeGestureEnrollment();
      context.go(AppRoute.home);
    } else {
      AppNavigator.backTo(context, AppRoute.settings);
    }
  }

  void _resetNewPattern() {
    setState(() {
      _firstPattern = null;
      _step = _GestureStep.drawNew;
      _padKey++;
    });
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

  @override
  Widget build(BuildContext context) {
    final canLeave = widget.mode == GesturePasswordMode.change;
    return PopScope(
      canPop: canLeave,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              children: [
                _GestureHeader(mode: widget.mode),
                const SizedBox(height: 8),
                Text(
                  _step.localized(context),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF60646C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 328,
                        maxHeight: 328,
                      ),
                      child: IgnorePointer(
                        ignoring: _saving,
                        child: PatternLockPad(
                          key: ValueKey(_padKey),
                          onCompleted: _handlePattern,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: _saving
                      ? const Center(child: CircularProgressIndicator())
                      : _step != _GestureStep.verifyCurrent &&
                            _step != _GestureStep.currentIncorrect
                      ? OutlinedButton.icon(
                          onPressed: _resetNewPattern,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.redraw),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GestureHeader extends StatelessWidget {
  const _GestureHeader({required this.mode});

  final GesturePasswordMode mode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (mode == GesturePasswordMode.change)
            Positioned(
              left: -10,
              child: IconButton(
                tooltip: context.l10n.back,
                onPressed: () =>
                    AppNavigator.backTo(context, AppRoute.settings),
                icon: const Icon(Icons.chevron_left, size: 42),
                color: GesturePasswordPage.brandBlue,
              ),
            ),
          Text(
            mode == GesturePasswordMode.enrollment
                ? context.l10n.setGesturePassword
                : context.l10n.changeGesturePassword,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: GesturePasswordPage.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _GestureStep {
  verifyCurrent,
  currentIncorrect,
  drawNew,
  tooShort,
  confirm,
  mismatch,
}

extension on _GestureStep {
  String localized(BuildContext context) => switch (this) {
    _GestureStep.verifyCurrent => context.l10n.gestureVerifyCurrent,
    _GestureStep.currentIncorrect => context.l10n.gestureIncorrect,
    _GestureStep.drawNew => context.l10n.gestureDrawNew,
    _GestureStep.tooShort => context.l10n.gestureTooShort,
    _GestureStep.confirm => context.l10n.gestureConfirm,
    _GestureStep.mismatch => context.l10n.gestureMismatch,
  };
}
