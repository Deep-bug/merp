// -----------------------------------------------------------------------------
// 文件：responsive_layout_test.dart
// 作用：回归验证窄屏、软键盘和大字体下登录及功能网格不会布局溢出
// 编写时间：2026-07-11
// 维护说明：调整登录或功能卡片尺寸时必须保持这些边界场景通过
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/permission_repository.dart';
import 'package:merp/features/home/domain/feature_item.dart';
import 'package:merp/features/home/widgets/home_feature_area.dart';
import 'package:merp/features/login/login_page.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:merp/l10n/generated/app_localizations.dart';
import 'package:merp/shared/adaptive_feature_grid.dart';

import '../helpers/memory_token_store.dart';

void main() {
  testWidgets('login remains scrollable when keyboard reduces screen height', (
    tester,
  ) async {
    _useCompactPhone(tester);
    final auth = _testAuthController();
    final settings = SettingsController(
      logger: AppLogger(),
      useSecureStorage: false,
    );
    addTearDown(auth.dispose);
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _testShell(
        LoginPage(authController: auth, settingsController: settings),
        viewInsets: const EdgeInsets.only(bottom: 300),
        textScale: 1.35,
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('验证码'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home feature cards fit compact screen with large text', (
    tester,
  ) async {
    _useCompactPhone(tester);

    await tester.pumpWidget(
      _testShell(
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(18),
            child: HomeFeatureArea(
              features: [
                FeatureItem(
                  id: 'inventory',
                  title: '库存管理与移动盘点',
                  description: '库存管理',
                  icon: Icons.inventory_2_outlined,
                  permissionCode: 'inventory.view',
                  launchMode: FeatureLaunchMode.native,
                  route: '/inventory',
                ),
                FeatureItem(
                  id: 'approval',
                  title: '采购审批工作台',
                  description: '采购审批',
                  icon: Icons.fact_check_outlined,
                  permissionCode: 'approval.view',
                  launchMode: FeatureLaunchMode.native,
                  route: '/approval',
                ),
              ],
              hasAnyFeature: true,
              hasAuthorizedFeature: true,
              loadStatus: PermissionLoadStatus.loaded,
              onRetry: _noopRetry,
              iconColor: Color(0xFF16A3DE),
            ),
          ),
        ),
        textScale: 1.8,
      ),
    );
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    // 普通卡片保持近似正方形；系统字体放大 1.8 倍时允许增高到 126，
    // 在不恢复旧版窄高卡片的前提下容纳两行标题。
    expect(delegate.mainAxisExtent, greaterThanOrEqualTo(126));
    expect(find.text('更多'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-line RT feature title fits the compact home card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testShell(
        Center(
          child: SizedBox(
            width: 84,
            height: 116,
            child: HomeFeatureCard(
              icon: Icons.manage_search_outlined,
              label: '线索商机(RT)',
              iconColor: const Color(0xFF16A3DE),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('线索商机(RT)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favorite sort grid stays three columns on phone widths', (
    tester,
  ) async {
    late AdaptiveFeatureGridMetrics compactMetrics;
    late AdaptiveFeatureGridMetrics regularMetrics;
    late AdaptiveFeatureGridMetrics selectionMetrics;
    late AdaptiveFeatureGridMetrics desktopMetrics;

    await tester.pumpWidget(
      _testShell(
        Builder(
          builder: (context) {
            compactMetrics = AdaptiveFeatureGridMetrics.favoriteSort(
              context,
              250,
            );
            regularMetrics = AdaptiveFeatureGridMetrics.favoriteSort(
              context,
              360,
            );
            selectionMetrics = AdaptiveFeatureGridMetrics.allFeatures(
              context,
              360,
            );
            desktopMetrics = AdaptiveFeatureGridMetrics.allFeatures(
              context,
              1200,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(compactMetrics.crossAxisCount, 3);
    expect(regularMetrics.crossAxisCount, 3);
    expect(regularMetrics.crossAxisCount, selectionMetrics.crossAxisCount);
    expect(regularMetrics.spacing, selectionMetrics.spacing);
    expect(regularMetrics.mainAxisExtent, selectionMetrics.mainAxisExtent);
    expect(desktopMetrics.crossAxisCount, greaterThan(3));
  });

  test('favorite sort changes target only after crossing cell centers', () {
    const metrics = AdaptiveFeatureGridMetrics(
      crossAxisCount: 3,
      spacing: 10,
      mainAxisExtent: 94,
    );

    expect(
      metrics.nearestIndexForPosition(
        localPosition: const Offset(104, 47),
        availableWidth: 320,
        itemCount: 7,
      ),
      0,
    );
    expect(
      metrics.nearestIndexForPosition(
        localPosition: const Offset(106, 47),
        availableWidth: 320,
        itemCount: 7,
      ),
      1,
    );
    expect(
      metrics.nearestIndexForPosition(
        localPosition: const Offset(160, 98),
        availableWidth: 320,
        itemCount: 7,
      ),
      1,
    );
    expect(
      metrics.nearestIndexForPosition(
        localPosition: const Offset(160, 100),
        availableWidth: 320,
        itemCount: 7,
      ),
      4,
    );
    expect(
      metrics.nearestIndexForPosition(
        localPosition: const Offset(270, 260),
        availableWidth: 320,
        itemCount: 7,
      ),
      6,
    );
  });
}

Future<void> _noopRetry() async {}

AuthController _testAuthController() {
  final logger = AppLogger();
  final tokenStore = MemoryTokenStore();
  final apiClient = ApiClient(
    config: const AppConfig(),
    tokenStore: tokenStore,
    logger: logger,
  );
  final controller = AuthController(
    authRepository: AuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
      logger: logger,
    ),
    permissionRepository: PermissionRepository(
      apiClient: apiClient,
      logger: logger,
    ),
    logger: logger,
  );
  controller.status = AuthStatus.unauthenticated;
  controller.captchaChallenge = CaptchaChallenge(
    captchaId: 'captcha-001',
    imageBytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );
  return controller;
}

Widget _testShell(
  Widget home, {
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context).copyWith(
        viewInsets: viewInsets,
        textScaler: TextScaler.linear(textScale),
      );
      return MediaQuery(data: mediaQuery, child: child!);
    },
    home: home,
  );
}

void _useCompactPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
