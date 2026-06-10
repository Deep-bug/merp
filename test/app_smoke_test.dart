import 'package:flutter_test/flutter_test.dart';
import 'package:merp/app/merp_app.dart';
import 'package:merp/core/auth/auth_controller.dart';
import 'package:merp/core/auth/auth_repository.dart';
import 'package:merp/core/auth/secure_token_store.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/device/camera_service.dart';
import 'package:merp/core/device/location_service.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/home/data/permission_repository.dart';
import 'package:merp/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login page before authentication', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const config = AppConfig();
    final tokenStore = SecureTokenStore();
    final apiClient = ApiClient(config: config, tokenStore: tokenStore);
    final permissions = PermissionRepository(apiClient: apiClient);
    final settings = SettingsController(useSecureStorage: false);
    await settings.load();
    final auth = AuthController(
      authRepository: AuthRepository(
        apiClient: apiClient,
        tokenStore: tokenStore,
      ),
      permissionRepository: permissions,
    );
    auth.status = AuthStatus.unauthenticated;

    await tester.pumpWidget(
      MerpApp(
        config: config,
        authController: auth,
        permissionRepository: permissions,
        settingsController: settings,
        cameraService: CameraService(),
        locationService: LocationService(config: config),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MERP'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
