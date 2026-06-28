# Flutter 静态资源热更新能力汇报

## 一、结论

Flutter 具备“静态资源运行时更新”的能力，但不建议把它表述为“Flutter 代码热更新”。

准确口径如下：

```text
Flutter 生产环境不做 Dart 业务代码热更新；
但可以通过后端下发资源清单、远程图片、主题配置、功能开关等方式，
实现首页背景、图标颜色、运营横幅、文案、入口排序等静态资源的动态更新。
```

对 MERP 项目来说，该能力可用于：

- 首页 banner 背景图或背景色更新。
- 功能图标颜色、主题色更新。
- 活动横幅、公告文案更新。
- 功能入口排序、显示隐藏、灰度发布。
- 不涉及业务逻辑的 UI 配置调整。

不可用于：

- 修改 Dart 业务逻辑。
- 新增复杂原生功能。
- 替换 Flutter 页面代码。
- 修改 Android/iOS 原生插件逻辑。

## 二、官方能力边界

Flutter 官方提供开发期 Hot Reload。根据 Flutter 官方文档，Hot Reload 的工作方式是将更新后的源码注入 Dart runtime，然后 Flutter 框架自动重建 Widget 树，用于快速查看开发改动效果。官方同时说明：手动 Hot Reload 需要应用运行在 debug mode；如果修改原生代码，则必须 full restart。

官方文档：

- Flutter Hot Reload：https://docs.flutter.dev/tools/hot-reload
- Flutter 网络图片能力：https://docs.flutter.dev/cookbook/images/network-image

官方网络图片文档说明，Flutter `Image` 组件支持展示不同类型图片，网络图片可通过 `Image.network()` 加载。因此，图片、颜色、文案、配置等运行时数据完全可以从服务端或 CDN 下发。

所以需要区分两类能力：

| 类型 | 是否支持 | 说明 |
|---|---:|---|
| 开发期 Hot Reload | 支持 | 用于开发调试，debug 模式下快速刷新 UI |
| 生产环境代码热更新 | 不建议 | 不应下发 Dart 代码替换业务逻辑 |
| 生产环境静态资源热更新 | 支持 | 通过接口/CDN 下发资源清单、图片 URL、颜色、文案等 |
| 生产环境功能开关/灰度配置 | 支持 | 通过后端配置控制功能显示、隐藏、排序 |

## 三、MERP 当前验证情况

项目中已经完成一个本地 Demo，用于验证“静态资源热更新”能力。

已实现文件：

```text
lib/core/resources/
├── runtime_resource_manifest.dart
└── resource_update_controller.dart

lib/features/resources/
└── resource_update_demo_page.dart

docs/
└── static_resource_hot_update_demo.md
```

已验证能力：

- 本地模拟后端下发资源包。
- 手机端应用资源包后，首页 UI 立即变化。
- 已支持变更首页首屏 banner 标题、副标题、背景色。
- 已支持变更顶部品牌色、左侧抽屉背景色、功能图标颜色。
- 资源变更会写入本地缓存，App 重启后仍保持。
- 支持一键恢复默认资源。

当前 Demo 的验证路径：

```text
首页
  → 左侧抽屉
  → 系统设置
  → 静态资源热更新演示
  → 应用绿色资源包 / 应用紫色资源包
  → 返回首页查看变化
```

## 四、推荐生产方案

生产环境建议采用“资源清单 manifest + CDN/后端配置 + 本地缓存”的方案。

整体流程：

```text
App 内置默认资源
  ↓
App 启动或用户进入首页时请求资源清单
  ↓
后端返回 manifest
  ↓
App 校验版本、hash、签名、灰度规则
  ↓
写入本地缓存
  ↓
首页、功能宫格、抽屉等页面读取运行时资源并自动刷新
```

推荐后端接口：

```http
GET /app/resource-manifest?platform=android&appVersion=1.0.0&tenant=merp
```

推荐响应结构：

```json
{
  "success": true,
  "code": "000000",
  "message": "请求成功",
  "data": {
    "version": "2026.06.28.001",
    "minAppVersion": "1.0.0",
    "bannerTitle": "MERP 2026",
    "bannerSubtitle": "企业移动工作台资源包",
    "bannerImageUrl": "https://cdn.example.com/merp/banner-20260628.png",
    "bannerColor": "#4DA9D7",
    "bannerDarkColor": "#439BC7",
    "brandColor": "#5E93E5",
    "iconColor": "#16A3DE",
    "enabledFeatureCodes": [
      "form.electronic.view",
      "task.mine.view"
    ],
    "updatedAt": "2026-06-28T10:00:00.000",
    "hash": "sha256-xxx",
    "signature": "server-signature"
  },
  "traceId": "20260628-xxxx"
}
```

## 五、适用场景

适合热更新的内容：

- 首页背景图、banner 图。
- 主题色、图标颜色、按钮颜色。
- 首页运营文案、公告文案。
- 功能入口顺序。
- 功能入口显示/隐藏。
- 无权限灰色样式、角标、提示文案。
- 节假日活动皮肤。
- 轻量级 A/B 测试配置。

不适合热更新的内容：

- 登录逻辑。
- 业务流程判断。
- 审批状态机。
- 原生相机、地图、指纹等插件能力。
- 数据库结构。
- Android/iOS 权限配置。
- Dart 页面代码。

## 六、安全与风控要求

生产落地时建议必须增加以下控制：

1. 版本校验

   `minAppVersion` 不满足时不应用资源，避免旧 App 读取新字段后异常。

2. Hash 校验

   图片或资源文件下载后校验 SHA-256，防止文件损坏。

3. 签名校验

   manifest 建议由后端签名，App 校验签名，防止资源被篡改。

4. 灰度发布

   支持按用户、部门、租户、版本、平台分批发布。

5. 失败回滚

   保留上一版可用资源。新资源解析失败或加载失败时，回退上一版。

6. 默认兜底

   App 包内必须保留默认资源，离线或接口失败时仍可正常使用。

7. 审计记录

   记录资源版本、生效时间、发布人、影响范围，便于问题追溯。

## 七、对比 H5/Cordova 的差异

| 对比项 | Cordova/Vue2 | Flutter |
|---|---|---|
| 页面代码更新 | H5 资源可整体替换 | 不建议替换 Dart 代码 |
| 静态图片更新 | 支持 | 支持 |
| 颜色/文案配置更新 | 支持 | 支持 |
| 性能体验 | 依赖 WebView | 原生渲染体验更好 |
| 安全边界 | H5 包更新风险较高 | 资源清单更新边界更清晰 |
| 审核风险 | 容易混入代码更新 | 只更新资源和配置，风险更低 |

因此，Flutter 的推荐策略不是复刻 Cordova 的整包 H5 热更新，而是把可变部分抽成“配置和资源”，把稳定业务逻辑留在 App 发版流程中。

## 八、投入评估

当前项目已经完成本地 Demo，后续生产化预计需要：

| 阶段 | 工作内容 | 预计投入 |
|---|---|---:|
| 已完成 | 本地资源清单 Demo、首页颜色/文案动态更新 | 已完成 |
| 第一阶段 | 接后端 manifest 接口、资源版本判断、本地缓存 | 1-2 天 |
| 第二阶段 | CDN 图片、hash 校验、失败回滚 | 2-3 天 |
| 第三阶段 | 签名校验、灰度发布、审计日志 | 3-5 天 |
| 第四阶段 | 管理后台配置页面 | 视后台复杂度评估 |

## 九、建议决策

建议采用 Flutter 静态资源热更新能力，但控制范围：

```text
允许热更新：图片、颜色、文案、入口排序、功能开关、灰度配置。
禁止热更新：Dart 业务代码、原生插件代码、核心业务逻辑。
```

对 MERP 项目建议分两步推进：

1. 近期：保留当前 Demo，并接入后端 manifest 接口，验证首页资源更新、功能入口配置更新。
2. 中期：增加 hash、签名、灰度和回滚机制，形成企业级资源发布能力。

最终汇报结论：

```text
Flutter 可以满足企业 App 对“静态资源热更新”的需求；
实现方式不是热更新代码，而是通过运行时资源清单和远程资源加载实现。
该方案安全边界清晰、符合 Flutter 官方能力模型，也更适合企业级 App 的稳定性要求。
```
