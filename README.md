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

项目统一使用 Flutter `3.44.6` 和项目内固定版本的 FVM。新同事不需要全局安装
FVM，也不要直接执行全局 `flutter`。首次拉取代码后，在项目根目录按系统运行：

完整教程见
[MERP Flutter 开发、运行与发布教程](docs/DEVELOPMENT_AND_RELEASE_GUIDE.md)。

```bash
# macOS
./tool/bootstrap
./tool/app doctor
```

```powershell
# Windows（CMD 或 PowerShell）
.\tool\bootstrap.cmd
.\tool\app.cmd doctor
```

`bootstrap` 会识别 macOS/Windows 和 CPU 架构，下载并校验对应平台的固定版本
FVM，安装 `.fvmrc` 指定的 Flutter、获取依赖并检查开发环境。macOS 额外检查
Xcode 和 CocoaPods；Windows 支持 Android 开发与打包，不能运行或构建 iOS。
重复执行会复用 `.tool-cache` 缓存。初始化同时会生成本机 QAS 配置和 IDE
运行配置；本地配置变化后可以单独执行：

```bash
# macOS
./tool/app ide
```

```powershell
# Windows
.\tool\app.cmd ide
```

日常联调使用真实登录的 QAS：

```bash
./tool/app run qas android
./tool/app run qas ios

# 指定设备
./tool/app run qas android -d <device-id>
```

内网不可用、仅需查看首页或页面排版时，使用独立 Mock 启动项。它复用 QAS 的
地址与原生 Flavor，但不请求登录、用户资料和菜单接口：

```bash
./tool/app run mock android
./tool/app run mock ios
```

Windows 使用相同参数，把入口替换为 `.\tool\app.cmd`：

```powershell
.\tool\app.cmd run qas android
.\tool\app.cmd run qas android -d emulator-5554
```

Android Studio 打开项目根目录后，可直接选择共享的 `MERP QAS Android`；执行过
`bootstrap` 后还会出现加载本机地图/WebView配置的
`MERP QAS Android (Local)`。VS Code 同样提供 QAS Android/iOS 的共享与 Local
启动项。共享配置不依赖密钥，保证新电脑可以启动；Local 配置文件均被 Git 忽略。

### 新电脑与 IDE 启动

新电脑必须打开 Flutter 项目根目录 `merp/`，不能只打开 `merp/android/`。
`build/` 是本机构建产物，不提交 Git，也不需要从其他电脑复制。

`android/local.properties` 仍是本机文件，不提交 Git。Gradle 会优先使用其中有效的
`flutter.sdk`；文件缺失或路径已经失效时，会自动回退到项目固定的
`.fvm/flutter_sdk`，并在本机生成或修复 `local.properties`。macOS 上缺少有效
`sdk.dir` 时也会尝试使用 `ANDROID_SDK_ROOT`、`ANDROID_HOME` 或默认的
`$HOME/Library/Android/sdk`；Windows 还会尝试
`%LOCALAPPDATA%\Android\Sdk`。如果仍找不到 Flutter SDK，按错误提示在项目根目录
执行当前系统的 `bootstrap` 即可。

Android Studio运行配置：

| 配置 | 用途 | 配置来源 |
| --- | --- | --- |
| `MERP QAS Android` | 无本地密钥也能启动的共享 QAS Debug | 仓库 `.run/` |
| `MERP QAS Android (Local)` | 加载本机地图、WebView和 QAS 覆盖值 | `./tool/app ide` 自动生成 |

不要使用 Android Studio自动产生的无 Flavor `app` 配置。项目启用
`qas/prd` Flavor 后不会生成 `app-debug.apk`，QAS Debug 的正确产物是：

```text
build/app/outputs/flutter-apk/app-qas-debug.apk
```

VS Code运行配置：

| 配置 | Flavor | 本地覆盖 |
| --- | --- | --- |
| `MERP QAS Android Debug` | `qas` | 否 |
| `MERP QAS Android Profile` | `qas` | 否 |
| `MERP QAS Android Debug (Local)` | `qas` | 是 |
| `MERP QAS iOS Debug` | `qas` | 否 |
| `MERP QAS iOS Debug (Local)` | `qas` | 是 |

`.vscode/settings.json` 只保存 `.fvm/flutter_sdk` 相对路径，不得提交某位开发者的
Android SDK、Flutter SDK、Pub Cache 或 Gradle Cache 绝对路径。
移动端启动项不写死 `deviceId`；运行前先在 VS Code 右下角选择当前模拟器或真机，
再按 `F5`。例如 Android 模拟器的真实设备 ID 通常是 `emulator-5554`，不同电脑
和不同启动次数可能变化，不能写进共享配置。

Windows 上安装 Flutter 与 Dart 的 VS Code 扩展后，仍选择
`MERP QAS Android Debug`，再选择 Android 模拟器或手机。项目没有 Windows
桌面端工程，因此“Windows 同事开发”指在 Windows 主机上开发 Android，不要选择
Windows 桌面设备。iOS 启动项只可在 macOS 使用。

代码检查与测试：

```bash
./tool/app analyze
./tool/app test
```

Windows 对应为 `.\tool\app.cmd analyze` 和 `.\tool\app.cmd test`。

构建矩阵：

```bash
# QAS 测试包
./tool/app build qas android  # arm64-v8a release APK
./tool/app build qas ios      # development IPA
IOS_OTA_BASE_URL=https://example.com/merp/ios ./tool/app build qas ios-ota

# PRD 正式包，本地需输入 prd 二次确认
./tool/app build prd android  # arm64-v8a release AAB
./tool/app build prd ios      # App Store IPA

# CI 无交互执行示例
CI=true BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build prd android
```

`ios-ota` 会构建 Ad Hoc IPA，并在 `build/ios/ota/qas` 生成可放到服务器的
`manifest.plist`。`IOS_OTA_BASE_URL` 必须填写服务器上最终存放 IPA 和 plist 的
HTTPS 目录，例如 `https://example.com/merp/ios`。生成后把该目录下的 IPA 和
`manifest.plist` 一起上传到服务器，安装链接格式为
`itms-services://?action=download-manifest&url=https://example.com/merp/ios/manifest.plist`。

命令会统一注入 Flavor、`config/<env>.json`、本地地图/WebView 配置、版本号和
构建编号，并在成功后打印实际产物的完整路径、环境、版本和 Git 提交。PRD 不提供
日常运行命令，也不会自动上传商店。Android 命令检测到终端 Java 低于 17 时，会
自动使用标准安装位置中的 Android Studio 内置 JDK。

环境配置：

- QAS 使用 `config/qas.json`，现有 QAS API 地址已迁移，始终走真实登录与真实菜单。
  默认关闭高频 Debug/Info
  追踪，只保留警告、错误、故障编号和应用内诊断信息；需要排查接口时可在
  `config/qas.local.json` 中临时设置 `"ENABLE_LOG": true`。
  VS Code 可直接按 F5 启动并在「调试控制台」查看日志；日志使用标准 ANSI 前景色，
  Error 为红色、Warning 为黄色。终端任务仅作为无需断点时的备用启动方式。
- PRD 使用 `config/prd.json`，生产 API 尚不能从仓库确认，当前留空并在构建前拦截。
- 本地或 CI 可生成被 Git 忽略的 `config/prd.local.json` 覆盖生产配置。
- 百度地图 AK 放在 `config/baidu_map.local.json`；WebView 私有参数放在
  `config/webview.local.json`。两者都不会进入 Git。

百度地图本地配置可从示例创建：

```bash
cp config/baidu_map.example.json config/baidu_map.local.json
```

打包注意事项：

- `config/baidu_map.local.json` 不能提交 Git；提交前执行 `git check-ignore -v config/baidu_map.local.json`。
- Android 百度 AK 会校验 applicationId 和签名 SHA1，release 签名变化后必须同步百度控制台。
- iOS 百度 AK 会校验 Bundle Identifier，Xcode 工程和百度控制台必须一致。
- Android PRD 使用 `com.delta.merpdelta`，QAS 使用 `com.delta.merpdelta.qas`，两者可同时安装。
- Android QAS release 使用 debug 签名作为测试包。PRD 必须配置
  `android/key.properties` 和生产 keystore，缺失时构建会失败，绝不回退到 debug 签名。
- Android Release 产物统一只包含 `arm64-v8a`；Debug 不限制 ABI，以保留
  Android Studio 和 VS Code 模拟器开发能力。
- iOS PRD 使用 `com.delta.merpdelta`，QAS 使用 `com.delta.merpdelta.qas`，共享
  Scheme 为 `prd` 和 `qas`。
- iOS IPA 需要匹配两个 Bundle ID 的证书和 Provisioning Profile；PRD 发布还需要
  Apple Distribution 证书和 App Store Connect 权限。
- iOS 必须打开 `ios/Runner.xcworkspace`，不要单独打开 `Runner.xcodeproj`。
- 修改百度插件、Gradle、Pod、权限、启动图或图标后，必须双端真机验证地图加载和点击定位。

仓库当前未绑定 CI 供应商。后续流水线只调用 `./tool/bootstrap` 和
`CI=true ./tool/app build prd <platform>`，不要在 CI 再维护一套 Flutter 参数。
CI 密钥至少包括 Android keystore 与四项 `key.properties` 值、PRD 环境配置、
百度平台 AK，以及 iOS Distribution 证书、私钥、Provisioning Profile 和
App Store Connect 凭证。

## 目录结构

```text
merp/
├── .run/                                    # Android Studio共享 Flutter运行配置
├── .vscode/                                 # VS Code QAS Flavor启动配置
├── config/                                  # QAS/PRD公共配置与本地覆盖模板
├── tool/                                     # 固定工具链、首次初始化和统一构建入口
│   ├── app / bootstrap                       # macOS 入口
│   ├── app.cmd / bootstrap.cmd               # Windows 入口
│   └── *.ps1                                 # Windows PowerShell 实现
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
│   │   │   └── auto_lock_guard.dart          # 自动锁屏、前后台计时和解锁流程
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
│   │   └── resources/                        # 首页内置展示清单
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

QAS 和生产配置默认使用真实菜单接口。请求参数由 `MENU_APP_ID=merp` 和 `MENU_FEATURE_SCOPE=at` 配置；离线排版开发请使用 `./tool/app run mock <android|ios>`，不要在 QAS 本地配置中打开 `MOCK_MENUS`。当前暂不使用接口返回的 `icon` 或 `iconUrl`，功能图标统一根据 `featureCode` 从客户端 `FeatureRegistry` 映射为 Material Icons，未知功能显示通用应用图标。

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
config/baidu_map.local.json
config/webview.local.json
```

填写或修改本地配置后重新生成 IDE配置：

```bash
./tool/app ide
```

PRD 首次构建时创建 `config/prd.local.json` 并填写真实生产地址；PRD 不提供本地
日常运行命令，只允许通过统一脚本构建：

```bash
./tool/app build prd android
./tool/app build prd ios
```

所有 `*.local.json` 均已加入 Git 忽略。QAS、Mock 与 PRD 使用独立安全存储命名空间，
不会互相读取 refresh token；QAS/PRD 首次进入各自环境需要登录一次，Mock 不保存登录会话。

百度地图当前接入 Android/iOS 基础地图与按需精确定位，不包含 Search SDK。真实 AK 放在 Git 忽略的
`config/baidu_map.local.json`，由 `tool/app` 和 Local IDE配置自动注入。

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
