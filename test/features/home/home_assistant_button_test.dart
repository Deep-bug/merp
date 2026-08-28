import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/features/home/widgets/home_assistant_button.dart';

void main() {
  testWidgets('assistant blinks with local frames and remains tappable', (
    tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAssistantButton(
            iconColor: Colors.blue,
            semanticLabel: 'AI搜索',
            onTap: () => tapCount += 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey(false)), findsOneWidget);
    await tester.tap(find.byType(HomeAssistantButton));
    expect(tapCount, 1);

    await tester.pump(const Duration(milliseconds: 2800));
    expect(find.byKey(const ValueKey(true)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey(false)), findsOneWidget);

    // 主动销毁组件，确保眨眼 Timer 随生命周期释放。
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('assistant starts bottom-right and snaps to nearest edge', (
    tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeAssistantOverlay(
            iconColor: Colors.blue,
            semanticLabel: 'AI搜索',
            onTap: () => tapCount += 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final initialPosition = tester.getTopLeft(find.byType(HomeAssistantButton));
    expect(initialPosition.dx, closeTo(714, 0.1));
    expect(initialPosition.dy, closeTo(500, 0.1));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HomeAssistantButton)),
    );
    await gesture.moveBy(const Offset(-250, -110));
    await tester.pump();
    await gesture.moveBy(const Offset(-250, -110));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final snappedPosition = tester.getTopLeft(find.byType(HomeAssistantButton));
    expect(snappedPosition.dx, closeTo(10, 0.1));
    expect(snappedPosition.dy, closeTo(280, 0.1));
    expect(tapCount, 0, reason: '拖动结束不能误触 AI 页面');

    await tester.tap(find.byType(HomeAssistantButton));
    expect(tapCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
