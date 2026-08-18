# HelpSupport Flutter App

HelpSupport 患者端与医生端移动应用工程，当前阶段包含 Flutter 基础壳、路由、主题、本地化、网络客户端、Token 存储、权限、本地通知、Firebase Push 初始化骨架，以及引导页和本地模型接口联调入口。

## 运行

```bash
flutter pub get
cd ..
./run_app.sh
```

`./run_app.sh` 会合并显示 `flutter devices`、`adb devices` 和可启动 Android AVD，让用户选择后在 `flutter_app/` 下执行 `flutter run -d <device id>`。脚本会在运行时把 Android SDK 的 `emulator`、`platform-tools` 和 `cmdline-tools/latest/bin` 加入 PATH；如果没有检测到 Android 设备，会自动执行 `flutter emulators --launch HelpSupport_API36` 并等待模拟器连接。选择可启动 Android AVD 时，脚本会先启动对应模拟器，再用启动后的 adb 设备 ID 运行 Flutter。

API 基础地址写在 `flutter_app/lib/core/api/api_client.dart` 的 `ApiClient.apiBaseUrl` 常量里。Debug 和正式包默认都使用 `https://help.openb8.org`；本机后端地址仍保留为 `http://10.0.0.6:8787`，需要时把 `apiBaseUrl` 改成 `localApiBaseUrl`。后端 API 使用现有 `/app/help/...` 路由。

如需切换默认 Android AVD 或关闭自动启动：

```bash
ANDROID_EMULATOR_ID=YourAvdName ./run_app.sh
AUTO_LAUNCH_ANDROID_EMULATOR=0 ./run_app.sh
```

## 正式包打包

APK、AAB 和 IPA 统一使用发布脚本。仓库根目录可以直接执行别名：

```bash
./package_release.sh
```

也可以在 `flutter_app/` 目录执行：

```bash
./tool/package_release.sh
```

无参数运行会进入交互菜单，由用户选择 APK、AAB、IPA、版本号、构建号和是否 dry-run。也可以按需直接传参只打单个平台或单类产物：

```bash
./tool/package_release.sh android
./tool/package_release.sh apk
./tool/package_release.sh aab
./tool/package_release.sh ipa --export-method ad-hoc
```

仓库根目录对应命令是 `./package_release.sh`，参数相同。

完整说明见 `../Doc/flutter-release-build.md`。

## iOS 模拟器构建安装

```bash
./tool/build_ios_simulator.sh
```

脚本会自动构建 Flutter iOS 模拟器包，安装到 iOS Simulator 并启动 App。默认优先使用已启动的模拟器；也可以指定目标设备：

```bash
IOS_SIMULATOR_NAME="iPhone 17" ./tool/build_ios_simulator.sh
```

脚本默认走增量构建，不清理 Flutter/Xcode 产物，也不刷新 Swift Package 缓存；只有依赖配置缺失或 `pubspec` 变更时才会执行 `flutter pub get`。日常推送模拟器直接运行上面的命令即可。

如需强制清理后重建：

```bash
CLEAN=1 ./tool/build_ios_simulator.sh
```

如遇到 Firebase 这类 Swift Package 版本解析失败，再显式刷新 Swift Package 缓存：

```bash
REFRESH_IOS_SPM=1 ./tool/build_ios_simulator.sh
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

- Android：运行 `./tool/build_android_llama.sh`，脚本会按 `llama_cpp_dart` 绑定对应的 `llama.cpp` 提交构建 CPU 和 Vulkan GPU 后端 `libmtmd.so`、`libllama.so`、`libggml*.so`，并复制 NDK 运行时 `libc++_shared.so`、`libomp.so` 到 `android/app/src/main/jniLibs/<abi>/`。
- iOS 模拟器：`flutter run -d ios` 和 `./tool/build_ios_simulator.sh` 会通过 Xcode 构建阶段从 `llama_cpp_dart` 的 pub cache 中读取当前模拟器架构的 `libllama.dylib`、`libggml*.dylib`、`libggml-metal.dylib` 和 `libmtmd.dylib`，再包装为 `Runner.app/Frameworks/*.framework`。如果需要使用自定义构建产物，可设置 `HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR=/absolute/path/to/dylibs`。
- iOS 真机：默认读取 `llama_cpp_dart` 的 `OS64` CPU 和 Metal 产物并包装为 framework；App Store/TestFlight 包不能直接嵌入非 Swift 的裸 `.dylib`，`./tool/package_release.sh ipa` 和 `./tool/upload_ios_archive.sh` 会在上传前拦截这类结构。
- 桌面或本机调试：可用 `--dart-define=HELP_SUPPORT_LLAMA_LIBRARY_PATH=/absolute/path/libllama.dylib` 指定动态库路径。

默认使用 `auto` 加载本地模型。Android 的 `auto` 默认使用 CPU，避免模拟器、云手机或厂商 Vulkan 驱动在 native 初始化阶段直接崩溃；如需在 Android 真机上验证 GPU，必须显式传入 `HELP_SUPPORT_LLAMA_BACKEND=gpu`，并通过系统 API、Vulkan 1.1 和模拟器检测后才会启用 GPU offload。iOS / macOS 的 `auto` 默认允许 Metal GPU offload。CPU 模式会强制 `nGpuLayers=0` 并关闭 KQV / op offload。如需显式指定模式，可传入：

```bash
flutter run -d <device id> \
  --dart-define=HELP_SUPPORT_LLAMA_BACKEND=gpu \
  --dart-define=HELP_SUPPORT_LLAMA_GPU_LAYERS=99

HELP_SUPPORT_LLAMA_BACKEND=gpu HELP_SUPPORT_LLAMA_GPU_LAYERS=99 ./tool/build_ios_simulator.sh
```

`HELP_SUPPORT_LLAMA_BACKEND` 支持 `cpu`、`gpu` 和 `auto`，默认值为 `auto`。`cpu` 强制 CPU；`gpu` 会强制 GPU 并在设备不支持时直接报错；`auto` 在 Android 上默认等同 CPU，在 iOS / macOS 支持 GPU 时使用 `HELP_SUPPORT_LLAMA_GPU_LAYERS`，未指定时默认 offload 99 层。Android GPU 后端使用 Vulkan，native 库默认按 `LLAMA_ANDROID_PLATFORM=android-28` 构建，设备系统和驱动必须支持 Android 9 / Vulkan 1.1；iOS GPU 后端使用 Metal。

Android 默认构建 `arm64-v8a`。如需额外构建 x86_64 模拟器库，可运行：

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
