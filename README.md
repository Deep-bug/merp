# MERP Flutter Shell

MERP 是原 Cordova 6.5 外壳的 Flutter 升级版本。Flutter 统一负责启动、登录鉴权、菜单权限、HTTP、系统安全、国际化、诊断日志、WebView 和原生能力 Bridge；旧 Vue 业务继续运行在 WebView 中，后续按模块逐步迁移为 Flutter 原生实现。

## 架构目标

- 清晰：启动、基础能力、路由、共享 UI 和业务模块边界明确。
- 可扩展：新业务按 feature 纵向拆分，不持续膨胀全局文件。
- 可协作：页面编排与具体组件分离，减少多人修改同一文件的冲突。
- 可诊断：启动、路由、鉴权、权限、HTTP、WebView 和 Bridge 使用统一结构化日志。
- 可兼容：Android 最低版本固定为 API 24，即 Android 7.0。
- 可迁移：Vue 与 Flutter 原生模块共用登录态、权限模型、路由和设备能力边界。

## 开发环境与打包

项目固定 Flutter `3.44.6`，团队启动/打包脚本仅维护 macOS。
完整操作见 [开发、运行与企业发布教程](docs/DEVELOPMENT_AND_RELEASE_GUIDE.md)。

```bash
./tool/bootstrap
./tool/app ide
```

### 安装身份与接口环境

| 身份（Flavor / Scheme） | Android applicationId / 默认 iOS Bundle ID | 签名用途 |
| --- | --- | --- |
| dev | `com.delta.merpdelta.qas` | 个人开发，支持 Debug/Profile/Release |
| qas | `com.delta.MERPDeltaTest` | 企业 QAS 分发 |
| prd | `com.delta.MERPDelta` | 企业 PRD 分发 |

身份的公共来源是 `config/build_profiles.json`。Android namespace 不变。
`run` 一律使用 dev 安装身份，命令中的 qas/prd/mock 选择接口环境；
`build` 使用 qas/prd 企业身份。Mock 不允许打包发布。

```bash
./tool/app run qas ios
./tool/app run qas android -d emulator-5554
./tool/app run qas android --recover -d emulator-5554
./tool/app run mock ios
./tool/app run prd ios           # 个人签名 + PRD 接口，需先填生产地址
./tool/app run qas ios --profile # 个人签名的性能测试
./tool/app run qas ios --release # 个人签名的 Release 验证
```

### 一次填写本机配置

`./tool/app ide` 只创建缺失文件，不覆盖已填内容：

- `ios/Config/Dev.local.xcconfig`：个人 DEVELOPMENT_TEAM，可覆盖 MERP_BUNDLE_ID。
- `ios/Config/Qas.local.xcconfig`、`Prd.local.xcconfig`：企业 Team 和对应 Profile。
- `config/baidu_map.dev.local.json`、`baidu_map.qas.local.json`、`baidu_map.prd.local.json`：各身份的地图 AK。
- `config/qas.local.json`、`prd.local.json`：接口地址等本机覆盖。
- `config/mock.local.json`、`webview.local.json`：Mock 和网页覆盖。

旧 `config/baidu_map.local.json` 仅在 dev 文件不存在时复制到 dev，新构建不再读取旧文件。
企业 Key 需要单独填写，不能使用个人包对应的 Key。真实值均被 Git 忽略。
Android Manifest 和 Dart 使用同一组传入的地图 AK。

### VS Code、Android Studio 和 Xcode

VS Code 选择 `MERP DEV · QAS · Debug + HTTP Logs · iOS/Android` 后按 F5。
启动前自动补齐本地空配置；在右下角选择实际设备，不在共享配置中固定 deviceId。
Mock、PRD 接口、Profile 和 Release 启动项都使用 dev 身份。
企业 IPA 从“运行任务”选择 Enterprise QAS/PRD iOS IPA。

Android Studio 打开项目根目录。共享配置为 `MERP DEV QAS Android` /
`MERP DEV MOCK Android`；`./tool/app ide` 生成对应 Local 配置。
不要使用无 Flavor 的原生 `app` 启动项。Debug APK 路径是
`build/app/outputs/flutter-apk/app-dev-debug.apk`。

Xcode 打开 `ios/Runner.xcworkspace`：日常调试选 dev，企业归档选 qas/prd。
新电脑无需运行 `configure_ios_flavors.rb`，Scheme 和工程配置已提交。
归档阶段根据当前 Scheme 重新解析配置，避免沿用上一次个人调试的地图 Key。
详细签名配置及直接用 Xcode 选择接口环境见开发教程。

`android/local.properties` 不提交。SDK 路径缺失时回退到项目 `.fvm/flutter_sdk`，
Android SDK 尝试环境变量或 `$HOME/Library/Android/sdk`。首次初始化后不需要复制
其他电脑的 `build/`。

### 企业构建

```bash
./tool/app build qas android # ARM64 APK，android/key-qas.properties
./tool/app build prd android # ARM64 AAB，android/key.properties
./tool/app build qas ios     # 企业 IPA
./tool/app build prd ios     # 企业 IPA

IOS_OTA_BASE_URL=https://example.com/merp/qas ./tool/app build qas ios-ota
IOS_OTA_BASE_URL=https://example.com/merp/prd ./tool/app build prd ios-ota
```

QAS/PRD iOS 均采用 enterprise 导出。OTA 输出在 `build/ios/ota/<qas|prd>/`，
包含 IPA 和安装用的 `manifest.plist`。企业证书及匹配包名的 Profile 需要安装在
发布电脑上；开发电脑只需自己的开发证书。Android 企业签名不回退到 debug。

版本来源为 `pubspec.yaml`，构建编号保持五位数；可用
`BUILD_NAME=1.2.0 BUILD_NUMBER=10001 ./tool/app build qas android` 覆盖。
PRD 本地构建要求输入 prd 确认；CI 可设置 `CI=true`。脚本不会自动发布。

### 检查与本机空间清理

```bash
./tool/app analyze
./tool/app test
ruby test/tool/build_configuration_test.rb
./tool/app clean --dry-run
./tool/app clean
```

清理前停止所有调试和构建。清理命令先归档 Android Release APK/AAB、mapping 和
符号文件到 `.artifacts/android/`，再清理项目构建产物；不归档 iOS IPA/Archive。
保留源码、Pods、本地配置、签名文件和全局 Gradle/Pub 缓存。首次重建后恢复增量构建。

Windows 专用 bootstrap/app/configure_ide 和 E 盘环境配置脚本已移除。
Gradle 上游自带的 `gradlew.bat` 及历史图标素材生成工具不属于团队启动/打包入口，保留。

## 目录结构

```text
merp/
├── .run/                                    # Android Studio共享 Flutter运行配置
├── .vscode/                                 # VS Code QAS Flavor启动配置
├── config/                                  # QAS/PRD公共配置与本地覆盖模板
├── tool/                                     # 固定工具链、首次初始化和统一构建入口
│   ├── app / bootstrap                       # macOS 开发与企业打包入口
│   └── build_configuration.rb                # 按安装身份解析配置
├── android/                                  # Android 工程、权限、启动图、图标和 Gradle 配置
│   └── app/
│       ├── build.gradle.kts                  # minSdk=24，明确兼容 Android 7.0
│       └── src/main/
│           ├── AndroidManifest.xml           # 网络、相机、定位和生物识别权限
│           └── res/                          # 原生 Splash 和 MERP 启动图标
├── docs/                                     # 架构验证和迁移说明文档
├── lib/
│   ├── main.dart                             # 进程入口、Zone 和全局异常捕获
│   ├── app/                                  # 应用装配层
│   │   ├── app_dependencies.dart             # 依赖创建、并行初始化和生命周期
│   │   ├── app_scope.dart                    # 向 Widget 树显式提供全局服务
│   │   ├── merp_bootstrap_app.dart           # 品牌启动页、异步初始化和启动错误页
│   │   ├── merp_app.dart                     # 主题、路由、语言和安全守卫装配
│   │   ├── security/
│   │   │   ├── app_lock_coordinator.dart      # 安全域、冷启动与无操作锁屏编排
│   │   │   ├── app_privacy_shield.dart        # 后台任务快照纯色遮罩
│   │   │   └── auto_lock_guard.dart           # 生命周期/触摸转发和锁屏 UI
│   │   └── theme/
│   │       └── app_theme.dart                # Material 主题和企业控件样式
│   ├── core/                                 # 与具体业务无关的基础能力
│   │   ├── auth/                             # Token、用户资料、会话、认证仓库和安全存储
│   │   ├── bridge/                           # Vue/H5 调用 Flutter 的受控协议
│   │   ├── config/                           # API、Vue 和地图环境配置
│   │   ├── device/                           # 相机、定位和地图 SDK 适配边界
│   │   ├── logging/                          # 结构化日志、故障编号和全局异常捕获
│   │   ├── network/                          # Dio、响应壳、异常和企业错误码
│   │   ├── platform/                         # WebView 等平台能力判断
│   │   ├── resources/                        # 首页内置展示清单
│   │   └── security/                         # 手势凭证、生物识别平台服务和解锁类型
│   ├── features/                             # 按业务纵向拆分的功能模块
│   │   ├── all_features/                     # 全部功能及权限状态
│   │   ├── bridge_test/                      # Vue3 Bridge 真机验证页
│   │   ├── home/
│   │   │   ├── data/                         # 权限菜单 Repository
│   │   │   ├── domain/                       # FeatureItem 领域模型
│   │   │   ├── widgets/                      # 头部、轮播、功能区、抽屉和悬浮按钮
│   │   │   └── home_page.dart                # 首页状态订阅和页面编排
│   │   ├── legacy/                           # 旧 Vue WebView 承载和错误处理
│   │   ├── login/                            # 登录页面
│   │   ├── map/                              # 地图业务入口和 SDK 占位
│   │   ├── profile/                          # 个人中心
│   │   └── settings/                         # 指纹、锁屏、手势、语言、版本和日志
│   ├── l10n/
│   │   ├── arb/                              # 简体与繁体 ARB 文案源文件
│   │   ├── generated/                        # Flutter gen_l10n 自动生成代码
│   │   └── l10n.dart                         # context.l10n 快捷入口
│   ├── routing/
│   │   ├── app_routes.dart                   # 路由路径唯一常量来源
│   │   ├── app_router.dart                   # go_router 路由表和登录守卫
│   │   ├── forbidden_page.dart               # 无权限页
│   │   └── splash_page.dart                  # Flutter 品牌加载页
│   └── shared/
│       └── app_error_view.dart               # 统一错误、空状态、故障编号和恢复操作
├── test/                                     # 冒烟、国际化和日志安全测试
├── l10n.yaml                                 # Flutter 官方多语言生成配置
├── pubspec.yaml                              # Flutter 版本、依赖和资源配置
└── README.md                                 # 当前架构与团队协作约定
```

## 启动流程

```text
Android/iOS 原生启动图
    -> Flutter Engine 启动并进入 main.dart
    -> main 安装 Zone / Flutter / Platform 异常捕获
    -> 立即 runApp(MerpBootstrapApp)，渲染 Flutter 品牌加载页
    -> AppDependencies 并行读取设置、资源缓存和地图占位服务
    -> 使用 refresh token 换取新 Token 并恢复会话
    -> MerpApp 装配语言、路由、主题和自动锁屏
    -> 根据登录态进入登录页或首页
    -> 首页后台并行加载用户资料和权限菜单
```

`main.dart` 不等待磁盘或网络后再 `runApp`，可以缩短中低端手机冷启动空白时间。具体业务权限和定位仍按需加载，避免首屏一次初始化全部插件。

### Android 启动时序

1. 系统点击桌面图标后，先显示 Android 原生 `LaunchTheme`。Android 12 及以上使用系统 SplashScreen 图标和背景，Android 12 以下使用 `launch_background.xml`。
2. Flutter Engine 启动，进入 `main.dart`。此时只安装全局异常捕获和结构化日志，不读取网络接口，也不申请系统权限。
3. `runApp(MerpBootstrapApp)` 立即输出 Flutter 首帧，展示 MERP 品牌加载页，避免原生启动图和 Flutter 页面之间出现白屏。
4. `AppDependencies.bootstrap()` 在 Flutter 品牌加载页背后并行执行：
   - 读取本地设置和语言。
   - 读取运行时静态资源缓存。
   - 创建百度地图适配服务并校验地图配置是否存在。
   - 使用安全存储中的 refresh token 换取新 Token；成功后立即恢复会话。
5. 这个阶段不会调用百度地图原生视图，不会启动百度定位 SDK，也不会弹定位权限框。
6. 用户进入“地图定位”页面后，页面先检查百度地图配置和隐私同意状态。未同意时显示说明页，用户点击同意后才调用百度地图 SDK 隐私同意和 AK 初始化。
7. 地图基础 SDK 激活后才创建百度原生地图视图，并等待底图加载、渲染或有效数据回调。
8. 用户点击定位按钮后，才配置百度定位 SDK、检查系统定位服务、申请前台定位权限，并发起单次精确定位。
9. Android 百度 AK 同时通过 `--dart-define-from-file` 做 Flutter 配置校验，并通过 Manifest placeholder 写入 `com.baidu.lbsapi.API_KEY` 供百度原生定位 SDK 读取。

### iOS 启动时序

1. 系统点击桌面图标后，先显示 iOS `LaunchScreen.storyboard` 和 `Assets.xcassets` 中的启动图资源。
2. Flutter Engine 启动，进入 `main.dart`。与 Android 一样，此时只安装异常捕获和日志，不申请定位权限。
3. `MerpBootstrapApp` 立即渲染 Flutter 品牌加载页，并在后台装配应用依赖。
4. 启动加载页期间只做配置、设置、资源缓存和 refresh token 刷新。刷新成功后立即进入首页，用户资料和权限菜单在首页后台并行加载。
5. 用户进入“地图定位”页面并同意百度隐私说明后，才调用 `BMFMapSDK.setAgreePrivacy(true)` 和 iOS AK 初始化。
6. iOS 的 `mapapi.bundle` 由 CocoaPods 的 `[CP] Copy Pods Resources` 自动复制进 `Runner.app`，不要手动再加到 Xcode target，避免出现重复复制。
7. 百度原生地图视图创建后，Flutter 同时监听地图加载、渲染完成、有效数据和状态变化回调，避免 iOS 首次回调过早导致页面误判超时。
8. 用户点击定位按钮后，才配置百度定位 SDK、检查系统定位服务、读取或申请 `When In Use` 前台定位权限，并请求单次精确定位。
9. iOS 更新地图定位点时使用跨平台 `setNewMapStatus`，不要调用 Android 独有的 `setZoomTo`。

### Splash 阶段 Flutter 在做什么

原生 Splash 只负责覆盖 Flutter Engine 冷启动的短暂空窗；Flutter 首帧出现后，页面切到 `SplashPage(isBootstrapping: true)`。这个 Flutter 品牌加载页期间，应用主要做这些事：

- 安装后的首次 UI 渲染和主题、本地化 delegate 装配。
- 创建 `AppConfig`、`ApiClient`、`SecureTokenStore`、`SettingsController` 等应用级依赖。
- 读取本地语言、自动锁屏、生物识别等设置。
- 读取静态资源热更新缓存和 manifest。
- 检查地图 provider 和平台 AK 是否存在，但不激活百度 SDK。
- 尝试恢复登录态；refresh token 失效时清理本地会话并进入登录页。
- refresh token 刷新成功后解除 Splash，进入首页。

Splash 阶段明确不做这些事：

- 不申请定位、相机、相册等系统权限。
- 不启动百度定位。
- 不创建百度地图原生视图。
- 不读取或上传真实经纬度。
- 不执行耗时业务数据预加载。

进入首页后，用户资料与权限菜单并行加载，只保存在当前进程内存中。用户资料读取真实接口；权限菜单通过带 Token 的 `POST /api/v1/app/features` 读取，并根据当前语言传递 `zh_CN` 或 `zh_TW`。客户端始终使用本地平台完整功能目录展示“全部功能”，后端返回列表只转换成当前账号的授权集合：授权入口点亮并允许收藏，未授权入口置灰且点击时显示权限提示。功能区加载期间显示骨架状态，真实接口网络失败时显示重试入口，且不会清除仍然有效的 refresh token。

如果冷启动刷新 Token 时遇到断网、超时或服务端 `5xx`，应用会保留 refresh token 并停留在启动恢复页供用户重试；只有服务端明确返回 `400/401/403` 表示 refresh token 无效时，才清理本地 Token 并进入登录页。

用户收藏与角标的生命周期由 `lib/app/user_session_data_coordinator.dart` 统一编排：

- 收藏和排序按“应用环境＋用户 ID”写入 SharedPreferences 的 v3 用户键；暂缺用户 ID 时使用已登录账号的独立临时域。同一轮登录补齐用户 ID 后可安全迁移，身份尚未知时不展示旧收藏。
- China/HK 只是同数据域的服务器选择，不拆分收藏；QAS/PRD 及不同用户相互隔离。
- 退出立即清空内存收藏和角标，但保留该用户持久化收藏，供本人下次登录恢复。延迟返回的旧角标请求不能写回新会话。
- 旧版 v2 全局收藏没有所有者信息，不自动分配给任何账号，也不删除原数据；升级后需要重新收藏一次。
- Mock 收藏、排序与示例角标仅在内存中生效，不读写正常用户数据。收藏不是凭证，Token 仍保存在原有安全存储中。

QAS 和生产配置默认使用真实菜单接口。请求参数由 `MENU_APP_ID=merp` 和 `MENU_FEATURE_SCOPE=at` 配置；离线排版开发请使用 `./tool/app run mock <android|ios>`。旧配置字段 `MOCK_MENUS` 暂时保留兼容，但权限仓库不再读取它，单独设置该值不能绕过真实权限接口。`PlatformFeatureCatalog` 是客户端完整功能白名单，后端菜单只决定当前用户获准使用哪些 ID。当前暂不使用接口返回的 `icon` 或 `iconUrl`，功能图标和可信路由统一由客户端目录决定，未知功能编码会被忽略并记录告警。

Mock 用户权限位于独立的 `MockUserFeaturePermissions`，不再承载功能标题、图标、分组或地址。平台新增功能时必须分别评审“客户端是否支持”与“Mock 用户是否授权”，避免新入口被开发模式自动放行。正常 `loadForSession` 始终访问真实权限接口；只有显式的开发 Mock 会话才调用 `loadDevelopmentMockMenu`。

本地解锁的底层能力集中在 `lib/core/security/`：

- `GestureCredentialStore` 负责手势哈希、安全存储和校验，保留原 v2 记录、120000 次 PBKDF2-HMAC-SHA256 及原存储键，升级不要求重新设置密码。读写删除串行执行；密码和哈希记录不进入日志。
- `BiometricService` 负责设备能力检测、系统认证与取消，返回明确结果，不持有账号、不决定页面跳转。是否可用仍以系统报告的已录入类型为准；验证方式由操作系统执行。
- `LocalSecurityController` 独立保存用户安全域、自动锁屏开关、解锁方式和提示翻译；`generation` 用于丢弃退出或换账号前发起的旧结果。`SettingsController` 只负责语言、服务器、版本等普通设置，并暂时保留旧安全方法代理以兼容现有调用。
- `AppLockCoordinator` 不依赖 Widget，统一编排账号安全域、冷启动验证、10 秒无操作计时及前后台恢复；它只读取最小的 `SecuritySessionState` 会话接口。`AutoLockGuard` 只转发生命周期/触摸事件并绘制界面。
- 后台纯色隐私遮罩独立于解锁方式；10 秒锁屏、错误 5 次退出策略没有改变。

这样的分层能保证启动体验稳定，也能满足隐私合规：地图展示在进入地图页后才初始化，精确定位在用户点击定位按钮后才触发。

## 模块协作规范

新增原生模块建议使用以下结构：

```text
lib/features/inventory/
├── data/                 # API DTO、数据源和 Repository 实现
├── domain/               # 实体、枚举、业务规则和 Repository 接口
├── presentation/         # Page、Controller 和页面级状态
└── widgets/              # 仅本模块复用的组件
```

协作约定：

- `features/A` 不直接引用 `features/B` 的页面实现，共用能力下沉到 `core` 或 `shared`。
- 页面不创建 Dio、插件服务或安全存储，统一通过 `AppScope` 获取已装配依赖。
- 所有页面路径写入 `AppRoute`，后端菜单与原生导航使用同一套路径。
- 页面点击前再次检查权限，不能只依赖“按钮是否显示”。
- 大页面只做状态订阅和编排，独立区域拆入模块自己的 `widgets`。
- 每个 Dart 文件使用统一文件头，标明文件意义、编写时间和维护边界。
- 关键注释解释设计原因、安全边界和扩展点，不重复描述显而易见的代码。

文件头模板：

```dart
// -----------------------------------------------------------------------------
// 文件：inventory_page.dart
// 作用：展示库存列表并编排筛选、分页和详情入口
// 编写时间：2026-07-10
// 维护说明：数据加载委托 InventoryController，页面不直接调用 Dio
// -----------------------------------------------------------------------------
```

## 状态管理

当前外壳使用 `ChangeNotifier + AppScope(InheritedWidget)`。登录、权限、设置、资源和日志状态数量有限，这种方案依赖显式、运行成本低，也适合 Android 7 中低端设备。

原生业务明显增多后，可从新模块开始引入 Riverpod；审批流、工单流转等强事件模块可独立使用 Bloc。不要同时在全局混用多种状态容器，也不要让页面通过隐式单例寻找业务状态。

## 简繁体国际化

项目使用 Flutter 官方 `gen_l10n`：

- 简体源文件：`lib/l10n/arb/app_zh.arb`
- 繁体源文件：`lib/l10n/arb/app_zh_TW.arb`
- 设置入口：系统设置 -> 设置语言
- 本地持久化：`SettingsController` 保存 `zh-CN` 或 `zh-TW`
- 页面调用：`context.l10n.login`

新增文案时：

1. 在两个 ARB 文件添加相同 key。
2. 执行 `flutter gen-l10n`。
3. 页面通过 `context.l10n` 使用生成属性，禁止手写 Locale 分支。
4. 动态菜单标题由后端按当前语言返回，Flutter 不翻译业务数据。

## 结构化日志

`AppLogger` 默认只记录警告和错误，并保留最近 200 条到内存环形缓冲区。系统设置中的“诊断日志”可查看、复制和清空日志。开启 `ENABLE_LOG` 后，Debug/Info 会写入调试终端和内存，但不会同步刷写诊断文件；只有警告和错误会落盘，避免高频日志阻塞 UI 线程。

开启 HTTP 日志后，VS Code 调试控制台会输出请求 URL、查询参数、请求体、响应状态、响应头、响应体、耗时和请求编号；错误会以红色、警告以黄色显示。密码、Token、验证码、Cookie 与图片 Base64 始终会被替换为 `<redacted>`，不会出现在控制台或诊断文件中。`I/flutter` 是 Android 自动添加的运输前缀，不影响后方 MERP 日志正文的级别颜色。

```dart
logger.info(
  'inventory',
  '库存列表加载完成',
  fields: {'count': rows.length, 'warehouseId': warehouseId},
);

final incidentId = logger.error(
  'inventory',
  '库存列表加载失败',
  error: error,
  stackTrace: stackTrace,
  fields: {'warehouseId': warehouseId},
);
```

异常日志会生成 `MERP-日期-时间-序号` 格式的故障编号。HTTP、WebView、Bridge、Flutter 渲染和未处理异步异常均进入统一日志；错误页面展示故障编号，用户可直接提供给研发定位。

日志安全约定：

- 禁止记录密码、完整 Token、Cookie、Secret 和图片 Base64。
- `AppLogger` 会对常见敏感 key 和 Bearer Token 做兜底脱敏，但不能代替代码审查。
- 生产接入 ELK、Sentry 或公司日志平台时，在日志层增加输出适配器，不修改业务页面。
- 远程上传必须取得隐私授权，并限制日志保留周期和访问权限。

## 统一 HTTP 与错误码

业务 Repository 只调用 `ApiClient.get/post/put/delete`。客户端统一完成：

- `Authorization: Bearer <token>` 注入。
- `X-Client: merp-flutter`、`X-Request-Id: merp-{timestamp}` 和请求耗时记录。
- 连接超时 30 秒、接收和发送超时 60 秒。
- 响应壳 `code/message/data` 解析，兼容 `data` 与 `data.data`。
- Dio 异常、HTTP 状态和后端错误码转换。
- 401 使用 refresh_token 自动刷新并重放原请求。
- 并发 401 共用同一次刷新请求，刷新失败后清理 Token 并跳转登录页。
- 错误日志与客户端故障编号生成。

客户端错误关键字：`clientTimeout`、`clientNetworkUnavailable`、
`clientCancelled`、`clientInvalidConfig`、`serverUnauthorized`、
`serverForbidden`、`serverNotFound`、`serverValidation`、`serverError`、
`clientUnknown`。

真实接口结构、认证时序和代码位置见 [API 对接说明](docs/api_integration.md)。

## Vue WebView Bridge

旧 Vue 页面通过 `window.MERPBridge.call(action, payload)` 调用 Flutter。当前支持：

- `bridge.ping`
- `auth.getSession`
- `auth.logout`
- `resource.getManifest`
- `app.getLocale`
- `app.showToast`
- `camera.takePhoto`
- `file.pick`
- `device.getInfo`
- `location.getCurrentPosition`
- `scanner.scanCode`
- `system.showMessage`
- `system.confirm`
- `navigation.closePage`
- `device.openAppSettings`

新增 action 必须在 `MerpNativeBridge` 中完成参数校验、返回结构、错误码和日志，并同步 Bridge 文档。相机和定位都由用户在 Vue 页面主动操作触发，不在页面加载或 App 启动时申请权限。Vue2 精确定位接入见 [定位 Bridge 文档](docs/vue2_location_bridge.md)。

统一 HTTP 和 WebView 首次请求会自动携带 `Accept-Language: zh-CN/zh-TW`。Vue 页面也可调用 `window.MERPBridge.getLocale()` 获取当前语言；后端菜单应按该语言返回本地化标题和描述。

## Android 7.0 兼容

- `android/app/build.gradle.kts` 固定 `minSdk = 24`。
- Android 7 使用 PNG launcher 图标；Android 8 及以上使用 adaptive icon。
- 生物识别同时声明 `USE_FINGERPRINT` 与 `USE_BIOMETRIC`。
- 避免首页大图一次性解码、无限日志缓存、频繁定时器和首屏批量插件初始化。
- 发布前至少验证 API 24、API 28、API 33 和当前 targetSdk 真机或模拟器。
- Android 7 系统 WebView 较旧，部署 Vue 页面时避免仅支持现代浏览器的新语法，必要时由构建工具转译并提供 polyfill。

## 环境配置

应用环境支持 `qas`、`mock` 和 `prd`。`APP_ENV` 用于选择部署环境并隔离安全
Token；`AUTH_ENVIRONMENT` 是认证接口业务参数，默认固定为 `merp`。其中 `mock`
仅能用于 Debug 启动，复用 QAS 的原生 Flavor 与地址配置，不能构建或发布。

QAS 使用已提交的 `config/qas.json`。日常运行统一使用：

```bash
./tool/app run qas android
./tool/app run qas ios
```

Mock 启动会跳过登录、用户资料及后端菜单加载，展示本地开发用户、完整菜单、默认
收藏和示例待办角标：

```bash
./tool/app run mock android
./tool/app run mock ios
```

`./tool/bootstrap` 会自动生成以下 Git 忽略文件，不存在本机密钥时内容为安全空值：

```text
config/qas.local.json
config/mock.local.json
config/baidu_map.dev.local.json
config/baidu_map.qas.local.json
config/baidu_map.prd.local.json
config/webview.local.json
```

填写或修改本地配置后重新生成 IDE配置：

```bash
./tool/app ide
```

PRD 使用前填写 `config/prd.local.json` 的真实生产地址。
`./tool/app run prd ios` 使用个人身份调试生产接口；企业发布使用：

```bash
./tool/app build prd android
./tool/app build prd ios
```

所有 `*.local.json` 均已加入 Git 忽略。QAS、Mock 与 PRD 使用独立安全存储命名空间，
不会互相读取 refresh token；QAS/PRD 首次进入各自环境需要登录一次，Mock 不保存登录会话。

百度地图当前接入 Android/iOS 基础地图与按需精确定位，不包含 Search SDK。真实 AK 放在 Git 忽略的
`config/baidu_map.<dev|qas|prd>.local.json`，按安装身份自动注入。

隐私初始化、Android/iOS 配置、CocoaPods、后端权限结构和故障排查见
[百度地图跨平台接入与调试复盘](docs/baidu_map_cross_platform_debugging.md)。

## 验证命令

```bash
./tool/bootstrap
./tool/app ide
./tool/app analyze
./tool/app test
./tool/app build qas android
./tool/app build qas ios
IOS_OTA_BASE_URL=https://example.com/merp/ios ./tool/app build qas ios-ota
```

提交前必须保证格式化、静态分析和自动化测试通过；涉及 Android 权限、启动图、WebView 或插件升级时，还需构建 APK 并在 API 24 设备验证。
