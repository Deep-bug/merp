# MERP Flutter Shell

MERP Flutter Shell 是原 Cordova 6.5 外壳的升级替代方案。Flutter 负责登录鉴权、菜单权限、统一 HTTP、系统设置、WebView 承载和原生能力 Bridge；现有 Vue2 业务页面继续运行在 WebView 中，后续可按模块逐步迁移为 Flutter 原生页面。

## 目录结构

```text
merp/
├── android/                         # Android 工程壳，包含权限、Activity、Gradle 配置
├── ios/                             # iOS 工程壳，包含 Info.plist 权限说明
├── web/                             # Flutter Web 运行入口，用于浏览器调试
├── test/                            # 自动化测试
│   └── app_smoke_test.dart          # App 启动冒烟测试
├── lib/                             # Flutter 主代码
│   ├── main.dart                    # 应用入口，只负责初始化依赖并启动 MerpApp
│   ├── app/                         # 应用级装配层
│   │   ├── app_dependencies.dart    # 统一创建配置、HTTP、鉴权、权限、设置、设备能力
│   │   ├── app_scope.dart           # InheritedWidget 依赖容器，页面通过它读取全局服务
│   │   ├── merp_app.dart            # MaterialApp、路由、全局自动锁屏守护
│   │   └── theme/
│   │       └── app_theme.dart       # 全局主题、颜色、控件样式
│   ├── routing/                     # 路由层
│   │   ├── app_router.dart          # go_router 路由表和登录守卫
│   │   ├── forbidden_page.dart      # 无权限页面
│   │   └── splash_page.dart         # 启动恢复登录态页面
│   ├── core/                        # 跨业务基础能力
│   │   ├── auth/                    # 登录、token、会话恢复
│   │   │   ├── auth_controller.dart # 登录态控制器，通知 UI 和路由刷新
│   │   │   ├── auth_repository.dart # 登录接口、退出、恢复本地 session
│   │   │   └── secure_token_store.dart # token 安全存储
│   │   ├── config/
│   │   │   └── app_config.dart      # API 地址、旧 Vue2 地址、地图密钥预留
│   │   ├── device/                  # 原生设备能力边界
│   │   │   ├── camera_service.dart  # 相机能力，供 Vue2 Bridge 调用
│   │   │   ├── location_service.dart # 定位能力占位
│   │   │   └── map_sdk_service.dart # 地图 SDK 初始化占位
│   │   └── network/                 # 统一 HTTP 层
│   │       ├── api_client.dart      # Dio 封装、token 注入、统一响应解析
│   │       ├── api_exception.dart   # 统一异常模型
│   │       ├── api_response.dart    # 后端响应壳解析
│   │       └── app_error_code.dart  # 企业级错误码分段
│   ├── shared/                      # 跨模块复用 UI
│   │   └── app_error_view.dart      # 统一错误页、空状态、重试视图
│   └── features/                    # 业务功能模块
│       ├── login/                   # 登录页
│       ├── home/                    # 首页工作台
│       │   ├── data/
│       │   │   └── permission_repository.dart # 菜单权限加载和缓存
│       │   ├── domain/
│       │   │   └── feature_item.dart # 功能菜单实体
│       │   └── home_page.dart       # 首页 UI、功能入口、左侧抽屉
│       ├── all_features/            # 全部功能页，有权限蓝色、无权限灰色
│       ├── legacy/                  # 旧 Vue2 WebView 承载
│       │   └── legacy_web_page.dart # WebView 加载、错误页、JS Bridge 注入
│       ├── map/                     # 地图占位页，预留百度地图等 SDK 接入点
│       ├── profile/                 # 个人中心
│       └── settings/                # 系统设置和安全能力
│           ├── settings_controller.dart # 指纹、自动锁屏、语言、版本检测
│           ├── settings_page.dart   # 系统设置页面
│           ├── gesture_password_page.dart # 手势密码设置
│           └── pattern_lock_pad.dart # 3x3 手势密码控件
├── pubspec.yaml                     # Flutter 依赖和版本配置
├── analysis_options.yaml            # Dart 静态检查规则
└── README.md                        # 项目说明
```

## 架构约定

当前分层适合“Flutter 外壳 + Vue2 逐步迁移”的 ERP 项目：

- `app`：应用装配层，只放全局依赖、主题、启动流程、自动锁屏等应用级能力。
- `core`：跨业务基础能力，例如鉴权、HTTP、设备能力、配置。
- `routing`：路由表、登录守卫、无权限和启动页。
- `features`：按业务模块纵向拆分，模块内部可继续拆 `data / domain / presentation`。
- `shared`：真正跨模块复用的 UI 组件，避免业务模块之间互相引用。

新增 Flutter 原生业务模块时，推荐结构：

```text
lib/features/inventory/
├── data/             # API、DTO、Repository 实现
├── domain/           # 实体、枚举、业务规则
└── presentation/     # Page、Widget、Controller 或 StateNotifier
```

## 状态管理

当前外壳阶段使用 `ChangeNotifier + AppScope(InheritedWidget)`，因为全局状态主要集中在登录、权限、系统设置三个对象，足够轻量。

后续原生业务模块增多后，推荐从新模块开始引入 `flutter_riverpod`；审批流、工单流转这类事件驱动很强的模块，也可以单独使用 `bloc`。不建议在大型 ERP 中全局滥用 `GetX`，避免状态来源分散。

## 核心功能

### 登录鉴权

- 登录接口默认路径：`/auth/login`。
- 登录成功后保存 token。
- 后续 HTTP 请求自动注入：`Authorization: Bearer <token>`。
- App 启动时恢复本地 session，恢复成功后拉取菜单权限。
- 后端返回 401 时清理 token 并回到登录页。

### 菜单权限

后端推荐返回“全部功能 + 当前账号权限码”：

```json
{
  "features": [
    {
      "id": "e-form",
      "title": "电子表单",
      "icon": "form",
      "permissionCode": "form.electronic.view",
      "launchMode": "legacyWeb",
      "route": "/legacy/e-form",
      "legacyPath": "/forms/electronic"
    }
  ],
  "permissionCodes": [
    "form.electronic.view"
  ]
}
```

首页只展示当前账号有权限的常用功能；全部功能页展示完整清单，有权限显示蓝色，无权限显示灰色。

### 旧 Vue2 WebView

- `launchMode=legacyWeb` 的功能进入 WebView。
- 页面地址由 `legacyVueBaseUrl + legacyPath` 拼接。
- WebView 加载时携带登录 token。
- 未配置 URL、网络失败、HTTP 404、无权限等场景统一展示错误 UI。

### Vue2 原生能力 Bridge

相机能力不是独立 Flutter 页面，而是通过 WebView Bridge 提供给旧 Vue2 页面。

Vue2 调用示例：

```js
try {
  const photo = await window.MERPBridge.takePhoto({
    includeBase64: true,
    imageQuality: 88,
    maxWidth: 1920
  })

  console.log(photo.name, photo.mimeType, photo.size, photo.dataUrl)
} catch (error) {
  console.warn(error.code, error.message)
}
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

Bridge 错误码：

- `CAMERA_CANCELLED`：用户取消拍照。
- `BRIDGE_BAD_REQUEST`：Vue2 发送的 Bridge 消息格式错误。
- `BRIDGE_UNSUPPORTED_ACTION`：Flutter 外壳暂不支持该 action。
- `BRIDGE_ERROR`：原生能力调用异常，例如权限被拒绝。

## 统一 HTTP 错误码

统一响应壳建议：

```json
{
  "success": true,
  "code": "000000",
  "message": "请求成功",
  "data": {},
  "traceId": "20260610-xxxx"
}
```

错误码分段：

- `000000`：成功。
- `Cxxxxx`：客户端错误，例如网络不可用、请求超时、响应格式错误。
- `Axxxxx`：认证授权错误，例如未登录、token 过期、无权限。
- `Bxxxxx`：业务错误，例如校验失败、数据不存在、状态冲突。
- `Sxxxxx`：服务端或网关错误，例如 400、404、500、503。

## 验证命令

```bash
dart format lib test
flutter analyze
flutter test
```
