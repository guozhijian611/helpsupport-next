# Flutter 正式包打包说明

本文档说明 `flutter_app/` 的 Android APK、Android App Bundle 和 iOS IPA 打包流程。打包脚本位于：

```bash
flutter_app/tool/package_release.sh
```

正式包使用 Flutter 非 Debug 构建，因此 API 基础地址会走 `ApiClient.packagedApiBaseUrl`：

```text
https://help.openb8.chat
```

## 快速打包

在 `flutter_app/` 目录执行：

```bash
./tool/package_release.sh
```

默认会依次输出：

| 目标 | 命令 | 产物位置 |
| --- | --- | --- |
| APK | `flutter build apk --release` | `flutter_app/build/app/outputs/flutter-apk/` |
| AAB | `flutter build appbundle --release` | `flutter_app/build/app/outputs/bundle/release/app-release.aab` |
| IPA | `flutter build ipa --release --export-method app-store` | `flutter_app/build/ios/ipa/` |

## 常用命令

只打 Android APK 和 AAB：

```bash
./tool/package_release.sh android
```

只打 APK：

```bash
./tool/package_release.sh apk
```

只打 AAB：

```bash
./tool/package_release.sh aab
```

只打 iOS IPA：

```bash
./tool/package_release.sh ipa
```

指定版本号和构建号：

```bash
./tool/package_release.sh --build-name 1.0.0 --build-number 2
```

iOS 内部分发包：

```bash
./tool/package_release.sh ipa --export-method ad-hoc
```

iOS 开发签名包：

```bash
./tool/package_release.sh ipa --export-method development
```

Android 按 ABI 拆分 APK：

```bash
./tool/package_release.sh apk --split-per-abi
```

强制清理后重新打包：

```bash
./tool/package_release.sh --clean
```

跳过 `flutter pub get`：

```bash
./tool/package_release.sh --no-pub-get
```

只打印将执行的命令，不实际构建：

```bash
./tool/package_release.sh android --dry-run
```

## Android 正式签名

当前仓库的 `android/app/build.gradle.kts` 中，Release 构建仍配置为 debug 签名：

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

这类 APK/AAB 可以用于本机验证构建流程，但不应作为正式渠道或应用商店发布包。正式发布前需要配置 Android release keystore，并把 `release` 构建类型切换为正式签名。

建议本地创建未提交的 `android/key.properties`：

```properties
storeFile=/absolute/path/to/release.jks
storePassword=你的 keystore 密码
keyAlias=你的 alias
keyPassword=你的 key 密码
```

然后在 `android/app/build.gradle.kts` 中读取该文件并配置 release signing。密钥文件、密码文件、证书私钥不得提交到 Git。

## Android 本地模型动态库

仓库已有 `android/app/src/main/jniLibs/arm64-v8a/` 动态库。需要重新构建本地模型 native runtime 时，再显式执行：

```bash
BUILD_ANDROID_LLAMA=1 ./tool/package_release.sh android
```

或：

```bash
./tool/package_release.sh apk --android-llama
```

该过程会拉取和编译 `llama.cpp`，耗时明显长于普通 Flutter 打包。

如需额外打 x86_64 模拟器动态库：

```bash
LLAMA_ANDROID_ABIS="arm64-v8a x86_64" BUILD_ANDROID_LLAMA=1 ./tool/package_release.sh apk
```

## iOS 签名和导出方式

当前 iOS 工程配置：

| 配置 | 当前值 |
| --- | --- |
| Bundle ID | `com.openb8.helpsupportApp` |
| Team ID | `33ZX95D3LJ` |
| 签名方式 | Automatic |

打 IPA 前需要确认本机 Xcode 已登录 Apple Developer 账号，并且 `com.openb8.helpsupportApp` 的证书、描述文件和相关能力可用。

常见导出方式：

| export-method | 用途 |
| --- | --- |
| `app-store` | TestFlight / App Store 上传 |
| `ad-hoc` | 指定设备内部分发 |
| `development` | 开发签名测试 |
| `enterprise` | 企业签名分发 |

脚本默认使用 `app-store`：

```bash
./tool/package_release.sh ipa
```

如需 ad-hoc：

```bash
./tool/package_release.sh ipa --export-method ad-hoc
```

## 版本号

默认版本来自 `flutter_app/pubspec.yaml`：

```yaml
version: 1.0.0+1
```

其中：

| 字段 | 含义 |
| --- | --- |
| `1.0.0` | `--build-name`，Android `versionName` / iOS `CFBundleShortVersionString` |
| `1` | `--build-number`，Android `versionCode` / iOS `CFBundleVersion` |

发布新包时必须递增 `--build-number`。例如：

```bash
./tool/package_release.sh all --build-name 1.0.0 --build-number 3
```

## 打包前检查

建议打包前至少确认：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
flutter test test/widget_test.dart
```

不要用 `flutter analyze` 替代运行或构建验证；本仓库的 Flutter 运行验证以 `flutter run`、`./tool/build_ios_simulator.sh` 或正式打包命令为准。

## 故障定位

Android 签名失败：

- 检查 `android/key.properties` 的路径和密码。
- 检查 `android/app/build.gradle.kts` 是否仍使用 debug signing。

iOS 导出失败：

- 打开 `ios/Runner.xcworkspace`，确认 Xcode 登录账号、Team、Bundle ID 和 Signing & Capabilities。
- 如果是 `ad-hoc`，确认目标设备 UDID 已加入描述文件。
- 如果是 `app-store`，确认证书和 App Store Connect 中的 Bundle ID 匹配。

API 地址不对：

- Debug 包使用 `http://10.0.0.6:8787`。
- APK/AAB/IPA 等非 Debug 包使用 `https://help.openb8.chat`。
