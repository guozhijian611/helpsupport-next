# HelpSupport Flutter

这是基于 `helpsupport-frontend` UniApp 患者/医生端重写的 Flutter App 目录，用于后续构建 Android APK 和 iOS IPA。

## 已迁移范围

- 患者/医生登录入口与演示登录
- 注册、资料、医生资格证书流程骨架
- 四 Tab 主导航：主页、社区、计划、我的
- 患者首页：预约、教育素材、娱乐、三种 AI 聊天模式、最近对话
- 医生首页：社区审核、患者管理、预约、任务模板、评估量表
- 社区、计划、我的、聊天、素材、娱乐、预约、消息中心等核心页面骨架
- Dio API 客户端，接口路径沿用 `/app/help/...`
- 复用 UniApp 的首页、认证、Tab、内容部分静态资源

## 运行

```bash
cd helpsupport_flutter
flutter pub get
flutter run
```

真实接口默认指向 `https://help.openb8.chat`。如需临时切换后端地址：

```bash
flutter run --dart-define=HELP_SUPPORT_API_BASE_URL=https://你的后端地址
```

## 构建 APK

```bash
cd helpsupport_flutter
flutter build apk --release --dart-define=HELP_SUPPORT_API_BASE_URL=https://help.openb8.chat
```

产物一般在：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 构建 IPA

iOS 需要在 macOS 上配置 Apple Developer 账号、Bundle Identifier、签名证书和 Provisioning Profile。

```bash
cd helpsupport_flutter
flutter build ipa --release --dart-define=HELP_SUPPORT_API_BASE_URL=https://help.openb8.chat
```

如果需要先打开 Xcode 配置签名：

```bash
open ios/Runner.xcworkspace
```

## 后续深化建议

- 按 UniApp 页面继续补齐：评论楼中楼、私人素材上传、预约时段选择、患者详情、计划配置、量表制作。
- 将当前 mock 数据逐页替换为 `ApiClient` 的真实接口调用。
- 接入图片上传、语音输入、实时通话、本地模型等原 UniApp 端侧能力。
