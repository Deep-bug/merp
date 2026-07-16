# 静态资源热更新 Demo

本文档说明 MERP Flutter Shell 如何验证“静态资源热更新”能力，例如首页背景色、横幅文案、图标颜色等在手机端无需重新发版即可变化。

## 先明确边界

Flutter 官方支持：

- 开发期 `hot reload`：修改 Dart UI 代码后，调试中的手机可以快速刷新。
- 开发期 `hot restart`：重新启动 Dart isolate，适合初始化逻辑变更。
- 生产环境动态加载网络图片、接口数据、本地缓存、配置文件。

Flutter 官方不支持：

- 生产环境热更新 Dart 代码。
- 像某些 H5 框架一样直接下发一段新业务代码并替换原生 App 逻辑。

因此，真实项目里不要把“热更新”理解成热更新 Flutter 代码。更稳妥的企业方案是：

```text
内置默认资源
  ↓
App 启动或手动刷新时请求后端资源清单 manifest
  ↓
校验版本、hash、签名、灰度规则
  ↓
写入本地缓存
  ↓
页面读取运行时资源清单并重绘
```

本 demo 用 `SharedPreferences` 模拟“手机端已经下载并缓存资源清单”，不依赖额外三方库，便于本地验证。

## Demo 覆盖内容

本次实现的文件：

```text
lib/core/resources/
├── runtime_resource_manifest.dart   # 运行时资源清单模型
└── resource_update_controller.dart  # 资源清单加载、缓存、应用、重置

lib/features/resources/
└── resource_update_demo_page.dart   # 本地资源热更新演示页

lib/features/home/home_page.dart     # 首页读取资源清单渲染 banner 和图标颜色
```

已接入的资源字段：

```json
{
  "version": "local-violet-demo",
  "bannerTitle": "MERP 主题资源包",
  "bannerSubtitle": "本地模拟节日/活动资源变更",
  "bannerColor": "#6A72E8",
  "bannerDarkColor": "#5159C8",
  "brandColor": "#5961D6",
  "iconColor": "#6670F0",
  "updatedAt": "2026-06-28T10:00:00.000"
}
```

字段说明：

- `version`：资源版本号，用于判断是否需要更新。
- `bannerTitle`：首页第一张横幅标题。
- `bannerSubtitle`：首页第一张横幅副标题。
- `bannerColor`：首页第一张横幅主背景色。
- `bannerDarkColor`：首页第一张横幅底部深色区域。
- `brandColor`：顶部标题、抽屉背景等品牌色。
- `iconColor`：首页功能图标颜色。
- `updatedAt`：资源更新时间。

## 本地验证步骤

1. 启动 App。

```bash
flutter run
```

2. 登录进入首页。

Demo 环境可以使用当前项目里的默认登录行为。如果后端不可用，会走本地 demo 菜单。

3. 打开左侧抽屉。

点击首页左上角菜单图标。

4. 进入系统设置。

点击 `系统设置`。

5. 进入资源热更新演示页。

点击：

```text
静态资源热更新演示
```

6. 点击 `应用绿色资源包`。

返回首页后应看到：

- 首页顶部标题颜色变化。
- 左侧抽屉背景色变化。
- 首页第一张 banner 背景色变化。
- 首页功能图标颜色变化。

7. 关闭 App 后重新打开。

资源仍然保持更新后的颜色，因为 demo 已将 manifest 写入本地缓存。

8. 点击 `重置资源`。

返回首页后恢复内置默认蓝色资源。

## 手动 JSON 验证

演示页支持直接修改 JSON 后点击 `应用 JSON`。

例如把颜色改成红色系：

```json
{
  "version": "local-red-demo",
  "bannerTitle": "MERP 红色资源包",
  "bannerSubtitle": "本地手动修改 JSON 后立即生效",
  "bannerColor": "#D94B4B",
  "bannerDarkColor": "#B73535",
  "brandColor": "#C43D3D",
  "iconColor": "#E04F4F",
  "updatedAt": "2026-06-28T10:00:00.000"
}
```

点击 `应用 JSON` 后返回首页查看变化。

## 改造成真实生产热更新

本地 demo 后续可以按下面方式改造成真实资源热更新。

### 1. 后端提供 manifest 接口

建议接口：

```http
GET /app/resource-manifest?platform=android&appVersion=1.0.0&tenant=merp
```

响应：

```json
{
  "success": true,
  "code": "000000",
  "message": "请求成功",
  "data": {
    "version": "2026.06.28.001",
    "minAppVersion": "1.0.0",
    "grayUsers": ["50636863"],
    "bannerTitle": "MERP 2026",
    "bannerSubtitle": "企业移动工作台资源包",
    "bannerColor": "#4DA9D7",
    "bannerDarkColor": "#439BC7",
    "brandColor": "#5E93E5",
    "iconColor": "#16A3DE",
    "updatedAt": "2026-06-28T10:00:00.000",
    "hash": "sha256-xxx",
    "signature": "server-signature"
  },
  "traceId": "20260628-xxxx"
}
```

### 2. App 启动时检查资源版本

推荐位置：

```text
lib/app/app_dependencies.dart
```

当前 demo：

```dart
final resourceUpdateController = ResourceUpdateController();
await resourceUpdateController.load();
```

真实项目可以扩展：

```dart
await resourceUpdateController.load();
await resourceUpdateController.checkRemoteManifest(apiClient);
```

### 3. 校验再落盘

生产环境必须做：

- 校验 `minAppVersion`，避免旧 App 读取不兼容字段。
- 校验 `version`，只更新新版本资源。
- 校验 `hash`，防止下载内容损坏。
- 校验 `signature`，防止资源被篡改。
- 支持灰度，避免一次性影响所有用户。
- 保留内置默认资源和上一版资源，失败时回滚。

### 4. 图片类资源处理

颜色和文案可以直接放 manifest。

图片建议放 CDN URL：

```json
{
  "homeBannerImageUrl": "https://cdn.example.com/merp/banner-20260628.png",
  "homeBannerImageHash": "sha256-xxx"
}
```

Flutter 页面可使用官方 `Image.network` 加载网络图片。若需要离线缓存，可以后续再引入图片缓存策略，但不要把业务逻辑和图片 URL 写死在页面里。

## 同类任务改造清单

以后遇到类似“静态资源想热更新”的需求，按这个清单改：

1. 判断是不是代码逻辑变更。
   - 是代码逻辑：必须发版。
   - 是颜色、文案、图片 URL、开关、排序：可以资源热更新。

2. 给资源定义 manifest 字段。

3. 在 `RuntimeResourceManifest` 增加字段和默认值。

4. 在页面中从 `AppScope.of(context).resourceUpdateController.manifest` 读取字段。

5. 在演示页或后端接口中下发新字段。

6. 加版本、hash、签名、灰度和回滚策略。

7. 跑验证命令。

```bash
dart format lib test
flutter analyze
flutter test
```

## 当前 demo 的限制

- 当前只演示颜色和文案更新，没有接真实后端。
- 当前用本地按钮模拟资源包下载。
- 当前没有做 hash 和签名校验。
- 当前没有下载真实图片资源。

这些限制是为了先验证能力闭环：资源清单变化后，手机端 UI 能立即变化，并且重启后仍保持。
