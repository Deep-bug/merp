# MERP Flutter 开发、运行与发布教程

本文档适用于 MERP Flutter 工程的日常开发、真机调试、测试包构建和正式发布。
项目已经统一封装 FVM、Flutter 版本、QAS/PRD Flavor 和双平台构建参数。

日常不要直接拼接复杂的 `flutter build` 命令。macOS 统一使用 `./tool/app`，
Windows 统一使用 `.\tool\app.cmd`。

## 1. 环境与应用矩阵

| 环境 | Android | iOS | 用途 |
|---|---|---|---|
| QAS | `com.delta.merpdelta.qas` | `com.delta.merpdelta.qas` | 日常开发、测试包 |
| PRD | `com.delta.merpdelta` | `com.delta.merpdelta` | 正式发布 |

QAS 应用名称为 `MERP QAS`，可与 PRD 同时安装。

构建产物：

| 命令 | 产物 |
|---|---|
| `build qas android` | QAS release APK |
| `build qas ios` | QAS development IPA |
| `build prd android` | PRD release AAB |
| `build prd ios` | PRD App Store IPA |

## 2. 新电脑首次初始化

### 2.1 安装系统工具

macOS 至少需要：

- Git
- Android Studio 和 Android SDK
- Xcode
- CocoaPods

Windows 至少需要：

- Git for Windows
- Android Studio 和 Android SDK
- VS Code（可选）及 Flutter、Dart 扩展
- Windows PowerShell 5.1 或更高版本

不需要提前全局安装 FVM。项目会下载固定的 FVM `4.1.2`，并安装
`.fvmrc` 指定的 Flutter `3.44.6`。

### 2.2 初始化项目

进入项目根目录：

```bash
# macOS
cd /path/to/merp
./tool/bootstrap
./tool/app doctor
```

Windows 在 CMD 或 PowerShell 中进入自己的项目目录：

```powershell
.\tool\bootstrap.cmd
.\tool\app.cmd doctor
```

`bootstrap` 会：

1. 检查操作系统和 CPU 架构。
2. 下载并校验当前平台对应的固定版本 FVM。
3. 安装 Flutter `3.44.6`。
4. 获取 Flutter 依赖。
5. 检查 Java 和 Android SDK；macOS 额外检查 Xcode 和 CocoaPods。

以后重新拉取依赖或排查环境时可以再次执行，缓存会被复用。

`android/local.properties` 保存本机 SDK 路径，必须继续被 Git 忽略。Android
Gradle 同步会优先读取其中有效的 `flutter.sdk`；文件不存在或路径已经失效时，
自动使用项目根目录的 `.fvm/flutter_sdk`，并在本机生成或修复
`local.properties`。如果 `sdk.dir` 缺失或无效，会继续尝试
`ANDROID_SDK_ROOT`、`ANDROID_HOME`；macOS 再尝试
`$HOME/Library/Android/sdk`，Windows 再尝试
`%LOCALAPPDATA%\Android\Sdk`。如果两处 Flutter SDK 都不存在，先在项目根目录
执行当前系统的 `bootstrap`，无需从其他电脑复制 `local.properties`。

如果 doctor 提示 Android licenses 未接受：

```bash
.fvm/flutter_sdk/bin/flutter doctor --android-licenses
```

Windows：

```powershell
.\.fvm\flutter_sdk\bin\flutter.bat doctor --android-licenses
```

## 3. 配置本地环境

### 3.1 QAS 配置

QAS 基础配置位于：

```text
config/qas.json
```

它包含 QAS API、环境名称、菜单 Mock 和日志开关。个人覆盖值可以写入：

```text
config/qas.local.json
```

该文件已被 Git 忽略。

### 3.2 百度地图 AK

首次配置：

```bash
cp config/baidu_map.example.json config/baidu_map.local.json
```

Windows 初始化时会自动创建该本地文件；也可以执行
`Copy-Item config\baidu_map.example.json config\baidu_map.local.json` 后填写。

然后在 `config/baidu_map.local.json` 中填写 Android 和 iOS AK。真实 AK 不得提交。

Android 百度 AK 需要匹配：

- Application ID
- APK 签名证书 SHA1

iOS 百度 AK 需要匹配 Bundle Identifier。

QAS 和 PRD 包标识不同，因此百度控制台通常需要分别配置。

### 3.3 WebView 本地参数

带 ticket、员工账号或本地调试 URL 的配置放在：

```text
config/webview.local.json
```

不要把 ticket、Token 或员工私有参数写进已跟踪配置文件。

### 3.4 PRD 配置

仓库中的 `config/prd.json` 不保存未经确认的生产 API。正式构建前创建：

```text
config/prd.local.json
```

示例：

```json
{
  "APP_ENV": "prd",
  "AUTH_ENVIRONMENT": "merp",
  "API_BASE_URL": "由发布负责人填写真实生产地址",
  "MOCK_MENUS": false,
  "ENABLE_LOG": false
}
```

`API_BASE_URL` 为空时，PRD 构建会被安全拦截。

## 4. 日常开发流程

### 4.1 拉取代码后

```bash
# macOS
git pull
./tool/bootstrap
```

```powershell
# Windows
git pull
.\tool\bootstrap.cmd
```

只有依赖或工具链发生变化时才需要重新执行 bootstrap，重复执行不会重复下载 FVM。

### 4.2 写完代码后的推荐顺序

```bash
./tool/app analyze
./tool/app test
./tool/app run qas android
```

Windows：

```powershell
.\tool\app.cmd analyze
.\tool\app.cmd test
.\tool\app.cmd run qas android
```

开发 iOS 时将最后一条改为：

```bash
./tool/app run qas ios
```

本地开发只运行 QAS，不提供 `run prd`。
Windows 只能开发、运行和构建 Android；iOS 必须使用 macOS 和 Xcode。

### 4.3 指定真机

查看设备：

```bash
.fvm/flutter_sdk/bin/flutter devices
```

Windows 对应 `.\.fvm\flutter_sdk\bin\flutter.bat devices`。

指定设备：

```bash
./tool/app run qas android -d <android-device-id>
./tool/app run qas ios -d <ios-device-id>
```

Windows 使用 `.\tool\app.cmd run qas android -d <android-device-id>`。

没有传 `-d` 时，脚本会自动选择当前平台的第一个可用设备。

### 4.4 热重载

`run` 命令启动后：

- 输入 `r`：热重载。
- 输入 `R`：热重启。
- 输入 `q`：停止运行。

修改 Dart 页面和一般业务逻辑通常使用热重载。修改 Gradle、Manifest、Podfile、
Info.plist、原生权限、插件或启动图后，必须停止并重新构建。

## 5. Android 开发与打包

### 5.1 Android 真机运行

1. 在手机中开启开发者选项和 USB 调试。
2. 连接数据线并允许电脑调试。
3. 确认设备：

```bash
# macOS 默认路径
$HOME/Library/Android/sdk/platform-tools/adb devices
```

Windows 可以直接执行 `adb devices`；如果找不到 `adb`，使用
`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe devices`，或把
`platform-tools` 加入 Path。

4. 运行 QAS：

```bash
./tool/app run qas android
```

### 5.2 使用 Android Studio

Android Studio 用于查看 Logcat、设备状态和原生 Gradle 配置。日常 Flutter 启动仍建议
使用统一入口运行，以确保 Flavor 和环境参数不会遗漏：macOS 使用
`./tool/app run qas android`，Windows 使用
`.\tool\app.cmd run qas android`。

仓库已提供可跨电脑使用的 Android Studio Flutter Run Configuration：

- `MERP QAS Android`：只读取仓库内的 `config/qas.json`，任何完成初始化的电脑都能启动。
- `MERP QAS Android (Local)`：由当前系统的 `bootstrap` 或 `app ide` 自动生成，
  额外读取被 Git 忽略的地图、WebView和 QAS 本地覆盖配置。

如果需要手动核对 Run Configuration：

- Dart entrypoint：`lib/main.dart`
- Build flavor：`qas`
- Additional run args：

```text
--dart-define-from-file=config/qas.json
--dart-define-from-file=config/baidu_map.local.json
--dart-define-from-file=config/webview.local.json
```

不要使用 Android Studio 自动产生的无 Flavor `app` 配置；它会错误寻找
`app-debug.apk`。正确的 QAS 产物是 `app-qas-debug.apk`。

### 5.2.1 VS Code

仓库的 `.vscode/launch.json` 已提供：

- `MERP QAS Android Debug`
- `MERP QAS Android Profile`
- `MERP QAS Android Debug (Local)`
- `MERP QAS iOS Debug`
- `MERP QAS iOS Debug (Local)`

共享启动项只依赖仓库配置；Local 启动项需要先执行当前系统的 `bootstrap` 或
`app ide`。`.vscode/settings.json` 只使用 `.fvm/flutter_sdk` 相对路径，
不得写入某位开发者的 Windows、macOS SDK 绝对路径。

Android/iOS 移动端启动项不设置固定 `deviceId`。运行前在 VS Code 右下角选择
当前模拟器、Simulator 或真机，再按 `F5`；共享配置会使用 Flutter 扩展当前选中的
真实设备 ID。`android` 和 `ios` 是平台名称，不是可跨电脑使用的设备 ID。

Windows 同事运行 Android 时同样选择 `MERP QAS Android Debug`，不需要 Windows
专属启动项。仓库当前没有 `windows/` 桌面端工程，所以 Windows 主机只用于开发
Android；iOS 启动项只能在 macOS 使用。

### 5.3 构建 QAS APK

```bash
./tool/app analyze
./tool/app test
./tool/app build qas android
```

Windows 对应：

```powershell
.\tool\app.cmd analyze
.\tool\app.cmd test
.\tool\app.cmd build qas android
```

脚本完成后会打印实际 APK 完整路径。当前典型路径为：

```text
build/app/outputs/apk/qas/release/app-qas-release.apk
```

安装到真机：

```bash
$HOME/Library/Android/sdk/platform-tools/adb install -r \
  build/app/outputs/apk/qas/release/app-qas-release.apk
```

### 5.4 配置 Android PRD 签名

复制示例：

```bash
cp android/key.properties.example android/key.properties
```

Windows 使用
`Copy-Item android\key.properties.example android\key.properties`。

填写：

```properties
storeFile=/绝对路径/production-upload-keystore.jks
storePassword=由发布负责人提供
keyAlias=由发布负责人提供
keyPassword=由发布负责人提供
```

`key.properties` 和 keystore 已被 Git 忽略。不要将密码写进 Gradle 或 CI 配置文件。

没有生产签名时，PRD 构建会明确失败，不会使用 debug 签名代替。

### 5.5 构建 Android PRD AAB

先设置正式版本：

```bash
BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build prd android
```

Windows PowerShell：

```powershell
$env:BUILD_NAME = "1.2.0"
$env:BUILD_NUMBER = "108"
.\tool\app.cmd build prd android
```

本地会显示 PRD 警告，输入：

```text
prd
```

才会继续。构建产物为 `.aab`，用于 Google Play 或企业应用发布平台。

构建后至少检查：

- Application ID 是 `com.delta.merpdelta`。
- 使用生产签名，不是 Android Debug 证书。
- `versionCode` 大于已发布版本。
- 百度 Android AK 包名和签名 SHA1 匹配。
- 登录、WebView、地图、定位、相机、文件和扫码完成真机回归。

### 5.6 只构建 arm64-v8a

如果所有目标设备都支持 64 位 ARM，可以在 `android/app/build.gradle.kts` 的
`defaultConfig` 中配置：

```kotlin
ndk {
    abiFilters += setOf("arm64-v8a")
}
```

配置前先检查目标设备：

```bash
adb shell getprop ro.product.cpu.abilist
```

输出必须包含 `arm64-v8a`。限制后，32 位 ARM 手机和 x86_64 模拟器将无法运行。
如果开发仍依赖模拟器，建议只限制 release 变体。

## 6. iOS 开发与打包

### 6.1 iOS 真机准备

1. 用数据线连接 iPhone。
2. iPhone 信任当前 Mac，并开启开发者模式。
3. 打开：

```text
ios/Runner.xcworkspace
```

不要打开 `Runner.xcodeproj`。

4. 在 Xcode 的 Signing & Capabilities 中确认 Team。
5. `qas` Scheme 使用 `com.delta.merpdelta.qas`。
6. `prd` Scheme 使用 `com.delta.merpdelta`。

### 6.2 iOS 真机运行

命令行：

```bash
./tool/app run qas ios
```

Xcode：

1. Scheme 选择 `qas`。
2. 设备选择连接的 iPhone。
3. Run Configuration 使用 `Debug-qas`。
4. 点击运行。

从 Xcode 运行时也必须保证 QAS 的 Dart define 已配置；团队日常优先使用
`./tool/app run qas ios`，避免遗漏参数。

### 6.3 构建 QAS IPA

```bash
./tool/app analyze
./tool/app test
./tool/app build qas ios
```

脚本使用 development 导出方式。成功后会打印 IPA 完整路径，当前典型路径：

```text
build/ios/ipa/merp.ipa
```

该 IPA 只能安装到 Provisioning Profile 包含的测试设备。

### 6.4 配置 iOS PRD 发布签名

PRD 发布需要：

- Apple Distribution 证书及私钥。
- `com.delta.merpdelta` 对应的 App Store Provisioning Profile。
- Apple Developer Team 权限。
- App Store Connect 应用记录和上传权限。

证书、私钥、Provisioning Profile 和 App Store Connect 凭证不得提交 Git。

### 6.5 构建 iOS PRD IPA

```bash
BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build prd ios
```

本地输入 `prd` 后，脚本以 App Store 方式归档和导出。构建成功不代表已上传商店；
上传和发布是独立步骤。

构建后检查：

- Scheme 为 `prd`。
- Bundle Identifier 为 `com.delta.merpdelta`。
- Display Name 为 `MERP`。
- 使用 Apple Distribution 签名。
- `CFBundleShortVersionString` 和 `CFBundleVersion` 正确。
- 百度 iOS AK 与 PRD Bundle ID 匹配。
- 真机完成登录恢复、WebView、Bridge、地图定位和系统返回回归。

## 7. 版本号规则

项目默认版本来自 `pubspec.yaml`：

```yaml
version: 1.0.0+1
```

- `1.0.0`：对用户展示的版本号。
- `1`：内部构建编号。

构建时可以覆盖：

```bash
BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build qas android
```

Android 的 `BUILD_NUMBER` 对应 `versionCode`，iOS 对应 `CFBundleVersion`。每次正式
上传都必须使用比商店现有版本更大的构建编号。

## 8. CI 接入

仓库没有绑定特定 CI 供应商。流水线只需调用统一入口：

```bash
./tool/bootstrap
./tool/app analyze
./tool/app test
CI=true BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build prd android
```

iOS：

```bash
CI=true BUILD_NAME=1.2.0 BUILD_NUMBER=108 ./tool/app build prd ios
```

`CI=true` 只跳过本地交互确认，不会关闭生产配置和签名检查。

CI Secret 至少包含：

- `config/prd.local.json` 所需生产配置。
- 百度 Android/iOS AK。
- Android keystore 和签名密码。
- iOS Distribution 证书、私钥和 Provisioning Profile。
- App Store Connect 凭证（只有上传任务需要）。

## 9. 发布前检查清单

### 公共检查

- `git status` 中没有误提交的本地配置、Token 或签名文件。
- `./tool/app analyze` 通过。
- `./tool/app test` 通过。
- 版本号和构建编号正确。
- QAS 验证通过后再构建 PRD。

### Android

- PRD AAB 包标识正确。
- 使用生产签名。
- minSdk 仍满足 Android 7 目标设备。
- 在最低版本和主流高版本真机上完成回归。
- 百度地图 AK 与签名 SHA1 匹配。

### iOS

- PRD Scheme 和 Bundle ID 正确。
- Distribution 证书和 Profile 有效。
- 最低支持版本真机完成回归。
- 百度 `mapapi.bundle`、地图和定位正常。
- IPA 验证通过后再上传 App Store Connect。

## 10. 常见问题

### 找不到 FVM

不要执行全局 `fvm`。macOS 运行：

```bash
./tool/bootstrap
```

Windows 运行：

```powershell
.\tool\bootstrap.cmd
```

### Android 找不到设备

```bash
adb kill-server
adb start-server
adb devices
```

确认手机已允许 USB 调试。

### Android PRD 提示 signing is not configured

这是预期保护。检查 `android/key.properties` 和 keystore，不要改回 debug 签名。

### iOS 提示 requires a development team

打开 `ios/Runner.xcworkspace`，选择 Runner target，在 Signing & Capabilities 中选择
正确 Team，并确认当前 Bundle ID 已在 Apple Developer 后台注册。

### iOS 提示 Provisioning Profile 缺少设备

QAS development IPA 需要将真机 UDID 加入开发者后台并重新生成 Profile。PRD App
Store Profile 不需要登记具体测试设备。

### 修改配置后应用仍使用旧值

`--dart-define` 是编译期配置，热重载不会替换。停止应用后重新执行：

```bash
./tool/app run qas android
```

或：

```bash
./tool/app run qas ios
```

### WebView 或百度插件修改后表现异常

停止运行并完整重建。iOS 必要时先执行：

```bash
cd ios
pod install
```

然后返回项目根目录通过 `./tool/app` 启动。
