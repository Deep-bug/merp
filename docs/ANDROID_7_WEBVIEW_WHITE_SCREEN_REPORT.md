# Android 7 WebView 白屏问题排查与修复报告

## 1. 报告摘要

MERP Flutter 应用在 Android 7.0 设备上打开“WebView Bridge 测试”和“电子表单”时出现白屏；相同功能在较高版本 Android 和 iOS 上可以完成页面渲染。

经过 Android 7 真机在线调试，已确认问题不是登录 Token、Flutter 路由、WebView 主页面网络请求或 MERP JS Bridge 注入失败，而是旧设备的 Chrome 58 WebView 无法解析远端 Vue 发布包中的现代 JavaScript 语法。浏览器在 Vue 初始化前发生语法解析错误，导致 `#app` 没有挂载任何内容，最终表现为白屏。

推荐的根治方案是由 Vue2 项目输出真正兼容 Chrome 58 的 Legacy 构建，并在发布前对全部 JavaScript 产物执行兼容性检查。Flutter 端应补充 WebView 版本识别、Legacy 地址分流和白屏错误提示，但无法单独将不兼容的远端 JavaScript 自动转换为 Chrome 58 可执行代码。

## 2. 问题环境

### 2.1 复现设备

| 项目 | 实际信息 |
| --- | --- |
| 设备型号 | CipherLab RS31 |
| Android 版本 | Android 7.0 |
| Android API | API 24 |
| WebView 实现 | `com.android.chrome` |
| Chrome/WebView 版本 | `58.0.3029.83` |
| Android System WebView | `0.0.0.1`，停用状态 |
| MERP 包名 | `com.delta.merpdelta` |

Android 7 允许 Chrome 作为系统 WebView 提供者，因此 Android System WebView 显示停用并不代表设备没有 WebView。MERP 运行日志明确记录：

```text
WebViewFactory: Loading com.android.chrome version 58.0.3029.83
```

### 2.2 复现页面

JS Bridge 测试页：

```text
https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/flutter_test.html#/home
```

电子表单页：

```text
https://mcrmapi.deltaww.com.cn/mcom/webvue/1.0.beta/dist/eform.html#/home
```

## 3. 用户现象

1. MERP 首页、登录、设置等 Flutter 原生页面可以正常使用。
2. 点击 WebView Bridge 测试或电子表单后，Flutter 标题栏正常显示。
3. WebView 内容区域为空白，没有加载失败提示。
4. 页面没有 Token 错误，登录会话刷新成功。
5. 同类页面在高版本 Android 和 iOS 上通常可以渲染。
6. Cordova 旧应用中部分业务页面可以打开，造成问题可能来自 Flutter WebView 插件的疑问。

## 4. 排查过程

### 4.1 排除 Flutter 主流程问题

真机日志确认：

- Flutter 路由成功进入 `bridge-test` 或 `legacy-web`。
- WebView 原生视图创建成功。
- 域名 DNS 解析成功。
- 页面主文档完成加载。
- MERP Bridge JavaScript 注入成功。
- Flutter 进程未崩溃。

因此问题不在 Flutter 路由、PlatformView 创建或 Bridge 注册阶段。

### 4.2 增加受控 WebView 诊断

项目增加了由 `WEBVIEW_DIAGNOSTICS` 控制的诊断能力：

- 捕获 JavaScript 控制台消息。
- 捕获主页面和子资源错误。
- 记录 WebView User-Agent。
- 检查 `document.readyState`。
- 检查 `#app` 是否存在及其子节点数量。
- 记录页面加载的脚本数量与脚本地址。

该能力默认关闭，只有使用以下构建参数时启用：

```bash
--dart-define=WEBVIEW_DIAGNOSTICS=true
```

### 4.3 Android 7 真机证据

JS Bridge 测试页实际控制台错误：

```text
Uncaught SyntaxError: Unexpected token ...
```

页面 DOM 检查结果：

```json
{
  "readyState": "complete",
  "appExists": true,
  "appChildCount": 0,
  "bodyTextLength": 0,
  "scriptCount": 10
}
```

这些结果说明：

1. HTML 主文档已经成功返回。
2. Vue 挂载节点 `#app` 已存在。
3. Vue 尚未生成任何子节点。
4. JavaScript 在 Vue 初始化前已经停止执行。

同时日志记录：

```text
MERPBridge 注入完成
```

因此，Bridge 注入不是白屏原因。Bridge 虽然已经注入到 `window`，但 Vue 测试界面没有成功渲染，用户无法点击页面按钮调用 Bridge。

## 5. 页面资源分析

`flutter_test.html` 会继续加载下列主要资源：

```text
jquery.min.js
chunk-elementUI.a6ff1ef1.js
chunk-libs.b821f5aa.js
7860.0ecd4509.js
flutter_test.31d5cbd5.js
```

Flutter 只负责加载入口 HTML。上述 JavaScript 文件均由 HTML 中的 `<script>` 标签和前端构建运行时继续加载，不是 Flutter 额外添加的资源。

从设备 WebView 缓存导出的 `chunk-elementUI.a6ff1ef1.js` 中没有发现对象展开语法；结合脚本加载顺序、控制台错误和之前同项目 `chunk-libs` 产物检查，问题定位在公共依赖构建链路，高概率具体来源是：

```text
chunk-libs.b821f5aa.js
```

Chrome 58 无法解析对象展开语法：

```js
const options = {
  ...source
}
```

由于 Chrome 必须先完整解析 JavaScript 文件再执行，任何一个顶层脚本包含不支持的语法，整个脚本都会停止执行。此类错误无法通过页面加载完成后注入 Polyfill 修复。

> 说明：Chrome 58 的控制台回调只返回错误消息，没有返回源文件和行号。最终文件级确认应在 Vue 发布目录中对 `chunk-libs.b821f5aa.js` 执行语法检查。

## 6. 根本原因

### 6.1 直接原因

远端 Vue2 发布产物包含 Chrome 58 不支持的现代 JavaScript 语法，导致旧 Android WebView 在脚本解析阶段发生致命错误，Vue 未能挂载。

### 6.2 构建侧原因

可能的构建配置问题包括：

- `browserslist` 没有包含 Chrome 58。
- Babel 只转译业务代码，没有转译 `node_modules` 中的第三方依赖。
- `chunk-libs` 中的 Vuetify、Element UI、PDF、弹窗或工具类依赖未经转译。
- 使用 Modern/Legacy 双构建时，Legacy 包仍混入现代语法。
- HTML 与带哈希 JavaScript 的缓存策略不一致，旧容器和新容器命中了不同发布版本。

## 7. 为什么高版本 Android 和 iOS 仍能渲染

高版本平台出现的异步错误与 Android 7 白屏不是同一类错误。

### Android 7

```text
语法解析错误 -> 公共脚本不执行 -> Vue 不创建 -> 白屏
```

### 高版本 Android/iOS

```text
脚本解析成功 -> Vue 完成挂载 -> 页面先渲染 -> 某个异步请求或 Promise 后续失败
```

异步运行时错误通常只影响部分数据或某个操作，不会自动删除已经生成的 DOM；语法解析错误则会阻止整个脚本启动。

## 8. Cordova 对照结论

设备上的 Cordova 旧应用信息：

| 项目 | 信息 |
| --- | --- |
| 包名 | `com.delta.MERPDelta` |
| 版本 | `2.2.20` |
| 最低 Android | API 16 |
| 目标 Android | API 30 |

对旧 APK 进行只读检查后：

- 未发现 Crosswalk 内核。
- 未发现腾讯 X5/TBS 内核。
- APK 内置大量 `assets/www/merp` 本地页面和 JavaScript。
- Cordova 通过本地功能列表动态拼接 URL，再使用 iframe 或 `location.href` 打开业务页面。

因此，目前没有证据表明 Cordova 通过独立浏览器内核解决了兼容性问题。Cordova 能打开页面更可能来自以下差异：

1. Cordova 使用了独立的旧缓存。
2. Cordova 实际打开的 URL、参数或页面版本不同。
3. Cordova 加载了 APK 内置本地入口，再访问不同的远端资源。
4. 服务端根据 User-Agent、参数或应用版本返回了不同资源。
5. Cordova 命中了不同哈希的 `chunk-libs` 文件。

如果 Cordova 和 Flutter 在同一个 Chrome 58 内核中加载完全相同的 JavaScript 字节，两者应产生相同语法错误。后续对照应以完整 URL、User-Agent 和 `chunk-libs` 哈希为准，而不是只比较页面标题。

## 9. 推荐修复方案

### 9.1 P0：Vue2 输出真正兼容 Chrome 58 的 Legacy 构建

在 Vue 项目 `package.json` 配置：

```json
{
  "browserslist": [
    "Chrome >= 58",
    "Android >= 7",
    "iOS >= 12"
  ]
}
```

在 `vue.config.js` 中先启用全部依赖转译：

```js
module.exports = {
  transpileDependencies: true
}
```

确认问题解决后，再缩小到明确依赖，降低构建时间：

```js
module.exports = {
  transpileDependencies: [
    'vuetify',
    'element-ui',
    'sweetalert2',
    'pdfjs-dist'
  ]
}
```

在 `babel.config.js` 中启用按需 Polyfill：

```js
module.exports = {
  presets: [
    [
      '@vue/cli-plugin-babel/preset',
      {
        useBuiltIns: 'usage',
        corejs: 3
      }
    ]
  ]
}
```

安装运行时补丁：

```bash
npm install core-js@3 --save
```

注意：Polyfill 只能补充缺失 API；对象展开等语法仍必须由 Babel 在构建阶段转换。

### 9.2 P0：增加发布产物兼容性检查

构建后执行：

```bash
npx es-check es5 "dist/**/*.js"
```

同时搜索未转换的对象展开语法：

```bash
rg '\{\s*\.\.\.' dist
```

重点检查：

```text
dist/chunk-libs.*.js
dist/chunk-elementUI.*.js
dist/flutter_test.*.js
```

### 9.3 P0：修正服务器缓存策略

入口 HTML 应及时重新验证：

```http
Cache-Control: no-cache
```

带内容哈希的 JavaScript/CSS 可以长期缓存：

```http
Cache-Control: public, max-age=31536000, immutable
```

每次发布应产生新的资源哈希，避免旧容器继续使用历史脚本。

### 9.4 P1：Flutter 按 WebView 版本分流

如果短期内必须同时保留现代包与旧设备兼容包，可部署两个入口：

```text
flutter_test.html
flutter_test_legacy.html
```

Flutter 根据 Android WebView 主版本选择地址：

```dart
final url = webViewMajorVersion < 61
    ? legacyBridgeUrl
    : bridgeUrl;
```

Legacy 页面仍必须由 Vue 构建链路生成，Flutter 无法自动转译远端脚本。

### 9.5 P1：Flutter 增加白屏检测与用户提示

页面完成后检查：

- `#app` 是否存在。
- `#app` 是否持续没有子节点。
- 是否收到 `SyntaxError`。
- 页面是否只有空白内容。

检测到不兼容时，展示明确错误：

```text
当前系统浏览器组件版本过低，无法打开该页面。
```

同时记录故障编号，避免用户只能看到纯白屏。

### 9.6 P2：模拟 Cordova User-Agent 验证

如果服务端确实根据 User-Agent 返回旧版资源，可在 Flutter 中临时模拟 Cordova User-Agent：

```dart
await controller.setUserAgent(cordovaUserAgent);
```

该方案只有在服务端已有兼容资源时有效，不应作为长期构建兼容方案。

### 9.7 P3：嵌入独立浏览器内核

无法修改 Vue 发布链路且旧设备必须长期支持时，可以评估 Android 独立 Chromium/X5/Gecko 类内核。

代价包括：

- APK 体积增加。
- Android 和 iOS 分别维护。
- JS Bridge、Cookie、文件、定位、相机和扫码需要重新适配。
- 内核升级、安全审计和隐私合规成本较高。

仅建议作为最后方案。

## 10. 无效或不推荐的处理方式

| 方式 | 结论 |
| --- | --- |
| `webview_flutter` 改为 `flutter_inappwebview` | 通常仍使用系统 WebView，不能改变 Chrome 58 语法能力 |
| 页面完成后注入 Polyfill | 语法解析已经失败，执行时机过晚 |
| 仅注入 `core-js` | 只能补 API，不能转换对象展开语法 |
| 反复刷新页面 | 每次都会在相同语法处失败 |
| 修改 Cookie 或混合内容配置 | 当前已确认不是鉴权或主页面网络错误 |
| Flutter 端正则替换远端 JS | 风险高，会破坏源码、缓存、Source Map 和签名，不可维护 |

## 11. 验收标准

### 11.1 Android 7 / Chrome 58

- `flutter_test.html#/home` 正常显示完整测试页面。
- 控制台不再出现 `Unexpected token ...`。
- `#app` 子节点数量大于 0。
- 定位、拍照、文件、设备信息、系统消息、登出和扫码按钮可见。
- 各 Bridge 调用成功返回或显示明确业务错误。
- 电子表单页面可以正常渲染。

### 11.2 高版本 Android

- 页面渲染和 Bridge 功能无回归。
- Cookie、登录态和返回导航正常。
- 没有因为 Legacy 构建引入明显性能退化。

### 11.3 iOS

- WKWebView 页面渲染正常。
- 左滑返回和标题栏返回正常。
- Bridge 功能及权限申请正常。

### 11.4 缓存验证

- 首次打开加载新哈希资源。
- 再次打开可以命中静态资源缓存。
- 发布新版本后入口 HTML 能发现新哈希资源。
- Cordova 与 Flutter 使用的脚本哈希可以明确对照。

## 12. 安全注意事项

1. WebView诊断必须通过 `WEBVIEW_DIAGNOSTICS` 显式开启，正式包默认关闭。
2. 不在日志中记录 Token、Cookie、票据、精确坐标和用户资料。
3. Android Debug WebView及旧系统组件可能自行输出请求头，诊断日志只能在受控环境中使用，不得直接发送到公共群组或外部平台。
4. 诊断完成后，应重新安装正常 Release 包。
5. 百度地图AK继续使用本地忽略配置，不提交Git。

## 13. 最终结论

Android 7 白屏的核心原因是旧设备使用 Chrome 58 WebView，而远端 Vue2 公共依赖产物包含 Chrome 58 无法解析的现代 JavaScript 语法。页面HTML和MERP Bridge都已成功加载，但Vue在初始化前停止执行。

最优修复路径是：

```text
Vue2 Legacy构建正确转译业务代码与第三方依赖
    -> 发布新哈希资源并修正缓存策略
    -> Android 7真机验证
    -> Flutter补充版本分流和白屏提示
```

单纯更换Flutter WebView插件无法解决JavaScript引擎版本问题。
