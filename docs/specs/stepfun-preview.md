# iOS fork：StepFun 云端服务接入方案

状态：经评审批准并完成实现；本地验证与限制见下文。日期：2026-10-02。

## 现状与真实边界

- 这是 UIKit / WKWebView 外壳，Web 标签页加载网页。没有 Swift 实现的 Gemini、Whisper、OpenAI 或 StepFun 云端多模态/语音调用，也没有原生图片问答入口。
- `MainWebViewController` 在迁移前把网页固定为 `https://project-resonance.net`。当时 DNS 发现成功仅写配置，并未改变实际加载 URL；Settings 中保存的 Endpoint 同样没有连接到 WebView。这些断开的配置链路已在此次修改中修复。
- Local Model 标签页下载 `resonance-{3,7,13}b` 示例文件；`ChatViewModel.generateResponse` 明确返回模拟答复，不能视为本地推理。此功能不具备可替换的云端接口，不应通过改模型名伪装为 StepFun 推理。
- 语音、图片及文本请求应沿用被加载的 `web-app` 前端和 Worker，由服务端配置 StepFun 官方 base URL / 模型 / Key。iOS 应只配置网页地址；不得将 StepFun Key 或官网 `/v1` 地址当作网页地址写入客户端。
- 已检查 `CLAUDE.md` 和 `docs/agents/domain.md`。当前机器仅安装 Xcode Command Line Tools，没有可用的完整 Xcode / iOS SDK / XcodeGen；可以执行 Foundation 配置测试和静态检查，不能声称通过 iOS 模拟器构建或真机麦克风验证。

## 目标与实施范围

1. 增加清晰的自有 Web 前端地址配置：Settings Endpoint 优先，其次 `Info.plist` 的 `RESONANCE_WEB_URL`（与 XcodeGen `project.yml` 一致）。默认留空，不自动连接原组织部署域名。
2. 连接现有 Settings 保存和 WebView 加载逻辑。返回 Web 标签页或点击刷新时读取配置并加载；未配置时显示配置说明，非法地址显示错误，不退回原组织网站；两者都先停止加载并用本地说明页替换已打开的网页，清空旧地址状态。只接收 HTTPS URL；HTTP 仅允许 localhost / 127.0.0.1 / ::1 模拟器本地调试。拒绝包含用户名密码的地址。
3. 本 fork 的 WebView 不再自动使用原组织域名的 DNS 发现。移除 Settings 中不再作用于当前加载链路的 DNS/Auto Discovery 控件，避免误导；保留独立 DNS 实现作为原有代码，不扩大改造。
4. 在 `Info.plist` 和 `project.yml` 增加中文麦克风用途说明，满足被加载网页请求录音的宿主声明。无原生摄像头入口，不新增虚构功能。
5. `ConfigurationService` 对 JS bridge 暴露的端点应来自已选择的网页源站，不能将旧缓存中的原组织端点混进本 fork；不返回任何供应商密钥，不宣称原生支持云端模型。
6. README 说明：先部署本账号 `web-app` fork，服务端设置官网 base URL 和 API Key，再填写该部署网页 URL；当前原生 Local Model 是未完成演示，不承诺 StepFun 云端功能。模型 ID / 分离的语音识别与合成端点以 web-app 的最终配置为准（目标为 Step-5 preview 和 StepAudio3 preview）。
7. CI 保留 push / PR 的无签名编译检查；移除 CI 中 release 分支 push 自动导出 IPA 的 job。手动 `release.yml` 保持 workflow_dispatch，仅用户显式执行才尝试打包，不做部署或发布。
8. 将客户端 Source Code 链接指向 `https://github.com/Zgh332358/ios-app`，README 链接使用本账号 fork。历史文档和许可证保留来源。

## 不做的事项

- 不在 Swift 中复制 web-app Worker 的语音或多模态接口，不把 API Key 放入 UserDefaults、Info.plist、源码或 WKWebView JS bridge。
- 不把本地示例模型改名为 StepFun 云端模型，不实现新本地推理引擎或新原生多模态 UI。
- 不部署网站、自动发布 IPA、上传用户音频或进行收费 API 调用。
- 不修改其他仓库，不 commit / push，由主代理统一核对后提交至账号 fork。

## 验收

- Foundation 级 URL / 配置测试覆盖：默认空值、Settings 优先于 Bundle、HTTPS、localhost HTTP、拒绝普通 HTTP / 用户名密码 / 非 Web 协议 / 相对路径。
- 人工审查 WebView 首次加载、回到标签页、刷新、清空配置的状态变更，确认都不回退原组织域名；无新硬编码密钥。
- `plutil` 验证属性列表，校对 XcodeGen 属性一致；Swift parse 检查（若工具可用），`git diff --check`。
- 检查 CI 不再自动导出 IPA；手动 release 保持显式调用。
- 完整 Xcode / iOS SDK 构建与设备录音、网页 ASR/TTS/多模态端到端验证列为未执行，需要部署网页和 API Key。

## 评审进展

- Architect：2026-10-02 主代理评审通过。明确不改变本地模拟 Chat；DNS 模块保留；地址清空后必须替换旧网页；不扩展为 ATS 全面改造。
- Senior / Manager / 独立 challenge：主代理确认全部 PASS，并于 2026-10-02 明确批准实施。
- 子代理只读 spec review：PASS，新增非法设置不回退 Bundle、旧缓存隔离、IPv6/凭据/端口等测试建议已落实。

## 实施验证记录

- 已完成网页配置读取、Settings 保存、WebView 切换和未配置本地页，默认不自动连接原组织网页。清空/非法配置时停止旧加载并禁止从历史记录恢复外部页面。
- `./scripts/test-configuration.sh`：33 项 Foundation 断言通过，使用 swiftc 编译并实际运行。
- 变更 Swift 文件的 `swiftc -frontend -parse`、`plutil -lint Resonance/App/Info.plist` 通过。parse 只验证语法，不代表 iOS 类型检查。
- 自动 IPA job 已移除，手动 workflow 的输入经 env 和双引号传参；Foundation 检查已加入 CI。
- 没有完整 Xcode/iOS SDK，未执行 iOS 构建、模拟器/真机 UI、麦克风或真实 StepFun 调用。完整验证需部署自有网页并后续提供服务端 Key。

## 最终复核（2026-10-07）

- 独立代码复审 PASS，无 Medium 或更高级别问题。评审者复跑 33 项 Foundation 断言、变更 Swift 语法解析、plist 检查和 diff 校验均通过。
- 发布安全复审 PASS：无自动 IPA / 部署 job；手动构建输入经 env 和双引号传参；客户端与 JS bridge 不保存或返回模型供应商 Key。
- 本地文档链接、网页地址默认空值和麦克风说明的 XcodeGen / plist 一致性检查通过。
- 开发环境仍只有 Xcode Command Line Tools；完整 iOS 编译、模拟器/真机界面和真实 StepFun 服务调用仍未验证。
