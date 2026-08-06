# MERP Flutter API 对接说明

本文档记录当前 Flutter 客户端与后端接口的实际契约。页面层不直接解析 JSON，
统一经 `ApiClient -> AuthRepository -> AuthController` 转换为领域模型。

## 1. 全局配置

| 配置 | 当前值 | 代码位置 |
| --- | --- | --- |
| API Base URL | `http://10.146.152.51:31234` | `lib/core/config/app_config.dart` |
| 部署环境 | `APP_ENV=qas/prd` | `config/environment.*.json` |
| 认证环境 | `AUTH_ENVIRONMENT=merp` | 登录与刷新请求体 |
| 菜单应用 | `MENU_APP_ID=merp` | 功能菜单请求体 |
| 菜单范围 | `MENU_FEATURE_SCOPE=at` | 功能菜单请求体 |
| 连接超时 | 30 秒 | `lib/core/network/api_client.dart` |
| 接收/发送超时 | 60 秒 | `lib/core/network/api_client.dart` |
| 客户端请求头 | `X-Client: merp-flutter` | ApiClient 请求拦截器 |
| 请求编号 | `X-Request-Id: merp-{timestamp}` | ApiClient 请求拦截器 |
| 鉴权 | `Authorization: Bearer <access_token>` | ApiClient 请求拦截器 |
| Token 存储 | Android RSA-OAEP + AES-GCM；iOS Keychain | `secure_token_store.dart` |

可以在运行或构建时覆盖地址：

```bash
flutter run \
  --dart-define-from-file=config/environment.qas.json \
  --dart-define-from-file=config/baidu_map.local.json
```

当前地址是 HTTP，因此 Android `usesCleartextTraffic` 和 iOS ATS 暂时允许明文
访问。生产后端支持 HTTPS 后，应同步删除两个平台的明文访问例外。

## 2. 统一响应

`ApiResponse.unwrap<T>` 先校验 `code`，再按 `data -> data.data` 顺序解包：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "data": {}
  }
}
```

一层 `data`、两层 `data` 以及迁移期直接返回业务对象均可处理。非成功 `code`
会转换为 `ApiException`，业务页面只展示统一的用户消息和故障编号。

## 3. 认证模型

```text
AuthTokens
├── accessToken   <- access_token
└── refreshToken  <- refresh_token，可空

UserProfile
├── id
├── accountName
├── displayName
├── department
├── email?
├── phone?
└── avatarUrl?

AuthSession
├── tokens: AuthTokens
└── profile: UserProfile
```

模型代码位于 `lib/core/auth/auth_models.dart`。`refresh_token` 只保存在安全存储
和 Flutter 内存中，不会注入 WebView Bridge；Bridge 仅提供短期 access token。

## 4. 接口与时序

### 验证码

登录页打开时调用 `GET /api/v1/auth/captcha`，设置 `skipAuth: true`。统一响应
解包后的数据结构为：

```json
{
  "captchaId": "captcha-001",
  "imagebase64": "data:image/png;base64,iVBORw0..."
}
```

客户端把 `captchaId` 和解码后的图片作为同一个 `CaptchaChallenge` 保存，刷新
时必须同时替换，禁止复用旧 ID。登录失败后清空用户输入并重新获取一套验证码。

### 登录

`POST /api/v1/auth/login`，设置 `skipAuth: true`：

```json
{
  "username": "admin",
  "password": "123456",
  "captchaId": "captcha-001",
  "captcheCode": "A7K9",
  "appId": "merp",
  "source": 1,
  "environment": "merp"
}
```

账号会先 `trim`。登录成功后先将 Token 写入安全存储，再调用用户信息接口；
用户信息失败时使用登录响应中的账号和显示名，不阻断登录。

### 用户信息

`GET /api/v1/user/userInfo`，自动携带 Bearer Token。返回数据转换为
`UserProfile`，首页侧栏、个人中心和 Bridge 共用同一个会话对象。

### 功能菜单

`POST /api/v1/app/features`，自动携带 Bearer Token：

```json
{
  "appId": "merp",
  "lang": "zh_CN",
  "sys_app_features": "at"
}
```

简体、繁体和英语分别传 `zh_CN`、`zh_TW`、`en_US`。平台完整功能目录由客户端
维护，并始终展示在“全部功能”页面。后端响应已经按当前账号过滤，客户端将其中
的 `featureCode` 映射为授权功能 ID：命中的功能点亮并允许收藏，未命中的功能
置灰且禁止收藏。`target` 用于覆盖已授权功能的旧业务页面路径。当前暂不使用响应
中的 `icon` 或 `iconUrl`，客户端根据平台功能 ID 从 `FeatureRegistry` 映射
Material Icons；未配置映射的功能显示通用应用图标。

### 自动刷新

`POST /api/v1/auth/refresh`，设置 `skipAuth: true`：

```json
{
  "refresh_token": "8b7c1a9f...",
  "environment": "merp"
}
```

收到 401 后，ApiClient 执行以下流程：

```text
受保护请求返回 401
  -> 等待或创建唯一 refresh Future
  -> 保存新 access_token/refresh_token
  -> 原请求标记为已重试并重放一次
  -> 刷新失败则清空安全存储和内存会话
  -> GoRouter 根据 AuthStatus 返回登录页
```

刷新响应未返回新 `refresh_token` 时继续使用旧值。应用启动恢复会话时也会主动
刷新一次，不直接信任磁盘中的旧 access token。

QAS 与 PRD 使用不同的安全存储命名空间，禁止把一个环境签发的 refresh token
发送到另一个环境。切换环境后第一次启动需要重新登录。

### 登出

`POST /api/v1/auth/logout`，设置 `skipAuth: true`，请求体只发送
`refreshToken`。无论后端成功、超时还是不可达，`finally` 都会清空本地 Token。

## 5. 错误码

| AppErrorCode | 场景 |
| --- | --- |
| `clientTimeout` | 连接、发送或接收超时 |
| `clientNetworkUnavailable` | 无网络、DNS 或连接失败 |
| `clientCancelled` | 请求被取消 |
| `clientInvalidConfig` | 证书或客户端配置异常 |
| `serverUnauthorized` | HTTP 401 |
| `serverForbidden` | HTTP 403 |
| `serverNotFound` | HTTP 404 |
| `serverValidation` | HTTP 400 |
| `serverError` | HTTP 5xx 或未识别的后端失败码 |
| `clientUnknown` | 客户端 catch-all |

## 6. 验证

接口契约测试位于：

```text
test/core/auth/auth_models_test.dart
test/core/auth/auth_repository_test.dart
test/core/network/api_response_test.dart
test/core/network/api_client_test.dart
```

其中网络测试使用假的 Dio `HttpClientAdapter`，不会连接真实服务器，但会完整经过
请求拦截器、响应解包、401 刷新和重试链路。
