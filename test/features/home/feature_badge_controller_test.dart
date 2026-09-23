import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/features/home/data/feature_badge_controller.dart';

void main() {
  test('keeps only positive counts keyed by feature id', () {
    final controller = FeatureBadgeController(logger: AppLogger());

    controller.replaceCounts({
      'e-form': 6,
      'my-task': 0,
      '': 9,
    }, generation: controller.generation);

    expect(controller.countFor('e-form'), 6);
    expect(controller.countFor('my-task'), 0);
    expect(controller.countFor('missing'), 0);
  });

  test('old badge responses cannot repopulate a new session', () {
    final controller = FeatureBadgeController(logger: AppLogger());
    final oldGeneration = controller.generation;
    controller.replaceCounts({'e-form': 6}, generation: oldGeneration);
    controller.clear();
    controller.replaceCounts({'e-form': 9}, generation: oldGeneration);
    expect(controller.countFor('e-form'), 0);
    controller.replaceCounts({'e-form': 2}, generation: controller.generation);
    expect(controller.countFor('e-form'), 2);
  });
}
