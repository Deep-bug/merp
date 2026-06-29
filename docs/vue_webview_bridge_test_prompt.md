# Vue3 WebView Bridge 测试页提示词

下面这段提示词可以直接复制给前端同事或 AI，让它生成一个 Vue3 测试页面，用于验证 WebView 中的 Vue 应用调用 Flutter 手机端能力。

## 提示词

```text
请帮我写一个 Vue3 单文件组件，用于测试 Flutter WebView 注入的 window.MERPBridge。

技术要求：
1. 使用 Vue3 Composition API，推荐 <script setup lang="ts">。
2. 如果不方便使用 TypeScript，可以输出 <script setup> 版本，但结构仍然按 Vue3 写。
3. 页面要适配手机端 WebView，宽度 100%，按钮适合手指点击。
4. 页面不依赖 UI 组件库，使用普通 HTML/CSS 即可。
5. 页面加载后检测 window.MERPBridge 是否存在。
6. 如果 Bridge 还没有注入，需要监听 window 的 MERPBridgeReady 事件。
7. 组件卸载时要移除事件监听。
8. 所有调用都要 try/catch，并把成功结果或失败错误显示在页面日志区。
9. 给 window.MERPBridge 写一个基础 TypeScript 类型声明，避免 TS 报错。

需要测试的 Bridge API：

1. Ping Flutter：
await window.MERPBridge.ping()

2. 获取 Flutter 登录态：
await window.MERPBridge.getSession()

3. 获取 Flutter 当前运行时资源清单：
await window.MERPBridge.getResourceManifest()

4. 调用 Flutter Toast：
await window.MERPBridge.showToast('Vue3 页面调用 Flutter Toast 成功')

5. 调用相机拍照，仅返回路径：
await window.MERPBridge.takePhoto({
  includeBase64: false,
  imageQuality: 80,
  maxWidth: 1280
})

6. 调用相机拍照，并返回 base64 预览：
const photo = await window.MERPBridge.takePhoto({
  includeBase64: true,
  imageQuality: 80,
  maxWidth: 1280
})
如果 photo.dataUrl 存在，在页面中用 <img :src="previewUrl" /> 展示预览。

7. 异常测试：
await window.MERPBridge.call('unsupported.action', {})
这个调用应当失败，页面要显示错误 code 和 message。

页面 UI 要包含：
- 顶部标题：MERP Vue3 Bridge 测试页
- Bridge 状态：等待注入 / 已注入
- 7 个测试按钮
- 日志输出区，显示 JSON.stringify(result, null, 2)
- 拍照图片预览区
- 清空日志按钮

Bridge 错误对象格式：
{
  code: string,
  message: string
}

请输出完整可运行的 Vue3 SFC 代码，包含：
- <template>
- <script setup lang="ts">
- <style scoped>

代码里要写清楚每个按钮调用的是哪个 action。
```

## Flutter 侧已支持的 API

Flutter WebView 会注入：

```js
window.MERPBridge
```

当前支持：

| JS 方法 | Flutter action | 用途 |
|---|---|---|
| `MERPBridge.ping()` | `bridge.ping` | 验证 JS 到 Flutter 链路 |
| `MERPBridge.getSession()` | `auth.getSession` | 获取当前登录态 |
| `MERPBridge.getResourceManifest()` | `resource.getManifest` | 获取静态资源清单 |
| `MERPBridge.showToast(message)` | `app.showToast` | 调用 Flutter Toast |
| `MERPBridge.takePhoto(options)` | `camera.takePhoto` | 调用原生相机 |
| `MERPBridge.call(action, payload)` | 自定义 action | 通用调用入口 |

## Flutter 内置测试入口

平台 Vue3 测试页已部署：

```text
http://42.192.127.131:8088/merp-bridge-test
```

普通浏览器打开时会显示“等待注入”，这是正常现象；只有放到 Flutter WebView 中，页面才能检测到 `window.MERPBridge`。

Flutter App 内测试入口：

```text
首页
  → 左侧抽屉
  → 系统设置
  → WebView Bridge 测试
```

该页面会加载平台地址，并注入同一套 `window.MERPBridge` 协议，用于验证真实 Vue3 页面调用 Flutter 手机端能力。

当前平台地址使用 HTTP。Android 侧已为测试放开 `usesCleartextTraffic`，iOS 侧已为 WebView 测试放开 `NSAllowsArbitraryLoadsInWebContent`。生产环境建议改成 HTTPS。

## Vue3 接入示例片段

### 类型声明

```ts
type BridgeError = {
  code: string
  message: string
}

type TakePhotoOptions = {
  includeBase64?: boolean
  imageQuality?: number
  maxWidth?: number
}

type CameraCapture = {
  path: string
  name: string
  mimeType: string
  size: number
  base64?: string | null
  dataUrl?: string | null
}

type MerpBridge = {
  version: string
  call<T = unknown>(action: string, payload?: Record<string, unknown>): Promise<T>
  ping(): Promise<unknown>
  getSession(): Promise<unknown>
  getResourceManifest(): Promise<unknown>
  showToast(message: string): Promise<unknown>
  takePhoto(options?: TakePhotoOptions): Promise<CameraCapture>
}

declare global {
  interface Window {
    MERPBridge?: MerpBridge
  }
}
```

### Bridge Ready 监听

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

### 调用示例

```ts
async function runPing() {
  try {
    const result = await window.MERPBridge?.ping()
    console.log(result)
  } catch (error) {
    const bridgeError = error as BridgeError
    console.warn(bridgeError.code, bridgeError.message)
  }
}
```

## Vue3 接入注意事项

1. 不要在组件初始化时立刻假设 `window.MERPBridge` 一定存在。
2. 所有 Bridge 调用必须 `try/catch`。
3. 拍照 `base64` 可能比较大，普通上传场景建议 `includeBase64: false`。
4. 需要页面立即预览时再使用 `includeBase64: true`。
5. 正式业务里 token 建议优先通过 WebView 请求头传递。

Flutter 旧系统容器会给 WebView 请求加：

```http
Authorization: Bearer <token>
```

`getSession()` 主要用于测试和特殊场景，不建议旧 Vue 页面到处手动拼 token。
