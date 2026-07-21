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

  takePhoto(options = {}) {
    return this.call('camera.takePhoto', options)
  },

  pickFiles(options = {}) {
    return this.call('file.pick', options)
  },

  getDeviceInfo() {
    return this.call('device.getInfo', {})
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
| 拍照 | `camera.takePhoto` | `includeBase64`, `imageQuality`, `maxWidth` |
| 文件 | `file.pick` | `allowMultiple`, `includeBase64`, `allowedExtensions`, `maximumFileBytes` |
| 设备信息 | `device.getInfo` | 无 |
| 系统消息 | `system.showMessage` | `mode: toast/dialog`, `title`, `message` |
| 系统确认 | `system.confirm` | `title`, `message` |

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
