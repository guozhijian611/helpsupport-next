# HelpSupport Flutter App

HelpSupport 患者端与医生端移动应用工程，当前阶段包含 Flutter 基础壳、路由、主题、本地化、网络客户端、Token 存储、权限、本地通知、Firebase Push 初始化骨架，以及引导页和本地模型接口联调入口。

## 运行

```bash
flutter pub get
flutter run -d ios --dart-define=HELP_SUPPORT_API_BASE_URL=http://10.0.0.6:8787
```

`HELP_SUPPORT_API_BASE_URL` 默认值是 `http://10.0.0.6:8787`，后端 API 使用现有 `/app/help/...` 路由。

## iOS 模拟器构建安装

```bash
./tool/build_ios_simulator.sh
```

脚本会自动构建 Flutter iOS 模拟器包，安装到 iOS Simulator 并启动 App。默认优先使用已启动的模拟器；也可以指定目标设备和接口地址：

```bash
IOS_SIMULATOR_NAME="iPhone 17" HELP_SUPPORT_API_BASE_URL=http://127.0.0.1:8787 ./tool/build_ios_simulator.sh
```

如需强制清理后重建：

```bash
CLEAN=1 ./tool/build_ios_simulator.sh
```

脚本默认会清理本项目 Swift Package repository 缓存并用 Xcode 强制刷新依赖，避免本机缓存缺少 Firebase 等版本导致构建失败；如确认缓存正常，可跳过刷新以缩短时间：

```bash
REFRESH_IOS_SPM=0 ./tool/build_ios_simulator.sh
```

## 引导页配置

App 启动后无登录态会进入 `/onboarding`，并请求：

```text
GET /app/help/common/onboarding?scene=first_launch&version=&locale={locale}
```

接口返回 `sa_app_onboarding_page` 中已启用的配置。移动端支持后端返回绝对图片 URL，也支持 `/storage/...` 这类相对路径；按钮动作按 `action_type` 执行 `next`、`skip`、`route` 和 `external_url`。

## 本地模型

本地模型对话使用 `llama_cpp_dart` 调用平台侧 llama.cpp 动态库。Flutter 负责从 `/app/help/local-model/catalog` 拉取模型目录、下载 GGUF 文件、校验 SHA256，并在设备本地完成回复。

运行前需要准备 native 动态库：

- Android：运行 `./tool/build_android_llama.sh`，脚本会按 `llama_cpp_dart` 绑定对应的 `llama.cpp` 提交构建 CPU-only `libmtmd.so`、`libllama.so`、`libggml*.so` 和 `libc++_shared.so`，并复制到 `android/app/src/main/jniLibs/<abi>/`。
- iOS：把 `libllama.dylib` 或对应 framework 嵌入 Runner target，并确保签名和嵌入方式符合 iOS 要求。
- 桌面或本机调试：可用 `--dart-define=HELP_SUPPORT_LLAMA_LIBRARY_PATH=/absolute/path/libllama.dylib` 指定动态库路径。

Android 默认加载 `libmtmd.so`。如需额外构建 x86_64 模拟器库，可运行：

```bash
LLAMA_ANDROID_ABIS="arm64-v8a x86_64" ./tool/build_android_llama.sh
```

如果动态库缺失、ABI 不匹配或依赖库缺失，本地模型聊天页会在发送前显示运行时检查错误。

## 校验

```bash
flutter gen-l10n
dart analyze
flutter test
```
