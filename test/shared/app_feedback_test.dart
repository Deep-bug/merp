import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/l10n/generated/app_localizations.dart';
import 'package:merp/shared/app_dialog.dart';
import 'package:merp/shared/app_error_view.dart';
import 'package:merp/shared/app_notice.dart';

void main() {
  testWidgets('app dialog exposes styled primary and secondary actions', (
    tester,
  ) async {
    var primaryPressed = false;
    var secondaryPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDialog(
            tone: AppDialogTone.warning,
            icon: Icons.lock_outline,
            title: '暂时无法使用',
            message: '当前账号没有访问权限',
            secondaryLabel: '取消',
            onSecondary: () => secondaryPressed = true,
            primaryLabel: '知道了',
            onPrimary: () => primaryPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('暂时无法使用'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.tap(find.text('知道了'));

    expect(secondaryPressed, isTrue);
    expect(primaryPressed, isTrue);
  });

  testWidgets('app notice replaces the currently visible notice', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    AppNotice.show(pageContext, message: '第一条提示');
    await tester.pump();
    AppNotice.show(pageContext, message: '第二条提示', tone: AppNoticeTone.success);
    await tester.pumpAndSettle();

    expect(find.text('第一条提示'), findsNothing);
    expect(find.text('第二条提示'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('error view hides details and renders one fault reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: AppErrorView(
            icon: Icons.error_outline,
            title: '加载失败',
            message: '请稍后重试',
            detail: 'technical detail',
            referenceId: 'MERP-TEST-1',
          ),
        ),
      ),
    );

    expect(find.text('故障编号：MERP-TEST-1'), findsOneWidget);
    expect(find.text('technical detail'), findsNothing);

    await tester.tap(find.text('查看详情'));
    await tester.pumpAndSettle();

    expect(find.text('technical detail'), findsOneWidget);
  });
}
