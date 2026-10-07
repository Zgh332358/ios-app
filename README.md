# 共鸣 iOS：连接自己的 StepFun 网页服务

这是 [Zgh332358/ios-app](https://github.com/Zgh332358/ios-app) 中的 iOS 配套应用，基于 [revoice-resonance/ios-app](https://github.com/revoice-resonance/ios-app) fork。它使用 UIKit 和 WKWebView 显示共鸣网页。**语音识别、语音合成和多模态请求由你部署的 [web-app](https://github.com/Zgh332358/web-app) 服务处理，StepFun API Key 只放在服务端。**

这个仓库没有独立的原生 StepFun API 客户端，也没有新增原生图片或视频对话界面。此次修改让原本不生效的网页地址设置真正控制 WebView，并取消自动连接原组织网页的行为。

## 先配置服务端，再连接 iOS

1. 按 [web-app README](https://github.com/Zgh332358/web-app#readme) 部署你自己账号下的前端与 Worker。仅 fork 代码不会自动得到可访问的网站。
2. 在该服务端配置下列变量；Key 可以等拿到后再填。没有 Key 时，网页仍可显示，模型请求会返回未配置错误。

   | 服务端变量 | 本次默认值 / 说明 |
   | --- | --- |
   | `OPENAI_API_KEY` | 你后续提供的 StepFun API Key，仅服务端保存 |
   | `OPENAI_BASE_URL` | `https://api.stepfun.com/v1` |
   | `MULTIMODAL_MODEL` | `step-5-preview` |
   | `ASR_MODEL` | `stepaudio-3-chat-preview` |
   | `TTS_MODEL` | `stepaudio-3-tts` |
   | `TTS_VOICE` | 由 web-app 配置；实际可用音色需用 Key 验证 |

3. 启动 iOS 应用，进入 **Settings → Web App URL**，填写部署完成的共鸣**网页**地址，例如 `https://your-resonance.example.com`。此地址仅是示例，不是已部署网站。不要填 StepFun 官网 API base URL，不要粘贴 API Key。
4. 返回 **Web** 标签页后会加载新地址。修改地址后返回该页、点击刷新或下拉刷新，都会重新读取配置。网页使用同源 Worker `/api/...` 接口。

当前对应的网页接口为 `/api/asr/recognize`、`/api/tts/speak` 和 `/api/multimodal/respond`。多模态接口提供文本/图片调用能力，但此次未新增对应原生界面；可见功能以你部署的网页版本为准。语音请求如何编码、模型参数及限制以 [web-app 接入规格](https://github.com/Zgh332358/web-app/blob/master/docs/specs/stepfun-preview.md) 为准。`stepaudio-3-tts` 与 `stepaudio-3-chat-preview` 是不同接口所用的模型 ID，不能把用户口头缩写直接当成 API 模型名。

## 网页地址的优先级

- 优先使用 Settings 中保存的非空地址。
- 留空时使用构建配置 `RESONANCE_WEB_URL`；仓库默认也是空值。没有可用配置时展示本地说明页。
- 非法的非空设置会显示错误，不会静默回退到构建配置。清空或非法配置会停止旧页面并显示本地说明；若构建配置非空且合法，清空设置会改为加载该构建地址。
- 接受完整 HTTPS 地址。HTTP 仅允许 `localhost`、`127.0.0.1`、`[::1]`，方便模拟器本机开发；真机的 localhost 指向手机，连接 Mac 或远端服务请使用可访问的 HTTPS 地址。
- 拒绝用户名/密码嵌入 URL。旧 DNS 自动发现和旧 `endpoint_config` 缓存不再参与 WebView 的地址选择；原先没有实际控制加载的 DNS 设置已从界面移除。

如果要给固定部署构建 App，可以在 `project.yml` 的 `targets.Resonance.info.properties.RESONANCE_WEB_URL` 中填写网页地址，然后重新执行 `xcodegen generate`。生成后的 `Resonance/App/Info.plist` 会使用同一值；提交源配置时应保持两处一致。通常直接使用 Settings 即可，无需重新编译。

JS bridge 的 `getConfig` 只返回是否已配置、网页 URL 和对应源站。它不返回供应商 Key、虚构的原生模型列表或历史 WebSocket 地址。网页中的身份认证及数据策略仍由 web-app 服务端负责。

## 构建与验证

需要 macOS、完整 Xcode（包含 iOS SDK）和 XcodeGen。项目目标为 iOS 15.0+；签名安装需要自行配置 Apple 开发团队和 Bundle ID。只有 Command Line Tools 无法构建 UIKit / WKWebView 应用。

```bash
brew install xcodegen
xcodegen generate
open Resonance.xcodeproj
```

在 Xcode 选择可用的 iOS 模拟器并运行 `Resonance` scheme。也可以根据已安装的模拟器运行：

```bash
xcodebuild -project Resonance.xcodeproj \
  -scheme Resonance -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

仅网页配置逻辑的测试可以在具备 Swift 编译器的 macOS 上独立执行，不需要 iOS SDK：

```bash
./scripts/test-configuration.sh
```

此测试实际编译并运行 Foundation 代码，覆盖 33 项断言：空配置、设置与构建值的优先级、非法设置不能回退、HTTPS/本机 HTTP、IPv6、用户名密码、端口范围、源站提取、旧缓存隔离，以及保存/清空配置后的更新。CI 的 push / PR 会执行该测试与无签名 iOS 编译；不再因推送 release 分支自动导出 IPA。`Release` 工作流保留手动触发，未验证签名和 IPA 导出是否可用。

**本次本地已验证：** Foundation 测试、变更 Swift 的语法解析、Info.plist 合法性与配置字段检查。当前开发环境仅有 Command Line Tools，未执行完整 iOS 构建、模拟器/真机 UI 或录音测试；尚未提供 Key，因此没有验证真实 StepFun 调用、模型权限或音色兼容性。推送后如运行 CI，应另行查看其实际构建结果。

## 保留功能与未完成事项

- **Local Model 标签页仍是原始演示。** `ChatViewModel` 返回模拟答复，未实现真实本地推理，也没有将其改名为云端 StepFun。其示例模型下载地址仍是历史站点，用户主动点下载仍可能访问该站点；这与 WebView 默认不再访问原组织网页是两回事。
- 独立 DNS 源码保留，但不参与当前 WebView 加载链路。项目没有实现额外的原生实时语音协议、声音克隆或语料库训练。
- 已增加麦克风用途说明。网页录音还取决于系统权限、WKWebView 和部署网页实现，需要真机验证。
- 保留原项目的 ATS 配置，本次不做全面网络安全重构。云端 Key 不应写入 Info.plist、UserDefaults、源码、构建产物或 JS bridge。

[本次修改规格与验证边界](docs/specs/stepfun-preview.md) 记录此次 fork 修改。原 [SPEC.md](SPEC.md) 和历史交接文档保留上游设计背景，不代表其中所有计划均已实现。许可证见 [LICENSE](LICENSE)。
