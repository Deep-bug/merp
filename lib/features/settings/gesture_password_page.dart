import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
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
  var _message = '请绘制新的手势密码，至少连接 4 个点';

  void _handlePattern(List<int> pattern) {
    if (pattern.length < 4) {
      setState(() {
        _message = '手势密码至少需要连接 4 个点';
        _padKey++;
      });
      return;
    }

    final first = _firstPattern;
    if (first == null) {
      setState(() {
        _firstPattern = pattern;
        _message = '请再次绘制相同手势以确认';
        _padKey++;
      });
      return;
    }

    if (!_samePattern(first, pattern)) {
      setState(() {
        _firstPattern = null;
        _message = '两次手势不一致，请重新设置';
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
    ).showSnackBar(const SnackBar(content: Text('手势密码已更新')));
    context.go('/settings');
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
              _message,
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
                  _message = '请绘制新的手势密码，至少连接 4 个点';
                  _padKey++;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重新绘制'),
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
              tooltip: '返回',
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.chevron_left, size: 42),
              color: GesturePasswordPage.brandBlue,
            ),
          ),
          Text(
            '修改图形密码',
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
