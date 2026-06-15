# iOS 本地推理运行时

本目录用于生成和同步 `MLC iOS` 运行时资产，目标是把以下内容落到 `UTS app-ios` 插件目录：

- `Resources/bundle/mlc-app-config.json`
- `Libs/*.a`
- `Frameworks/MLCSwift.xcframework`
- `vendor/MLCSwift/*`

## 推荐流程

1. 生成模型打包配置

```bash
cd /Users/allen/Downloads/project/项目/helpsupport/helpsupport-frontend
pnpm generate:mlc-config
```

2. 生成 iOS `dist` 产物

```bash
pnpm package:mlc-ios-runtime
```

默认输出目录是 [dist-ios](/Users/allen/Downloads/project/项目/helpsupport/helpsupport-frontend/dist-ios)，不会覆盖 Android 的 `dist/lib/mlc4j`。

3. 同步到 `UTS` 插件目录，并自动构建 `MLCSwift.xcframework`

```bash
pnpm prepare:mlc-ios-runtime -- --source ./dist-ios
```

4. 做运行时检查

```bash
pnpm check:mlc-ios-runtime
```

## 前置条件

- 本机已安装完整 `Xcode`
- `xcrun -sdk iphoneos --find metallib` 可返回有效路径
- `mlc_llm` 已可用
- 仓库根目录存在完整的 `.mlc-llm-source`

如果当前 `xcode-select` 仍然指向 `CommandLineTools`，脚本会优先自动使用：

- `/Applications/Xcode.app/Contents/Developer`
- `DEVELOPER_DIR` 环境变量

如果提示缺少 `Metal Toolchain`，先执行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain
```

## 关键输出目录

- [mlc-package-config.json](/Users/allen/Downloads/project/项目/helpsupport/helpsupport-frontend/mlc-ios/mlc-package-config.json)
- [app-ios](/Users/allen/Downloads/project/项目/helpsupport/helpsupport-frontend/uni_modules/local-llm-bridge/utssdk/app-ios)

同步完成后，`app-ios` 下应至少包含：

- `Resources/bundle/mlc-app-config.json`
- `Resources/mlc-app-config.json`
- `Libs/*.a`
- `Frameworks/MLCSwift.xcframework`
- `vendor/MLCSwift/Package.swift`
- `.mlc-ios-runtime-manifest.json`
