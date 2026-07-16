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
  String get login => '登录';

  @override
  String get account => '账号';

  @override
  String get password => '密码';

  @override
  String get loginFailed => '登录失败';

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
  String get security => '安全';

  @override
  String get enableBiometric => '启用指纹解锁';

  @override
  String get biometricSubtitle => '用于自动锁屏后的快速解锁';

  @override
  String get biometricUnavailable => '当前设备无法启用指纹解锁';

  @override
  String get autoLock => '自动锁屏';

  @override
  String get autoLockSubtitle => '开启后 10 秒未操作自动锁屏';

  @override
  String get changeGesturePassword => '修改图形密码';

  @override
  String get gestureConfigured => '已设置手势密码';

  @override
  String get gestureNotConfigured => '未设置手势密码';

  @override
  String get general => '通用';

  @override
  String get language => '设置语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get resourceUpdate => '静态资源热更新演示';

  @override
  String get resourceUpdateSubtitle => '本地模拟资源清单更新首页背景和图标颜色';

  @override
  String get bridgeTest => 'WebView Bridge 测试';

  @override
  String get bridgeTestSubtitle => '验证 Vue/H5 页面调用 Flutter 原生能力';

  @override
  String get versionCheck => '版本检测';

  @override
  String currentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get check => '检查';

  @override
  String get newVersion => '发现新版本';

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
  String get noFeatureList => '暂无功能清单';

  @override
  String get noFeatureListMessage => '后端没有返回全部功能数据，请检查菜单权限接口。';

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
  String get resourceVersion => '当前资源版本';

  @override
  String get resourceSource => '资源来源';

  @override
  String get resourceUpdatedAt => '更新时间';

  @override
  String get builtInResource => '内置资源';

  @override
  String get applyEmerald => '应用绿色资源包';

  @override
  String get applyViolet => '应用紫色资源包';

  @override
  String get resetResource => '重置资源';

  @override
  String get manualResourceJson => '手动资源清单 JSON';

  @override
  String get resourceJsonHint => '修改颜色值后点击“应用 JSON”，即可模拟后端下发资源清单。';

  @override
  String get applyJson => '应用 JSON';

  @override
  String get viewHome => '查看首页';

  @override
  String resourceUpdateFailed(String error) {
    return '资源更新失败：$error';
  }

  @override
  String get emeraldApplied => '已应用绿色资源包，返回首页查看变化';

  @override
  String get violetApplied => '已应用紫色资源包，返回首页查看变化';

  @override
  String get resourceReset => '已恢复内置默认资源';

  @override
  String get jsonApplied => '已应用 JSON 资源清单，返回首页查看变化';

  @override
  String get sourceBuiltIn => '内置默认资源';

  @override
  String get sourceCache => '本地缓存资源';

  @override
  String get sourceCacheFallback => '缓存解析失败，已回退默认资源';

  @override
  String get sourceManualJson => '手动粘贴 JSON';

  @override
  String get sourceEmerald => '本地模拟绿色资源包';

  @override
  String get sourceViolet => '本地模拟紫色资源包';

  @override
  String get sourceReset => '已重置为内置默认资源';
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
  String get login => '登入';

  @override
  String get account => '帳號';

  @override
  String get password => '密碼';

  @override
  String get loginFailed => '登入失敗';

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
  String get security => '安全';

  @override
  String get enableBiometric => '啟用指紋解鎖';

  @override
  String get biometricSubtitle => '用於自動鎖定後快速解鎖';

  @override
  String get biometricUnavailable => '目前裝置無法啟用指紋解鎖';

  @override
  String get autoLock => '自動鎖定';

  @override
  String get autoLockSubtitle => '開啟後 10 秒未操作即自動鎖定';

  @override
  String get changeGesturePassword => '修改圖形密碼';

  @override
  String get gestureConfigured => '已設定手勢密碼';

  @override
  String get gestureNotConfigured => '未設定手勢密碼';

  @override
  String get general => '一般';

  @override
  String get language => '設定語言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get resourceUpdate => '靜態資源熱更新示範';

  @override
  String get resourceUpdateSubtitle => '在本機模擬資源清單更新首頁背景和圖示顏色';

  @override
  String get bridgeTest => 'WebView Bridge 測試';

  @override
  String get bridgeTestSubtitle => '驗證 Vue/H5 頁面呼叫 Flutter 原生能力';

  @override
  String get versionCheck => '版本檢查';

  @override
  String currentVersion(String version) {
    return '目前版本 $version';
  }

  @override
  String get check => '檢查';

  @override
  String get newVersion => '發現新版本';

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
  String get noFeatureList => '暫無功能清單';

  @override
  String get noFeatureListMessage => '後端未回傳全部功能資料，請檢查選單權限介面。';

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
  String get resourceVersion => '目前資源版本';

  @override
  String get resourceSource => '資源來源';

  @override
  String get resourceUpdatedAt => '更新時間';

  @override
  String get builtInResource => '內建資源';

  @override
  String get applyEmerald => '套用綠色資源包';

  @override
  String get applyViolet => '套用紫色資源包';

  @override
  String get resetResource => '重設資源';

  @override
  String get manualResourceJson => '手動資源清單 JSON';

  @override
  String get resourceJsonHint => '修改顏色值後點選「套用 JSON」，即可模擬後端下發資源清單。';

  @override
  String get applyJson => '套用 JSON';

  @override
  String get viewHome => '查看首頁';

  @override
  String resourceUpdateFailed(String error) {
    return '資源更新失敗：$error';
  }

  @override
  String get emeraldApplied => '已套用綠色資源包，返回首頁查看變更';

  @override
  String get violetApplied => '已套用紫色資源包，返回首頁查看變更';

  @override
  String get resourceReset => '已恢復內建預設資源';

  @override
  String get jsonApplied => '已套用 JSON 資源清單，返回首頁查看變更';

  @override
  String get sourceBuiltIn => '內建預設資源';

  @override
  String get sourceCache => '本機快取資源';

  @override
  String get sourceCacheFallback => '快取解析失敗，已回復預設資源';

  @override
  String get sourceManualJson => '手動貼上 JSON';

  @override
  String get sourceEmerald => '本機模擬綠色資源包';

  @override
  String get sourceViolet => '本機模擬紫色資源包';

  @override
  String get sourceReset => '已重設為內建預設資源';
}
