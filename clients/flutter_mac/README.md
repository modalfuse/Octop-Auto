# Octop-Auto Flutter macOS 客户端

连接已经在跑的 Octop 服务（默认学校 hp02：`http://100.101.163.69:8088`）。这是远程桌面壳，不替代仓库里的 `desktop/`（Wails 本地捆绑服务）。

## 能做什么

- 首次启动确认 Base URL，并用 `GET /api/health` 探测
- 用户名密码登录。访问令牌放在 macOS 钥匙串（`flutter_secure_storage`），不写入仓库或日志
- 对话页默认选 agent `main`（小通）。消息走 `WS /api/agents/{id}/chat/ws`，按 `token` 帧流式显示；失败时可以重试
- 侧栏「项目空间」：新建、选择、删除、折叠。列表存在本机，不上传

修改 Base URL 会清掉已保存的登录态。

## 云端已跑过的检查

环境：Ubuntu x86_64，Flutter 3.47.8（Dart 3.13.7）。

```bash
cd clients/flutter_mac
flutter analyze   # No issues found
flutter test      # 13 passed
```

同一台 Linux 上执行 `flutter build macos` 会失败：Flutter 在非 macOS 主机没有 `macos` 子命令（`Could not find a subcommand named "macos" for "flutter build".`）。窗口构建和 hp02 联调需要在 Mac 上做。

## 在用户 Mac 上测试

Flutter 路径和工作目录按本机约定：

```bash
export PATH="/Users/qiang/works/7-Projects/flutter/bin:$PATH"
cd /Users/qiang/works/12-AutoResearch/Octop-Auto
git pull
cd clients/flutter_mac
flutter pub get
flutter analyze
flutter test
flutter build macos
flutter run -d macos
```

联调前先确认 Tailscale 能访问 hp02：

```bash
curl -sS http://100.101.163.69:8088/api/health
```

期望类似 `{"status":"ok",...}`。然后在窗口里登录，向 main 发一条文本。不要把密码写进命令、脚本或日志。

若 `flutter run` 打不开窗口，看 `flutter doctor` 里的 Xcode / CocoaPods。钥匙串需要 `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements` 里的 `keychain-access-groups`；出站访问需要 `com.apple.security.network.client`。这两项已经写在工程里。
