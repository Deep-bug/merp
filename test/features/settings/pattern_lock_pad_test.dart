import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/features/settings/pattern_lock_pad.dart';

void main() {
  testWidgets('fast diagonal gesture reliably selects three center points', (
    tester,
  ) async {
    List<int>? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 300,
            child: PatternLockPad(onCompleted: (value) => completed = value),
          ),
        ),
      ),
    );

    final origin = tester.getTopLeft(find.byType(PatternLockPad));
    final gesture = await tester.startGesture(origin + const Offset(50, 50));
    await gesture.moveBy(const Offset(2, 2));
    await gesture.moveTo(origin + const Offset(250, 250));
    await gesture.up();
    await tester.pump();

    expect(completed, [0, 4, 8]);
  });

  testWidgets('touching the empty space between dots selects nothing', (
    tester,
  ) async {
    List<int>? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 300,
            child: PatternLockPad(onCompleted: (value) => completed = value),
          ),
        ),
      ),
    );

    final origin = tester.getTopLeft(find.byType(PatternLockPad));
    await tester.tapAt(origin + const Offset(100, 100));
    await tester.pump();

    expect(completed, isNull);
  });
}
