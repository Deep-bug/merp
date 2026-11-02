# MERP macOS 开发与企业发布教程

项目把“安装身份”和“后端环境”分开。开发者不再反复修改 Bundle ID、Team 或百度 Key。
日常运行使用个人身份 dev；给测试人员/员工分发使用企业身份 qas/prd。

## 1. 配置矩阵

| 安装身份 | Android applicationId | iOS 默认 Bundle ID | 默认签名 |
| --- | --- | --- | --- |
| dev | com.delta.merpdelta.qas | com.delta.merpdelta.qas | Android debug / Apple Development |
| qas | com.delta.MERPDeltaTest | com.delta.MERPDeltaTest | QAS keystore / 企业分发 |
| prd | com.delta.MERPDelta | com.delta.MERPDelta | PRD keystore / 企业分发 |

dev 沿用原先可调试的包名，并改名显示为 MERP DEV。QAS 显示 MERP QAS，PRD 显示 MERP。
企业身份保持旧 Cordova 应用包名；覆盖升级仍需匹配旧证书/签名及递增版本。
个人与企业包可以同时安装，App 本地数据分别保存。

`config/build_profiles.json` 是公共身份定义。Gradle 直接读取；iOS 的已提交 xcconfig
由维护者执行 `ruby tool/configure_ios_flavors.rb` 生成。仅调整公共身份时需要重新生成。
新电脑日常开发不需要安装 xcodeproj gem，也不需要执行该生成脚本。

## 2. 新电脑首次配置

macOS 需要 Xcode、Android Studio/SDK、CocoaPods 和系统 Ruby。
打开完整 Flutter 项目，不要只打开 android 目录。

```bash
./tool/bootstrap
./tool/app ide
```

bootstrap 安装项目固定版本 FVM/Flutter，获取依赖并创建本机配置。
`./tool/app ide` 可重复运行：只创建缺失配置，不覆盖已有 Team、AK 或接口地址。
只维护 macOS 团队入口；Windows app/bootstrap/configure_ide 脚本已删除。

`android/local.properties` 保存本机路径，不提交 Git。缺失时 Gradle 使用
`.fvm/flutter_sdk`，并尝试从 ANDROID_SDK_ROOT、ANDROID_HOME 或
`$HOME/Library/Android/sdk` 查找 Android SDK。不要复制别人电脑的 SDK 路径或 build 目录。

### 个人 iOS 签名：只填一次

打开 `ios/Config/Dev.local.xcconfig`：

```text
DEVELOPMENT_TEAM = 你的个人开发TeamID
// 只有当前 Bundle ID 无法由你的 Team 注册时才覆盖：
// MERP_BUNDLE_ID = com.yourcompany.merp.dev
```

在 Xcode 的 Settings → Accounts 登录个人开发账号，手机开启 Developer Mode，
连接电脑并信任。dev 使用 Automatic Signing 和 Apple Development。
本次迁移会把仓库中原有可用的开发 Team 移入本机 Dev.local.xcconfig；
其他同事按各自 Team 填写。不要把个人 Team 再写回 project.pbxproj。

可在终端核对解析结果：

```bash
xcodebuild -project ios/Runner.xcodeproj -scheme dev \
  -configuration Debug-dev -showBuildSettings |
  grep -E 'PRODUCT_BUNDLE_IDENTIFIER =|DEVELOPMENT_TEAM =|CODE_SIGN_STYLE ='
```

### 地图 Key：按安装身份填写

初始化会创建：

```text
config/baidu_map.dev.local.json
config/baidu_map.qas.local.json
config/baidu_map.prd.local.json
```

每份格式相同：

```json
{
  "BAIDU_MAP_ANDROID_AK": "",
  "BAIDU_MAP_IOS_AK": ""
}
```

dev 文件填写个人开发包的 Key。Android AK 必须匹配对应包名与签名 SHA1；
不同同事的 debug keystore 可能不同，应使用与自己签名匹配的 AK。
iOS AK 必须匹配最终 Bundle ID；若在 Dev.local.xcconfig 覆盖 Bundle ID，
同步修改 dev 文件里的 iOS AK，一次设置后不必日常切换。

旧 `baidu_map.local.json` 仅在 dev 文件不存在时复制到 dev；原文件保留。
企业配置从空模板创建，绝不把旧个人 Key 自动复制给企业包。
真实 Key 和所有 *.local 配置均被 Git 忽略。发布前脚本检查对应平台 Key 非空。

## 3. VS Code 日常使用

选择实际设备，然后在“运行和调试”选择：

- MERP DEV · QAS · Debug + HTTP Logs · iOS / Android
- MERP DEV · Mock · Debug · iOS / Android
- MERP DEV · PRD API · Debug + HTTP Logs · iOS / Android
- MERP DEV · QAS · Profile · iOS / Android
- MERP DEV · QAS · Release · iOS / Android

所有这些启动项都使用 `--flavor dev`，加载 dev 地图 Key。
Profile/Release 只改变运行模式，不改成企业包名或企业签名。
F5 前的任务会创建缺失的本机配置文件，已有配置不覆盖。
日志继续在 VS Code 调试控制台查看。

PRD API 调试前，必须在 `config/prd.local.json` 填写真实地址。
它仍是个人开发 App，不是企业 PRD 安装包。
Mock 复用 QAS 地址但跳过登录/菜单等接口；仅用于开发。

不要固定共享 deviceId；每次在右下角选择模拟器/真机。
修改原生权限、签名、插件、包名或 Key 后应停止应用并完整重建，不能只热重载。

终端等价命令：

```bash
./tool/app run qas ios
./tool/app run qas android
./tool/app run mock ios
./tool/app run prd ios
./tool/app run qas ios --profile
./tool/app run qas ios --release
./tool/app run qas android -d emulator-5554 -v
./tool/app run qas android --recover -d emulator-5554
```

`--recover` 从公共身份配置读取 dev 的真实包名，停止目标 App 并清理该设备 ADB
转发，不卸载 App、不清除数据。它会清理该设备全部 adb forward，先停止其他调试会话。
没有 -d 时选择第一个对应平台设备，多设备时建议明确指定。

## 4. Android Studio

打开项目根目录，使用共享的 `MERP DEV QAS Android` 或 `MERP DEV MOCK Android`。
执行 `./tool/app ide` 后，带 Local 的配置加载本机地图/WebView 设置。
不带 Local 的共享入口不加载私有 AK，适合无地图的基础启动。

不要使用自动生成的无 Flavor 原生 app 配置。开发产物为：

```text
build/app/outputs/flutter-apk/app-dev-debug.apk
```

开发 Debug/Profile 保留模拟器需要的 ABI；Android Release 继续只打包 ARM64。
调试 JDK 使用 Android Studio 内置 JDK 或 Java 17 以上。

## 5. Xcode 直接调试与归档

打开 `ios/Runner.xcworkspace`：

| Scheme | Run | Archive | 用途 |
| --- | --- | --- | --- |
| dev | Debug-dev，允许调试器 | Release-dev，个人签名 | 个人开发、性能验证 |
| qas | Release-qas，不附加调试器 | Release-qas，企业签名 | 企业 QAS |
| prd | Release-prd，不附加调试器 | Release-prd，企业签名 | 企业 PRD |

企业分发签名不提供断点/热重载，日常调试选择 dev。
dev 下需要 Profile 或 Release 时可编辑 Run 的 Build Configuration，签名身份仍是个人。

第一次新增 dev 配置后，在 macOS 执行：

```bash
./.fvm/flutter_sdk/bin/flutter pub get
cd ios
pod install
```

日常 Flutter 构建也会按需更新 Pods。无需删除 Podfile.lock 或升级全部 Pods。

直接用 Xcode 的 dev 默认连接 QAS；如果此前通过 Flutter CLI/VS Code 启动过 dev，
会沿用最近那次 dev 的 APP_ENV 和显式参数。希望 Xcode 固定某个接口环境时，在
Dev.local.xcconfig 设置：

```text
MERP_API_ENV = qas
```

也可写 prd/mock；该本地设置对 iOS 的 CLI 构建也生效。通常留空，让 VS Code 启动项决定。
企业 Scheme 始终强制对应接口环境，并清除 Mock 登录/更新开关。

工程的 Flutter 构建阶段通过 `tool/xcode_backend` 调用原始 Flutter 构建脚本。
它根据当前配置重新读取对应身份的地图文件，拒绝旧 Generated.xcconfig 中不匹配身份的参数。
不打印 Key；不修改 Flutter SDK。不要手动编辑 Generated.xcconfig。

## 6. 企业发布电脑

### iOS

安装公司提供的企业证书及其私钥（通常是带密码的 .p12），再安装两个 Bundle ID
各自匹配的企业 Provisioning Profile。填写：

```text
// ios/Config/Qas.local.xcconfig
DEVELOPMENT_TEAM = 企业TeamID
PROVISIONING_PROFILE_SPECIFIER = 企业QAS描述文件名称
```

`Prd.local.xcconfig` 填企业 Team 与 PRD Profile。这些设置只影响企业身份。
同时填写 baidu_map.qas.local.json / baidu_map.prd.local.json 的企业 AK。

```bash
./tool/app build qas ios
./tool/app build prd ios
```

两者都以 enterprise 导出 IPA。也可在 Xcode 选择 qas/prd → Product → Archive，
在 Organizer 导出企业分发包。导出用的 ExportOptions.plist 与 OTA manifest.plist
用途不同：前者给 Xcode 导出，后者给手机通过网页安装。

需要安装清单时：

```bash
IOS_OTA_BASE_URL=https://example.com/apps/qas ./tool/app build qas ios-ota
IOS_OTA_BASE_URL=https://example.com/apps/prd ./tool/app build prd ios-ota
```

产物位于 `build/ios/ota/qas` 或 `build/ios/ota/prd`。
把目录中的 IPA、manifest.plist 上传到相同 HTTPS 路径，安装链接形如：

```text
itms-services://?action=download-manifest&url=https://example.com/apps/qas/manifest.plist
```

清单读取 IPA 中真实 Bundle ID/版本，不从个人配置猜测。
脚本不会自动上传服务器。只有匹配企业证书/Profile 的机器才能完成企业签名导出。

### Android

QAS 使用 `android/key-qas.properties`，PRD 使用 `android/key.properties`。
分别从同名 example 复制，填写 keystore 路径、storePassword、keyAlias、keyPassword。
覆盖旧应用时必须用旧应用的真实签名；不能使用个人 debug 签名代替。

```bash
./tool/app build qas android # ARM64 APK
./tool/app build prd android # ARM64 AAB
```

沿用现有产物格式：QAS APK 可直接安装；AAB 不可直接用 adb 安装。
内部 PRD APK 若有需要，可使用相同 PRD 配置调用 Flutter build apk；仍需通过
Gradle 的身份、APP_ENV、地图 Key 和签名校验。
QAS/PRD 只开放 Release 变体；dev 用于 Debug/Profile/Release 开发验证。

## 7. 版本、维护和检查

版本来源：pubspec.yaml 的 `version: 1.0.0+10000`。
显示版本与五位数内部版本独立；构建编号递增，不从显示版本字符串推导。
更新接口低于 minimumVersionCode 强制升级，介于 minimum/latest 之间可选升级。

```bash
BUILD_NAME=1.2.0 BUILD_NUMBER=10001 ./tool/app build qas ios
./tool/app analyze
./tool/app test
ruby test/tool/build_configuration_test.rb
```

构建配置回归测试覆盖 dev 的三种接口环境、企业 Key 隔离、Mock 禁用、
Xcode 跨身份切换、CLI 身份及 enterprise 导出参数。它不需要企业私钥。

`./tool/app clean --dry-run` 预览项目空间清理；清理前停止 IDE 调试和构建。
清理会归档 Android Release APK/AAB、mapping/符号文件，不归档 iOS IPA/Archive，
保留 Pods、本地配置、签名和全局缓存。

改公共身份时，维护者安装 xcodeproj gem 后执行一次
`ruby tool/configure_ios_flavors.rb` 并提交生成的工程、xcconfig 和 Scheme。
生成器不会覆盖已有本地 Team。普通同事拉代码后无需执行它。

常见问题：

- 包名权限错误：只改 Dev.local.xcconfig 的 MERP_BUNDLE_ID，并同步个人地图 AK。
- Could not attach：确认选中 dev/Debug-dev，使用 Apple Development 和开发 Profile。
- 企业 Profile 不匹配：核对 Bundle ID 大小写、企业 Team、证书私钥和 Profile。
- 地图白屏/鉴权失败：检查当前身份对应的 AK；Android 还要核对实际签名 SHA1。
- Xcode 缺少 Pods 配置：pub get 后执行 pod install，不要用 xcodeproj 替代 xcworkspace。
- install/run 卡住：使用 -v 查看阶段，Android 可加 --recover；不会重置 App 数据。
