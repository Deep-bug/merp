import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/resources/runtime_resource_manifest.dart';
import 'package:merp/features/home/widgets/home_banner_carousel.dart';
import 'package:merp/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('PNG banner stretches to fill the existing carousel area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeBannerCarousel(
            manifest: RuntimeResourceManifest.defaults(),
            bannerAssets: const ['assets/branding/splash_background.png'],
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.fill);
    expect(tester.getSize(find.byType(HomeBannerCarousel)).height, 178);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
