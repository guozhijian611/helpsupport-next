# HelpSupport TestFlight 交接文档

更新时间：2026-07-02 23:10 左右

## 当前结论

HelpSupport iOS 包已重新构建并上传到 App Store Connect / TestFlight。

| 项目 | 当前值 |
| --- | --- |
| App 名称 | `HelpSupport` |
| App Apple ID | `6786692861` |
| Bundle ID | `com.openb8.helpsupportApp` |
| Team ID | `33ZX95D3LJ` |
| 已上传版本 | `1.0.2 (4)` |
| 上传方式 | Xcode `xcodebuild -exportArchive` 直传 App Store Connect |
| 上传结果 | `Upload succeeded` / `EXPORT SUCCEEDED` |

上传后仍需要等待 App Store Connect 后台处理。若处理通过，TestFlight 页面会出现 `1.0.2 (4)`；若后台再次拒绝，会收到 Apple Developer 邮件。

## 本次处理过的问题

### 1. App 图标 alpha 通道

Apple 曾拒绝：

```text
ITMS-90426 / Invalid large app icon
The large app icon ... can't be transparent or contain an alpha channel.
```

已处理：iOS AppIcon 改为无透明通道、满版图标。

相关提交：

```text
ccc0b0ee fix: 移除 iOS 图标透明通道
```

### 2. SwiftSupport 相关拒绝（已定位真正根因）

Apple 曾拒绝：

```text
ITMS-90426: Invalid Swift Support - The SwiftSupport folder is missing.
ITMS-90429: Swift dylibs aren't at the expected location.
ITMS-90433: Swift dylib doesn't have the correct code signature.
```

真正根因（2026-07-03 复查确认）：

- `Runner.app/Frameworks/` 里的多个 Flutter / CocoaPods 嵌入框架确实链接了 `/usr/lib/swift/libswift*.dylib`。
- Xcode 26 的 `swift-stdlib-tool --print` 对这些框架返回空，导致标准 archive/export 流程没有自动把 Swift 运行时拷进 `Payload/Runner.app/Frameworks/`，也没有生成有效的 `SwiftSupport/iphoneos/`。
- App Store Connect 后台会按实际依赖校验 SwiftSupport，所以即使 `flutter build ipa` 本身成功，仍会异步退回 `ITMS-90426`。
- `ITMS-90429` 和 `ITMS-90433` 是手工拆 IPA、移动或重签 Swift dylib 后造成的结构/签名不一致，不应继续用手工改 IPA 的方式修。
- 邮件里的 `Rebuild using the current public (GM) version of Xcode` 是 Apple 的模板话术；本机 Xcode 26.6 (17F113) 是正式版，与本次退回无关。

已废弃的错误做法（不要再用）：

- 手工拆 IPA、移动 / 补 `SwiftSupport`、重签 Swift dylib：会继续触发 90429 / 90433。
- 只改 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`，但不检查最终 IPA 结构：构建可能成功，App Store Connect 后台仍会退回。

正确修法（本次已落地）：

- `Podfile` 不再把 CocoaPods 生成的 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES` patch 成 `NO`。
- `Runner.xcodeproj/project.pbxproj` 显式保留 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES` 和 `EMBEDDED_CONTENT_CONTAINS_SWIFT = YES`。
- 新增 `ios/scripts/embed_swift_stdlibs.sh` 构建阶段：用 `otool -L` 解析实际 Swift dylib 依赖，从 Xcode toolchain 拷贝 app 内签名副本，并在 archive/IPA 顶层生成未重签的 `SwiftSupport/iphoneos` 副本。
- 修复成功判据：重打包后解包 IPA，`Payload/Runner.app/Frameworks/libswift*.dylib` 和 `SwiftSupport/iphoneos/libswift*.dylib` 都存在，且数量一致。

签名相关（此前已处理，仍然有效）：

- 安装了 `Apple Distribution: zhijian guo (33ZX95D3LJ)`。
- 打包脚本增加分发证书检查。
- 使用 Xcode archive 直传流程上传，不再拖本地 IPA 到 Transporter。

相关提交：

```text
8c5befb3 fix: 校验 iOS 分发签名
cf5b15bd fix: 修复 iOS Swift 支持包结构   ← 方向错误，已被本次修复推翻
```

### 3. Xcode iOS 26.5 平台组件缺失

打包时曾报错：

```text
No simulator runtime version from ["23E254a"] available to use with iphonesimulator SDK version 23F81a
iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.
```

排查结论：

- Xcode 是 `26.6 (17F113)`。
- `iphoneos26.5` SDK build 是 `23F81a`。
- 本机一开始只注册了 iOS 26.4 runtime，导致 Xcode asset catalog 编译和归档失败。

已处理：

```bash
xcodebuild -runFirstLaunch -checkForNewerComponents
xcodebuild -downloadAllPlatforms
```

`downloadAllPlatforms` 开始下载 watchOS 后已中断，只保留需要的 iOS 26.5 runtime。当前检查结果应包含：

```text
iOS 26.5 (26.5 - 23F77) - com.apple.CoreSimulator.SimRuntime.iOS-26-5
```

以后只发布 iPhone / TestFlight 时，只需要 iOS 平台组件；不需要下载 watchOS、tvOS、visionOS。

## 本次实际执行的关键命令

### 检查签名证书

```bash
security find-identity -v -p codesigning
```

当前应能看到：

```text
Apple Development: zhijian guo (A34W945L6R)
Apple Distribution: zhijian guo (33ZX95D3LJ)
Developer ID Application: zhijian guo (33ZX95D3LJ)
```

### 清理 Xcode / Flutter 缓存

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* build/ios
flutter clean
```

### 重新打 TestFlight 包

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
./tool/package_release.sh ipa --export-method app-store --build-name 1.0.2 --build-number 10
```

本次产物：

```text
build/ios/archive/Runner.xcarchive
build/ios/ipa/helpsupport_app.ipa
```

### 上传到 App Store Connect

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
./tool/upload_ios_archive.sh
```

本次上传结果：

```text
Progress 100%: Uploaded package is processing.
Progress 100%: Upload succeeded.
Uploaded Runner
** EXPORT SUCCEEDED **
```

## 当前已知警告

上传成功后 Xcode 报了 dSYM 上传警告：

```text
exportArchive Upload Symbols Failed
The archive did not include a dSYM for PDFium.framework
The archive did not include a dSYM for libggml*.dylib / libllama.dylib / libmtmd.dylib
```

这些是符号文件缺失警告，通常不阻止 TestFlight 处理，只会影响崩溃日志符号化。若后续需要更完整的线上崩溃解析，再补 PDFium 和 llama/ggml 相关动态库的 dSYM。

## 后续继续发布时的流程

1. App Store Connect 里确认 `1.0.2 (10)` 是否处理完成。
2. 如果处理通过，在 TestFlight 里添加内部测试员或提交外部测试审核。
3. 下次再上传同版本时必须递增 build number，例如 `1.0.2 (11)`。
4. 不要复用已上传或被拒的 build number。
5. 遇到 SwiftSupport 相关错误时，不要手工改 IPA；优先用 Xcode Organizer 或 `./tool/upload_ios_archive.sh` 从 archive 重新上传。

推荐命令：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
./tool/package_release.sh ipa --export-method app-store --build-name 1.0.2 --build-number 5
./tool/upload_ios_archive.sh
```

## 重要注意事项

- `TestFlight` 使用 `app-store` 分发签名，不是 `development`。
- 本机必须有 `Apple Distribution` 证书。
- Xcode 必须安装当前 SDK 对应的 iOS platform/runtime。
- 如果 Xcode 又提示 `iOS xx.x is not installed`，优先打开 `Xcode > Settings > Components` 安装 iOS 平台组件。
- 不要执行 `xcodebuild -downloadAllPlatforms` 下载全部平台，除非确实需要 watchOS / tvOS / visionOS。
- 本次上传是“传输成功”，最终是否可测试以 App Store Connect 后台处理结果为准。
