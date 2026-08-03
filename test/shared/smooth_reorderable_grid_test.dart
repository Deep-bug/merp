import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/shared/adaptive_feature_grid.dart';
import 'package:merp/shared/widgets/smooth_reorderable_grid.dart';

void main() {
  const metrics = AdaptiveFeatureGridMetrics(
    crossAxisCount: 3,
    spacing: 10,
    mainAxisExtent: 94,
  );

  testWidgets('reports original ids and indexes after a valid reorder', (
    tester,
  ) async {
    List<String>? originalIds;
    int? oldIndex;
    int? newIndex;

    await tester.pumpWidget(
      _testShell(
        SmoothReorderableGrid<String>(
          items: const ['A', 'B', 'C'],
          itemId: (item) => item,
          itemBuilder: _itemBuilder,
          metrics: metrics,
          dragDelay: const Duration(milliseconds: 100),
          topAutoScrollInset: 0,
          onReorder: (ids, oldValue, newValue) async {
            originalIds = ids;
            oldIndex = oldValue;
            newIndex = newValue;
          },
        ),
      ),
    );

    final start = tester.getCenter(find.text('A'));
    final target = tester.getCenter(find.text('B'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 220));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(originalIds, const ['A', 'B', 'C']);
    expect(oldIndex, 0);
    expect(newIndex, 1);
  });

  testWidgets('restores the original order when dropped outside the grid', (
    tester,
  ) async {
    var saveCount = 0;

    await tester.pumpWidget(
      _testShell(
        SmoothReorderableGrid<String>(
          items: const ['A', 'B', 'C'],
          itemId: (item) => item,
          itemBuilder: _itemBuilder,
          metrics: metrics,
          dragDelay: const Duration(milliseconds: 100),
          topAutoScrollInset: 0,
          onReorder: (ids, oldIndex, newIndex) async {
            saveCount += 1;
          },
        ),
      ),
    );

    final start = tester.getCenter(find.text('A'));
    final target = tester.getCenter(find.text('C'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 220));
    await gesture.moveTo(const Offset(10, 500));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(saveCount, 0);
    expect(
      tester.getTopLeft(find.text('A')).dx,
      lessThan(tester.getTopLeft(find.text('B')).dx),
    );
  });
}

Widget _itemBuilder(BuildContext context, String item) {
  return ColoredBox(
    color: Colors.white,
    child: Center(child: Text(item)),
  );
}

Widget _testShell(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}
