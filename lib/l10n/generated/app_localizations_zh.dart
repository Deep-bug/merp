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

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MERP';

  @override
  String get workbench => '企业移动工作台';

  @override
  String get loadingWorkbench => '正在加载企业工作台';

  @override
  String get restoringSession => '正在恢复登录状态';

  @override
  String get startupFailed => '启动失败';

  @override
  String get startupFailedMessage => '应用初始化没有完成，请检查本地配置、网络或后端服务状态。';

  @override
  String get clearSessionAndLogin => '清除登录状态并进入登录页';

  @override
  String get login => '登录';

  @override
  String get account => '账号';

  @override
  String get password => '密码';

  @override
  String get captcha => '验证码';

  @override
  String get refreshCaptcha => '点击刷新验证码';

  @override
  String get captchaLoadFailed => '验证码加载失败，点击重试';

  @override
  String get loginFailed => '登录失败';

  @override
  String get loginAccountRequiredTitle => '请输入账号';

  @override
  String get loginAccountRequiredMessage => '请输入您的登录账号后继续。';

  @override
  String get loginPasswordRequiredTitle => '请输入密码';

  @override
  String get loginPasswordRequiredMessage => '请输入账号对应的登录密码后继续。';

  @override
  String get loginCaptchaRequiredTitle => '请输入验证码';

  @override
  String get loginCaptchaRequiredMessage => '请输入右侧图片中的验证码后继续。';

  @override
  String get legalConsentRequiredTitle => '请同意相关声明';

  @override
  String get legalConsentRequiredMessage =>
      '请勾选“我已阅读并同意《版权及免责声明》《个资法声明》”后继续登录。';

  @override
  String get captchaPreparingTitle => '验证码正在加载';

  @override
  String get captchaPreparingMessage => '请等待验证码加载完成，或点击验证码图片重新获取。';

  @override
  String get copyrightDisclaimer => '版权及免责声明';

  @override
  String get personalDataStatement => '个资法声明';

  @override
  String get legalConsentPrefix => '我已阅读并同意';

  @override
  String get menu => '菜单';

  @override
  String get profile => '个人中心';

  @override
  String get currentUser => '当前用户';

  @override
  String get userId => '用户编号';

  @override
  String get email => '邮箱';

  @override
  String get phone => '手机号';

  @override
  String get notProvided => '未提供';

  @override
  String get departmentNotProvided => '未提供部门信息';

  @override
  String get fieldWork => '外勤管理';

  @override
  String get fieldWorkSubtitle => '任务、定位、工单一站处理';

  @override
  String get dataAssets => '数据资产';

  @override
  String get dataAssetsSubtitle => '客户、设备、盘点统一入口';

  @override
  String get noFeatures => '暂无可用功能';

  @override
  String get noFeaturesMessage => '后端没有返回任何功能清单，请确认菜单接口或刷新后重试。';

  @override
  String get noAuthorizedFeatures => '暂无授权功能';

  @override
  String get noAuthorizedFeaturesMessage => '当前账号暂时没有可打开的常用功能，可进入更多查看全部功能授权状态。';

  @override
  String get noFavoriteFeatures => '尚未收藏首页功能';

  @override
  String get noFavoriteFeaturesMessage => '请进入更多功能，点击图标右上角的星标添加到首页。';

  @override
  String get favoriteFeature => '收藏到首页';

  @override
  String get unfavoriteFeature => '取消首页收藏';

  @override
  String get favoriteRequiresPermission => '未授权功能不能收藏到首页';

  @override
  String get featurePermissionDenied => '没有权限，无法使用';

  @override
  String get permissionDialogTitle => '暂时无法使用';

  @override
  String featurePermissionDeniedMessage(String title) {
    return '当前账号没有“$title”的访问权限，请联系管理员开通后重试。';
  }

  @override
  String favoritePermissionDeniedMessage(String title) {
    return '“$title”尚未授权，暂时不能添加到首页。';
  }

  @override
  String get favoriteFeatureOrder => '首页应用';

  @override
  String get favoriteFeatureOrderHint => '拖动图标调整显示排序';

  @override
  String get more => '更多';

  @override
  String get missingRoute => '功能路由未配置';

  @override
  String missingRouteMessage(String title) {
    return '功能“$title”没有配置 route，请联系管理员检查菜单配置。';
  }

  @override
  String get acknowledge => '知道了';

  @override
  String get systemSettings => '系统设置';

  @override
  String get logout => '登出';

  @override
  String get cancel => '取消';

  @override
  String get logoutConfirmTitle => '退出当前账号？';

  @override
  String get logoutConfirmMessage => '退出后需要重新输入账号、密码和验证码登录。';

  @override
  String get logoutConfirmAction => '退出登录';

  @override
  String get security => '安全';

  @override
  String get enableBiometric => '启用指纹解锁';

  @override
  String get biometricSubtitle => '用于自动锁屏后的快速解锁';

  @override
  String get biometricUnavailable => '当前设备无法启用指纹解锁';

  @override
  String get biometricUnavailableTitle => '无法启用此解锁方式';

  @override
  String get gestureUnlock => '图形密码解锁';

  @override
  String get gestureUnlockSubtitle => '冷启动和自动锁屏后绘制图形密码';

  @override
  String get fingerprintUnlock => '指纹解锁';

  @override
  String get fingerprintUnlockSubtitle => '开启时检测设备指纹服务并立即验证';

  @override
  String get faceUnlock => '面容解锁';

  @override
  String get faceUnlockSubtitle => '开启时检测设备面容服务并立即验证';

  @override
  String get autoLock => '自动锁屏';

  @override
  String get autoLockSubtitle => '开启后 10 秒未操作自动锁屏';

  @override
  String get changeGesturePassword => '修改图形密码';

  @override
  String get setGesturePassword => '设置图形密码';

  @override
  String get gestureConfigured => '已设置手势密码';

  @override
  String get gestureNotConfigured => '未设置手势密码';

  @override
  String get general => '通用';

  @override
  String get language => '设置语言';

  @override
  String get switchServer => '切换服务器';

  @override
  String get clearWebData => '清除 Web 页面与数据';

  @override
  String get clearWebDataSubtitle => '清除旧页面资源、网页登录状态和离线数据';

  @override
  String get clearWebDataConfirmTitle => '清除 Web 页面与数据？';

  @override
  String get clearWebDataConfirmMessage =>
      '将清除旧 Vue 页面缓存、H5 登录状态、草稿和离线数据，但不会退出 MERP App 登录。';

  @override
  String get clearWebDataAction => '立即清除';

  @override
  String get clearWebDataSuccess => 'Web 页面与数据已清除，请重新打开业务页面。';

  @override
  String get clearWebDataFailed => '清除 Web 页面与数据失败，请稍后重试。';

  @override
  String currentServer(String server) {
    return '当前：$server';
  }

  @override
  String get selectServer => '选择服务器';

  @override
  String get chinaDmz => 'China DMZ';

  @override
  String get hkDmz => 'HK DMZ';

  @override
  String get confirm => '确认';

  @override
  String serverSwitched(String server) {
    return '已切换至 $server';
  }

  @override
  String get serverConfigurationInvalid => '服务器地址配置无效，请联系管理员。';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get bridgeTest => 'WebView Bridge 测试';

  @override
  String get bridgeTestSubtitle => '验证 Vue/H5 页面调用 Flutter 原生能力';

  @override
  String get versionCheck => '版本检测';

  @override
  String get versionCheckFailed => '版本检测失败，请稍后重试。';

  @override
  String currentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get check => '检查';

  @override
  String get newVersion => '发现新版本';

  @override
  String alreadyLatestVersion(String version) {
    return '已是最新版本 $version';
  }

  @override
  String versionResult(
    String message,
    String currentVersion,
    String latestVersion,
  ) {
    return '$message\n当前版本：$currentVersion\n最新版本：$latestVersion';
  }

  @override
  String get diagnosticLogs => '诊断日志';

  @override
  String get diagnosticLogsSubtitle => '查看请求、异常和故障编号';

  @override
  String get autoLocked => '已自动锁屏';

  @override
  String get autoLockedMessage => '10 秒未操作，为保护企业数据已锁定当前会话。';

  @override
  String get biometricUnlock => '指纹解锁';

  @override
  String get continueUsing => '继续使用';

  @override
  String get biometricFailed => '指纹验证失败';

  @override
  String get gestureIncorrect => '手势密码不正确，请重试';

  @override
  String get gestureVerifyCurrent => '请先绘制当前手势密码';

  @override
  String get coldStartLocked => '请验证手势密码';

  @override
  String get coldStartLockedMessage => '应用已恢复登录状态，验证成功后可继续使用。';

  @override
  String get gestureAutoLockedMessage => '10 秒未操作，请绘制图形密码继续使用。';

  @override
  String get fingerprintVerificationTitle => '请验证指纹';

  @override
  String get fingerprintVerificationMessage => '请使用当前设备已录入的指纹继续使用 MERP。';

  @override
  String get faceVerificationTitle => '请验证面容';

  @override
  String get faceVerificationMessage => '请使用当前设备已录入的面容继续使用 MERP。';

  @override
  String get gestureRequiredMessage => '首次使用需要设置手势密码，完成后进入首页。';

  @override
  String get gestureDrawNew => '请绘制新的手势密码，至少连接 4 个点';

  @override
  String get gestureTooShort => '手势密码至少需要连接 4 个点';

  @override
  String get gestureConfirm => '请再次绘制相同手势以确认';

  @override
  String get gestureMismatch => '两次手势不一致，请重新设置';

  @override
  String get gestureUpdated => '手势密码已更新';

  @override
  String get redraw => '重新绘制';

  @override
  String get allFeatures => '全部功能';

  @override
  String get manageMyApps => '管理我的应用';

  @override
  String get noFeatureList => '暂无功能清单';

  @override
  String get noFeatureListMessage => '平台完整功能目录为空，请检查客户端功能配置。';

  @override
  String noFeaturePermission(String title) {
    return '当前账号没有“$title”的访问权限';
  }

  @override
  String get authorized => '已授权';

  @override
  String get unauthorized => '未授权';

  @override
  String get noPermission => '无访问权限';

  @override
  String get returnWorkbench => '返回工作台';

  @override
  String get pageNotFound => '页面不存在';

  @override
  String get pageNotFoundMessage => '当前路由没有对应页面，请检查后端菜单 route 配置。';

  @override
  String get reportSubscription => '报表订阅';

  @override
  String get reportSubscriptionReserved => '报表订阅功能预留中';

  @override
  String get back => '返回';

  @override
  String get logConsole => '诊断日志';

  @override
  String get logEmpty => '当前暂无诊断日志';

  @override
  String get clearLogs => '清空日志';

  @override
  String get copyLogs => '复制日志';

  @override
  String get logsCopied => '诊断日志已复制';

  @override
  String errorReference(String id) {
    return '故障编号：$id';
  }

  @override
  String get viewErrorDetails => '查看详情';

  @override
  String get hideErrorDetails => '收起详情';

  @override
  String get copyErrorReference => '复制故障编号';

  @override
  String get errorReferenceCopied => '故障编号已复制';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get reload => '重新加载';

  @override
  String get backToSettings => '返回设置';

  @override
  String get webViewUnsupported => '当前平台不支持 WebView';

  @override
  String get bridgeMobileOnly =>
      '请在 Android/iOS 手机端验证 Vue 页面调用 Flutter Bridge。';

  @override
  String get bridgeLoadFailed => '桥接测试页加载失败';

  @override
  String get bridgeLoadFailedMessage =>
      '无法打开平台上的 Vue3 桥接测试页，请检查网络、端口、防火墙或 HTTP 明文访问配置。';

  @override
  String get bridgeHttpError => '桥接测试页返回异常';

  @override
  String get bridgeHttpErrorMessage => '平台测试页已响应，但 HTTP 状态码不是成功状态。';

  @override
  String get legacyPage => '旧系统页面';

  @override
  String get legacyMobileOnly => '旧 Vue 页面需要在 Android/iOS 手机端 WebView 中验证。';

  @override
  String get moduleMissing => '功能参数缺失';

  @override
  String get moduleMissingMessage => '当前功能没有传入模块编号，请检查菜单 route 配置。';

  @override
  String get featureNotFound => '功能不存在';

  @override
  String get featureNotFoundMessage => '后端菜单中没有找到这个功能，可能是菜单已下线或权限数据过期。';

  @override
  String get legacyForbiddenMessage => '当前账号没有打开该功能的权限，请联系管理员调整角色或菜单授权。';

  @override
  String get urlMissing => '页面地址未配置';

  @override
  String get urlMissingMessage => '该功能还没有配置旧 Vue 页面 URL，暂时无法打开。';

  @override
  String get featureNotIntegrated => '功能暂未接入';

  @override
  String get featureNotIntegratedMessage => '当前旧 Vue 系统根地址还是占位地址，所以旧页面还不能打开。';

  @override
  String get invalidUrl => '页面地址格式错误';

  @override
  String get invalidUrlMessage => '旧系统页面地址必须是 http 或 https 地址。';

  @override
  String get pageLoadFailed => '页面加载失败';

  @override
  String get pageLoadFailedMessage => '网络连接失败、服务器不可达，或旧系统页面暂时不可用。';

  @override
  String get serverError => '服务器返回错误';

  @override
  String get legacyNotFoundMessage => '旧系统没有找到该页面，请检查菜单 URL 是否正确。';

  @override
  String get legacyServerErrorMessage => '旧系统服务器返回异常状态，请稍后重试或联系管理员。';

  @override
  String get mapLocation => '地图定位';

  @override
  String get mapPlaceholder => '地图 SDK 接口占位';

  @override
  String get currentProvider => '当前厂商';

  @override
  String get mapIntegrationHint => '后续接入地图时，实现设备层地图与定位服务即可，业务页面和路由无需跟随第三方插件修改。';

  @override
  String get mapPrivacyTitle => '使用百度地图前请确认';

  @override
  String get mapPrivacyMessage =>
      '地图页面将使用百度地图基础 SDK 加载地图数据，并支持按需精确定位。进入页面不会申请定位权限，只有点击定位按钮或业务页面主动调用时才会弹出系统授权。';

  @override
  String get mapPrivacyPolicy => '百度地图开放平台隐私政策';

  @override
  String get mapDecline => '暂不使用';

  @override
  String get mapAgreeAndContinue => '同意并继续';

  @override
  String get mapLoading => '正在加载地图';

  @override
  String get mapIosOnly => '当前演示已配置 Android/iOS 百度地图。Web 需要单独接入 JS SDK 后再启用。';

  @override
  String get mapConfigMissing => '地图配置缺失';

  @override
  String get mapKeyMissing => '未读取到当前平台的百度地图 AK，请使用本地配置文件启动应用。';

  @override
  String get mapLoadFailed => '地图加载失败';

  @override
  String get mapLoadTimeout =>
      '百度地图在限定时间内没有完成加载，请检查网络、AK 与 iOS Bundle Identifier 是否匹配。';

  @override
  String get locateMe => '定位到我的位置';

  @override
  String get openSystemSettings => '去设置';

  @override
  String get addressUnavailable => '暂未获取到地址';

  @override
  String locationResult(String accuracy, String address) {
    return '精度 ±$accuracy 米 · $address';
  }

  @override
  String get locationPrivacyTitle => '使用精确定位';

  @override
  String get locationPrivacyMessage =>
      '该业务将调用百度定位 SDK 获取 BD-09 坐标、定位精度和地址，用于地图、外勤或签到。应用只在本次操作时申请“使用 App 期间”的定位权限，不启用后台定位。';

  @override
  String get locationPrivacyDeclined => '用户未同意定位隐私说明';

  @override
  String get locationFailedRetry => '定位失败，请稍后重试';

  @override
  String get scannerTitle => '扫码';

  @override
  String get scannerPermissionTitle => '需要相机权限才能扫码';

  @override
  String get scannerPermissionMessage => '请在系统设置中允许 MERP 使用相机。';

  @override
  String get scannerStartFailed => '扫码相机启动失败';

  @override
  String get scannerStartFailedMessage => '相机暂时无法使用，请稍后重试。';

  @override
  String get scanOpenSettings => '打开系统设置';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'MERP';

  @override
  String get workbench => '企業行動工作臺';

  @override
  String get loadingWorkbench => '正在載入企業工作臺';

  @override
  String get restoringSession => '正在恢復登入狀態';

  @override
  String get startupFailed => '啟動失敗';

  @override
  String get startupFailedMessage => '應用程式初始化未完成，請檢查本機設定、網路或後端服務狀態。';

  @override
  String get clearSessionAndLogin => '清除登入狀態並進入登入頁';

  @override
  String get login => '登入';

  @override
  String get account => '帳號';

  @override
  String get password => '密碼';

  @override
  String get captcha => '驗證碼';

  @override
  String get refreshCaptcha => '點擊重新整理驗證碼';

  @override
  String get captchaLoadFailed => '驗證碼載入失敗，點擊重試';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get loginAccountRequiredTitle => '請輸入帳號';

  @override
  String get loginAccountRequiredMessage => '請輸入您的登入帳號後繼續。';

  @override
  String get loginPasswordRequiredTitle => '請輸入密碼';

  @override
  String get loginPasswordRequiredMessage => '請輸入帳號對應的登入密碼後繼續。';

  @override
  String get loginCaptchaRequiredTitle => '請輸入驗證碼';

  @override
  String get loginCaptchaRequiredMessage => '請輸入右側圖片中的驗證碼後繼續。';

  @override
  String get legalConsentRequiredTitle => '請同意相關聲明';

  @override
  String get legalConsentRequiredMessage =>
      '請勾選「我已閱讀並同意《版權及免責聲明》《個資法聲明》」後繼續登入。';

  @override
  String get captchaPreparingTitle => '驗證碼正在載入';

  @override
  String get captchaPreparingMessage => '請等待驗證碼載入完成，或點選驗證碼圖片重新取得。';

  @override
  String get copyrightDisclaimer => '版權及免責聲明';

  @override
  String get personalDataStatement => '個資法聲明';

  @override
  String get legalConsentPrefix => '我已閱讀並同意';

  @override
  String get menu => '選單';

  @override
  String get profile => '個人中心';

  @override
  String get currentUser => '目前使用者';

  @override
  String get userId => '使用者編號';

  @override
  String get email => '電子郵件';

  @override
  String get phone => '手機號碼';

  @override
  String get notProvided => '未提供';

  @override
  String get departmentNotProvided => '未提供部門資訊';

  @override
  String get fieldWork => '外勤管理';

  @override
  String get fieldWorkSubtitle => '任務、定位、工單一站處理';

  @override
  String get dataAssets => '資料資產';

  @override
  String get dataAssetsSubtitle => '客戶、設備、盤點統一入口';

  @override
  String get noFeatures => '暫無可用功能';

  @override
  String get noFeaturesMessage => '後端未回傳任何功能清單，請確認選單介面或重新整理後再試。';

  @override
  String get noAuthorizedFeatures => '暫無授權功能';

  @override
  String get noAuthorizedFeaturesMessage => '目前帳號暫時沒有可開啟的常用功能，可進入更多查看全部功能授權狀態。';

  @override
  String get noFavoriteFeatures => '尚未收藏首頁功能';

  @override
  String get noFavoriteFeaturesMessage => '請進入更多功能，點擊圖示右上角的星號新增到首頁。';

  @override
  String get favoriteFeature => '收藏到首頁';

  @override
  String get unfavoriteFeature => '取消首頁收藏';

  @override
  String get favoriteRequiresPermission => '未授權功能不能收藏到首頁';

  @override
  String get featurePermissionDenied => '沒有權限，無法使用';

  @override
  String get permissionDialogTitle => '暫時無法使用';

  @override
  String featurePermissionDeniedMessage(String title) {
    return '目前帳號沒有「$title」的存取權限，請聯絡管理員開通後重試。';
  }

  @override
  String favoritePermissionDeniedMessage(String title) {
    return '「$title」尚未授權，暫時不能加入首頁。';
  }

  @override
  String get favoriteFeatureOrder => '首頁應用';

  @override
  String get favoriteFeatureOrderHint => '拖動圖示調整顯示排序';

  @override
  String get more => '更多';

  @override
  String get missingRoute => '功能路由未設定';

  @override
  String missingRouteMessage(String title) {
    return '功能「$title」未設定 route，請聯絡管理員檢查選單設定。';
  }

  @override
  String get acknowledge => '知道了';

  @override
  String get systemSettings => '系統設定';

  @override
  String get logout => '登出';

  @override
  String get cancel => '取消';

  @override
  String get logoutConfirmTitle => '登出目前帳號？';

  @override
  String get logoutConfirmMessage => '登出後需要重新輸入帳號、密碼和驗證碼登入。';

  @override
  String get logoutConfirmAction => '登出';

  @override
  String get security => '安全';

  @override
  String get enableBiometric => '啟用指紋解鎖';

  @override
  String get biometricSubtitle => '用於自動鎖定後快速解鎖';

  @override
  String get biometricUnavailable => '目前裝置無法啟用指紋解鎖';

  @override
  String get biometricUnavailableTitle => '無法啟用此解鎖方式';

  @override
  String get gestureUnlock => '圖形密碼解鎖';

  @override
  String get gestureUnlockSubtitle => '冷啟動和自動鎖定後繪製圖形密碼';

  @override
  String get fingerprintUnlock => '指紋解鎖';

  @override
  String get fingerprintUnlockSubtitle => '開啟時檢查裝置指紋服務並立即驗證';

  @override
  String get faceUnlock => '面容解鎖';

  @override
  String get faceUnlockSubtitle => '開啟時檢查裝置面容服務並立即驗證';

  @override
  String get autoLock => '自動鎖定';

  @override
  String get autoLockSubtitle => '開啟後 10 秒未操作即自動鎖定';

  @override
  String get changeGesturePassword => '修改圖形密碼';

  @override
  String get setGesturePassword => '設定圖形密碼';

  @override
  String get gestureConfigured => '已設定手勢密碼';

  @override
  String get gestureNotConfigured => '未設定手勢密碼';

  @override
  String get general => '一般';

  @override
  String get language => '設定語言';

  @override
  String get switchServer => '切換伺服器';

  @override
  String get clearWebData => '清除 Web 頁面與資料';

  @override
  String get clearWebDataSubtitle => '清除舊頁面資源、網頁登入狀態和離線資料';

  @override
  String get clearWebDataConfirmTitle => '清除 Web 頁面與資料？';

  @override
  String get clearWebDataConfirmMessage =>
      '將清除舊 Vue 頁面快取、H5 登入狀態、草稿和離線資料，但不會登出 MERP App。';

  @override
  String get clearWebDataAction => '立即清除';

  @override
  String get clearWebDataSuccess => 'Web 頁面與資料已清除，請重新開啟業務頁面。';

  @override
  String get clearWebDataFailed => '清除 Web 頁面與資料失敗，請稍後再試。';

  @override
  String currentServer(String server) {
    return '目前：$server';
  }

  @override
  String get selectServer => '選擇伺服器';

  @override
  String get chinaDmz => 'China DMZ';

  @override
  String get hkDmz => 'HK DMZ';

  @override
  String get confirm => '確認';

  @override
  String serverSwitched(String server) {
    return '已切換至 $server';
  }

  @override
  String get serverConfigurationInvalid => '伺服器地址設定無效，請聯絡管理員。';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get bridgeTest => 'WebView Bridge 測試';

  @override
  String get bridgeTestSubtitle => '驗證 Vue/H5 頁面呼叫 Flutter 原生能力';

  @override
  String get versionCheck => '版本檢查';

  @override
  String get versionCheckFailed => '版本檢查失敗，請稍後再試。';

  @override
  String currentVersion(String version) {
    return '目前版本 $version';
  }

  @override
  String get check => '檢查';

  @override
  String get newVersion => '發現新版本';

  @override
  String alreadyLatestVersion(String version) {
    return '已是最新版本 $version';
  }

  @override
  String versionResult(
    String message,
    String currentVersion,
    String latestVersion,
  ) {
    return '$message\n目前版本：$currentVersion\n最新版本：$latestVersion';
  }

  @override
  String get diagnosticLogs => '診斷日誌';

  @override
  String get diagnosticLogsSubtitle => '查看請求、例外和故障編號';

  @override
  String get autoLocked => '已自動鎖定';

  @override
  String get autoLockedMessage => '10 秒未操作，為保護企業資料已鎖定目前工作階段。';

  @override
  String get biometricUnlock => '指紋解鎖';

  @override
  String get continueUsing => '繼續使用';

  @override
  String get biometricFailed => '指紋驗證失敗';

  @override
  String get gestureIncorrect => '手勢密碼不正確，請重試';

  @override
  String get gestureVerifyCurrent => '請先繪製目前的手勢密碼';

  @override
  String get coldStartLocked => '請驗證手勢密碼';

  @override
  String get coldStartLockedMessage => '應用程式已恢復登入狀態，驗證成功後可繼續使用。';

  @override
  String get gestureAutoLockedMessage => '10 秒未操作，請繪製圖形密碼繼續使用。';

  @override
  String get fingerprintVerificationTitle => '請驗證指紋';

  @override
  String get fingerprintVerificationMessage => '請使用目前裝置已登錄的指紋繼續使用 MERP。';

  @override
  String get faceVerificationTitle => '請驗證面容';

  @override
  String get faceVerificationMessage => '請使用目前裝置已登錄的面容繼續使用 MERP。';

  @override
  String get gestureRequiredMessage => '首次使用需要設定手勢密碼，完成後進入首頁。';

  @override
  String get gestureDrawNew => '請繪製新的手勢密碼，至少連接 4 個點';

  @override
  String get gestureTooShort => '手勢密碼至少需要連接 4 個點';

  @override
  String get gestureConfirm => '請再次繪製相同手勢以確認';

  @override
  String get gestureMismatch => '兩次手勢不一致，請重新設定';

  @override
  String get gestureUpdated => '手勢密碼已更新';

  @override
  String get redraw => '重新繪製';

  @override
  String get allFeatures => '全部功能';

  @override
  String get manageMyApps => '管理我的應用';

  @override
  String get noFeatureList => '暫無功能清單';

  @override
  String get noFeatureListMessage => '平臺完整功能目錄為空，請檢查用戶端功能設定。';

  @override
  String noFeaturePermission(String title) {
    return '目前帳號沒有「$title」的存取權限';
  }

  @override
  String get authorized => '已授權';

  @override
  String get unauthorized => '未授權';

  @override
  String get noPermission => '無存取權限';

  @override
  String get returnWorkbench => '返回工作臺';

  @override
  String get pageNotFound => '頁面不存在';

  @override
  String get pageNotFoundMessage => '目前路由沒有對應頁面，請檢查後端選單 route 設定。';

  @override
  String get reportSubscription => '報表訂閱';

  @override
  String get reportSubscriptionReserved => '報表訂閱功能預留中';

  @override
  String get back => '返回';

  @override
  String get logConsole => '診斷日誌';

  @override
  String get logEmpty => '目前暫無診斷日誌';

  @override
  String get clearLogs => '清除日誌';

  @override
  String get copyLogs => '複製日誌';

  @override
  String get logsCopied => '診斷日誌已複製';

  @override
  String errorReference(String id) {
    return '故障編號：$id';
  }

  @override
  String get viewErrorDetails => '查看詳細資料';

  @override
  String get hideErrorDetails => '收起詳細資料';

  @override
  String get copyErrorReference => '複製故障編號';

  @override
  String get errorReferenceCopied => '故障編號已複製';

  @override
  String get retry => '重試';

  @override
  String get refresh => '重新整理';

  @override
  String get reload => '重新載入';

  @override
  String get backToSettings => '返回設定';

  @override
  String get webViewUnsupported => '目前平臺不支援 WebView';

  @override
  String get bridgeMobileOnly =>
      '請在 Android/iOS 行動裝置驗證 Vue 頁面呼叫 Flutter Bridge。';

  @override
  String get bridgeLoadFailed => '橋接測試頁載入失敗';

  @override
  String get bridgeLoadFailedMessage =>
      '無法開啟平臺上的 Vue3 橋接測試頁，請檢查網路、連接埠、防火牆或 HTTP 明文存取設定。';

  @override
  String get bridgeHttpError => '橋接測試頁回傳異常';

  @override
  String get bridgeHttpErrorMessage => '平臺測試頁已回應，但 HTTP 狀態碼不是成功狀態。';

  @override
  String get legacyPage => '舊系統頁面';

  @override
  String get legacyMobileOnly => '舊 Vue 頁面需要在 Android/iOS 行動裝置 WebView 中驗證。';

  @override
  String get moduleMissing => '功能參數缺失';

  @override
  String get moduleMissingMessage => '目前功能未傳入模組編號，請檢查選單 route 設定。';

  @override
  String get featureNotFound => '功能不存在';

  @override
  String get featureNotFoundMessage => '後端選單中找不到此功能，可能是選單已下線或權限資料過期。';

  @override
  String get legacyForbiddenMessage => '目前帳號沒有開啟此功能的權限，請聯絡管理員調整角色或選單授權。';

  @override
  String get urlMissing => '頁面位址未設定';

  @override
  String get urlMissingMessage => '此功能尚未設定舊 Vue 頁面 URL，暫時無法開啟。';

  @override
  String get featureNotIntegrated => '功能暫未接入';

  @override
  String get featureNotIntegratedMessage => '目前舊 Vue 系統根位址仍是預留位址，因此尚無法開啟舊頁面。';

  @override
  String get invalidUrl => '頁面位址格式錯誤';

  @override
  String get invalidUrlMessage => '舊系統頁面位址必須是 http 或 https 位址。';

  @override
  String get pageLoadFailed => '頁面載入失敗';

  @override
  String get pageLoadFailedMessage => '網路連線失敗、伺服器無法連線，或舊系統頁面暫時不可用。';

  @override
  String get serverError => '伺服器回傳錯誤';

  @override
  String get legacyNotFoundMessage => '舊系統找不到該頁面，請檢查選單 URL 是否正確。';

  @override
  String get legacyServerErrorMessage => '舊系統伺服器回傳異常狀態，請稍後重試或聯絡管理員。';

  @override
  String get mapLocation => '地圖定位';

  @override
  String get mapPlaceholder => '地圖 SDK 介面預留';

  @override
  String get currentProvider => '目前廠商';

  @override
  String get mapIntegrationHint => '後續接入地圖時，實作裝置層地圖與定位服務即可，業務頁面和路由無需跟隨第三方外掛修改。';

  @override
  String get mapPrivacyTitle => '使用百度地圖前請確認';

  @override
  String get mapPrivacyMessage =>
      '地圖頁面將使用百度地圖基礎 SDK 載入地圖資料，並支援按需精確定位。進入頁面不會申請定位權限，只有點選定位按鈕或業務頁面主動呼叫時才會顯示系統授權。';

  @override
  String get mapPrivacyPolicy => '百度地圖開放平臺隱私政策';

  @override
  String get mapDecline => '暫不使用';

  @override
  String get mapAgreeAndContinue => '同意並繼續';

  @override
  String get mapLoading => '正在載入地圖';

  @override
  String get mapIosOnly => '目前示範已設定 Android/iOS 百度地圖。Web 需單獨接入 JS SDK 後再啟用。';

  @override
  String get mapConfigMissing => '地圖設定缺失';

  @override
  String get mapKeyMissing => '未讀取到目前平臺的百度地圖 AK，請使用本機設定檔啟動應用程式。';

  @override
  String get mapLoadFailed => '地圖載入失敗';

  @override
  String get mapLoadTimeout =>
      '百度地圖在限定時間內未完成載入，請檢查網路、AK 與 iOS Bundle Identifier 是否一致。';

  @override
  String get locateMe => '定位到我的位置';

  @override
  String get openSystemSettings => '前往設定';

  @override
  String get addressUnavailable => '暫未取得地址';

  @override
  String locationResult(String accuracy, String address) {
    return '精度 ±$accuracy 公尺 · $address';
  }

  @override
  String get locationPrivacyTitle => '使用精確定位';

  @override
  String get locationPrivacyMessage =>
      '此業務將呼叫百度定位 SDK 取得 BD-09 座標、定位精度和地址，用於地圖、外勤或簽到。應用程式只在本次操作時申請「使用 App 期間」的定位權限，不啟用背景定位。';

  @override
  String get locationPrivacyDeclined => '使用者未同意定位隱私說明';

  @override
  String get locationFailedRetry => '定位失敗，請稍後重試';

  @override
  String get scannerTitle => '掃碼';

  @override
  String get scannerPermissionTitle => '需要相機權限才能掃碼';

  @override
  String get scannerPermissionMessage => '請在系統設定中允許 MERP 使用相機。';

  @override
  String get scannerStartFailed => '掃碼相機啟動失敗';

  @override
  String get scannerStartFailedMessage => '相機暫時無法使用，請稍後重試。';

  @override
  String get scanOpenSettings => '開啟系統設定';
}
