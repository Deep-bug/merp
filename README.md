# MERP Flutter Shell

本项目用于替换原 Cordova 6.5 外壳：Flutter 负责登录、鉴权、菜单权限、统一 HTTP、设备能力 bridge、系统设置和逐步原生化；现有 Vue2 业务页面继续通过 WebView 承载，后续可按模块迁移为 Flutter 原生页面。

## 功能模块

### 登录与鉴权
- 登录接口由后端提供，默认路径为 `/auth/login`。
- 登录成功后保存 token，后续请求自动注入 `Authorization: Bearer <token>`。
- App 启动时会恢复本地 token，恢复成功后自动拉取菜单权限。
- 后端返回 401 时会清理本地 token，并由路由守卫引导回登录页。

### 首页工作台
- 顶部标题为 `MERP 2025`，左侧打开个人抽屉，右侧进入个人中心。
- 蓝色横幅为 `PageView` 图片轮播位，支持自动轮播和手动滑动。
- 功能区为 3 列 4 行：
  - 前 3 行展示当前账号有权限的 9 个常用功能。
  - 第 4 行只展示“更多”入口。
- 功能块使用白底、圆角、图标底色和阴影，贴近移动 ERP 工作台入口。

### 更多与全部功能
- 点击首页“更多”进入 `/features`。
- 全部功能页展示后端返回的完整功能清单。
- 有权限的功能显示蓝色，可点击进入。
- 无权限的功能显示灰色，点击后提示当前账号无权限。

### 旧 Vue2 页面承载
- `launchMode=legacyWeb` 的功能进入 WebView。
- WebView 地址由 `legacyVueBaseUrl + legacyPath` 拼接。
- 未配置旧系统根地址、未配置页面路径、网络失败、HTTP 404 等情况都会展示统一错误页。
- WebView 会带上登录 token：`Authorization: Bearer <token>`。
- 当前默认 `legacyVueBaseUrl` 仍为占位地址，正式接入时需要改成真实旧 Vue2 移动端入口。

### Vue2 原生能力 Bridge

相机不是独立 Flutter 业务功能，而是预留给旧 Vue2 页面调用的原生 bridge。

Flutter 注入到 WebView 的对象：

```js
window.MERPBridge
```

Vue2 调用拍照：

```js
try {
  const photo = await window.MERPBridge.takePhoto({
    includeBase64: true,
    imageQuality: 88,
    maxWidth: 1920
  })

  // photo.dataUrl 可直接用于预览；photo.path 可用于后续扩展原生上传。
  console.log(photo.name, photo.mimeType, photo.size, photo.dataUrl)
} catch (error) {
  // error: { code, message }
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

错误码：
- `CAMERA_CANCELLED`：用户取消拍照。
- `BRIDGE_BAD_REQUEST`：Vue2 发送的 bridge 消息格式错误。
- `BRIDGE_UNSUPPORTED_ACTION`：Flutter 外壳暂不支持该 action。
- `BRIDGE_ERROR`：原生能力调用异常，例如权限被拒绝。

主要文件：
- `lib/features/legacy/legacy_web_page.dart`：WebView 容器与 JS bridge 注入。
- `lib/core/device/camera_service.dart`：相机权限、拍照和返回结构封装。

### Flutter 原生页面
- `launchMode=native` 的功能直接进入 Flutter 路由。
- 当前已有地图占位页、个人中心、全部功能、系统设置等原生页面。
- 百度地图暂不接插件，只保留配置位置和接口边界，后续可替换具体地图厂商。

### 系统设置与安全
系统设置入口在左侧抽屉中，路由为 `/settings`。

已包含：
- 启用指纹解锁：基于 `local_auth`，用于自动锁屏后的快速解锁。
- 自动锁屏：开启后登录状态下 10 秒未操作自动锁屏。
- 修改图形密码：3x3 手势密码盘，两次确认后保存。
- 设置语言：本地保存 `简体中文 / English` 选择。
- 版本检测：当前保留后端接口接入点，demo 返回当前已是最新版本。

## 架构分层

- `lib/app`：应用入口、主题、依赖容器、自动锁屏守护。
- `lib/routing`：基于 `go_router` 的登录守卫和页面路由。
- `lib/core/auth`：登录、token 存储、会话恢复、退出。
- `lib/core/network`：基于 `dio` 的统一 HTTP 客户端、响应壳解析和错误码。
- `lib/core/device`：相机 bridge 支撑、地图 SDK 占位、定位占位接口。
- `lib/features/home`：首页工作台、功能入口、权限菜单模型。
- `lib/features/all_features`：全部功能页和权限状态展示。
- `lib/features/legacy`：旧 Vue2 页面 WebView 容器和原生能力 bridge。
- `lib/features/settings`：系统设置、指纹、自动锁屏、手势密码、语言、版本检测。
- `lib/features/profile`：个人中心。
- `lib/features/map`：地图定位占位页面。

## 后端接口约定

真实接口地址集中在 `lib/core/config/app_config.dart`：
- `apiBaseUrl`：后端 API 根地址。
- `loginPath`：登录接口，默认 `/auth/login`。
- `menuPath`：权限菜单接口，默认 `/auth/menus`。
- `legacyVueBaseUrl`：旧 Vue2 移动端根地址。

### 登录响应

建议返回：

```json
{
  "token": "access-token",
  "userName": "张三"
}
```

也兼容统一响应壳：

```json
{
  "success": true,
  "code": "000000",
  "message": "请求成功",
  "data": {
    "token": "access-token",
    "userName": "张三"
  },
  "traceId": "20260610-xxxx"
}
```

### 菜单权限响应

推荐返回“全部功能 + 当前账号权限码”：

```json
{
  "features": [
    {
      "id": "e-form",
      "title": "电子表单",
      "description": "旧表单中心",
      "icon": "form",
      "permissionCode": "form.electronic.view",
      "launchMode": "legacyWeb",
      "route": "/legacy/e-form",
      "legacyPath": "/forms/electronic"
    },
    {
      "id": "field-work",
      "title": "外勤管理2.0",
      "description": "外勤签到与定位",
      "icon": "field",
      "permissionCode": "field.work.view",
      "launchMode": "native",
      "route": "/native/map"
    }
  ],
  "permissionCodes": [
    "form.electronic.view",
    "field.work.view"
  ]
}
```

兼容迁移期：如果后端暂时只返回数组，前端会把数组中的功能都当作已授权功能。

## 统一 HTTP 与错误码

所有后端接口统一从 `lib/core/network/api_client.dart` 发起，业务代码不直接使用 `dio`。

推荐后端响应壳：

```json
{
  "success": true,
  "code": "000000",
  "message": "请求成功",
  "data": {},
  "traceId": "20260610-xxxx"
}
```

前端错误码分段：
- `000000`：成功。
- `Cxxxxx`：客户端错误，如网络不可用、请求超时、响应格式错误。
- `Axxxxx`：认证授权错误，如未登录、token 过期、无权限。
- `Bxxxxx`：业务错误，如校验失败、数据不存在、状态冲突。
- `Sxxxxx`：服务端或网关错误，如 400、404、500、503。

业务层捕获 `ApiException` 后使用 `error.userMessage` 展示给用户，里面会自动附带后端 `traceId`。

## 地图接口预留

当前不接入具体地图插件，只保留对接位置：
- `mapProvider`：地图厂商标识，可填 `baidu`、`amap`、`tencent` 等。
- `androidMapApiKey`：Android 地图 SDK 密钥。
- `iosMapApiKey`：iOS 地图 SDK 密钥。
- `webMapApiKey`：Web 地图 SDK 密钥。

主要预留文件：
- `lib/core/device/map_sdk_service.dart`
- `lib/core/device/location_service.dart`
- `lib/features/map/map_page.dart`

## VSCode 与 E 盘缓存

项目已包含 `.vscode/settings.json`、`.vscode/launch.json`、`.vscode/extensions.json`：
- Flutter SDK：`E:\flutter_windows_3.24.4-stable\flutter`
- Android SDK：`E:\android`
- 模拟机目录：`E:\android-avd`
- Gradle 缓存：`E:\.gradle`
- Pub 缓存：`E:\pub-cache`

写入 Windows 用户环境变量：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\tools\setup_android_e_drive.ps1 -Apply
```

确认无误后清理 C 盘旧缓存：

```powershell
.\tools\setup_android_e_drive.ps1 -Apply -CleanResidual
```

如果 `flutter doctor -v` 提示缺少 Android cmdline-tools，请在 Android Studio 的 SDK Manager 中把 SDK Location 设置为 `E:\android`，并安装 `Android SDK Command-line Tools (latest)`。

## 验证命令

```bash
dart format lib test
flutter analyze
flutter test
```
