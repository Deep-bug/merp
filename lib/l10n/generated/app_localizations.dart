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

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

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

  /// No description provided for @resourceUpdate.
  ///
  /// In zh, this message translates to:
  /// **'静态资源热更新演示'**
  String get resourceUpdate;

  /// No description provided for @resourceUpdateSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本地模拟资源清单更新首页背景和图标颜色'**
  String get resourceUpdateSubtitle;

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

  /// No description provided for @versionResult.
  ///
  /// In zh, this message translates to:
  /// **'{message}\n当前版本：{currentVersion}\n最新版本：{latestVersion}'**
  String versionResult(
    String message,
    String currentVersion,
    String latestVersion,
  );

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
  /// **'后端没有返回全部功能数据，请检查菜单权限接口。'**
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

  /// No description provided for @openSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get openSystemSettings;

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

  /// No description provided for @resourceVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前资源版本'**
  String get resourceVersion;

  /// No description provided for @resourceSource.
  ///
  /// In zh, this message translates to:
  /// **'资源来源'**
  String get resourceSource;

  /// No description provided for @resourceUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get resourceUpdatedAt;

  /// No description provided for @builtInResource.
  ///
  /// In zh, this message translates to:
  /// **'内置资源'**
  String get builtInResource;

  /// No description provided for @applyEmerald.
  ///
  /// In zh, this message translates to:
  /// **'应用绿色资源包'**
  String get applyEmerald;

  /// No description provided for @applyViolet.
  ///
  /// In zh, this message translates to:
  /// **'应用紫色资源包'**
  String get applyViolet;

  /// No description provided for @resetResource.
  ///
  /// In zh, this message translates to:
  /// **'重置资源'**
  String get resetResource;

  /// No description provided for @manualResourceJson.
  ///
  /// In zh, this message translates to:
  /// **'手动资源清单 JSON'**
  String get manualResourceJson;

  /// No description provided for @resourceJsonHint.
  ///
  /// In zh, this message translates to:
  /// **'修改颜色值后点击“应用 JSON”，即可模拟后端下发资源清单。'**
  String get resourceJsonHint;

  /// No description provided for @applyJson.
  ///
  /// In zh, this message translates to:
  /// **'应用 JSON'**
  String get applyJson;

  /// No description provided for @viewHome.
  ///
  /// In zh, this message translates to:
  /// **'查看首页'**
  String get viewHome;

  /// No description provided for @resourceUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'资源更新失败：{error}'**
  String resourceUpdateFailed(String error);

  /// No description provided for @emeraldApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用绿色资源包，返回首页查看变化'**
  String get emeraldApplied;

  /// No description provided for @violetApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用紫色资源包，返回首页查看变化'**
  String get violetApplied;

  /// No description provided for @resourceReset.
  ///
  /// In zh, this message translates to:
  /// **'已恢复内置默认资源'**
  String get resourceReset;

  /// No description provided for @jsonApplied.
  ///
  /// In zh, this message translates to:
  /// **'已应用 JSON 资源清单，返回首页查看变化'**
  String get jsonApplied;

  /// No description provided for @sourceBuiltIn.
  ///
  /// In zh, this message translates to:
  /// **'内置默认资源'**
  String get sourceBuiltIn;

  /// No description provided for @sourceCache.
  ///
  /// In zh, this message translates to:
  /// **'本地缓存资源'**
  String get sourceCache;

  /// No description provided for @sourceCacheFallback.
  ///
  /// In zh, this message translates to:
  /// **'缓存解析失败，已回退默认资源'**
  String get sourceCacheFallback;

  /// No description provided for @sourceManualJson.
  ///
  /// In zh, this message translates to:
  /// **'手动粘贴 JSON'**
  String get sourceManualJson;

  /// No description provided for @sourceEmerald.
  ///
  /// In zh, this message translates to:
  /// **'本地模拟绿色资源包'**
  String get sourceEmerald;

  /// No description provided for @sourceViolet.
  ///
  /// In zh, this message translates to:
  /// **'本地模拟紫色资源包'**
  String get sourceViolet;

  /// No description provided for @sourceReset.
  ///
  /// In zh, this message translates to:
  /// **'已重置为内置默认资源'**
  String get sourceReset;
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
      <String>['zh'].contains(locale.languageCode);

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
