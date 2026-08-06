// -----------------------------------------------------------------------------
// 文件：pattern_lock_pad.dart
// 作用：实现可复用的 3x3 手势密码输入与平滑轨迹绘制控件
// 编写时间：2026-07-10
// 维护说明：只返回点位序列；命中判定采用圆形热区，避免方格边界误触
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PatternLockPad extends StatefulWidget {
  const PatternLockPad({
    super.key,
    required this.onCompleted,
    this.enabledColor = const Color(0xFF16A3DE),
    this.disabledColor = const Color(0xFFE0E0E0),
  });

  final ValueChanged<List<int>> onCompleted;
  final Color enabledColor;
  final Color disabledColor;

  @override
  State<PatternLockPad> createState() => _PatternLockPadState();
}

class _PatternLockPadState extends State<PatternLockPad> {
  final List<int> _pattern = [];
  Offset? _lastPointerPosition;
  Offset? _currentPointerPosition;

  void _begin(Offset position, Size size) {
    _lastPointerPosition = position;
    _currentPointerPosition = position;
    _trackSegment(position, position, size);
  }

  void _update(Offset position, Size size) {
    final previous = _lastPointerPosition ?? position;
    _lastPointerPosition = position;
    _trackSegment(previous, position, size);
  }

  void _trackSegment(Offset from, Offset to, Size size) {
    final centers = _centers(size);
    final hitRadius = _hitRadius(size);
    final candidates = <({int index, double progress})>[];

    for (var index = 0; index < centers.length; index++) {
      if (_pattern.contains(index)) {
        continue;
      }
      final progress = _segmentProgress(centers[index], from, to);
      final closest = Offset.lerp(from, to, progress)!;
      if ((centers[index] - closest).distance <= hitRadius) {
        candidates.add((index: index, progress: progress));
      }
    }
    candidates.sort((left, right) => left.progress.compareTo(right.progress));

    setState(() {
      _currentPointerPosition = to;
      for (final candidate in candidates) {
        _addIndex(candidate.index);
      }
    });
  }

  void _finish() {
    final completed = List<int>.unmodifiable(_pattern);
    setState(() {
      _lastPointerPosition = null;
      _currentPointerPosition = null;
    });
    if (completed.isNotEmpty) {
      widget.onCompleted(completed);
    }
  }

  void _addIndex(int index) {
    if (_pattern.contains(index)) {
      return;
    }
    if (_pattern.isNotEmpty) {
      final middle = _middleIndex(_pattern.last, index);
      if (middle != null && !_pattern.contains(middle)) {
        _pattern.add(middle);
      }
    }
    _pattern.add(index);
  }

  List<Offset> _centers(Size size) {
    final cell = size.width / 3;
    return List<Offset>.generate(9, (index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(cell * col + cell / 2, cell * row + cell / 2);
    });
  }

  double _hitRadius(Size size) => math.min(size.width / 3 * 0.32, 38);

  double _segmentProgress(Offset point, Offset from, Offset to) {
    final segment = to - from;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) {
      return 0;
    }
    final relative = point - from;
    return ((relative.dx * segment.dx + relative.dy * segment.dy) /
            lengthSquared)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int? _middleIndex(int from, int to) {
    final fromRow = from ~/ 3;
    final fromCol = from % 3;
    final toRow = to ~/ 3;
    final toCol = to % 3;
    final rowDistance = (fromRow - toRow).abs();
    final colDistance = (fromCol - toCol).abs();
    final crossesMiddle =
        (rowDistance == 2 && colDistance == 0) ||
        (rowDistance == 0 && colDistance == 2) ||
        (rowDistance == 2 && colDistance == 2);
    if (!crossesMiddle) {
      return null;
    }
    return ((fromRow + toRow) ~/ 2) * 3 + ((fromCol + toCol) ~/ 2);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxWidth);
          return RepaintBoundary(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _begin(event.localPosition, size),
              onPointerMove: (event) => _update(event.localPosition, size),
              onPointerUp: (_) => _finish(),
              onPointerCancel: (_) => _finish(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // 参与手势竞技场，防止锁屏覆盖层的滚动容器抢走绘制动作。
                onPanStart: (_) {},
                onPanUpdate: (_) {},
                child: CustomPaint(
                  painter: _PatternPainter(
                    pattern: List<int>.unmodifiable(_pattern),
                    currentPointerPosition: _currentPointerPosition,
                    enabledColor: widget.enabledColor,
                    disabledColor: widget.disabledColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({
    required this.pattern,
    required this.currentPointerPosition,
    required this.enabledColor,
    required this.disabledColor,
  });

  final List<int> pattern;
  final Offset? currentPointerPosition;
  final Color enabledColor;
  final Color disabledColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = List<Offset>.generate(9, (index) {
      final cell = size.width / 3;
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(cell * col + cell / 2, cell * row + cell / 2);
    });

    final linePaint = Paint()
      ..color = enabledColor.withValues(alpha: 0.72)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(size.width * 0.018, 3);
    for (var i = 0; i < pattern.length - 1; i++) {
      canvas.drawLine(centers[pattern[i]], centers[pattern[i + 1]], linePaint);
    }
    if (pattern.isNotEmpty && currentPointerPosition != null) {
      canvas.drawLine(
        centers[pattern.last],
        currentPointerPosition!,
        linePaint,
      );
    }

    for (var i = 0; i < centers.length; i++) {
      final selected = pattern.contains(i);
      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = selected ? enabledColor : disabledColor;
      final innerPaint = Paint()
        ..color = selected ? enabledColor : Colors.white;
      canvas.drawCircle(centers[i], size.width * 0.086, outerPaint);
      canvas.drawCircle(centers[i], size.width * 0.042, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return !listEquals(oldDelegate.pattern, pattern) ||
        oldDelegate.currentPointerPosition != currentPointerPosition ||
        oldDelegate.enabledColor != enabledColor ||
        oldDelegate.disabledColor != disabledColor;
  }
}
