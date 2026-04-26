# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

AI Plan Monitor 是一个 macOS 菜单栏应用，用于统一监控多个 AI 服务的订阅额度、使用窗口和账号状态。支持官方服务（Codex、Claude、Gemini 等）和第三方中转站点的统一监控。

## 构建与运行

- `swift build` - 构建可执行文件
- `swift run` - 从源码启动应用（需要 macOS 14+）
- `swift test` - 运行测试套件
- `./scripts/package_dmg.sh` - 打包通用 DMG 到 `dist/` 目录

版本号存储在根目录的 `VERSION` 文件中。打包脚本默认使用 ad-hoc 签名，可通过环境变量配置 Developer ID 签名和公证。

## 代码架构

项目使用 Swift Package Manager，主要代码在 `Sources/AIPlanMonitor`，按职责分层：

### 核心模块

- **App/** - 应用生命周期、窗口管理、状态栏控制器
  - `AIPlanMonitorApp.swift` - SwiftUI 应用入口
  - `StatusBarController.swift` - 菜单栏图标和菜单管理
  - `AppViewModel.swift` - 应用级状态和协调逻辑
  - `SettingsWindowController.swift` - 设置窗口管理

- **UI/** - SwiftUI 视图组件
  - `SettingsView.swift` - 设置界面主视图
  - `MenuContentView.swift` - 菜单栏下拉内容
  - `SettingsWindowAppearanceResolver.swift` - 主题和外观解析

- **Providers/** - 各服务的集成实现
  - 每个 provider 实现 `UsageProvider` 协议
  - 官方服务：`CodexProvider`、`ClaudeProvider`、`GeminiProvider`、`CopilotProvider` 等
  - 第三方中转：`RelayProvider`（基于模板配置）
  - 核心协议定义在 `ProviderProtocol.swift`

- **Services/** - 共享服务层
  - 凭证管理：`BrowserCredentialService`、`CodexDesktopAuthService`、`ClaudeDesktopAuthService`
  - 账号管理：`CodexAccountSlotStore`、`ClaudeAccountSlotStore`
  - 本地数据：`CodexLocalUsageService`、`ClaudeLocalUsageService`
  - 通知和更新：`AlertEngine`、`AppUpdateService`

- **Models/** - 数据模型
  - `ProviderModels.swift` - Provider 类型、认证配置、枚举定义
  - `RelayModels.swift` - 第三方中转站点的模板和配置模型

- **Utils/** - 工具函数和辅助类

- **Resources/** - 图标和内置的中转站点 JSON 配置文件

### Provider 架构

所有 provider 实现 `UsageProvider` 协议：

```swift
protocol UsageProvider: Sendable {
    var descriptor: ProviderDescriptor { get }
    func fetch() async throws -> UsageSnapshot
    func fetch(forceRefresh: Bool) async throws -> UsageSnapshot
}
```

错误处理通过 `ProviderError` 枚举统一分类：
- `missingCredential` - 缺少凭证
- `unauthorized` / `unauthorizedDetail` - 认证失败
- `rateLimited` - 被限流
- `invalidResponse` - 响应格式错误
- `commandFailed` - 命令执行失败
- `timeout` - 超时
- `unavailable` - 服务不可用

### 凭证策略

第三方中转站点支持三种凭证模式：
- **Manual Preferred** - 优先使用手动保存的凭证，浏览器凭证作为兜底
- **Browser Preferred** - 优先使用浏览器凭证，手动保存的作为兜底
- **Browser Only** - 仅使用浏览器凭证

手动保存的凭证存储在 macOS Keychain，应用配置保存在 `~/Library/Application Support/AIPlanMonitor`。

### Codex 多账号切换

项目的特色功能之一是支持 Codex 本地多账号管理：
- 自动识别当前 Codex 桌面端的 `auth.json`
- 支持导入和切换多个本地账号
- 保留未激活账号的额度窗口和倒计时
- 相关实现在 `CodexAccountSlotStore`、`CodexDesktopAuthService`、`CodexAuthPathResolver`

## 测试

测试位于 `Tests/AIPlanMonitorTests`，使用 XCTest 框架。测试文件镜像生产代码结构，例如 `CodexProvider.swift` 对应 `CodexLocalUsageServiceTests.swift`。

修改以下内容时应添加或更新测试：
- Provider 解析逻辑
- 配置默认值
- 凭证处理
- 倒计时和额度计算逻辑

## 代码风格

- 4 空格缩进
- 类型使用 `UpperCamelCase`，方法和属性使用 `lowerCamelCase`
- 每个文件一个主要类型，文件名与类型名一致
- Provider 特定代码放在 `Providers/`，共享逻辑放在 `Services/` 或 `Utils/`
- 项目未配置格式化工具或 linter，遵循 Xcode/SwiftPM 默认风格

## 提交规范

提交信息保持简洁、具体，聚焦单一变更。历史记录混合使用简洁的祈使句（如 `Fix update detection and menubar update badge`）和带前缀的格式（如 `feat:`、`chore:`、`release:`）。

PR 应包含：
- 用户可见行为的简要说明
- 相关 issue 或上下文链接
- 菜单栏或设置界面变更的截图
- 新增配置、认证、签名或打包行为的说明

## 安全注意事项

- 手动保存的凭证默认存储在 macOS Keychain
- 浏览器凭证读取仅在用户启用相应模式时进行
- 不要在代码或提交中包含真实的 API 密钥、Token 或 Cookie
- Provider 实现应正确处理认证失败和过期场景

## 支持的服务

### 官方服务
Codex、Claude、Gemini、GitHub Copilot、Cursor、Windsurf、Kimi、Amp、Z.ai、JetBrains AI、Kiro、OpenCode Go

### 第三方中转模板
`open.ailinyu.de`、`platform.moonshot.cn`、`platform.xiaomimimo.com`、`platform.minimaxi.com`、`hongmacc.com`、`platform.deepseek.com`、`dragoncode.codes`、通用 New API 兼容站点

详细信息见 `docs/PROVIDERS.md`。
