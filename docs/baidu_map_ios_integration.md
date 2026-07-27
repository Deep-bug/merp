# 百度地图 iOS 基础地图接入说明

## 本次范围

当前接入百度 Android/iOS 基础地图与按需精确定位：

- 已接入 `flutter_baidu_mapapi_base` 与 `flutter_baidu_mapapi_map`。
- 已接入 `flutter_bmflocation: 3.8.4`，输出 BD-09 坐标、精度和地址。
- 未接入 Search SDK，不提供 POI、地址或路线检索。
- App 启动和进入页面时不申请定位权限，只有用户主动定位时才申请前台权限。
- 不启用后台定位，不声明 Always/后台定位权限。
- Android 已支持前台精确定位；Web 暂不启用，后续需单独接入 JS SDK。

依赖固定为 `flutter_baidu_mapapi_map: 4.0.1`。截至 2026-07-15，`4.0.1+1`
包含鸿蒙专用 `TargetPlatform.ohos` API，标准 Flutter 3.44.5 无法编译，因此不能升级。
定位插件同样固定为不带 `+` 的 `3.8.4`，带 `+` 的版本是鸿蒙版本。
升级百度插件前必须同时执行 Flutter 静态分析、测试和 Android/iOS 构建验证。

## 密钥配置

真实 AK 只存放在 Git 忽略文件 `config/baidu_map.local.json`：

```json
{
  "BAIDU_MAP_ANDROID_AK": "你的 Android AK",
  "BAIDU_MAP_IOS_AK": "你的 iOS AK"
}
```

仓库只提交 `config/baidu_map.example.json`。严禁在 Dart、Info.plist、日志、
截图或业务接口中写入真实 AK。

百度 Android AK 会校验包名与 SHA1，当前 Android applicationId 为
`com.delta.merpdelta`；iOS AK 会校验 Bundle Identifier，当前 iOS 标识为
`com.delta.merpdelta`。百度开放平台控制台中的应用配置必须与工程完全一致。
如果公司正式包名不同，应先统一修改工程和百度控制台配置。

## macOS / iOS 启动步骤

Windows 不能编译或运行 iOS，以下命令需在安装 Xcode 与 CocoaPods 的 macOS 执行：

```bash
flutter pub get
cd ios
pod install --repo-update
cd ..
flutter run --dart-define-from-file=config/baidu_map.local.json
```

也可以用 Xcode 打开 `ios/Runner.xcworkspace`。通过 Xcode 启动时，需要在
Scheme 的 Run Arguments 中加入：

```text
--dart-define-from-file=config/baidu_map.local.json
```

更稳定的团队做法是统一使用 Flutter 命令或 VS Code `launch.json` 启动，避免成员漏传 AK。

## 隐私与初始化时序

`MapSdkService.initialize()` 在启动阶段只校验配置，不调用百度 SDK。首次进入地图页：

1. 展示百度地图用途和隐私政策地址。
2. 用户点击“同意并继续”。
3. 本地记录隐私版本并调用 `BMFMapSDK.setAgreePrivacy(true)`。
4. 注入 iOS AK 与 BD-09 坐标系。
5. 创建原生地图视图；15 秒未收到加载回调时展示可重试错误页和故障编号。
6. 只有点击“我的位置”或 Vue2 主动调用 Bridge 时，才申请系统前台定位权限。
7. Android 请求高精度定位并启用 GPS；定位使用 BD-09LL 坐标、最多三次候选结果，并按业务精度阈值决定是否成功。

若公司隐私协议版本变化，请修改 `MapSdkService` 中隐私缓存键的版本后缀，促使用户重新确认。

## 后端功能权限

真实菜单接口应返回一个原生地图功能，并仅向有权限的账号下发权限码：

```json
{
  "features": [
    {
      "id": "map-location",
      "title": "地图定位",
      "description": "百度基础地图",
      "icon": "map",
      "permissionCode": "map.location.view",
      "launchMode": "native",
      "route": "/native/map"
    }
  ],
  "permissionCodes": ["map.location.view"]
}
```

未授权账号在“全部功能”页看到灰色图标，首页不会显示该功能。

## 后续扩展边界

- 地图展示：继续封装在 `features/map/widgets/baidu_map_view.dart`。
- 定位：`LocationService` 统一处理按需授权、BD-09 坐标、精度门槛和错误码。
- 检索：新增 Search Repository，不让页面直接调用厂商 API。
- Android：AK 写入 Manifest placeholder，运行时仍通过 `--dart-define-from-file` 做配置校验，并在 API 24+ 真机验证。

## 常见故障

- 地图空白或鉴权失败：检查 AK、Bundle Identifier、网络和百度控制台应用状态。
- 找不到 Pod：执行 `flutter pub get` 后再运行 `pod install --repo-update`。
- 页面提示缺少配置：确认启动命令包含 `--dart-define-from-file`。
- 定位精度不足：移动到开阔位置、开启 iOS“精确位置”后重试。
- 永久拒绝权限：由用户点击“去设置”，应用不会自动跳转系统设置。
- 普通浏览器提示不支持：当前 Web 未接入 JS SDK。

Vue2 调用协议与错误处理见 [Vue2 精确定位 Bridge](vue2_location_bridge.md)。
