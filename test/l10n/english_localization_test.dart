import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('English locale exposes translated application copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Text(AppLocalizations.of(context).login),
                Text(AppLocalizations.of(context).captcha),
                Text(AppLocalizations.of(context).systemSettings),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Verification code'), findsOneWidget);
    expect(find.text('System Settings'), findsOneWidget);
  });
}
