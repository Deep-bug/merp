# WebView 中 Vue 调用手机硬件能力改造方案

## 1. 背景

MERP 原 Cordova 外壳中，Vue 页面可以通过 Cordova 插件调用相机、定位、扫码等手机能力。升级到 Flutter 外壳后，旧 Vue/Vue3 页面仍运行在 WebView 中，但不再直接依赖 Cordova 插件。

推荐改造方式：

```text
Vue 页面
  ↓ window.MERPBridge
Flutter WebView Bridge
  ↓ 统一 action 分发
Flutter 原生能力服务
  ↓
Android / iOS 插件或 SDK
```

核心目标：

- Vue 页面不直接依赖 Android/iOS 插件。
- 手机硬件能力统一由 Flutter 管控。
- 权限申请、错误码、返回结构在 Flutter 侧统一。
- 后续 Vue 页面逐步迁移 Flutter 原生页面时，底层设备能力可以复用。

## 2. 当前已验证能力

公网 Vue3 测试页：

```text
http://42.192.127.131:8088/merp-bridge-test
```

Flutter App 内验证入口：

```text
首页
  → 左侧抽屉
  → 系统设置
  → WebView Bridge 测试
```

已验证：

- Vue3 页面可检测 `window.MERPBridge` 注入。
- Vue3 页面可调用 Flutter `ping`。
- Vue3 页面可读取 Flutter 登录态。
- Vue3 页面可读取 Flutter 运行时资源清单。
- Vue3 页面可调用 Flutter Toast。
- Vue3 页面可调用 Flutter 相机。
- Vue3 页面可收到 Flutter 返回的成功结果或错误对象。

## 3. Bridge 总体协议

### 3.1 文档与地址边界（Bridge 2.4.0）

- 业务入口必须匹配 App 配置中的 H5 origin（协议、域名和端口）；菜单返回的 URL 不会自动加入白名单。额外第一方域名在 `AppConfig.trustedWebOrigins` 中显式维护。
- 当前 WebView 只允许同 origin 导航。跨域业务跳转需要回到 App 功能入口重新换码；第三方登录/下载跳转需单独评估，不应直接扩大权限。
- `window.MERPBridge.call(...)` 及现有快捷方法保持不变。注入脚本自动携带文档 nonce，业务代码不需要管理它；不再接受直接向 `MerpNative.postMessage` 发送的无 nonce 消息。
- 导航、重试、关闭页面或登录身份变化后，旧消息和旧异步回调不再生效。返回结果不会交给另一个文档。
- 目前为旧 H5 兼容保留 `auth.getSession` 的 access-token 字段和首次请求 Authorization；refresh token 始终不对 H5 开放。
- nonce 与顶层 origin 校验是纵深防护，并非原生 frame-origin 鉴别，也不能防住同源 XSS。H5 服务仍需维护 CSP、可信脚本/iframe 来源和后端鉴权。

协议脚本在 `lib/core/bridge/bridge_script.dart`，原生分发在 `merp_native_bridge.dart`，地址策略在 `web_access_policy.dart`。可运行 `node --test test/core/bridge/bridge_script_contract_test.mjs` 验证 JS 协议，不需要安装 npm 包。

Flutter 注入到 WebView 的对象：

```js
window.MERPBridge
```

通用调用方式：

```js
await window.MERPBridge.call(action, payload)
```

请求结构：

```json
{
  "id": "request-id",
  "documentNonce": "由注入脚本自动填充，业务代码不传",
  "action": "camera.takePhoto",
  "payload": {}
}
```

成功返回：

```js
Promise.resolve(data)
```

失败返回：

```js
Promise.reject({
  code: 'CAMERA_CANCELLED',
  message: '用户取消拍照'
})
```

## 4. Flutter 侧文件分工

当前核心文件：

```text
lib/core/bridge/
└── merp_native_bridge.dart       # WebView Bridge 注入、action 分发、结果回调

lib/core/device/
├── camera_service.dart           # 相机能力封装
├── location_service.dart         # 定位能力边界，后续接入地图/定位 SDK
└── map_sdk_service.dart          # 地图 SDK 初始化占位

lib/features/legacy/
└── legacy_web_page.dart          # 旧 Vue 页面 WebView 容器

lib/features/bridge_test/
└── bridge_test_page.dart         # Vue3 Bridge 测试页容器
```

改造原则：

- `merp_native_bridge.dart` 只做协议解析和 action 分发。
- `core/device` 负责封装手机硬件能力。
- Vue 页面只认 `window.MERPBridge`，不关心 Flutter 插件细节。
- 每个硬件能力必须有统一错误码。

## 5. Vue3 侧标准接入方式

### 5.1 等待 Bridge 注入

不要在页面初始化时假设 `window.MERPBridge` 已经存在。

```ts
import { onMounted, onUnmounted, ref } from 'vue'

const bridgeReady = ref(false)

function refreshBridgeState() {
  bridgeReady.value = Boolean(window.MERPBridge)
}

onMounted(() => {
  refreshBridgeState()
  window.addEventListener('MERPBridgeReady', refreshBridgeState)
  setTimeout(refreshBridgeState, 300)
  setTimeout(refreshBridgeState, 1000)
})

onUnmounted(() => {
  window.removeEventListener('MERPBridgeReady', refreshBridgeState)
})
```

### 5.2 统一调用封装

建议 Vue3 项目封装一个文件：

```text
src/bridge/merpBridge.ts
```

示例：

```ts
type BridgeError = {
  code: string
  message: string
}

function getBridge() {
  if (!window.MERPBridge) {
    throw {
      code: 'WEB_BRIDGE_NOT_READY',
      message: 'MERPBridge 尚未注入，请在 Flutter WebView 中打开页面'
    }
  }
  return window.MERPBridge
}

export async function callNative<T>(
  action: string,
  payload: Record<string, unknown> = {}
): Promise<T> {
  try {
    return await getBridge().call<T>(action, payload)
  } catch (error) {
    const bridgeError = error as BridgeError
    console.warn('[MERPBridge]', action, bridgeError)
    throw bridgeError
  }
}
```

业务页面只调用封装后的方法，不直接散落 `window.MERPBridge.call(...)`。

## 6. 相机能力改造

### 6.1 Vue3 调用方式

仅返回文件路径和文件信息：

```ts
const photo = await window.MERPBridge.takePhoto({
  includeBase64: false,
  imageQuality: 80,
  maxWidth: 1280
})
```

返回 base64，用于页面立即预览：

```ts
const photo = await window.MERPBridge.takePhoto({
  includeBase64: true,
  imageQuality: 80,
  maxWidth: 1280
})

previewUrl.value = photo.dataUrl
```

返回结构：

```json
{
  "path": "app-temp-file-path",
  "name": "image.jpg",
  "mimeType": "image/jpeg",
  "size": 123456,
  "base64": "...",
  "dataUrl": "data:image/jpeg;base64,..."
}
```

### 6.2 Flutter 侧实现位置

```text
lib/core/device/camera_service.dart
lib/core/bridge/merp_native_bridge.dart
```

Bridge action：

```text
camera.takePhoto
```

### 6.3 建议错误码

| 错误码 | 含义 |
|---|---|
| `CAMERA_PERMISSION_DENIED` | 用户拒绝相机权限 |
| `CAMERA_CANCELLED` | 用户取消拍照 |
| `CAMERA_UNAVAILABLE` | 当前设备没有可用相机 |
| `CAMERA_CAPTURE_FAILED` | 拍照失败 |

### 6.4 注意事项

- 普通业务上传建议 `includeBase64: false`，避免 WebView 内存压力。
- 需要页面预览时再传 `includeBase64: true`。
- 后续可扩展 `native.uploadFile`，让 Flutter 直接上传本地文件，Vue 只拿上传结果。

## 7. 定位能力改造

当前项目已经接入百度 iOS 单次精确定位：

```text
lib/core/device/location_service.dart
```

`LocationService` 统一处理隐私、前台权限、BD-09 坐标、精度门槛、超时与错误码。
完整 Vue2 示例见 [Vue2 精确定位 Bridge](vue2_location_bridge.md)。

### 7.1 推荐 Bridge action

```text
location.getCurrentPosition
```

Vue3 调用：

```ts
const location = await window.MERPBridge.call('location.getCurrentPosition', {
  timeoutMs: 25000,
  maximumAccuracyMeters: 50
})
```

推荐返回结构：

```json
{
  "latitude": 22.543096,
  "longitude": 114.057865,
  "accuracyMeters": 30,
  "coordinateType": "bd09ll",
  "provider": "baidu",
  "address": "广东省深圳市南山区...",
  "timestamp": "2026-06-29T10:00:00.000"
}
```

### 7.2 Flutter 侧实现位置

- `lib/core/device/location_service.dart`：业务编排与统一错误。
- `lib/core/device/baidu_location_adapter_mobile.dart`：百度最高精度单次定位。
- `lib/core/bridge/merp_native_bridge.dart`：Vue 调用、隐私确认和结果返回。
- `lib/features/map/map_page.dart`：地图定位按钮和定位点。

权限只在 `locateOnce` 被用户操作触发后申请。Android/iOS 权限声明如下：

Android：

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

iOS：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>用于地图定位、签到和现场业务处理。</string>
```

### 7.3 建议错误码

| 错误码 | 含义 |
|---|---|
| `LOCATION_PERMISSION_DENIED` | 用户拒绝定位权限 |
| `LOCATION_PERMISSION_PERMANENTLY_DENIED` | 用户永久拒绝，需要手动去系统设置 |
| `LOCATION_SERVICE_DISABLED` | 系统定位服务未开启 |
| `LOCATION_TIMEOUT` | 定位超时 |
| `LOCATION_KEY_MISSING` | 定位密钥未配置 |
| `LOCATION_ACCURACY_INSUFFICIENT` | 定位结果未达到业务精度阈值 |
| `LOCATION_SDK_FAILED` | 百度定位 SDK 失败 |

## 8. 其他手机硬件能力改造方式

### 8.1 扫码

推荐 action：

```text
scanner.scanCode
```

Vue3 调用：

```ts
const result = await window.MERPBridge.call('scanner.scanCode', {
  formats: ['qrCode', 'barCode']
})
```

返回：

```json
{
  "text": "MERP-ORDER-10001",
  "format": "qrCode"
}
```

### 8.2 文件选择

推荐 action：

```text
file.pick
```

Vue3 调用：

```ts
const file = await window.MERPBridge.call('file.pick', {
  accept: ["image/*", "application/pdf"],
  multiple: false
})
```

### 8.3 原生上传

推荐 action：

```text
file.upload
```

适合大文件、图片、视频，不建议全部转 base64 给 WebView。

Vue3 调用：

```ts
const uploadResult = await window.MERPBridge.call('file.upload', {
  path: photo.path,
  bizType: 'work-order-attachment'
})
```

### 8.4 震动

推荐 action：

```text
device.vibrate
```

Vue3 调用：

```ts
await window.MERPBridge.call('device.vibrate', {
  durationMs: 80
})
```

### 8.5 设备信息

推荐 action：

```text
device.getInfo
```

返回：

```json
{
  "platform": "android",
  "appVersion": "1.0.0",
  "deviceModel": "Pixel 8",
  "systemVersion": "Android 15"
}
```

## 9. Action 命名规范

统一使用：

```text
模块.动作
```

示例：

```text
bridge.ping
auth.getSession
resource.getManifest
camera.takePhoto
location.getCurrentPosition
scanner.scanCode
file.pick
file.upload
device.vibrate
device.getInfo
```

不要使用：

```text
takePhoto
getLocation
scan
```

原因：后续 action 变多后容易冲突。

## 10. 统一错误对象

所有失败都返回：

```json
{
  "code": "LOCATION_PERMISSION_DENIED",
  "message": "用户拒绝定位权限"
}
```

Vue3 侧统一处理：

```ts
try {
  const result = await callNative('location.getCurrentPosition')
} catch (error) {
  const bridgeError = error as BridgeError
  showToast(bridgeError.message)
}
```

## 11. 权限处理原则

权限必须由 Flutter 侧统一申请和解释：

- Vue 页面只发起业务请求。
- Flutter 判断权限是否已授权。
- 未授权时 Flutter 发起系统权限申请。
- 用户拒绝后 Flutter 返回统一错误码。
- Vue 页面只展示业务友好的提示文案。

不要让 Vue 页面直接判断 Android/iOS 权限状态。

## 12. 安全要求

1. Bridge 只允许白名单 action。

   不在 `switch` 中注册的 action 必须返回：

```text
BRIDGE_UNSUPPORTED_ACTION
```

2. 不要把高风险能力暴露给任意网页。

   WebView 只加载公司可信域名，例如：

```text
42.192.127.131:8088
正式环境域名
```

3. 生产环境使用 HTTPS。

   当前测试页使用 HTTP，仅用于验证阶段。

4. token 优先通过 WebView 请求头传递。

```http
Authorization: Bearer <token>
```

`auth.getSession` 主要用于测试和特殊场景，不建议业务页面到处手动拼 token。

5. 大文件不要走 base64。

   图片、视频、PDF 建议走原生上传或分片上传。

## 13. 验收清单

每新增一个硬件能力，都按下面清单验收：

- Android 真机通过。
- Android 模拟器通过。
- iOS 真机或模拟器通过。
- 普通浏览器打开页面不会误判，显示“等待注入”。
- Flutter Web/Windows 打开 WebView 测试页不会红屏。
- 用户拒绝权限时 Vue 页面能收到明确错误码。
- 用户取消操作时 Vue 页面能收到明确错误码。
- 网络异常、SDK 未配置、设备不支持都有错误提示。
- 返回结构有文档。
- Vue3 页面有 try/catch。
- Flutter 侧 action 已加入白名单。

## 14. 推荐改造顺序

建议按风险从低到高推进：

1. `bridge.ping`：验证链路。
2. `app.showToast`：验证 Flutter UI 回调。
3. `auth.getSession`：验证登录态。
4. `camera.takePhoto`：验证相机。
5. `location.getCurrentPosition`：验证按需权限、精度阈值和拒绝恢复。
6. `scanner.scanCode`：接入扫码。
7. `file.pick` / `file.upload`：处理文件。
8. `device.getInfo` / `device.vibrate`：补齐设备能力。

## 15. 总结

WebView 中的 Vue 页面调用手机硬件能力，推荐统一走 Flutter Bridge：

```text
Vue3 页面调用 window.MERPBridge
Flutter Bridge 校验 action
Flutter device service 调用原生插件或 SDK
Flutter 返回统一 JSON
Vue3 页面展示结果或错误
```

这套方案已经通过公网 Vue3 测试页验证，后续新增定位、扫码、文件等能力时，只需要按同一模式扩展 action 和 device service。
