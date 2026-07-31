# 百度地图跨平台接入与调试复盘

本文记录 MERP Flutter 项目中 Android/iOS 百度地图与精确定位能力的接入方式、验证命令和主要避坑点。当前实现目标是：基础地图可显示、用户主动点击后获取精确 BD-09LL 坐标、Android/iOS 真机均可运行，且真实 AK 不进入 Git。

## 当前接入结果

- Flutter 通过 FVM 固定工程版本运行。
- Android 和 iOS 均接入百度基础地图。
- Android 和 iOS 均接入百度单次精确定位。
- 定位坐标统一输出 `bd09ll`。
- 地图页只在用户进入并同意隐私后初始化百度地图 SDK。
- 定位权限只在用户点击定位按钮时申请。
- 不启用后台定位，不申请 Always 权限。
- 真实 AK 仅放在 `config/baidu_map.local.json`，该文件已被 Git 忽略。

## 依赖版本

当前版本在真机上验证通过：

```yaml
permission_handler: ^12.0.3
flutter_baidu_mapapi_base: 4.0.1+1
flutter_baidu_mapapi_map: 4.0.1
flutter_bmflocation: 3.8.4
```

百度 Flutter 插件版本不要随手升级。带 `+` 的部分版本包含非标准 Flutter 平台 API，升级后必须重新执行静态分析、Android 构建、iOS 构建和双端真机定位验证。

## AK 配置方式

真实密钥只允许放在本地文件：

```json
{
  "BAIDU_MAP_ANDROID_AK": "Android AK",
  "BAIDU_MAP_IOS_AK": "iOS AK"
}
```

把密钥文件保存后，通过项目统一入口启动。入口会自动加载该本地文件：

```bash
# macOS
./tool/app run qas android
```

```powershell
# Windows
.\tool\app.cmd run qas android
```

提交前必须确认：

```bash
git check-ignore -v config/baidu_map.local.json
git status --short
```

严禁把真实 AK 写入 Dart、Gradle、Info.plist、README、日志、截图或接口返回。

## Android 配置要点

Android AK 不能只靠 Dart 运行时配置，百度定位 SDK 还会读取 Manifest 中的 `com.baidu.lbsapi.API_KEY`。工程中使用 Gradle 从本地 ignored JSON 读取 AK，并写入 Manifest placeholder：

```kotlin
manifestPlaceholders["BAIDU_MAP_ANDROID_AK"] = readLocalBaiduMapAk()
```

Manifest 中保留：

```xml
<meta-data
    android:name="com.baidu.lbsapi.API_KEY"
    android:value="${BAIDU_MAP_ANDROID_AK}" />
```

Android 还需要自定义 Application 继承百度地图插件的 Application 基类，否则可能出现原生初始化空指针：

```kotlin
class MerpApplication : BmfMapApplication()
```

Manifest 的 application 节点要指定：

```xml
android:name=".MerpApplication"
```

权限策略：

- 保留 `ACCESS_FINE_LOCATION` 和 `ACCESS_COARSE_LOCATION`。
- 移除后台定位权限。
- 移除百度旧 SDK 可能传递的敏感或废弃权限。
- 只在用户点击定位时通过 `permission_handler` 请求前台权限。

## iOS 配置要点

iOS 使用运行时 AK 注入：

```dart
BMFMapSDK.setAgreePrivacy(true);
BMFMapSDK.setApiKeyAndCoordType(apiKey, BMF_COORD_TYPE.BD09LL);
```

iOS 真机运行前需要：

- Xcode 已配置 Development Team。
- 使用 `ios/Runner.xcworkspace` 而不是单独打开 `Runner.xcodeproj`。
- `ios/Pods` 完整安装。
- Bundle Identifier 与百度开放平台 iOS AK 配置完全一致。

常用命令：

```bash
./tool/bootstrap
cd ios && pod install --repo-update && cd ..
./tool/app run qas ios -d <iPhone device id>
```

如果日志提示 `地图所需资源文件不完整，请正确添加 mapapi.bundle`，先不要手动往 Xcode target 里加 bundle。CocoaPods 的 `[CP] Copy Pods Resources` 正常会复制 `mapapi.bundle`，手动添加反而会造成 `Multiple commands produce mapapi.bundle`。正确排查方式：

```bash
rg "mapapi.bundle" ios/Pods/Target\ Support\ Files/Pods-Runner
rm -rf build/ios/Debug-iphoneos build/ios/iphoneos/Runner.app
.fvm/flutter_sdk/bin/flutter build ios \
  --debug \
  --no-codesign \
  --flavor qas \
  --dart-define-from-file=config/qas.json \
  --dart-define-from-file=config/baidu_map.local.json
test -d build/ios/iphoneos/Runner.app/mapapi.bundle
du -sh build/ios/iphoneos/Runner.app/mapapi.bundle
```

本次验证中，clean build 后 `Runner.app/mapapi.bundle` 约为 9.4M。

## 初始化时序

推荐时序：

1. App 启动时只装配服务和检查配置，不调用百度 SDK。
2. 进入地图页后展示用途和隐私说明。
3. 用户点击同意后，调用百度地图隐私同意和 AK 初始化。
4. 创建原生地图视图。
5. 地图视图创建后注册加载、渲染、有效数据和状态变化回调。
6. 用户点击定位按钮后，再配置百度定位 SDK、检查系统定位服务、申请前台定位权限。
7. 单次定位成功后更新地图定位点和地图状态。

这个时序能同时满足隐私合规、最小权限和 Flutter 页面可恢复性。

## 地图加载回调避坑

iOS 上 `setMapDidLoadCallback` 有概率在 Dart 注册前已经由原生侧触发，导致 Flutter 误以为底图 15 秒内没有加载完成。

当前处理方式：

- 同时监听 `setMapDidLoadCallback`。
- 同时监听 `setMapDidFinishedRenderCallback`。
- 同时监听 `setMapRenderValidDataCallback`。
- 同时监听 `setMapStatusDidChangedCallback`。
- 原生视图创建后设置短延迟兜底，避免页面卡在 loading。
- 页面侧的 `_onMapLoaded` 做幂等处理，多个回调只处理一次。

另外，`BMFMapOptions.mapPadding` 在当前 iOS 插件组合下会输出 `mapPadding 不合法`，已移除。

## 定位回调避坑

Android 的 `flutter_bmflocation 3.8.4` 存在一个兼容问题：`setAgreePrivacy(true)` 原生端调用了百度 `LocationClient.setAgreePrivacy(true)`，但 MethodChannel 没有返回结果，Dart await 会一直挂起。

当前处理方式：

- Android 对 `setAgreePrivacy` 增加 500ms timeout。
- 超时后记录 warning，并按已设置隐私继续执行。
- iOS 仍然正常等待插件返回。

Android 成功定位类型需要显式识别：

- `61`
- `66`
- `161`

否则会把成功定位误判为错误，导致定位按钮一直 loading 或提示失败。

## 更新地图位置避坑

百度地图 Flutter 插件里 `setZoomTo` 标注为 Android 独有。iOS 调用会抛：

```text
MissingPluginException(No implementation found for method flutter_bmfmap/map/setZoomTo)
```

定位本身其实已经成功，失败发生在地图缩放更新阶段。当前改为跨平台可用的：

```dart
setNewMapStatus(
  mapStatus: BMFMapStatus(fLevel: 18, targetGeoPt: coordinate),
  animateDurationMs: 500,
)
```

这样中心点和缩放级别一次更新，Android/iOS 都能通过。

## 日志排查路径

定位按钮点击后，建议按这些阶段观察：

1. `定位按钮点击`
2. `创建新的定位请求`
3. `阶段 1/7 检查平台支持`
4. `阶段 2/7 检查隐私同意状态`
5. `阶段 3/7 检查定位 AK 配置`
6. `阶段 4/7 开始配置百度定位 SDK`
7. `阶段 5/7 检查系统定位服务开关`
8. `阶段 6/7 检查并申请前台定位权限`
9. `阶段 7/7 开始请求百度单次定位`
10. `收到百度定位原始回调`
11. `精确定位完成`
12. `地图已显示定位结果`
13. `定位 UI 退出 loading 状态`

如果卡在 4，优先检查插件隐私同意和 AK 配置。
如果卡在 7，优先检查系统定位服务、网络、百度 AK 包名/Bundle ID、iOS 精确位置开关。
如果定位成功但地图不动，优先检查是否误用了 Android 独有地图控制方法。

## 双端验证命令

静态检查：

```bash
./tool/app analyze
```

```powershell
.\tool\app.cmd analyze
```

Android QAS release 构建：

```bash
./tool/app build qas android
```

```powershell
.\tool\app.cmd build qas android
```

iOS debug 构建：

```bash
.fvm/flutter_sdk/bin/flutter build ios \
  --debug \
  --no-codesign \
  --flavor qas \
  --dart-define-from-file=config/qas.json \
  --dart-define-from-file=config/baidu_map.local.json
```

iOS 真机启动：

```bash
./tool/app run qas ios -d <iPhone device id>
```

## 已验证的关键现象

- Android 百度地图原生初始化空指针已通过自定义 `MerpApplication` 修复。
- Android 定位隐私同意 MethodChannel 不返回已通过 timeout 兼容。
- Android 定位成功类型已覆盖 `61/66/161`。
- iOS `mapapi.bundle` 已由 CocoaPods 正确复制到 App 包。
- iOS 地图加载不再依赖单一回调。
- iOS `setZoomTo` 异常已通过 `setNewMapStatus` 修复。
- iOS 真机定位日志显示约 10 米精度，并成功更新地图。

## 发布前检查清单

- 百度控制台 Android 包名、SHA1 与实际签名一致。
- 百度控制台 iOS Bundle Identifier 与工程一致。
- `config/baidu_map.local.json` 被 Git 忽略。
- Release 包使用正式签名，不再使用 debug signingConfig。
- Android/iOS 真机均完成“进入地图页 -> 加载底图 -> 点击定位 -> 地图显示定位点”的全链路验证。
- 日志中不打印真实 AK、经纬度和完整地址。
- 后台定位权限未声明。
- 隐私协议文案覆盖百度地图和百度定位 SDK。
