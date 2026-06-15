# Android MLC 运行时准备

这个目录用于承接 `mlc_llm package` 的 Android 配置和运行时同步流程。

补充说明：

- 本目录和其中脚本只覆盖 Android 运行时。
- iOS 当前仅完成 `UTS` 桥接与诊断语义，不在本目录的运行时打包范围内。

## 1. 生成打包配置

在 `helpsupport-frontend` 目录执行：

```bash
pnpm generate:mlc-config
```

会生成：

- `mlc-android/mlc-package-config.json`
- `uni_modules/local-llm-bridge/utssdk/model-registry.uts`

## 2. 使用 MLC 打包 Android 运行时

在安装了 `mlc_llm` 的环境中，基于上一步生成的配置执行：

```bash
pnpm package:mlc-android-runtime
```

执行前请先确认已经安装 Android NDK。脚本会优先按下面顺序自动解析 `TVM_NDK_CC`：

- 环境变量 `TVM_NDK_CC`
- 环境变量 `ANDROID_NDK_HOME` / `NDK_HOME`
- `ANDROID_SDK_ROOT` / `ANDROID_HOME` / `~/Library/Android/sdk` 下的 `ndk/<version>/toolchains/llvm/prebuilt/*/bin/aarch64-linux-android24-clang`

如果命令一开始就提示“未检测到可用的 Android NDK clang”，说明当前机器还没有可用的 NDK。先在 Android Studio 的 SDK Manager 中安装 `NDK (Side by side)`，或手动设置：

```bash
export TVM_NDK_CC="<你的 NDK>/toolchains/llvm/prebuilt/<host>/bin/aarch64-linux-android24-clang"
```

如果你使用项目里的本地源码目录 `.mlc-llm-source`，还需要确认已经把关键子模块拉完整，至少要有：

- `3rdparty/tvm`
- `3rdparty/tokenizers-cpp`
- `3rdparty/xgrammar`

缺失时可以在 `.mlc-llm-source` 目录执行：

```bash
git submodule update --init --recursive
```

`mlc4j` 绑定构建还依赖 `rustup/cargo/rustc`、`cmake` 和 `java`。当前包装脚本会自动把 Homebrew `rustup` 和 `~/.cargo/bin` 加入 PATH。

如果你希望直接调用底层命令，也可以执行：

```bash
pnpm mlc-llm -- package --package-config ./mlc-android/mlc-package-config.json
```

完成后应拿到 `dist/lib/mlc4j` 目录，目录里至少需要包含：

- `src/main/assets/mlc-app-config.json`
- `src/main/java/...`
- `output/*.jar`
- `output/<abi>/*.so`

## 3. 同步到 UTS Android 插件

```bash
pnpm prepare:mlc-android-runtime -- --source <dist/lib/mlc4j目录>
```

默认会同步到：

`uni_modules/local-llm-bridge/utssdk/app-android`

同步内容包括：

- `assets/`
- `libs/`
- `ai/mlc/...` Java 源码
- `config.json` 的 ABI 配置

脚本会维护 `.mlc-runtime-manifest.json`，重复执行时会先清理上一轮生成文件，再写入本轮运行时资产。

如需清空已经同步到 UTS 插件目录的运行时资产，可执行：

```bash
pnpm clean:mlc-android-runtime
```

如果只想先看将删除哪些文件，可执行：

```bash
pnpm clean:mlc-android-runtime -- --dry-run
```

## 4. 运行时自检

在上自定义基座或真机前，建议先执行：

```bash
pnpm check:mlc-android-runtime
```

该命令会检查：

- `assets/mlc-app-config.json` 是否存在且模型配置完整
- `.mlc-runtime-manifest.json` 是否存在
- `libs/*.jar` / `libs/<abi>/*.so` 是否齐全
- `config.json` 中 `abis` 是否覆盖当前同步到插件目录的 ABI

如果命令失败，优先重新执行：

```bash
pnpm prepare:mlc-android-runtime -- --source <dist/lib/mlc4j目录>
```

如果怀疑插件目录里混入了旧版本 `jar/so/assets`，建议先执行：

```bash
pnpm clean:mlc-android-runtime
pnpm prepare:mlc-android-runtime -- --source <dist/lib/mlc4j目录>
```

## 5. App 联调前体检

如果希望一次性检查 `mlc_llm`、模型打包配置、运行时资产和当前前端构建链，可执行：

```bash
pnpm check:app-local-ai
```

从当前版本开始，这条体检也会检查 Android NDK / `TVM_NDK_CC`，避免 `mlc_llm package` 在 4 个模型都处理完后才因为 NDK 缺失而失败。
同时也会检查：

- 本地 `.mlc-llm-source` 子模块是否完整
- `rustup/cargo/rustc`
- `cmake`
- `java`

如只想检查环境和运行时资产，跳过构建步骤，可执行：

```bash
pnpm check:app-local-ai -- --skip-build
```

如果已经连接 Android 真机，并希望快速检查设备 ABI、已安装包和常见本地模型目录，可执行：

```bash
pnpm check:app-local-ai-adb -- --device <serial>
```

默认会先检查 `adb`、在线设备和 ABI 是否与当前 `arm64-v8a` 运行时匹配，并尝试按 `UniApp AppID` 从设备侧 `Android/data/*/apps/<appid>` 目录自动反查候选包名。

如果你已经知道自定义基座包名，也可以显式传入：

```bash
pnpm check:app-local-ai-adb -- --device <serial> --package <包名>
```

如需同时抓取原生桥接和运行时日志，可执行：

```bash
pnpm logcat:app-local-ai -- --device <serial> --clear
```

如需直接查看设备侧 `_doc/help-local-llm` 目录里每个模型的完整度、缺失文件和 `marker` 状态，可执行：

```bash
pnpm check:app-local-ai-device-models -- --device <serial>
```

如果你已经知道自定义基座包名，也可以显式传入：

```bash
pnpm check:app-local-ai-device-models -- --device <serial> --package <包名>
```

如果你希望把预检、目录自检和 `logcat -d` 一次性收成一份 Markdown 报告，可执行：

```bash
pnpm collect:app-local-ai-device-report -- --device <serial>
```

默认会写入：

- `mlc-android/reports/app-local-ai-device-report-时间戳.md`
- 同名 `.json` 摘要文件

如果你希望从这份采集结果里直接生成“多设备联调汇总表”的建议行，可执行：

```bash
pnpm summarize:app-local-ai-device-report -- --latest
```

如果你希望直接生成一份“真机联调记录模板”的预填版，可执行：

```bash
pnpm prefill:app-local-ai-device-record -- --latest
```

如果你希望把“采集报告 + 预填记录 + 汇总建议行 + 索引”一次性产出，可执行：

```bash
pnpm finalize:app-local-ai-device-report -- --device <serial>
```

如果你还希望在总装结束后顺手同步 `多设备联调汇总表.md`，可执行：

```bash
pnpm finalize:app-local-ai-device-report -- --device <serial> --sync-table
```

如果你已经在 App 页面点了“复制联调信息”，并把文本保存成文件，还可以直接在总装时一并并入摘要：

```bash
pnpm finalize:app-local-ai-device-report -- --device <serial> --diagnostics-input <联调信息文本路径> --sync-table
```

如果你希望在总装结束后，顺手把 `APP-LOCAL-01` 到 `APP-LOCAL-04` 自动回填到项目根目录专项测试材料，可执行：

```bash
pnpm finalize:app-local-ai-device-report -- --device <serial> --diagnostics-input <联调信息文本路径> --sync-table --sync-root-docs
```

如果只想把联调信息文本合并进已有摘要，可执行：

```bash
pnpm merge:app-local-ai-runtime-diagnostics -- --json <摘要路径> --input <联调信息文本路径>
```

如果你希望把最新摘要直接同步进 `多设备联调汇总表.md`，可执行：

```bash
pnpm sync:app-local-ai-summary-table -- --latest
```

如果你已经把页面“复制联调信息”合并进摘要，还希望把 `APP-LOCAL-01` 到 `APP-LOCAL-04`、`AI本地能力首轮验证记录.md` 和 `功能测试清单.md` 一并回填到项目根目录专项测试材料，可执行：

```bash
pnpm sync:app-local-ai-root-docs -- --json <摘要路径>
```

这条命令默认还会在摘要同目录生成一份 `.root-docs-sync.md` 回填报告，方便后续留档。

默认只看这些标签：

- `HelpLocalLLM`
- `AndroidRuntime`
- `System.err`

## 6. Android 真机联调

真机联调步骤、状态解释和排查清单见：

- `mlc-android/真机联调清单.md`
- `mlc-android/真机联调记录模板.md`
- `mlc-android/多设备联调汇总表.md`

iOS 侧当前不适用本目录的 `mlc4j` 打包链路；如需继续推进，应单独接入 `MLC iOS SDK` 或等效原生运行时。
