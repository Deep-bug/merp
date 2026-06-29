# Vue2 WebView Bridge 测试页提示词

下面这段提示词可以直接复制给前端同事或 AI，让它生成一个 Vue2 测试页面，用于验证 WebView 中的 Vue 应用调用 Flutter 手机端能力。

## 提示词

```text
请帮我写一个 Vue2 单文件组件或 Vue2 页面，用于测试 Flutter WebView 注入的 window.MERPBridge。

技术要求：
1. 使用 Vue2 语法，不要使用 Vue3 Composition API。
2. 页面要适配手机端 WebView，宽度 100%，按钮适合手指点击。
3. 页面不依赖 UI 组件库，使用普通 HTML/CSS 即可。
4. 页面加载后检测 window.MERPBridge 是否存在。
5. 如果 Bridge 还没有注入，需要监听 window 的 MERPBridgeReady 事件。
6. 所有调用都要 try/catch，并把成功结果或失败错误显示在页面日志区。

需要测试的 Bridge API：

1. Ping Flutter：
await window.MERPBridge.ping()

2. 获取 Flutter 登录态：
await window.MERPBridge.getSession()

3. 获取 Flutter 当前运行时资源清单：
await window.MERPBridge.getResourceManifest()

4. 调用 Flutter Toast：
await window.MERPBridge.showToast('Vue 页面调用 Flutter Toast 成功')

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
如果 photo.dataUrl 存在，在页面中用 <img :src="photo.dataUrl" /> 展示预览。

7. 异常测试：
await window.MERPBridge.call('unsupported.action', {})
这个调用应当失败，页面要显示错误 code 和 message。

页面 UI 要包含：
- 顶部标题：MERP Vue Bridge 测试页
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

请输出完整可运行的 Vue2 页面代码，并在代码里写清楚每个按钮调用的是哪个 action。
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

App 内已经提供一个不依赖后端的内置测试页：

```text
首页
  → 左侧抽屉
  → 系统设置
  → WebView Bridge 测试
```

该页面运行在 Flutter WebView 中，使用同一套 `window.MERPBridge` 协议，可以先验证 Flutter 侧能力是否正常。

## Vue2 接入注意事项

1. 不要在页面初始化时立刻假设 `window.MERPBridge` 一定存在。

   推荐：

```js
mounted() {
  if (window.MERPBridge) {
    this.bridgeReady = true
    return
  }
  window.addEventListener('MERPBridgeReady', () => {
    this.bridgeReady = true
  })
}
```

2. 所有 Bridge 调用必须 try/catch。

```js
try {
  const result = await window.MERPBridge.ping()
  console.log(result)
} catch (error) {
  console.warn(error.code, error.message)
}
```

3. 拍照 base64 可能比较大。

列表、表单普通上传场景建议：

```js
includeBase64: false
```

需要页面立即预览时再使用：

```js
includeBase64: true
```

4. 正式业务里 token 建议优先通过 WebView 请求头传递。

Flutter 旧系统容器会给 WebView 请求加：

```http
Authorization: Bearer <token>
```

`getSession()` 主要用于测试和特殊场景，不建议旧 Vue2 页面到处手动拼 token。
