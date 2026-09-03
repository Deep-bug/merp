// -----------------------------------------------------------------------------
// 文件：Flutter 官方 gen_l10n 自动生成的国际化代码
// 作用：为 MERP 提供强类型多语言文案访问接口
// 编写时间：2026-07-10
// 维护说明：请修改 lib/l10n/arb/*.arb，禁止直接编辑本文件
// -----------------------------------------------------------------------------

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MERP';

  @override
  String get workbench => 'Enterprise Mobile Workspace';

  @override
  String get loadingWorkbench => 'Loading enterprise workspace';

  @override
  String get restoringSession => 'Restoring your session';

  @override
  String get startupFailed => 'Startup failed';

  @override
  String get startupFailedMessage =>
      'The app could not finish initializing. Check the local configuration, network, or backend service status.';

  @override
  String get clearSessionAndLogin => 'Clear session and go to login';

  @override
  String get login => 'Log in';

  @override
  String get loggingIn => 'Logging in…';

  @override
  String get account => 'Account';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get captcha => 'Verification code';

  @override
  String get refreshCaptcha => 'Tap to refresh the verification code';

  @override
  String get captchaLoadFailed =>
      'Failed to load the verification code. Tap to retry.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginAccountRequiredTitle => 'Enter your account';

  @override
  String get loginAccountRequiredMessage =>
      'Enter your login account to continue.';

  @override
  String get loginPasswordRequiredTitle => 'Enter your password';

  @override
  String get loginPasswordRequiredMessage =>
      'Enter the password for this account to continue.';

  @override
  String get loginCaptchaRequiredTitle => 'Enter the verification code';

  @override
  String get loginCaptchaRequiredMessage =>
      'Enter the verification code shown in the image to continue.';

  @override
  String get legalConsentRequiredTitle => 'Accept the statements';

  @override
  String get legalConsentRequiredMessage =>
      'Select “I have read and agree to the Copyright and Disclaimer and Personal Data Statement” to continue.';

  @override
  String get captchaPreparingTitle => 'Verification code is loading';

  @override
  String get captchaPreparingMessage =>
      'Wait for the verification code to load, or tap the image to request a new one.';

  @override
  String get copyrightDisclaimer => 'Copyright and Disclaimer';

  @override
  String get personalDataStatement => 'Personal Data Statement';

  @override
  String get legalConsentPrefix => 'I have read and agree to';

  @override
  String get menu => 'Menu';

  @override
  String get profile => 'Profile';

  @override
  String get currentUser => 'Current user';

  @override
  String get userId => 'User ID';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Mobile number';

  @override
  String get notProvided => 'Not provided';

  @override
  String get departmentNotProvided => 'Department information not provided';

  @override
  String get fieldWork => 'Field Operations';

  @override
  String get fieldWorkSubtitle =>
      'Manage tasks, locations, and work orders in one place';

  @override
  String get dataAssets => 'Data Assets';

  @override
  String get dataAssetsSubtitle =>
      'Unified access to customers, equipment, and inventory';

  @override
  String get noFeatures => 'No features available';

  @override
  String get noFeaturesMessage =>
      'The backend did not return any features. Check the menu API or refresh and try again.';

  @override
  String get noAuthorizedFeatures => 'No authorized features';

  @override
  String get noAuthorizedFeaturesMessage =>
      'This account currently has no frequently used features available. Open More to review all feature permissions.';

  @override
  String get noFavoriteFeatures => 'No home favorites yet';

  @override
  String get noFavoriteFeaturesMessage =>
      'Open More and tap the star on a feature to add it to the home page.';

  @override
  String get favoriteFeature => 'Add to Home';

  @override
  String get unfavoriteFeature => 'Remove from Home';

  @override
  String get favoriteRequiresPermission =>
      'Unauthorized features cannot be added to Home';

  @override
  String get featurePermissionDenied =>
      'You do not have permission to use this feature';

  @override
  String get permissionDialogTitle => 'Temporarily unavailable';

  @override
  String featurePermissionDeniedMessage(String title) {
    return 'This account does not have access to “$title”. Contact your administrator to request access.';
  }

  @override
  String favoritePermissionDeniedMessage(String title) {
    return '“$title” is not authorized and cannot be added to Home.';
  }

  @override
  String get favoriteFeatureOrder => 'Home Apps';

  @override
  String get favoriteFeatureOrderHint =>
      'Drag icons to change their display order';

  @override
  String get more => 'More';

  @override
  String get missingRoute => 'Feature route is not configured';

  @override
  String missingRouteMessage(String title) {
    return 'The feature “$title” does not have a route. Ask an administrator to check the menu configuration.';
  }

  @override
  String get acknowledge => 'Got it';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get logout => 'Log out';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutConfirmTitle => 'Log out of this account?';

  @override
  String get logoutConfirmMessage =>
      'You will need to enter your account, password, and verification code again.';

  @override
  String get logoutConfirmAction => 'Log out';

  @override
  String get security => 'Security';

  @override
  String get enableBiometric => 'Enable fingerprint unlock';

  @override
  String get biometricSubtitle => 'Quickly unlock after automatic locking';

  @override
  String get biometricUnavailable =>
      'Fingerprint unlock is unavailable on this device';

  @override
  String get biometricUnavailableTitle => 'This unlock method is unavailable';

  @override
  String get gestureUnlock => 'Pattern unlock';

  @override
  String get gestureUnlockSubtitle =>
      'Draw your pattern after a cold start or automatic lock';

  @override
  String get fingerprintUnlock => 'Fingerprint unlock';

  @override
  String get fingerprintUnlockSubtitle =>
      'Checks the device fingerprint service and verifies immediately when enabled';

  @override
  String get faceUnlock => 'Face unlock';

  @override
  String get faceUnlockSubtitle =>
      'Checks the device face recognition service and verifies immediately when enabled';

  @override
  String get autoLock => 'Automatic lock';

  @override
  String get autoLockSubtitle =>
      'Automatically lock after 10 seconds of inactivity';

  @override
  String get changeGesturePassword => 'Change pattern password';

  @override
  String get setGesturePassword => 'Set pattern password';

  @override
  String get gestureConfigured => 'Pattern password configured';

  @override
  String get gestureNotConfigured => 'Pattern password not configured';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get switchServer => 'Switch Server';

  @override
  String get clearWebData => 'Clear Web Pages and Data';

  @override
  String get clearWebDataSubtitle =>
      'Clear legacy page resources, web login state, and offline data';

  @override
  String get clearWebDataConfirmTitle => 'Clear web pages and data?';

  @override
  String get clearWebDataConfirmMessage =>
      'This clears legacy Vue page caches, H5 login state, drafts, and offline data without logging out of the MERP app.';

  @override
  String get clearWebDataAction => 'Clear now';

  @override
  String get clearWebDataSuccess =>
      'Web pages and data have been cleared. Reopen the business page.';

  @override
  String get clearWebDataFailed =>
      'Failed to clear web pages and data. Try again later.';

  @override
  String currentServer(String server) {
    return 'Current: $server';
  }

  @override
  String get selectServer => 'Select Server';

  @override
  String get chinaDmz => 'China DMZ';

  @override
  String get hkDmz => 'HK DMZ';

  @override
  String get confirm => 'Confirm';

  @override
  String serverSwitched(String server) {
    return 'Switched to $server';
  }

  @override
  String get serverConfigurationInvalid =>
      'The server address configuration is invalid. Contact your administrator.';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get english => 'English';

  @override
  String get bridgeTest => 'WebView Bridge Test';

  @override
  String get bridgeTestSubtitle =>
      'Verify Vue/H5 access to Flutter native capabilities';

  @override
  String get versionCheck => 'Check for Updates';

  @override
  String get versionCheckFailed =>
      'Unable to check for updates. Try again later.';

  @override
  String currentVersion(String version) {
    return 'Current version $version';
  }

  @override
  String get check => 'Check';

  @override
  String get newVersion => 'New Version Available';

  @override
  String alreadyLatestVersion(String version) {
    return 'Version $version is up to date';
  }

  @override
  String versionResult(
    String message,
    String currentVersion,
    String latestVersion,
  ) {
    return '$message\nCurrent version: $currentVersion\nLatest version: $latestVersion';
  }

  @override
  String get forceUpdateTitle => 'Required Update Available';

  @override
  String get forceUpdateMessage =>
      'This version is too old. Update the app to continue.';

  @override
  String updateVersion(String version) {
    return 'New version $version';
  }

  @override
  String get updateNotes => 'What\'s New';

  @override
  String get downloadingUpdate => 'Downloading the new version';

  @override
  String downloadedSize(String size) {
    return 'Downloaded $size';
  }

  @override
  String get downloadUpdate => 'Download Update';

  @override
  String get retryDownload => 'Retry Download';

  @override
  String get continueInstall => 'Continue Installation';

  @override
  String get openInstallAgain => 'Open Installer Again';

  @override
  String get mockDownloadComplete =>
      'The simulated download is complete. No installation package was created and the system installer was not opened.';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateFailed =>
      'The update could not be completed. Check your network and try again.';

  @override
  String get installPermissionHint =>
      'Allow MERP to install apps in system settings, then return to continue.';

  @override
  String get diagnosticLogs => 'Diagnostic Logs';

  @override
  String get diagnosticLogsSubtitle =>
      'View requests, errors, and incident IDs';

  @override
  String get autoLocked => 'Automatically Locked';

  @override
  String get autoLockedMessage =>
      'The current session was locked after 10 seconds of inactivity to protect enterprise data.';

  @override
  String get biometricUnlock => 'Fingerprint Unlock';

  @override
  String get continueUsing => 'Continue';

  @override
  String get biometricFailed => 'Fingerprint verification failed';

  @override
  String get gestureIncorrect => 'Incorrect pattern. Try again.';

  @override
  String get gestureVerifyCurrent => 'Draw your current pattern first';

  @override
  String get coldStartLocked => 'Verify your pattern';

  @override
  String get coldStartLockedMessage =>
      'Your session has been restored. Verify successfully to continue.';

  @override
  String get gestureAutoLockedMessage =>
      'The app was inactive for 10 seconds. Draw your pattern to continue.';

  @override
  String get fingerprintVerificationTitle => 'Verify Your Fingerprint';

  @override
  String get fingerprintVerificationMessage =>
      'Use a fingerprint enrolled on this device to continue using MERP.';

  @override
  String get faceVerificationTitle => 'Verify Your Face';

  @override
  String get faceVerificationMessage =>
      'Use face recognition enrolled on this device to continue using MERP.';

  @override
  String get gestureRequiredMessage =>
      'Set a pattern password on first use, then continue to the home page.';

  @override
  String get gestureDrawNew => 'Draw a new pattern connecting at least 4 dots';

  @override
  String get gestureTooShort => 'Your pattern must connect at least 4 dots';

  @override
  String get gestureConfirm => 'Draw the same pattern again to confirm';

  @override
  String get gestureMismatch => 'The patterns do not match. Set them again.';

  @override
  String get gestureUpdated => 'Pattern password updated';

  @override
  String get redraw => 'Redraw';

  @override
  String get allFeatures => 'All Features';

  @override
  String get manageMyApps => 'Manage My Apps';

  @override
  String get noFeatureList => 'No feature catalog';

  @override
  String get noFeatureListMessage =>
      'The platform feature catalog is empty. Check the client feature configuration.';

  @override
  String noFeaturePermission(String title) {
    return 'This account does not have access to “$title”';
  }

  @override
  String get authorized => 'Authorized';

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get noPermission => 'No access';

  @override
  String get returnWorkbench => 'Return to Workspace';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get pageNotFoundMessage =>
      'No page matches this route. Check the route in the backend menu configuration.';

  @override
  String get reportSubscription => 'Report Subscriptions';

  @override
  String get reportSubscriptionReserved =>
      'Report subscriptions are coming soon';

  @override
  String get back => 'Back';

  @override
  String get logConsole => 'Diagnostic Logs';

  @override
  String get logEmpty => 'No diagnostic logs yet';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get copyLogs => 'Copy Logs';

  @override
  String get logsCopied => 'Diagnostic logs copied';

  @override
  String errorReference(String id) {
    return 'Incident ID: $id';
  }

  @override
  String get viewErrorDetails => 'View Details';

  @override
  String get hideErrorDetails => 'Hide Details';

  @override
  String get copyErrorReference => 'Copy Incident ID';

  @override
  String get errorReferenceCopied => 'Incident ID copied';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get reload => 'Reload';

  @override
  String get backToSettings => 'Back to Settings';

  @override
  String get webViewUnsupported => 'WebView is not supported on this platform';

  @override
  String get bridgeMobileOnly =>
      'Verify Vue-to-Flutter Bridge calls on an Android or iOS device.';

  @override
  String get bridgeLoadFailed => 'Failed to load the Bridge test page';

  @override
  String get bridgeLoadFailedMessage =>
      'Unable to open the Vue3 Bridge test page. Check the network, port, firewall, or cleartext HTTP configuration.';

  @override
  String get bridgeHttpError => 'Bridge test page returned an error';

  @override
  String get bridgeHttpErrorMessage =>
      'The test page responded, but its HTTP status was not successful.';

  @override
  String get legacyPage => 'Legacy System Page';

  @override
  String get legacyMobileOnly =>
      'Legacy Vue pages must be verified in WebView on an Android or iOS device.';

  @override
  String get moduleMissing => 'Feature parameter is missing';

  @override
  String get moduleMissingMessage =>
      'No module ID was provided for this feature. Check the route in the menu configuration.';

  @override
  String get featureNotFound => 'Feature Not Found';

  @override
  String get featureNotFoundMessage =>
      'This feature was not found in the backend menu. It may have been removed or its permission data may be outdated.';

  @override
  String get legacyForbiddenMessage =>
      'This account cannot open this feature. Contact your administrator to adjust the role or menu permissions.';

  @override
  String get urlMissing => 'Page URL is not configured';

  @override
  String get urlMissingMessage =>
      'No legacy Vue page URL is configured for this feature.';

  @override
  String get featureNotIntegrated => 'Feature Not Yet Integrated';

  @override
  String get featureNotIntegratedMessage =>
      'The legacy Vue system base URL is still a placeholder, so this page cannot be opened yet.';

  @override
  String get invalidUrl => 'Invalid Page URL';

  @override
  String get invalidUrlMessage =>
      'The legacy system page URL must use http or https.';

  @override
  String get pageLoadFailed => 'Page Load Failed';

  @override
  String get pageLoadFailedMessage =>
      'The network connection failed, the server is unreachable, or the legacy page is temporarily unavailable.';

  @override
  String get serverError => 'Server Error';

  @override
  String get legacyNotFoundMessage =>
      'The legacy system could not find this page. Check the menu URL.';

  @override
  String get legacyServerErrorMessage =>
      'The legacy server returned an error. Try again later or contact your administrator.';

  @override
  String get mapLocation => 'Map and Location';

  @override
  String get mapPlaceholder => 'Map SDK Placeholder';

  @override
  String get currentProvider => 'Current provider';

  @override
  String get mapIntegrationHint =>
      'To integrate a map provider later, implement the device map and location services. Business pages and routes do not need to change with the third-party plugin.';

  @override
  String get mapPrivacyTitle => 'Before Using Baidu Maps';

  @override
  String get mapPrivacyMessage =>
      'This page uses the Baidu Maps SDK to load map data and supports precise location on demand. Location permission is requested only when you tap the location button or a business page requests it.';

  @override
  String get mapPrivacyPolicy => 'Baidu Maps Platform Privacy Policy';

  @override
  String get mapDecline => 'Not Now';

  @override
  String get mapAgreeAndContinue => 'Agree and Continue';

  @override
  String get mapLoading => 'Loading map';

  @override
  String get mapIosOnly =>
      'This demo configures Baidu Maps for Android and iOS. Web support requires a separate JavaScript SDK integration.';

  @override
  String get mapConfigMissing => 'Map Configuration Missing';

  @override
  String get mapKeyMissing =>
      'No Baidu Maps AK was found for this platform. Start the app with the local configuration file.';

  @override
  String get mapLoadFailed => 'Failed to Load Map';

  @override
  String get mapLoadTimeout =>
      'Baidu Maps did not finish loading in time. Check the network, AK, and iOS Bundle Identifier.';

  @override
  String get locateMe => 'Show My Location';

  @override
  String get openSystemSettings => 'Open Settings';

  @override
  String get addressUnavailable => 'Address unavailable';

  @override
  String locationResult(String accuracy, String address) {
    return 'Accuracy ±$accuracy m · $address';
  }

  @override
  String get locationPrivacyTitle => 'Use Precise Location';

  @override
  String get locationPrivacyMessage =>
      'This feature uses the Baidu Location SDK to obtain BD-09 coordinates, accuracy, and address for maps, field operations, or check-in. It requests location permission only for this action while the app is in use and does not enable background location.';

  @override
  String get locationPrivacyDeclined =>
      'Location privacy notice was not accepted';

  @override
  String get locationFailedRetry =>
      'Unable to determine your location. Try again later.';

  @override
  String get scannerTitle => 'Scan';

  @override
  String get scannerPermissionTitle => 'Camera permission is required to scan';

  @override
  String get scannerPermissionMessage =>
      'Allow MERP to use the camera in system settings.';

  @override
  String get scannerStartFailed => 'Failed to Start Scanner';

  @override
  String get scannerStartFailedMessage =>
      'The camera is temporarily unavailable. Try again later.';

  @override
  String get scanOpenSettings => 'Open System Settings';
}
