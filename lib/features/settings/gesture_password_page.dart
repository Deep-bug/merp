// -----------------------------------------------------------------------------
// 文件：gesture_password_page.dart
// 作用：完成手势密码的首次绘制、二次确认和安全保存流程
// 编写时间：2026-07-10
// 维护说明：密码持久化委托 SettingsController，页面不保存明文轨迹
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';
import 'pattern_lock_pad.dart';

class GesturePasswordPage extends StatefulWidget {
  const GesturePasswordPage({super.key});

  static const brandBlue = Color(0xFF5E93E5);

  @override
  State<GesturePasswordPage> createState() => _GesturePasswordPageState();
}

class _GesturePasswordPageState extends State<GesturePasswordPage> {
  List<int>? _firstPattern;
  var _padKey = 0;
  var _message = _GestureMessage.drawNew;

  void _handlePattern(List<int> pattern) {
    if (pattern.length < 4) {
      setState(() {
        _message = _GestureMessage.tooShort;
        _padKey++;
      });
      return;
    }

    final first = _firstPattern;
    if (first == null) {
      setState(() {
        _firstPattern = pattern;
        _message = _GestureMessage.confirm;
        _padKey++;
      });
      return;
    }

    if (!_samePattern(first, pattern)) {
      setState(() {
        _firstPattern = null;
        _message = _GestureMessage.mismatch;
        _padKey++;
      });
      return;
    }

    _save(pattern);
  }

  Future<void> _save(List<int> pattern) async {
    await AppScope.of(context).settingsController.saveGesturePassword(pattern);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.gestureUpdated)));
    AppNavigator.backTo(context, AppRoute.settings);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          children: [
            const _GestureHeader(),
            const SizedBox(height: 42),
            Text(
              _message.localized(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF60646C),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 34),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: PatternLockPad(
                  key: ValueKey(_padKey),
                  onCompleted: _handlePattern,
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _firstPattern = null;
                  _message = _GestureMessage.drawNew;
                  _padKey++;
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.redraw),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestureHeader extends StatelessWidget {
  const _GestureHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -10,
            child: IconButton(
              tooltip: context.l10n.back,
              onPressed: () => AppNavigator.backTo(context, AppRoute.settings),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: GesturePasswordPage.brandBlue,
            ),
          ),
          Text(
            context.l10n.changeGesturePassword,
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

enum _GestureMessage { drawNew, tooShort, confirm, mismatch }

extension on _GestureMessage {
  String localized(BuildContext context) => switch (this) {
    _GestureMessage.drawNew => context.l10n.gestureDrawNew,
    _GestureMessage.tooShort => context.l10n.gestureTooShort,
    _GestureMessage.confirm => context.l10n.gestureConfirm,
    _GestureMessage.mismatch => context.l10n.gestureMismatch,
  };
}
