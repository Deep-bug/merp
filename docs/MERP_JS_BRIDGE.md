# MERP Vue2 JS Bridge

Vue2 页面在 MERP 手机端 WebView 中通过以下 Promise API 调用原生能力：

```js
window.MERPBridge.call(action, payload)
```

`window.MERPBridge` 由 Flutter WebView 注入，Vue2 不需要自行实现底层
`postMessage` 和回调匹配。`MerpBridgePlugin` 不是 npm 包，而是 Vue2 项目中的
本地工具模块。参考实现位于 `docs/vue2/merp-bridge.js`。

## Vue2 接入

### 1. 添加 Bridge 工具模块

在 Vue2 项目中新建 `src/utils/merp-bridge.js`：

```js
const READY_EVENT = 'MERPBridgeReady'
const READY_TIMEOUT = 10000

function createError(code, message, details) {
  return {
    code,
    message,
    details: details || {}
  }
}

function getBridge() {
  if (typeof window === 'undefined') return null

  const bridge = window.MERPBridge
  return bridge && typeof bridge.call === 'function' ? bridge : null
}

function waitUntilReady(timeoutMs = READY_TIMEOUT) {
  const bridge = getBridge()
  if (bridge) return Promise.resolve(bridge)

  if (typeof window === 'undefined') {
    return Promise.reject(
      createError('BRIDGE_UNAVAILABLE', '当前环境不支持手机端 Bridge')
    )
  }

  return new Promise((resolve, reject) => {
    let finished = false

    const cleanup = () => {
      clearTimeout(timer)
      window.removeEventListener(READY_EVENT, onReady)
    }

    const onReady = () => {
      const nativeBridge = getBridge()
      if (!nativeBridge || finished) return

      finished = true
      cleanup()
      resolve(nativeBridge)
    }

    const timer = setTimeout(() => {
      if (finished) return

      finished = true
      cleanup()
      reject(
        createError(
          'BRIDGE_NOT_READY',
          '等待手机端 Bridge 注入超时，请在 MERP App 中打开页面',
          { timeoutMs }
        )
      )
    }, timeoutMs)

    window.addEventListener(READY_EVENT, onReady)
    // 防止 Bridge 在首次检查与事件监听之间完成注入，造成事件丢失。
    onReady()
  })
}

export const merpBridge = {
  isReady() {
    return Boolean(getBridge())
  },

  waitUntilReady,

  async call(action, payload = {}) {
    if (typeof action !== 'string' || !action.trim()) {
      throw createError('INVALID_ACTION', 'Bridge action 不能为空')
    }

    const bridge = await waitUntilReady()
    return bridge.call(action.trim(), payload)
  },

  getCurrentPosition(options = {}) {
    return this.call('location.getCurrentPosition', options)
  },

  scanCode(options = {}) {
    return this.call('scanner.scanCode', options)
  },

  takePhoto(options = {}) {
    return this.call('camera.takePhoto', options)
  },

  pickFiles(options = {}) {
    return this.call('file.pick', options)
  },

  getDeviceInfo() {
    return this.call('device.getInfo', {})
  },

  logout() {
    return this.call('auth.logout', {})
  },

  showSystemMessage(options = {}) {
    return this.call('system.showMessage', options)
  },

  confirm(options = {}) {
    return this.call('system.confirm', options)
  }
}

export default {
  install(Vue) {
    Object.defineProperty(Vue.prototype, '$merpBridge', {
      value: merpBridge
    })
  }
}
```

### 2. 在 main.js 注册

```js
import Vue from 'vue'
import App from './App.vue'
import MerpBridgePlugin from '@/utils/merp-bridge'

Vue.use(MerpBridgePlugin)

new Vue({
  render: h => h(App)
}).$mount('#app')
```

### 3. 在组件中调用

可以调用通用 Action：

```js
async loadDeviceInfo() {
  try {
    const result = await this.$merpBridge.call('device.getInfo', {})
    console.log('设备信息', result)
  } catch (error) {
    console.error('设备信息获取失败', error)
  }
}
```

也可以调用语义化方法：

```js
async locate() {
  try {
    const result = await this.$merpBridge.getCurrentPosition({
      timeoutMs: 25000,
      maximumAccuracyMeters: 50
    })
    console.log('定位结果', result)
  } catch (error) {
    console.error('定位失败', error)
  }
}
```

页面可监听 Bridge 注入完成事件：

```js
window.addEventListener('MERPBridgeReady', function () {
  console.log(window.MERPBridge.version)
})
```

## 测试能力

| 能力 | Action | 主要参数 |
| --- | --- | --- |
| 定位 | `location.getCurrentPosition` | `timeoutMs`, `maximumAccuracyMeters` |
| 扫码 | `scanner.scanCode` | `formats`，为空时支持全部格式 |
| 拍照 | `camera.takePhoto` | `includeBase64`, `imageQuality`, `maxWidth` |
| 文件 | `file.pick` | `allowMultiple`, `includeBase64`, `allowedExtensions`, `maximumFileBytes` |
| 设备信息 | `device.getInfo` | 无 |
| 系统消息 | `system.showMessage` | `mode: toast/dialog`, `title`, `message` |
| 系统确认 | `system.confirm` | `title`, `message` |
| 退出登录 | `auth.logout` | 无，手机端固定二次确认 |

扫码示例：

```js
async scanBusinessCode() {
  try {
    const result = await this.$merpBridge.scanCode({
      formats: ['qrCode', 'barCode']
    })
    console.log('扫码内容', result.text)
    console.log('码制', result.format)
  } catch (error) {
    if (error.code !== 'SCANNER_CANCELLED') {
      console.error('扫码失败', error)
    }
  }
}
```

`barCode` 是常见一维条码集合的兼容别名；也可指定 `code128`、`ean13`、
`dataMatrix`、`pdf417` 等具体格式。扫码成功返回：

```js
{ text: 'MERP-ORDER-10001', format: 'qrCode' }
```

## 扫码原生实现

扫码能力由以下三个 Flutter 文件组成，职责从 WebView 协议到相机界面依次分层：

| 文件 | 主要职责 |
| --- | --- |
| `lib/core/bridge/merp_native_bridge.dart` | 接收 `scanner.scanCode`，校验参数、打开扫码页并回传 Promise 结果 |
| `lib/core/device/scanner_models.dart` | 把 Vue2 的 `formats` 字符串数组转换为原生码制，并固定返回 JSON 契约 |
| `lib/features/scanner/barcode_scanner_page.dart` | 提供原生相机预览、扫码框、闪光灯、摄像头切换和权限异常处理 |

### 1. Bridge 动作分发

在 `MerpNativeBridge.handleMessage` 中注册动作：

```dart
case 'scanner.scanCode':
  await _scanCode(requestId, payload);
```

`_scanCode` 解析 Vue2 参数，进入全屏原生页面；用户返回时统一转换为 Bridge
resolve/reject。取消扫码不是空结果，而是 `SCANNER_CANCELLED`，这样业务页能明确
区分“用户取消”和“没有拿到内容”。

```dart
Future<void> _scanCode(String requestId, Object? payload) async {
  final options = payload is Map<String, dynamic>
      ? payload
      : const <String, dynamic>{};
  late final List<BarcodeFormat> formats;
  try {
    formats = parseScannerFormats(options['formats']);
  } on ScannerFormatException catch (error) {
    await _reject(requestId, 'SCANNER_INVALID_FORMATS', error.message);
    return;
  }

  final result = await Navigator.of(context).push<ScanCodeResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BarcodeScannerPage(formats: formats),
    ),
  );
  if (result == null) {
    await _reject(requestId, 'SCANNER_CANCELLED', '用户取消扫码');
    return;
  }
  await _resolve(requestId, result.toJson());
}
```

原生注入对象和 Vue2 工具模块都提供语义化方法：

```js
scanCode(options) {
  return this.call('scanner.scanCode', options || {})
}
```

### 2. 格式解析与返回模型

`scanner_models.dart` 只处理跨端数据，不涉及页面或 WebView。`formats` 缺省或传
空数组时不限制码制；`barCode` 会展开为常见一维条码集合；不能识别的格式会返回
`SCANNER_INVALID_FORMATS`，不会静默降级为全格式扫描。

```dart
class ScanCodeResult {
  const ScanCodeResult({required this.text, required this.format});

  final String text;
  final BarcodeFormat format;

  Map<String, Object?> toJson() => {
    'text': text,
    'format': format.name,
  };
}

List<BarcodeFormat> parseScannerFormats(Object? value) {
  if (value == null || value is List && value.isEmpty) {
    return const [];
  }
  if (value is! List) {
    throw const ScannerFormatException('formats 必须是字符串数组');
  }

  final formats = <BarcodeFormat>{};
  for (final item in value) {
    final name = item.toString().trim();
    if (name == 'barCode') {
      formats.addAll(_oneDimensionalFormats);
      continue;
    }
    final format = _formatByName[name];
    if (format == null) {
      throw ScannerFormatException('不支持的扫码格式：$name');
    }
    formats.add(format);
  }
  return formats.toList(growable: false);
}
```

当前支持 `qrCode`、`barCode`、`code128`、`code39`、`code93`、`codabar`、
`dataMatrix`、`ean13`、`ean8`、`itf14`、`upcA`、`upcE`、`pdf417` 和 `aztec`。

### 3. 原生相机扫码页

`barcode_scanner_page.dart` 基于 `mobile_scanner` 创建一个完整的 Flutter 页面。
页面只接受模型层转换后的 `BarcodeFormat`，因此不会再解析 WebView 数据。

```dart
late final MobileScannerController _controller = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates,
  formats: widget.formats,
  autoZoom: true,
);

Future<void> _handleDetection(BarcodeCapture capture) async {
  if (_completed) return;

  final barcode = capture.barcodes
      .where((item) => (item.rawValue ?? item.displayValue ?? '').isNotEmpty)
      .firstOrNull;
  final text = barcode?.rawValue ?? barcode?.displayValue;
  if (barcode == null || text == null || text.isEmpty) return;

  _completed = true;
  await _controller.stop();
  if (mounted) {
    Navigator.of(context).pop(
      ScanCodeResult(text: text, format: barcode.format),
    );
  }
}
```

页面提供返回按钮、闪光灯、前后摄像头切换、点击对焦、扫描框和系统设置入口。相机
权限被拒绝时会在原生页面说明原因，并提供“打开系统设置”按钮；用户从页面返回则
由 Bridge 转为 `SCANNER_CANCELLED`。

### 扫码错误码

| 错误码 | 含义 | Vue2 处理建议 |
| --- | --- | --- |
| `SCANNER_CANCELLED` | 用户主动退出扫码页 | 通常忽略，不提示错误 |
| `SCANNER_INVALID_FORMATS` | `formats` 不是数组或包含未支持码制 | 修正调用参数 |
| `BRIDGE_CONTEXT_UNAVAILABLE` | WebView 页面已不可用 | 重新进入业务页面后再试 |
| `BRIDGE_ERROR` | 原生相机初始化或运行异常 | 记录 `incidentId` 后提示重试 |

### 依赖和平台权限

扫码依赖为 `mobile_scanner: ^7.4.0`。Android 已声明 `CAMERA` 权限；iOS 已声明
`NSCameraUsageDescription`，授权文案已说明拍照和扫码用途。Android 使用 ML Kit
内置扫码模型，首次引入会增加大约 3-10MB 的 APK 体积，但无需依赖 Google Play
Services 下载模型，适合企业设备和无 Google 服务的机型。

## Vue2 驱动手机端退出登录

远端页面不要自行删除 Web 缓存来模拟登出，应调用手机端统一认证流程：

```js
async logoutFromApp() {
  try {
    const result = await this.$merpBridge.logout()
    if (!result.accepted) {
      return
    }
    // 手机端随后会清理 token、用户内存资料和权限菜单，并自动返回登录页。
  } catch (error) {
    console.error('手机端退出登录失败', error)
  }
}
```

`auth.logout` 会强制显示原生确认框，防止远端脚本或误触直接清除手机端会话。
用户确认后 Promise 返回：

```js
{ accepted: true, cancelled: false }
```

用户取消时返回 `{ accepted: false, cancelled: true }`。确认退出后 Flutter 调用服务端
登出接口；无论服务端是否可用，本地 refresh token 都会被清理，路由守卫会自动切换
到登录页。Vue2 不需要也不应该接触 refresh token。

Bridge 错误统一以 Promise reject 返回：

```js
{
  code: 'FILE_CANCELLED',
  message: '用户取消选择文件',
  incidentId: null,
  details: {}
}
```

文件和照片只有在 `includeBase64: true` 时返回 Base64。单文件最大限制由
`maximumFileBytes` 控制，手机端最高允许配置为 20MB。设备信息不返回 IDFA、
IDFV、Android ID 等永久标识。

Vue2 完整测试组件见 `docs/vue2/MerpBridgeTest.vue`。部署后通过以下参数把手机端
测试 WebView 指向页面地址：

```bash
--dart-define=BRIDGE_TEST_URL=https://your-domain.example/merp-bridge-test
```

当前远程测试页为：

```text
https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/my_task.html#/flutterTest
```

带临时 `quake-ticket` 的完整地址存放在 Git 忽略的
`config/webview.local.json`。本地运行时追加：

```bash
--dart-define-from-file=config/webview.local.json
```
