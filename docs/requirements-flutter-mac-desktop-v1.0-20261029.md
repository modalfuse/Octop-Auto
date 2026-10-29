# Octop-Auto Flutter Mac 桌面客户端需求 v1.0-20261029

## 1. 背景与目标

在 Mac 上用 **Flutter** 做 Octop-Auto 桌面客户端；**后端服务固定跑在学校 hp02**（已有 Octop Web：`http://rgzn-hp02:8088`，Tailscale IP `100.101.163.69`）。本客户端是「连远程服务的桌面壳 + 原生体验」，**不是**仓库现有 `desktop/`（Wails 本地捆绑服务）的替代品；两者并存，新代码放在独立目录。

工作目录（本机）：`/Users/qiang/works/12-AutoResearch/Octop-Auto`  
远程仓库：https://github.com/modalfuse/Octop-Auto  
归档：改动及时 push 到该仓（默认分支或特性分支均可，合并进 `main`）。

## 2. 非目标（本期不做）

- 不把 Octop Python 服务嵌进 Mac 本机进程（不替代 Wails green portable）
- 不做 Windows/Linux 安装包（架构可预留，本期只交付 macOS）
- 不实现微信/企微/QQ 渠道配置向导（可后续）
- 不改 hp02 上 LLM provider 密钥存放方式

## 3. 服务端约定

| 项 | 值 |
|----|----|
| 主机 | Tailscale `rgzn-hp02` / `100.101.163.69` |
| Web/API | `http://100.101.163.69:8088`（开发默认；设置里可改 Base URL） |
| 鉴权 | 与现有 Web 一致（admin 登录 / session / token，以 `docs/api.md` 与现网为准） |
| Agent | 默认使用已有 `main`（小通） |

客户端只通过 HTTP(S)/WebSocket（若现网对话流用 SSE/WS）访问上述服务，不 SSH、不直连数据库。

## 4. 产品范围（MVP）

### 4.1 壳与导航

- macOS 窗口应用（Flutter macOS desktop）
- 侧栏结构对齐 Web，至少包含：
  - **项目空间**（可折叠）：「新建项目」+ 项目列表（一期可用本地存储；若已有服务端 API 则优先服务端）
  - **对话**：会话列表 + 与 `main` 的聊天
  - 设置入口：服务器 Base URL、账号登录/退出
- 视觉参考现网 Web + 已上线的「项目空间」补丁（`deploy/hp02-overlay`、`dashboard/public/assets/project-space.*`）

### 4.2 对话

- 登录后进入对话页，可发文本消息
- 展示助手回复；若 API 支持流式，优先流式渲染，否则整段返回
- 错误态可读（如服务不可达、未登录、模型失败），提供重试

### 4.3 连接与配置

- 首次启动引导填写/确认 Base URL（默认填 hp02 地址）
- 探测健康检查（可用现网 `/api/...` 健康或首页可达性）
- 凭据存 macOS 安全存储（Keychain / `flutter_secure_storage`），**禁止**明文写进仓库或日志

### 4.4 工程结构（建议）

```
clients/flutter_mac/          # 新建 Flutter 工程根（名称可微调，保持在仓库内）
  README.md                   # 如何跑、如何连 hp02
  ...
docs/requirements-flutter-mac-desktop-v1.0-20261029.md  # 本文档
```

不要改坏现有 `desktop/`（Wails）。可选：在仓库根 README_CN 增加一节「Flutter Mac 客户端」链接。

## 5. 技术约束

- Flutter stable（本机已有约 3.35.x 即可；以 `flutter doctor` 可通过为准）
- 目标平台：`macos`
- Dart 空安全；状态管理任选（Riverpod / Provider / Bloc），保持简单
- API 客户端根据 `docs/api.md` 与浏览器 Network 行为对齐；不确定时以 hp02 现网为准
- 提交信息不要包含 AI/Cursor/生成工具痕迹或 Co-authored-by

## 6. 测试要求（Cursor 必须做）

1. `flutter create` / 依赖安装后：`flutter analyze` 无 error
2. `flutter test`：至少覆盖「Base URL 解析」「未登录拦截或等价单元测试」各 1 个
3. macOS 构建：`flutter build macos` 或 `flutter run -d macos` 能启动窗口
4. **联调（在用户 Mac、经 Tailscale）**：对 `http://100.101.163.69:8088` 做健康探测；若可登录则发一条测试消息到 `main`（无密钥进日志）。若网络不可达，在 PR/报告中写明阻塞原因与复现命令，仍需完成可离线跑的单测与构建
5. 在 PR 或提交说明中附：如何从本工作目录启动客户端

## 7. 交付物

- 合并或可审查的分支，含 `clients/flutter_mac/`（或等价路径）
- 更新本需求文档状态（文末「实现状态」）
- 本地工作树位于 `/Users/qiang/works/12-AutoResearch/Octop-Auto`，并 push 到 `modalfuse/Octop-Auto`

## 8. 实现状态

- [x] Flutter macOS 工程骨架（`clients/flutter_mac/`）
- [x] 设置 / Base URL / 安全存储登录（钥匙串 entitlement 已写入 macOS runner）
- [x] 对话 MVP（main，WebSocket `token` 帧）
- [x] 项目空间侧栏（本机存储：新建、选择、删除、折叠）
- [x] analyze / test：云端 Ubuntu x86_64、Flutter 3.47.8。`flutter analyze` 无 issue，`flutter test` 13 passed
- [ ] macos build：Linux 上的 Flutter 没有 `flutter build macos` 子命令，需在 Mac 上执行（命令见 `clients/flutter_mac/README.md`）
- [ ] hp02 联调记录：云端未连 Tailscale。Mac 上先 `curl -sS http://100.101.163.69:8088/api/health`，再在窗口登录并向 main 发一条消息（密码不要进入命令或日志）
