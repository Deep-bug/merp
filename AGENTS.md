# MERP 持久开发规则

## 项目与阅读入口

- Flutter Android/iOS 企业移动外壳，承载旧 Vue2 业务；不是桌面端项目。
- 开始工作先读 `docs/HANDOFF.md`，再按需读 `docs/PROJECT_CONTEXT.md`、README 和相关源代码。
- `lib/AGENTS.md` 的有效工作规则继续适用；本文件不替代子目录规则。
- 事实优先级：当前代码描述实现，用户最终确认描述目标；两者冲突必须说明，不自行认定已完成。

## 工作方式（用户要求与现有规范）

- 一次聚焦一个明确目标。要求“方案/讲解/先不修改”时只读分析。
- 修改后做与风险相称的验证，说明未验证事项；不要将脚本检查等同真机验证。
- 未经明确要求，不提交、推送、上传或发布。不擅自升级依赖或重构无关模块。
- 先检查 Git 状态；保留用户已有改动，不能因其报错就自动回滚。
- 注释解释设计原因、安全边界和生命周期；复杂改动保持可维护，不把完整聊天记录写入文档。

## 架构边界（项目现有规范）

- `app` 装配依赖及跨域生命周期；`core` 提供鉴权、网络、安全、Bridge、设备能力。
- `features` 承载业务；`shared` 仅放共享 UI；路由集中于 `lib/routing`。
- 页面通过 `AppScope` 取得依赖，不自行创建 Dio、插件服务、安全存储或隐式全局单例。
- 网络统一走 `ApiClient`；认证不反向依赖具体收藏/页面，跨域协调用 app 层。
- 安全底层归 `core/security`，锁屏编排归 `app/security`；不要继续扩大 SettingsController 的安全兼容代理。
- 本地平台功能目录、用户授权集合、Mock 授权数据三者分离；收藏不得越过权限校验。
- Bridge 只扩展受控 action：校验来源、会话、参数、权限、返回结构和错误码，并同步协议文档/测试。

## 硬性约束

- Token/密码/私钥/Cookie/验证码/图片 Base64/一次性 Code 不进入源码、日志或交接文档；真实配置与签名仅放被忽略的本机文件。
- 保留会话 generation、单飞刷新和文档 nonce 等竞态防护；异步结果不得跨账号或跨文档回写。
- 新文案补齐简体、繁体、英文 ARB，页面使用 `context.l10n`；不要只改生成文件。
- 地图、定位、相机等敏感能力按用户操作和授权触发，启动不主动取定位。
- 后台遮罩纯色无 logo；Android 7–12 不自行增加 FLAG_SECURE（用户曾明确暂不采用）。
- Mock 仅允许显式 mock Debug，不允许渗入 QAS/PRD 发布；不能用 MOCK_MENUS 单独绕过权限。
- 团队启动/打包入口仅维护 macOS；不要恢复 Windows 专用脚本。Android Release 只含 ARM64，QAS/PRD 都生成 APK；iOS 企业分发。
- 不随意改包名/签名/百度 Key：dev 身份用于调试，qas/prd 用于企业包；身份与 API 环境是两个维度。

## 验证

- Dart 改动按需运行 `./tool/app analyze`、`./tool/app test` 及相关专项测试。
- 构建配置改动运行 `ruby test/tool/build_configuration_test.rb`、Shell 语法检查，并尽可能做 Gradle 配置/任务图验证。
- Bridge JS 协议测试：`node --test test/core/bridge/bridge_script_contract_test.mjs`（需 Node）。
- 原生、签名、生物识别、WebView 数据清理和 Release 问题必须列出真机验证要求，不作未经验证的安全保证。
