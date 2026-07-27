# MERP 移动端新方案原型可行性验证报告

## 1. 汇报摘要

本次原型验证采用“Flutter 原生应用壳 + Vue2 远端业务页面 + JSBridge 原生能力”
的混合开发方案。Flutter 负责登录会话、导航、权限、地图、定位、相机、扫码、
文件选择和系统交互；存量及快速迭代业务继续由 Vue2 页面承载。

原型已证明以下核心链路可行：

1. Flutter 可以统一承载 Android 和 iOS 应用入口，并管理登录态和页面导航。
2. Vue2 页面可以在 Flutter WebView 中运行，并通过 JSBridge 调用手机原生能力。
3. 百度地图和精确定位已在 Android、iOS 两个平台完成接入。
4. 电子表单、JSBridge 测试页和固资盘点页面均可作为远端业务页面挂载。
5. Android 7.0 的白屏问题已定位并解决：重新编译 Node/Vue 依赖，使发布脚本兼容
   Chrome 58 后，旧设备可以正常渲染页面。
6. QAS、PRD 环境能够独立配置，地图 AK、业务 URL 等敏感或本地配置不提交 Git。

**阶段结论：新方案具备继续推进试点和业务迁移的技术可行性。**

> **截图位 01：原型汇报封面**
>
> 建议画面：手机首页或“首页 + 地图 + JSBridge 测试页”三图组合。
>
> 建议文件名：`images/prototype/01-cover.png`

## 2. 方案结构

```text
Vue2 远端业务页面
        |
        | window.MERPBridge.call(action, payload)
        v
Flutter JSBridge 协议层
        |
        +-- 登录与会话
        +-- 百度地图与定位
        +-- 拍照与扫码
        +-- 文件选择
        +-- 设备信息
        +-- 系统消息与确认框
        +-- 手机端退出登录
        |
        v
Android / iOS 原生系统能力
```

方案价值：

- 存量 Vue2 页面可继续使用，降低一次性重写成本。
- 新增硬件能力由 Flutter 统一实现，Vue2 不需要分别适配 Android 和 iOS。
- 原生能力通过 Action 白名单开放，网页不能任意访问手机系统。
- Flutter 与网页可以独立迭代，适合电子表单、盘点、外勤等企业业务。
- 登录、Token、权限和错误日志由手机端统一管理。

> **截图位 02：方案架构图**
>
> 建议画面：使用上面的四层结构制作一页汇报图。
>
> 建议文件名：`images/prototype/02-architecture.png`

## 3. 原型已验证功能

### 3.1 应用启动与登录会话

| 功能 | 原型表现 | 验证重点 |
| --- | --- | --- |
| 原生启动页 | Android/iOS 启动后平滑进入 Flutter 品牌加载页 | 冷启动期间无明显白屏 |
| 账号登录 | 调用 QAS/PRD 登录接口并安全保存 Token | 登录成功进入首页 |
| 会话恢复 | 重启应用后使用 refresh token 请求新 access token | access token 15 分钟过期不影响下次启动 |
| Token 自动刷新 | 接口返回 401 时刷新 Token 并重放请求 | 并发请求共用一次刷新 |
| 异常恢复 | 断网、超时、服务端异常可重试 | 不因临时网络错误误删 refresh token |
| 环境隔离 | QAS 与 PRD 使用独立配置和本地 Token | 防止测试、生产会话串用 |

> **截图位 03：原生启动页和 Flutter 加载页**
>
> 建议画面：启动图、Flutter 品牌加载页各一张。
>
> 建议文件名：`images/prototype/03-splash.png`

> **截图位 04：登录页与自动恢复后的首页**
>
> 建议画面：左侧登录页，右侧杀掉进程后再次打开直接进入首页。
>
> 建议文件名：`images/prototype/04-login-session.png`

### 3.2 首页与统一业务入口

原型首页提供统一工作台、侧边栏、用户入口、功能菜单和页面返回能力。当前菜单接口
使用 Mock 数据并默认授予全部权限，用于快速验证页面容器和路由。

当前展示的业务入口：

| 类别 | 功能入口 | 当前原型状态 |
| --- | --- | --- |
| 已重点验证 | 电子表单、地图定位、固资盘点3.0 | 页面已接入并进行真机验证 |
| 原生能力验证 | JSBridge 测试页 | 定位、拍照、扫码等能力测试入口 |
| 容器/菜单验证 | 外勤管理2.0、我的任务、服务派工、线索商机 | Mock 菜单和路由占位 |
| 容器/菜单验证 | 客户、客户360、设备履历、FAQ、AI搜索、代理人设定 | Mock 菜单和路由占位 |

> 注意：标记为“容器/菜单验证”的功能只证明 Flutter 可以接收权限菜单、展示入口并
> 打开对应路由，不代表相关业务页面已经完成。

> **截图位 05：首页完整功能菜单**
>
> 建议画面：分别截取首页上半部分和下半部分，确保“地图定位”“固资盘点3.0”等入口
> 清晰可见。
>
> 建议文件名：`images/prototype/05-home-menu.png`

### 3.3 百度地图与精确定位

已完成 Android、iOS 百度地图基础 SDK 和定位 SDK 接入：

- 用户进入地图页面后才初始化地图，不在 App 启动阶段申请定位权限。
- 首次使用先展示百度隐私说明，用户同意后再激活 SDK。
- 用户点击定位按钮后才申请系统权限并发起单次定位。
- 返回 BD-09 坐标、定位精度等信息。
- 地图自动移动到当前位置并展示定位点。
- 业务定位要求精度在 50 米以内，超时或精度不足时给出明确提示。
- 页面提供标题栏和返回按钮，并兼容 Android 系统返回与 iOS 左滑返回。

> **截图位 06：地图隐私同意和定位授权**
>
> 建议画面：百度隐私说明、Android/iOS 定位权限框。
>
> 建议文件名：`images/prototype/06-map-permission.png`

> **截图位 07：地图精确定位结果**
>
> 建议画面：地图定位点、经纬度、精度信息同时可见。
>
> 建议文件名：`images/prototype/07-map-location.png`

### 3.4 Vue2 JSBridge 原生能力

远端 Vue2 页面通过统一接口调用手机端：

```js
window.MERPBridge.call(action, payload)
```

测试页面提供以下能力：

| 功能 | Bridge Action | 原型验证内容 | 建议截图 |
| --- | --- | --- | --- |
| Bridge 连接 | `bridge.ping` | 网页识别手机端 Bridge 版本及连接状态 | “Bridge 已连接”状态 |
| 登录态读取 | `auth.getSession` | 获取受控会话数据，不暴露 refresh token | 返回结果区域 |
| 定位 | `location.getCurrentPosition` | 获取 BD-09 坐标、精度和时间 | 坐标 JSON 结果 |
| 拍照 | `camera.takePhoto` | 打开系统相机、拍照、压缩并回传预览 | 相机页和照片预览 |
| 扫码 | `scanner.scanCode` | 扫描二维码及常见一维码并返回内容、码制 | 扫码框和成功结果 |
| 文件 | `file.pick` | 打开系统文件选择器，限制格式、数量和大小 | 文件选择页和文件信息 |
| 设备信息 | `device.getInfo` | 返回机型、系统版本、App 版本等非永久标识 | 设备信息 JSON |
| 系统消息 | `system.showMessage` | Vue2 驱动原生 Toast 或消息框 | 原生消息框 |
| 系统确认 | `system.confirm` | 调用原生确认/取消交互并返回结果 | 确认框和结果 |
| 返回手机首页 | `navigation.closePage` | 关闭当前 WebView，返回下层 Flutter 首页 | Vue2 顶部栏和 Flutter 首页 |
| 打开设置 | `device.openAppSettings` | 权限被拒绝后跳转应用系统设置 | 系统设置页 |
| 退出登录 | `auth.logout` | 原生二次确认、清理会话并返回登录页 | 确认框和登录页 |
| 语言读取 | `app.getLocale` | 获取当前简体/繁体语言 | 返回结果区域 |
| 资源清单 | `resource.getManifest` | 获取手机端资源版本信息 | 返回结果区域 |

Bridge 调用统一使用 Promise 返回结果；失败时返回标准错误码、错误信息和
`incidentId`，便于网页和手机日志对应排查。

> **截图位 08：JSBridge 测试页全景**
>
> 建议画面：页面标题、“Bridge 已连接”、全部功能按钮和调用结果区域。
>
> 建议文件名：`images/prototype/08-bridge-overview.png`

> **截图位 09：定位、设备信息调用成功**
>
> 建议画面：两个调用结果连续显示，突出网页成功获取原生数据。
>
> 建议文件名：`images/prototype/09-bridge-data.png`

> **截图位 10：拍照与扫码**
>
> 建议画面：拍照预览、扫码原生页面、扫码结果三张组合。
>
> 建议文件名：`images/prototype/10-camera-scanner.png`

> **截图位 11：文件、系统消息与系统确认**
>
> 建议画面：系统文件选择器、原生消息框、原生确认框。
>
> 建议文件名：`images/prototype/11-file-system-ui.png`

> **截图位 12：Vue2 驱动手机端退出登录**
>
> 建议画面：网页点击退出、手机端二次确认、返回登录页三个步骤。
>
> 建议文件名：`images/prototype/12-web-logout.png`

### 3.5 远端业务页面挂载

| 页面 | 验证内容 | 当前结论 |
| --- | --- | --- |
| JSBridge 测试页 | Vue2 页面加载、Bridge 注入、原生能力调用 | 可行 |
| 电子表单 | Flutter WebView 打开现有电子表单 | 可行 |
| 固资盘点3.0 | Flutter WebView 打开盘点页面并保留原生导航 | 可行 |

旧业务 WebView 不再叠加 Flutter 公共标题栏，页面标题和顶部返回由 Vue2 统一呈现；
Vue2 根页面通过 `navigation.closePage` 返回 Flutter 首页。Android 系统返回键仍优先
返回上一层页面，不会在业务页中直接退出整个应用；iOS 页面保留系统安全区。

> **截图位 13：电子表单页面**
>
> 建议画面：Vue2 顶部栏、返回按钮和电子表单正文同时出现，无重复手机端标题栏。
>
> 建议文件名：`images/prototype/13-eform.png`

> **截图位 14：固资盘点3.0 页面**
>
> 建议画面：在 Android 7 原型机上完整显示盘点页面，保留系统状态栏和 Vue2
> 顶部栏，用于证明旧设备兼容问题已解决。
>
> 建议文件名：`images/prototype/14-asset-inventory-android7.png`

## 4. Android 7.0 兼容验证

### 4.1 问题现象

Android 7 原型机使用 Chrome WebView `58.0.3029.83`。页面 HTML、网络和登录态均
正常，但 Vue 根节点没有挂载，控制台报错：

```text
Uncaught SyntaxError: Unexpected token ...
```

### 4.2 根因

Vue2 发布目录中的部分 Node 依赖没有被编译为 Chrome 58 可识别的 JavaScript。
Flutter WebView 成功加载了页面，但旧版 JavaScript 引擎在解析业务脚本时中止执行，
最终表现为白屏。

### 4.3 已验证解决方式

1. 在 Vue2 工程中调整 `package.json`、Babel 或 Browserslist 兼容目标。
2. 重新安装或重新编译 Node 依赖和前端发布文件。
3. 让开发服务监听局域网地址。
4. Android 7 手机与电脑连接同一 Wi-Fi。
5. Flutter WebView 临时指向电脑局域网 IP。
6. JSBridge 页面和固资盘点页面在 Android 7 上恢复渲染。

这次验证证明：问题位于前端构建产物兼容性，不是 Flutter WebView、JSBridge、
登录 Token 或页面 URL 的架构缺陷。

> **截图位 15：Android 7 兼容验证对比**
>
> 建议画面：左侧修改前白屏，右侧重新编译后正常页面；标注同一台 Android 7 设备。
>
> 建议文件名：`images/prototype/15-android7-before-after.png`

> **截图位 16：Android 7 WebView 版本证据**
>
> 建议画面：设备 Android 版本和 Chrome Stable `58.0.3029.83` 版本信息。
>
> 建议文件名：`images/prototype/16-android7-webview-version.png`

## 5. 可行性评价

| 评估项 | 结论 | 说明 |
| --- | --- | --- |
| 存量 Vue2 复用 | 可行 | 页面可继续部署在服务器，由 Flutter WebView 加载 |
| 原生能力复用 | 可行 | 一套 Bridge 同时服务多个 Vue2 业务页面 |
| Android/iOS 统一 | 可行 | Flutter 统一协议，平台差异封装在手机端 |
| Android 7 支持 | 有条件可行 | 前端构建必须持续输出 Chrome 58 兼容产物 |
| 登录与安全 | 可行 | refresh token 由手机安全存储管理，不交给网页 |
| 快速业务试点 | 可行 | 适合先迁移电子表单、固资盘点、外勤等场景 |
| 长期维护 | 可控 | 需要固定 Bridge 协议、兼容矩阵和发布检查 |

## 6. 上线前建议

1. 将 Chrome 58/Android 7 兼容目标固化到 Vue2 工程，不依赖开发人员手工修改。
2. 在 CI 中同时构建网页和 Flutter，并增加 Android 7、现代 Android、iOS 真机回归。
3. QAS 可使用局域网 IP 联调；PRD 必须恢复正式 HTTPS 域名，禁止使用本地 IP。
4. Bridge Action 继续采用白名单，新增能力必须定义参数、返回结构和错误码。
5. refresh token、地图 AK、业务票据等敏感信息不得写入 Git 或网页日志。
6. 菜单 Mock 仅用于原型；正式上线前接入真实权限菜单并完成无权限场景测试。
7. 对定位、相机、扫码、文件分别验证授权允许、拒绝和永久拒绝三种状态。
8. 保留结构化日志与 `incidentId`，方便移动端和网页端联合排障。

## 7. 建议汇报演示顺序

1. 展示启动页和自动恢复登录，说明手机端统一管理会话。
2. 展示首页完整菜单，说明 Flutter 是统一移动工作台。
3. 打开地图定位，展示原生地图、授权和精确坐标。
4. 打开 JSBridge 测试页，确认“Bridge 已连接”。
5. 依次演示设备信息、系统消息、拍照、扫码和文件选择。
6. 打开电子表单与固资盘点，说明存量 Vue2 页面可以复用。
7. 在 Android 7 原型机展示固资盘点正常运行，重点说明兼容问题已解决。
8. 最后演示网页驱动手机端退出登录，说明网页与原生会话闭环已打通。

推荐汇报口径：

> 本次原型已经完成“手机端统一底座、存量 Vue2 页面复用、网页调用原生硬件、
> Android/iOS 双平台支持、Android 7 旧设备兼容”的关键验证。下一阶段不需要推翻
> 现有 Web 业务，可以按业务模块逐步迁移，并通过统一 JSBridge 持续扩展移动能力。
