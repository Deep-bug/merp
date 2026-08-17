import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/home/data/feature_badge_controller.dart';

void main() {
  test('keeps only positive counts keyed by feature id', () {
    final controller = FeatureBadgeController(logger: AppLogger());

    controller.replaceCounts({'e-form': 6, 'my-task': 0, '': 9});

    expect(controller.countFor('e-form'), 6);
    expect(controller.countFor('my-task'), 0);
    expect(controller.countFor('missing'), 0);
  });
}
