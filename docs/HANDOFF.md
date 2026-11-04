# 新会话交接

更新：2026-11-04；源码基线 `0b57a47`。先读根 AGENTS.md，再读本文；详细架构见 [PROJECT_CONTEXT](PROJECT_CONTEXT.md)。本文不记录敏感本机参数，也不保证其他电脑/服务器与本仓库一致。

## 1. 当前现场（先处理，不要覆盖）

- 当前 main 跟踪 origin/main。此前 `0b57a47` 已推送 Gitee 与 GitHub；开始新任务仍应重新检查 Git 状态与远端，不假定长期同步。
- 轮播文件原有的误输入顿号已按用户要求删除；文件恢复到 `0b57a47` 中相同内容，未改变轮播高度、样式或业务行为，因此没有新增源码差异。
- 用户已要求上传本轮交接文档；三份文档随该次提交交接。不修改配置/依赖，不构建发布。
- 根 AGENTS.md 原不存在；lib/AGENTS.md 原有规则完整保留。

## 2. 最近有效成果及验证级别

| 成果 | 证据 / 验证边界 |
| --- | --- |
| PRD Android 从 AAB 改成 ARM64 APK，QAS 同路径构建 | 0b57a47，tool/app、README；未真实生成签名 APK |
| Release 校验优先按明确 assemble/bundle 的 flavor；泛任务才看精确产物任务 | 0b57a47，android/app/build.gradle.kts；上轮 Java 21 Gradle tasks 通过，QAS dry-run 停在缺 QAS 签名文件，未在用户出错电脑复测 |
| 个人 dev 与企业 qas/prd 签名/地图 Key 分离 | 14094ea；配置解析测试存在，不代表所有企业证书可用 |
| 安全编排/能力拆分、用户数据域协调、平台目录与 Mock 分离 | c062fbb；代码及专项测试存在，不宣称全真机回归完成 |
| 打开 Vue2 前通过 handoff 获取一次性 code | 83f8808、fd26c08 与当前 auth/legacy 源码；真实后端兑换时效/幂等未核验 |

已实现的其他能力见 PROJECT_CONTEXT。角标后端、SQLite 不是已完成项；“有测试代码”不等于本次测试通过。

## 3. 已知问题、冲突与待办优先级

以下优先级是交接建议，不代表用户授权实施全部任务。

### P0：恢复可验证基线

1. 轮播语法阻塞已解除，全项目静态分析通过；后续按新改动范围运行全量或专项单测，不把轮播专项通过等同全量回归。
2. 在原出错电脑验证 `./tool/app build qas android`。真实 QAS 签名、地图 Key 和 API 覆盖必须由开发者配置；本次没有读取其秘密值。若仍 mismatch，采集实际 Gradle 请求任务和脱敏身份环境，不直接关闭保护。

### P1：上线与安全边界确认

- **HTTPS 迁移尚未落库**：用户称已域名化；共享 qas.json / mock.json / AppConfig 默认仍有旧 HTTP 内网地址，prd.json 为空。需确认每个环境 China/HK API、H5 与下载域名、网关路径前缀和证书链。`environment.qas.json` 不是当前主构建入口，勿只改它。
- **网页数据清理冲突**：用户可见最终清单要求保留 Service Worker/离线业务数据，但 iOS 当前 allWebsiteDataTypes 会全清，Android WebStorage.deleteAllData 也需按系统 WebView 实测界定。先确认需求是否已被后续全清要求覆盖；不可宣称目前保留。
- **启动强更未启用**：app_dependencies.dart 的 checkAtStartup 调用已注释。版本判断/设置页检测代码存在，是否恢复启动检查需用户决定；不能自动解除注释。
- **H5 Token 兼容**：handoff 已接入，但 auth.getSession 和首次页面 Authorization 仍存在。是否移除此兼容需确认旧 Vue2 依赖；refresh token 不得传给网页。
- **清理失败仍登出**：AuthController 对网页清理失败只告警后放行下一次登录，可能残留上一账号网页数据；是安全权衡待评审，不视为已保证跨账号绝对隔离。
- 正式法律 HTML 仍需法务确认替换 demo；版本接口 minimum/latest 协议需后端实际样例确认。HTTPS-only、下载限制、ATS/cleartext 收紧均未做。

### P2：待开发需求与技术债

- 固资盘点离线 SQLite + CRUD Bridge：用户确认只用于该模块，联网后同步远端；当前无插件、数据库、表、事务、CRUD action 或同步队列。仅补 Vue2 JS 封装不够。先取旧 Cordova 数据结构和 SQL、同步接口、幂等规则、退出/换账号未同步数据策略；数据库迁移/隔离/加密要求待定。不要开放任意 SQL 执行器作为既定设计。
- 首页/更多角标只有统一状态与 Mock 数据，待正式聚合接口。
- 更新 README 与旧技术文档中的语言、请求头、热更新/启动检查描述（本任务不扩大为维护所有历史文档）。X-Client 当前 merptest 是否应保留需后端确认。
- 手势/生物识别、隐私快照、WebView 清理/Bridge、ARM64 APK 升级覆盖安装需要 Android/iOS 真机矩阵。曾有模拟器 ADB attach 卡住，换模拟器解决过一次，不代表所有卡住都是同一原因。
- SettingsController 安全兼容代理、MerpNativeBridge 大分发器、RuntimeResourceManifest demo 残留及同步日志文件写入是可评估债务；不未经授权继续全局重构/换状态管理框架。

## 4. 下一会话建议切入点

轮播语法问题已解决。下一步让用户在“QAS Release 原机复验 / HTTPS 接入 / 固资离线存储设计”中明确一个任务，并按范围补全单测/真机验证。固资 SQLite 尚未批准实施，不自动选择或新增依赖。

## 5. 运行与验证命令

```bash
git status --short --branch
git log -6 --oneline
./tool/app doctor
./tool/app ide
./tool/app run qas android --dart-define=ENABLE_LOG=true
./tool/app run qas android --recover -d <device-id>
./tool/app run qas ios
./tool/app run mock android
./tool/app analyze
./tool/app test
ruby test/tool/build_configuration_test.rb
node --test test/core/bridge/bridge_script_contract_test.mjs
bash -n tool/app tool/configure_ide tool/clean_project
git diff --check
```

`doctor/bootstrap/ide` 会初始化工具链或补本地文件，不是纯只读；build 会生成产物，不是部署。新会话先判断授权范围再执行。不要把设备占位文本原样粘贴为命令。

已批准需要真实打包时才运行：`./tool/app build qas android` 或 `./tool/app build prd android`（两者均 ARM64 APK；PRD 要人工确认）。run 始终 dev 身份；run --release 不是 qas/prd 企业包。iOS enterprise IPA 与 OTA 详见 README/发布教程；旧 enterprise Profile 不能作为 dev 附加调试证书。构建号五位，更新旧包要同包名/签名且 code 更大。

### 本次实际验证

- `ruby test/tool/build_configuration_test.rb`：10 tests / 57 assertions，0 failures/errors；Ruby 环境另有 ffi 扩展未构建告警。
- `bash -n tool/app tool/configure_ide tool/clean_project`：通过。
- Node Bridge 测试：未执行，终端找不到 node。不要因此新增依赖或改项目版本。
- 后续修复验证：`./tool/app analyze` 全项目无问题；期间 FVM 获取 Flutter 标签出现 HTTP2 网络告警，但分析命令最终 exit 0。轮播文件直接 Dart analyze 也无问题。
- `.fvm/flutter_sdk/bin/flutter test --no-pub test/features/home_banner_carousel_test.dart`：1 项通过，PNG 拉伸填充及 178 高度保持不变。
- 未做全量 Flutter 测试、真机或实际签名构建，不声称全量回归通过。

## 6. 失败教训与未确认信息

- 上传 GitHub 曾读正常但真实 push HTTP 400/断连；本机使用仅单次命令的 HTTP/1.1 + postBuffer 后成功，是经验性绕过，不证明所有网络故障根因相同。未经用户要求不推送、不改全局 Git 代理。
- 不把 help 中的 build prd android 与真实身份 mismatch 报错混为一谈；定位必须看第一条实际异常。
- 直接 Gradle 检查曾默认 Java 8 失败，Android Studio JBR 21 可用；tool/app 有 JDK 回退。不要误改依赖以修复本机 Java 环境。
- 原生源代码位于 android/ios，不会因正常 Flutter 编译消失；不要把改动放入 build 或 Pods 产物。
- 早期对话有大量仅用户消息可见、缺失对应助手实现/工具证据；未验证的包名演进、后端协议、设备测试和性能结论不作为验收事实。
- 部署域名、TLS/网关配置、Code TTL/兑换机制、真实盘点表与同步合同、企业密钥有效性、正式法律文本、老 Android 遮罩验收均待确认。
