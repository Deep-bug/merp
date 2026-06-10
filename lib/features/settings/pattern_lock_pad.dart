import 'dart:math' as math;

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

  void _track(Offset position, Size size) {
    final index = _indexFromPosition(position, size);
    if (index == null || _pattern.contains(index)) {
      return;
    }
    setState(() => _pattern.add(index));
  }

  void _finish() {
    if (_pattern.isNotEmpty) {
      widget.onCompleted(List.unmodifiable(_pattern));
    }
  }

  int? _indexFromPosition(Offset position, Size size) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }

    final cell = size.width / 3;
    final col = (position.dx / cell).floor().clamp(0, 2);
    final row = (position.dy / cell).floor().clamp(0, 2);
    return row * 3 + col;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxWidth);
          return GestureDetector(
            onPanStart: (details) => _track(details.localPosition, size),
            onPanUpdate: (details) => _track(details.localPosition, size),
            onPanEnd: (_) => _finish(),
            onTapDown: (details) => _track(details.localPosition, size),
            onTapUp: (_) => _finish(),
            child: CustomPaint(
              painter: _PatternPainter(
                pattern: _pattern,
                enabledColor: widget.enabledColor,
                disabledColor: widget.disabledColor,
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
    required this.enabledColor,
    required this.disabledColor,
  });

  final List<int> pattern;
  final Color enabledColor;
  final Color disabledColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = List.generate(9, (index) {
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

    for (var i = 0; i < centers.length; i++) {
      final selected = pattern.contains(i);
      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = selected ? enabledColor : disabledColor;
      final innerPaint = Paint()
        ..color = selected ? enabledColor : Colors.white;
      canvas.drawCircle(centers[i], size.width * 0.075, outerPaint);
      canvas.drawCircle(centers[i], size.width * 0.035, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.enabledColor != enabledColor ||
        oldDelegate.disabledColor != disabledColor;
  }
}
