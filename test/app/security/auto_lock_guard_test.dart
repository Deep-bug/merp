// -----------------------------------------------------------------------------
// 文件：auto_lock_guard_test.dart
// 作用：验证应用切换前后台时的隐私遮罩行为
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/security/app_privacy_shield.dart';
import 'package:merp/app/security/auto_lock_guard.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/permission_repository.dart';
import 'package:merp/features/settings/settings_controller.dart';

import '../../helpers/memory_token_store.dart';

void main() {
  testWidgets('未登录且未开启自动锁屏时，进入后台仍立即遮挡敏感内容', (tester) async {
    final logger = AppLogger();
    const config = AppConfig();
    final tokenStore = MemoryTokenStore();
    final apiClient = ApiClient(
      config: config,
      tokenStore: tokenStore,
      logger: logger,
    );
    final permissionRepository = PermissionRepository(
      apiClient: apiClient,
      logger: logger,
    );
    final authController = AuthController(
      authRepository: AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
        logger: logger,
      ),
      permissionRepository: permissionRepository,
      logger: logger,
    )..status = AuthStatus.unauthenticated;
    final settingsController = SettingsController(
      logger: logger,
      useSecureStorage: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AutoLockGuard(
          authController: authController,
          settingsController: settingsController,
          child: const Scaffold(body: Text('敏感业务内容')),
        ),
      ),
    );

    expect(find.byKey(AppPrivacyShield.overlayKey), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byKey(AppPrivacyShield.overlayKey), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.byKey(AppPrivacyShield.overlayKey), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byKey(AppPrivacyShield.overlayKey), findsNothing);
  });
}
