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

项目推荐使用 FVM 固定 Flutter 版本，版本配置见 `.fvmrc`。当前验证版本为
Flutter `3.44.6`。

使用 FVM 的同学：

```bash
fvm install
fvm flutter pub get
fvm flutter run --dart-define-from-file=config/baidu_map.local.json
```

不使用 FVM 的同学，需要先保证本机 `flutter --version` 与 `.fvmrc` 一致或兼容，
然后把命令里的 `fvm flutter` 换成 `flutter`：

```bash
flutter pub get
flutter run --dart-define-from-file=config/baidu_map.local.json
```

百度地图和定位依赖本地 AK 配置。复制示例文件后填写真实 AK，真实文件已被 Git 忽略：

```bash
cp config/baidu_map.example.json config/baidu_map.local.json
```

Android debug 包：

```bash
fvm flutter build apk --debug \
  --dart-define-from-file=config/baidu_map.local.json
```

Android release 包：

```bash
fvm flutter build apk --release \
  --dart-define-from-file=config/baidu_map.local.json
```

iOS debug 构建校验：

```bash
fvm flutter build ios --debug --no-codesign \
  --dart-define-from-file=config/baidu_map.local.json
```

iOS 正式签名包需要在 Xcode 中配置 Apple Developer Team、Bundle ID、证书和
provisioning profile。未配置签名时，可先使用无签名构建产物进行后续重签或内部验证。

打包注意事项：

- `config/baidu_map.local.json` 不能提交 Git；提交前执行 `git check-ignore -v config/baidu_map.local.json`。
- Android 百度 AK 会校验 applicationId 和签名 SHA1，release 签名变化后必须同步百度控制台。
- iOS 百度 AK 会校验 Bundle Identifier，Xcode 工程和百度控制台必须一致。
- 当前 Android release 暂用 debug signingConfig，生产发布前必须改成正式签名。
- iOS 必须打开 `ios/Runner.xcworkspace`，不要单独打开 `Runner.xcodeproj`。
- 修改百度插件、Gradle、Pod、权限、启动图或图标后，必须双端真机验证地图加载和点击定位。

## 目录结构

```text
merp/
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
│   │   └── resources/                        # 运行时静态资源清单和缓存控制
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
│   │   ├── resources/                        # 静态资源更新验证页面
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
├── tools/                                    # E 盘环境配置和图标生成工具
├── l10n.yaml                                 # Flutter 官方多语言生成配置
├── pubspec.yaml                              # Flutter 版本、依赖和资源配置
└── README.md                                 # 当前架构与团队协作约定
```

## 启动流程

```text
Android 原生 Splash
    -> main 安装 Zone / Flutter / Platform 异常捕获
    -> 立即渲染 MerpBootstrapApp 品牌加载页
    -> AppDependencies 并行读取设置、资源缓存和地图占位初始化
    -> 恢复 Token、会话和菜单权限
    -> MerpApp 装配语言、路由、主题和自动锁屏
```

`main.dart` 不等待磁盘或网络后再 `runApp`，可以缩短中低端手机冷启动空白时间。具体业务权限和定位仍按需加载，避免首屏一次初始化全部插件。

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

`AppLogger` 当前写入 Android Studio/VS Code 调试终端，并保留最近 200 条到内存环形缓冲区。系统设置中的“诊断日志”可查看、复制和清空日志。

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
- `resource.getManifest`
- `app.getLocale`
- `app.showToast`
- `camera.takePhoto`
- `location.getCurrentPosition`
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

当前 API 默认地址是 `http://10.146.152.51:31234`。生产环境建议使用
`--dart-define` 注入 API、Vue 地址和地图配置，真实密钥不得提交 Git：

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.146.152.51:31234 \
  --dart-define=LEGACY_VUE_BASE_URL=https://erp.example.com/mobile
```

百度地图当前接入 Android/iOS 基础地图与按需精确定位，不包含 Search SDK。真实 AK 放在 Git 忽略的
`config/baidu_map.local.json`，启动时使用：

```bash
flutter run --dart-define-from-file=config/baidu_map.local.json
```

隐私初始化、Android/iOS 配置、CocoaPods、后端权限结构和故障排查见
[百度地图跨平台接入与调试复盘](docs/baidu_map_cross_platform_debugging.md)。

## 验证命令

```bash
flutter pub get
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/baidu_map.local.json
flutter build ios --debug --no-codesign --dart-define-from-file=config/baidu_map.local.json
```

提交前必须保证格式化、静态分析和自动化测试通过；涉及 Android 权限、启动图、WebView 或插件升级时，还需构建 APK 并在 API 24 设备验证。
