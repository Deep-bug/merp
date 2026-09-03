// -----------------------------------------------------------------------------
// 文件：Flutter 官方 gen_l10n 自动生成的国际化代码
// 作用：为 MERP 提供强类型多语言文案访问接口
// 编写时间：2026-07-10
// 维护说明：请修改 lib/l10n/arb/*.arb，禁止直接编辑本文件
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'MERP'**
  String get appTitle;

  /// No description provided for @workbench.
  ///
  /// In zh, this message translates to:
  /// **'企业移动工作台'**
  String get workbench;

  /// No description provided for @loadingWorkbench.
  ///
  /// In zh, this message translates to:
  /// **'正在加载企业工作台'**
  String get loadingWorkbench;

  /// No description provided for @restoringSession.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复登录状态'**
  String get restoringSession;

  /// No description provided for @localNetworkChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在连接公司内网'**
  String get localNetworkChecking;

  /// No description provided for @localNetworkRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要本地网络权限'**
  String get localNetworkRequiredTitle;

  /// No description provided for @localNetworkRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'MERP 需要访问本地网络才能连接公司服务器。请允许本地网络访问，并确认已连接公司 Wi-Fi 或 VPN。'**
  String get localNetworkRequiredMessage;

  /// No description provided for @localNetworkUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法连接公司内网'**
  String get localNetworkUnavailableTitle;

  /// No description provided for @localNetworkUnavailableMessage.
  ///
  /// In zh, this message translates to:
  /// **'请检查公司 Wi-Fi、VPN 和服务器状态后重试。'**
  String get localNetworkUnavailableMessage;

  /// No description provided for @openSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get openSystemSettings;

  /// No description provided for @startupFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get startupFailed;

  /// No description provided for @startupFailedMessage.
  ///
  /// In zh, this message translates to:
  /// **'应用初始化没有完成，请检查本地配置、网络或后端服务状态。'**
  String get startupFailedMessage;

  /// No description provided for @clearSessionAndLogin.
  ///
  /// In zh, this message translates to:
  /// **'清除登录状态并进入登录页'**
  String get clearSessionAndLogin;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @loggingIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中…'**
  String get loggingIn;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get account;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In zh, this message translates to:
  /// **'显示密码'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In zh, this message translates to:
  /// **'隐藏密码'**
  String get hidePassword;

  /// No description provided for @captcha.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get captcha;

  /// No description provided for @refreshCaptcha.
  ///
  /// In zh, this message translates to:
  /// **'点击刷新验证码'**
  String get refreshCaptcha;

  /// No description provided for @captchaLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码加载失败，点击重试'**
  String get captchaLoadFailed;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败'**
  String get loginFailed;

  /// No description provided for @loginAccountRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入账号'**
  String get loginAccountRequiredTitle;

  /// No description provided for @loginAccountRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的登录账号后继续。'**
  String get loginAccountRequiredMessage;

  /// No description provided for @loginPasswordRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get loginPasswordRequiredTitle;

  /// No description provided for @loginPasswordRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'请输入账号对应的登录密码后继续。'**
  String get loginPasswordRequiredMessage;

  /// No description provided for @loginCaptchaRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入验证码'**
  String get loginCaptchaRequiredTitle;

  /// No description provided for @loginCaptchaRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'请输入右侧图片中的验证码后继续。'**
  String get loginCaptchaRequiredMessage;

  /// No description provided for @legalConsentRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'请同意相关声明'**
  String get legalConsentRequiredTitle;

  /// No description provided for @legalConsentRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'请勾选“我已阅读并同意《版权及免责声明》《个资法声明》”后继续登录。'**
  String get legalConsentRequiredMessage;

  /// No description provided for @captchaPreparingTitle.
  ///
  /// In zh, this message translates to:
  /// **'验证码正在加载'**
  String get captchaPreparingTitle;

  /// No description provided for @captchaPreparingMessage.
  ///
  /// In zh, this message translates to:
  /// **'请等待验证码加载完成，或点击验证码图片重新获取。'**
  String get captchaPreparingMessage;

  /// No description provided for @copyrightDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'版权及免责声明'**
  String get copyrightDisclaimer;

  /// No description provided for @personalDataStatement.
  ///
  /// In zh, this message translates to:
  /// **'个资法声明'**
  String get personalDataStatement;

  /// No description provided for @legalConsentPrefix.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意'**
  String get legalConsentPrefix;

  /// No description provided for @menu.
  ///
  /// In zh, this message translates to:
  /// **'菜单'**
  String get menu;

  /// No description provided for @profile.
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get profile;

  /// No description provided for @currentUser.
  ///
  /// In zh, this message translates to:
  /// **'当前用户'**
  String get currentUser;

  /// No description provided for @userId.
  ///
  /// In zh, this message translates to:
  /// **'用户编号'**
  String get userId;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get phone;

  /// No description provided for @notProvided.
  ///
  /// In zh, this message translates to:
  /// **'未提供'**
  String get notProvided;

  /// No description provided for @departmentNotProvided.
  ///
  /// In zh, this message translates to:
  /// **'未提供部门信息'**
  String get departmentNotProvided;

  /// No description provided for @fieldWork.
  ///
  /// In zh, this message translates to:
  /// **'外勤管理'**
  String get fieldWork;

  /// No description provided for @fieldWorkSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'任务、定位、工单一站处理'**
  String get fieldWorkSubtitle;

  /// No description provided for @dataAssets.
  ///
  /// In zh, this message translates to:
  /// **'数据资产'**
  String get dataAssets;

  /// No description provided for @dataAssetsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'客户、设备、盘点统一入口'**
  String get dataAssetsSubtitle;

  /// No description provided for @noFeatures.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用功能'**
  String get noFeatures;

  /// No description provided for @noFeaturesMessage.
  ///
  /// In zh, this message translates to:
  /// **'后端没有返回任何功能清单，请确认菜单接口或刷新后重试。'**
  String get noFeaturesMessage;

  /// No description provided for @noAuthorizedFeatures.
  ///
  /// In zh, this message translates to:
  /// **'暂无授权功能'**
  String get noAuthorizedFeatures;

  /// No description provided for @noAuthorizedFeaturesMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前账号暂时没有可打开的常用功能，可进入更多查看全部功能授权状态。'**
  String get noAuthorizedFeaturesMessage;

  /// No description provided for @noFavoriteFeatures.
  ///
  /// In zh, this message translates to:
  /// **'尚未收藏首页功能'**
  String get noFavoriteFeatures;

  /// No description provided for @noFavoriteFeaturesMessage.
  ///
  /// In zh, this message translates to:
  /// **'请进入更多功能，点击图标右上角的星标添加到首页。'**
  String get noFavoriteFeaturesMessage;

  /// No description provided for @favoriteFeature.
  ///
  /// In zh, this message translates to:
  /// **'收藏到首页'**
  String get favoriteFeature;

  /// No description provided for @unfavoriteFeature.
  ///
  /// In zh, this message translates to:
  /// **'取消首页收藏'**
  String get unfavoriteFeature;

  /// No description provided for @favoriteRequiresPermission.
  ///
  /// In zh, this message translates to:
  /// **'未授权功能不能收藏到首页'**
  String get favoriteRequiresPermission;

  /// No description provided for @featurePermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'没有权限，无法使用'**
  String get featurePermissionDenied;

  /// No description provided for @permissionDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法使用'**
  String get permissionDialogTitle;

  /// No description provided for @featurePermissionDeniedMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前账号没有“{title}”的访问权限，请联系管理员开通后重试。'**
  String featurePermissionDeniedMessage(String title);

  /// No description provided for @favoritePermissionDeniedMessage.
  ///
  /// In zh, this message translates to:
  /// **'“{title}”尚未授权，暂时不能添加到首页。'**
  String favoritePermissionDeniedMessage(String title);

  /// No description provided for @favoriteFeatureOrder.
  ///
  /// In zh, this message translates to:
  /// **'首页应用'**
  String get favoriteFeatureOrder;

  /// No description provided for @favoriteFeatureOrderHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动图标调整显示排序'**
  String get favoriteFeatureOrderHint;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @missingRoute.
  ///
  /// In zh, this message translates to:
  /// **'功能路由未配置'**
  String get missingRoute;

  /// No description provided for @missingRouteMessage.
  ///
  /// In zh, this message translates to:
  /// **'功能“{title}”没有配置 route，请联系管理员检查菜单配置。'**
  String missingRouteMessage(String title);

  /// No description provided for @acknowledge.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get acknowledge;

  /// No description provided for @systemSettings.
  ///
  /// In zh, this message translates to:
  /// **'系统设置'**
  String get systemSettings;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出当前账号？'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'退出后需要重新输入账号、密码和验证码登录。'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logoutConfirmAction;

  /// No description provided for @security.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get security;

  /// No description provided for @enableBiometric.
  ///
  /// In zh, this message translates to:
  /// **'启用指纹解锁'**
  String get enableBiometric;

  /// No description provided for @biometricSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用于自动锁屏后的快速解锁'**
  String get biometricSubtitle;

  /// No description provided for @biometricUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前设备无法启用指纹解锁'**
  String get biometricUnavailable;

  /// No description provided for @biometricUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'无法启用此解锁方式'**
  String get biometricUnavailableTitle;

  /// No description provided for @gestureUnlock.
  ///
  /// In zh, this message translates to:
  /// **'图形密码解锁'**
  String get gestureUnlock;

  /// No description provided for @gestureUnlockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'冷启动和自动锁屏后绘制图形密码'**
  String get gestureUnlockSubtitle;

  /// No description provided for @fingerprintUnlock.
  ///
  /// In zh, this message translates to:
  /// **'指纹解锁'**
  String get fingerprintUnlock;

  /// No description provided for @fingerprintUnlockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'开启时检测设备指纹服务并立即验证'**
  String get fingerprintUnlockSubtitle;

  /// No description provided for @faceUnlock.
  ///
  /// In zh, this message translates to:
  /// **'面容解锁'**
  String get faceUnlock;

  /// No description provided for @faceUnlockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'开启时检测设备面容服务并立即验证'**
  String get faceUnlockSubtitle;

  /// No description provided for @autoLock.
  ///
  /// In zh, this message translates to:
  /// **'自动锁屏'**
  String get autoLock;

  /// No description provided for @autoLockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'开启后 10 秒未操作自动锁屏'**
  String get autoLockSubtitle;

  /// No description provided for @changeGesturePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改图形密码'**
  String get changeGesturePassword;

  /// No description provided for @setGesturePassword.
  ///
  /// In zh, this message translates to:
  /// **'设置图形密码'**
  String get setGesturePassword;

  /// No description provided for @gestureConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已设置手势密码'**
  String get gestureConfigured;

  /// No description provided for @gestureNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未设置手势密码'**
  String get gestureNotConfigured;

  /// No description provided for @general.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get general;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'设置语言'**
  String get language;

  /// No description provided for @switchServer.
  ///
  /// In zh, this message translates to:
  /// **'切换服务器'**
  String get switchServer;

  /// No description provided for @clearWebData.
  ///
  /// In zh, this message translates to:
  /// **'清除 Web 页面与数据'**
  String get clearWebData;

  /// No description provided for @clearWebDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'清除旧页面资源、网页登录状态和离线数据'**
  String get clearWebDataSubtitle;

  /// No description provided for @clearWebDataConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除 Web 页面与数据？'**
  String get clearWebDataConfirmTitle;

  /// No description provided for @clearWebDataConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'将清除旧 Vue 页面缓存、H5 登录状态、草稿和离线数据，但不会退出 MERP App 登录。'**
  String get clearWebDataConfirmMessage;

  /// No description provided for @clearWebDataAction.
  ///
  /// In zh, this message translates to:
  /// **'立即清除'**
  String get clearWebDataAction;

  /// No description provided for @clearWebDataSuccess.
  ///
  /// In zh, this message translates to:
  /// **'Web 页面与数据已清除，请重新打开业务页面。'**
  String get clearWebDataSuccess;

  /// No description provided for @clearWebDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除 Web 页面与数据失败，请稍后重试。'**
  String get clearWebDataFailed;

  /// No description provided for @currentServer.
  ///
  /// In zh, this message translates to:
  /// **'当前：{server}'**
  String currentServer(String server);

  /// No description provided for @selectServer.
  ///
  /// In zh, this message translates to:
  /// **'选择服务器'**
  String get selectServer;

  /// No description provided for @chinaDmz.
  ///
  /// In zh, this message translates to:
  /// **'China DMZ'**
  String get chinaDmz;

  /// No description provided for @hkDmz.
  ///
  /// In zh, this message translates to:
  /// **'HK DMZ'**
  String get hkDmz;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @serverSwitched.
  ///
  /// In zh, this message translates to:
  /// **'已切换至 {server}'**
  String serverSwitched(String server);

  /// No description provided for @serverConfigurationInvalid.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址配置无效，请联系管理员。'**
  String get serverConfigurationInvalid;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @traditionalChinese.
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get traditionalChinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bridgeTest.
  ///
  /// In zh, this message translates to:
  /// **'WebView Bridge 测试'**
  String get bridgeTest;

  /// No description provided for @bridgeTestSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'验证 Vue/H5 页面调用 Flutter 原生能力'**
  String get bridgeTestSubtitle;

  /// No description provided for @versionCheck.
  ///
  /// In zh, this message translates to:
  /// **'版本检测'**
  String get versionCheck;

  /// No description provided for @versionCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'版本检测失败，请稍后重试。'**
  String get versionCheckFailed;

  /// No description provided for @currentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 {version}'**
  String currentVersion(String version);

  /// No description provided for @check.
  ///
  /// In zh, this message translates to:
  /// **'检查'**
  String get check;

  /// No description provided for @newVersion.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get newVersion;

  /// No description provided for @alreadyLatestVersion.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本 {version}'**
  String alreadyLatestVersion(String version);

  /// No description provided for @versionResult.
  ///
  /// In zh, this message translates to:
  /// **'{message}\n当前版本：{currentVersion}\n最新版本：{latestVersion}'**
  String versionResult(
    String message,
    String currentVersion,
    String latestVersion,
  );

  /// No description provided for @forceUpdateTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现必要更新'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前版本过低，需要升级后才能继续使用。'**
  String get forceUpdateMessage;

  /// No description provided for @updateVersion.
  ///
  /// In zh, this message translates to:
  /// **'新版本 {version}'**
  String updateVersion(String version);

  /// No description provided for @updateNotes.
  ///
  /// In zh, this message translates to:
  /// **'更新内容'**
  String get updateNotes;

  /// No description provided for @downloadingUpdate.
  ///
  /// In zh, this message translates to:
  /// **'正在下载新版本'**
  String get downloadingUpdate;

  /// No description provided for @downloadedSize.
  ///
  /// In zh, this message translates to:
  /// **'已下载 {size}'**
  String downloadedSize(String size);

  /// No description provided for @downloadUpdate.
  ///
  /// In zh, this message translates to:
  /// **'下载更新'**
  String get downloadUpdate;

  /// No description provided for @retryDownload.
  ///
  /// In zh, this message translates to:
  /// **'重新下载'**
  String get retryDownload;

  /// No description provided for @continueInstall.
  ///
  /// In zh, this message translates to:
  /// **'继续安装'**
  String get continueInstall;

  /// No description provided for @openInstallAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新打开安装'**
  String get openInstallAgain;

  /// No description provided for @mockDownloadComplete.
  ///
  /// In zh, this message translates to:
  /// **'模拟下载已完成，本次不会创建安装包或打开系统安装器。'**
  String get mockDownloadComplete;

  /// No description provided for @updateNow.
  ///
  /// In zh, this message translates to:
  /// **'立即更新'**
  String get updateNow;

  /// No description provided for @updateFailed.
  ///
  /// In zh, this message translates to:
  /// **'升级未完成，请检查网络后重试。'**
  String get updateFailed;

  /// No description provided for @installPermissionHint.
  ///
  /// In zh, this message translates to:
  /// **'请在系统设置中允许 MERP 安装应用，然后返回继续安装。'**
  String get installPermissionHint;

  /// No description provided for @diagnosticLogs.
  ///
  /// In zh, this message translates to:
  /// **'诊断日志'**
  String get diagnosticLogs;

  /// No description provided for @diagnosticLogsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看请求、异常和故障编号'**
  String get diagnosticLogsSubtitle;

  /// No description provided for @autoLocked.
  ///
  /// In zh, this message translates to:
  /// **'已自动锁屏'**
  String get autoLocked;

  /// No description provided for @autoLockedMessage.
  ///
  /// In zh, this message translates to:
  /// **'10 秒未操作，为保护企业数据已锁定当前会话。'**
  String get autoLockedMessage;

  /// No description provided for @biometricUnlock.
  ///
  /// In zh, this message translates to:
  /// **'指纹解锁'**
  String get biometricUnlock;

  /// No description provided for @continueUsing.
  ///
  /// In zh, this message translates to:
  /// **'继续使用'**
  String get continueUsing;

  /// No description provided for @biometricFailed.
  ///
  /// In zh, this message translates to:
  /// **'指纹验证失败'**
  String get biometricFailed;

  /// No description provided for @gestureIncorrect.
  ///
  /// In zh, this message translates to:
  /// **'手势密码不正确，请重试'**
  String get gestureIncorrect;

  /// No description provided for @gestureVerifyCurrent.
  ///
  /// In zh, this message translates to:
  /// **'请先绘制当前手势密码'**
  String get gestureVerifyCurrent;

  /// No description provided for @coldStartLocked.
  ///
  /// In zh, this message translates to:
  /// **'请验证手势密码'**
  String get coldStartLocked;

  /// No description provided for @coldStartLockedMessage.
  ///
  /// In zh, this message translates to:
  /// **'应用已恢复登录状态，验证成功后可继续使用。'**
  String get coldStartLockedMessage;

  /// No description provided for @gestureAutoLockedMessage.
  ///
  /// In zh, this message translates to:
  /// **'10 秒未操作，请绘制图形密码继续使用。'**
  String get gestureAutoLockedMessage;

  /// No description provided for @fingerprintVerificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'请验证指纹'**
  String get fingerprintVerificationTitle;

  /// No description provided for @fingerprintVerificationMessage.
  ///
  /// In zh, this message translates to:
  /// **'请使用当前设备已录入的指纹继续使用 MERP。'**
  String get fingerprintVerificationMessage;

  /// No description provided for @faceVerificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'请验证面容'**
  String get faceVerificationTitle;

  /// No description provided for @faceVerificationMessage.
  ///
  /// In zh, this message translates to:
  /// **'请使用当前设备已录入的面容继续使用 MERP。'**
  String get faceVerificationMessage;

  /// No description provided for @gestureRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'首次使用需要设置手势密码，完成后进入首页。'**
  String get gestureRequiredMessage;

  /// No description provided for @gestureDrawNew.
  ///
  /// In zh, this message translates to:
  /// **'请绘制新的手势密码，至少连接 4 个点'**
  String get gestureDrawNew;

  /// No description provided for @gestureTooShort.
  ///
  /// In zh, this message translates to:
  /// **'手势密码至少需要连接 4 个点'**
  String get gestureTooShort;

  /// No description provided for @gestureConfirm.
  ///
  /// In zh, this message translates to:
  /// **'请再次绘制相同手势以确认'**
  String get gestureConfirm;

  /// No description provided for @gestureMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次手势不一致，请重新设置'**
  String get gestureMismatch;

  /// No description provided for @gestureUpdated.
  ///
  /// In zh, this message translates to:
  /// **'手势密码已更新'**
  String get gestureUpdated;

  /// No description provided for @redraw.
  ///
  /// In zh, this message translates to:
  /// **'重新绘制'**
  String get redraw;

  /// No description provided for @allFeatures.
  ///
  /// In zh, this message translates to:
  /// **'全部功能'**
  String get allFeatures;

  /// No description provided for @manageMyApps.
  ///
  /// In zh, this message translates to:
  /// **'管理我的应用'**
  String get manageMyApps;

  /// No description provided for @noFeatureList.
  ///
  /// In zh, this message translates to:
  /// **'暂无功能清单'**
  String get noFeatureList;

  /// No description provided for @noFeatureListMessage.
  ///
  /// In zh, this message translates to:
  /// **'平台完整功能目录为空，请检查客户端功能配置。'**
  String get noFeatureListMessage;

  /// No description provided for @noFeaturePermission.
  ///
  /// In zh, this message translates to:
  /// **'当前账号没有“{title}”的访问权限'**
  String noFeaturePermission(String title);

  /// No description provided for @authorized.
  ///
  /// In zh, this message translates to:
  /// **'已授权'**
  String get authorized;

  /// No description provided for @unauthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get unauthorized;

  /// No description provided for @noPermission.
  ///
  /// In zh, this message translates to:
  /// **'无访问权限'**
  String get noPermission;

  /// No description provided for @returnWorkbench.
  ///
  /// In zh, this message translates to:
  /// **'返回工作台'**
  String get returnWorkbench;

  /// No description provided for @pageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前路由没有对应页面，请检查后端菜单 route 配置。'**
  String get pageNotFoundMessage;

  /// No description provided for @reportSubscription.
  ///
  /// In zh, this message translates to:
  /// **'报表订阅'**
  String get reportSubscription;

  /// No description provided for @reportSubscriptionReserved.
  ///
  /// In zh, this message translates to:
  /// **'报表订阅功能预留中'**
  String get reportSubscriptionReserved;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @logConsole.
  ///
  /// In zh, this message translates to:
  /// **'诊断日志'**
  String get logConsole;

  /// No description provided for @logEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前暂无诊断日志'**
  String get logEmpty;

  /// No description provided for @clearLogs.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get clearLogs;

  /// No description provided for @copyLogs.
  ///
  /// In zh, this message translates to:
  /// **'复制日志'**
  String get copyLogs;

  /// No description provided for @logsCopied.
  ///
  /// In zh, this message translates to:
  /// **'诊断日志已复制'**
  String get logsCopied;

  /// No description provided for @errorReference.
  ///
  /// In zh, this message translates to:
  /// **'故障编号：{id}'**
  String errorReference(String id);

  /// No description provided for @viewErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get viewErrorDetails;

  /// No description provided for @hideErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'收起详情'**
  String get hideErrorDetails;

  /// No description provided for @copyErrorReference.
  ///
  /// In zh, this message translates to:
  /// **'复制故障编号'**
  String get copyErrorReference;

  /// No description provided for @errorReferenceCopied.
  ///
  /// In zh, this message translates to:
  /// **'故障编号已复制'**
  String get errorReferenceCopied;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @reload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @backToSettings.
  ///
  /// In zh, this message translates to:
  /// **'返回设置'**
  String get backToSettings;

  /// No description provided for @webViewUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不支持 WebView'**
  String get webViewUnsupported;

  /// No description provided for @bridgeMobileOnly.
  ///
  /// In zh, this message translates to:
  /// **'请在 Android/iOS 手机端验证 Vue 页面调用 Flutter Bridge。'**
  String get bridgeMobileOnly;

  /// No description provided for @bridgeLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'桥接测试页加载失败'**
  String get bridgeLoadFailed;

  /// No description provided for @bridgeLoadFailedMessage.
  ///
  /// In zh, this message translates to:
  /// **'无法打开平台上的 Vue3 桥接测试页，请检查网络、端口、防火墙或 HTTP 明文访问配置。'**
  String get bridgeLoadFailedMessage;

  /// No description provided for @bridgeHttpError.
  ///
  /// In zh, this message translates to:
  /// **'桥接测试页返回异常'**
  String get bridgeHttpError;

  /// No description provided for @bridgeHttpErrorMessage.
  ///
  /// In zh, this message translates to:
  /// **'平台测试页已响应，但 HTTP 状态码不是成功状态。'**
  String get bridgeHttpErrorMessage;

  /// No description provided for @legacyPage.
  ///
  /// In zh, this message translates to:
  /// **'旧系统页面'**
  String get legacyPage;

  /// No description provided for @legacyMobileOnly.
  ///
  /// In zh, this message translates to:
  /// **'旧 Vue 页面需要在 Android/iOS 手机端 WebView 中验证。'**
  String get legacyMobileOnly;

  /// No description provided for @moduleMissing.
  ///
  /// In zh, this message translates to:
  /// **'功能参数缺失'**
  String get moduleMissing;

  /// No description provided for @moduleMissingMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前功能没有传入模块编号，请检查菜单 route 配置。'**
  String get moduleMissingMessage;

  /// No description provided for @featureNotFound.
  ///
  /// In zh, this message translates to:
  /// **'功能不存在'**
  String get featureNotFound;

  /// No description provided for @featureNotFoundMessage.
  ///
  /// In zh, this message translates to:
  /// **'后端菜单中没有找到这个功能，可能是菜单已下线或权限数据过期。'**
  String get featureNotFoundMessage;

  /// No description provided for @legacyForbiddenMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前账号没有打开该功能的权限，请联系管理员调整角色或菜单授权。'**
  String get legacyForbiddenMessage;

  /// No description provided for @urlMissing.
  ///
  /// In zh, this message translates to:
  /// **'页面地址未配置'**
  String get urlMissing;

  /// No description provided for @urlMissingMessage.
  ///
  /// In zh, this message translates to:
  /// **'该功能还没有配置旧 Vue 页面 URL，暂时无法打开。'**
  String get urlMissingMessage;

  /// No description provided for @featureNotIntegrated.
  ///
  /// In zh, this message translates to:
  /// **'功能暂未接入'**
  String get featureNotIntegrated;

  /// No description provided for @featureNotIntegratedMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前旧 Vue 系统根地址还是占位地址，所以旧页面还不能打开。'**
  String get featureNotIntegratedMessage;

  /// No description provided for @invalidUrl.
  ///
  /// In zh, this message translates to:
  /// **'页面地址格式错误'**
  String get invalidUrl;

  /// No description provided for @invalidUrlMessage.
  ///
  /// In zh, this message translates to:
  /// **'旧系统页面地址必须是 http 或 https 地址。'**
  String get invalidUrlMessage;

  /// No description provided for @pageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'页面加载失败'**
  String get pageLoadFailed;

  /// No description provided for @pageLoadFailedMessage.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败、服务器不可达，或旧系统页面暂时不可用。'**
  String get pageLoadFailedMessage;

  /// No description provided for @serverError.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回错误'**
  String get serverError;

  /// No description provided for @legacyNotFoundMessage.
  ///
  /// In zh, this message translates to:
  /// **'旧系统没有找到该页面，请检查菜单 URL 是否正确。'**
  String get legacyNotFoundMessage;

  /// No description provided for @legacyServerErrorMessage.
  ///
  /// In zh, this message translates to:
  /// **'旧系统服务器返回异常状态，请稍后重试或联系管理员。'**
  String get legacyServerErrorMessage;

  /// No description provided for @mapLocation.
  ///
  /// In zh, this message translates to:
  /// **'地图定位'**
  String get mapLocation;

  /// No description provided for @mapPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'地图 SDK 接口占位'**
  String get mapPlaceholder;

  /// No description provided for @currentProvider.
  ///
  /// In zh, this message translates to:
  /// **'当前厂商'**
  String get currentProvider;

  /// No description provided for @mapIntegrationHint.
  ///
  /// In zh, this message translates to:
  /// **'后续接入地图时，实现设备层地图与定位服务即可，业务页面和路由无需跟随第三方插件修改。'**
  String get mapIntegrationHint;

  /// No description provided for @mapPrivacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'使用百度地图前请确认'**
  String get mapPrivacyTitle;

  /// No description provided for @mapPrivacyMessage.
  ///
  /// In zh, this message translates to:
  /// **'地图页面将使用百度地图基础 SDK 加载地图数据，并支持按需精确定位。进入页面不会申请定位权限，只有点击定位按钮或业务页面主动调用时才会弹出系统授权。'**
  String get mapPrivacyMessage;

  /// No description provided for @mapPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'百度地图开放平台隐私政策'**
  String get mapPrivacyPolicy;

  /// No description provided for @mapDecline.
  ///
  /// In zh, this message translates to:
  /// **'暂不使用'**
  String get mapDecline;

  /// No description provided for @mapAgreeAndContinue.
  ///
  /// In zh, this message translates to:
  /// **'同意并继续'**
  String get mapAgreeAndContinue;

  /// No description provided for @mapLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载地图'**
  String get mapLoading;

  /// No description provided for @mapIosOnly.
  ///
  /// In zh, this message translates to:
  /// **'当前演示已配置 Android/iOS 百度地图。Web 需要单独接入 JS SDK 后再启用。'**
  String get mapIosOnly;

  /// No description provided for @mapConfigMissing.
  ///
  /// In zh, this message translates to:
  /// **'地图配置缺失'**
  String get mapConfigMissing;

  /// No description provided for @mapKeyMissing.
  ///
  /// In zh, this message translates to:
  /// **'未读取到当前平台的百度地图 AK，请使用本地配置文件启动应用。'**
  String get mapKeyMissing;

  /// No description provided for @mapLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'地图加载失败'**
  String get mapLoadFailed;

  /// No description provided for @mapLoadTimeout.
  ///
  /// In zh, this message translates to:
  /// **'百度地图在限定时间内没有完成加载，请检查网络、AK 与 iOS Bundle Identifier 是否匹配。'**
  String get mapLoadTimeout;

  /// No description provided for @locateMe.
  ///
  /// In zh, this message translates to:
  /// **'定位到我的位置'**
  String get locateMe;

  /// No description provided for @addressUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂未获取到地址'**
  String get addressUnavailable;

  /// No description provided for @locationResult.
  ///
  /// In zh, this message translates to:
  /// **'精度 ±{accuracy} 米 · {address}'**
  String locationResult(String accuracy, String address);

  /// No description provided for @locationPrivacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'使用精确定位'**
  String get locationPrivacyTitle;

  /// No description provided for @locationPrivacyMessage.
  ///
  /// In zh, this message translates to:
  /// **'该业务将调用百度定位 SDK 获取 BD-09 坐标、定位精度和地址，用于地图、外勤或签到。应用只在本次操作时申请“使用 App 期间”的定位权限，不启用后台定位。'**
  String get locationPrivacyMessage;

  /// No description provided for @locationPrivacyDeclined.
  ///
  /// In zh, this message translates to:
  /// **'用户未同意定位隐私说明'**
  String get locationPrivacyDeclined;

  /// No description provided for @locationFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'定位失败，请稍后重试'**
  String get locationFailedRetry;

  /// No description provided for @scannerTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫码'**
  String get scannerTitle;

  /// No description provided for @scannerPermissionTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限才能扫码'**
  String get scannerPermissionTitle;

  /// No description provided for @scannerPermissionMessage.
  ///
  /// In zh, this message translates to:
  /// **'请在系统设置中允许 MERP 使用相机。'**
  String get scannerPermissionMessage;

  /// No description provided for @scannerStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'扫码相机启动失败'**
  String get scannerStartFailed;

  /// No description provided for @scannerStartFailedMessage.
  ///
  /// In zh, this message translates to:
  /// **'相机暂时无法使用，请稍后重试。'**
  String get scannerStartFailedMessage;

  /// No description provided for @scanOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开系统设置'**
  String get scanOpenSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
