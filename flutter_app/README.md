# HelpSupport Flutter App

HelpSupport 患者端与医生端移动应用工程，当前阶段包含 Flutter 基础壳、路由、主题、本地化、网络客户端、Token 存储、权限、本地通知、Firebase Push 初始化骨架，以及引导页和本地模型接口联调入口。

## 运行

```bash
flutter pub get
flutter run --dart-define=HELP_SUPPORT_API_BASE_URL=http://127.0.0.1:8787
```

`HELP_SUPPORT_API_BASE_URL` 默认值是 `http://127.0.0.1:8787`，后端 API 使用现有 `/app/help/...` 路由。

## 校验

```bash
flutter gen-l10n
dart analyze
flutter test
```
