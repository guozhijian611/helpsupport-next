---
name: flutter-redscreen-debug
description: HelpSupport Flutter 红屏 / 断言 / 弹窗上下文排错技能。用于 `flutter_app/` 中诊断 `BuildContext`、`showDialog`、`showModalBottomSheet`、InheritedWidget、路由切换、热重启后状态不一致等导致的红屏、断言和交互异常，并给出最小修复与验证流程。
---

# Flutter 红屏排错技能

## 适用场景

- 用户给出 Flutter 红屏截图、断言文本、`framework.dart` 行号或 iOS/Android 运行时异常。
- 症状集中在“点一下编辑/弹窗/切换主题或语言/关闭页面就红屏”。
- 需要排查 `BuildContext`、`InheritedWidget`、`showDialog`、`showModalBottomSheet`、`Navigator`、`Overlay`、`mounted`、热重启后状态不一致等问题。

## 本仓库事实

- Flutter 客户端根目录：`flutter_app/`。
- 运行验证优先：
  - 真机：`cd flutter_app && flutter run -d <device id> --dart-define=HELP_SUPPORT_API_BASE_URL=...`
  - 模拟器完整链路：`cd flutter_app && ./tool/build_ios_simulator.sh`
- 不要用 `flutter analyze` 代替运行验证。
- 热重启后如果暴露代码、路由、资源、生成缓存或启动状态异常，直接停止当前会话并重新完整构建安装，不要加 fallback、兼容分支或旧入口绕过去。

## 处理顺序

1. 先执行 `git status --short`，确认工作区是否干净，避免覆盖用户改动。
2. 抄下完整红屏文本，至少保留：
   - 断言文件和行号
   - 触发动作
   - 当前页面路由或文件名
3. 在 `flutter_app/lib/` 精确搜索错误关键词、页面标题、按钮文案、交互入口。
4. 优先检查当前页面的：
   - `showDialog`
   - `showModalBottomSheet`
   - `showDatePicker`
   - `Navigator.of(context)`
   - `context.push/go/pop`
   - `Theme.of(context)`
   - `MediaQuery.of/context.sizeOf`
   - `Localizations` / `_t(context, ...)`
5. 任何 `await` 之后继续操作页面状态、路由或 notice，必须复查 `mounted` / `context.mounted`。
6. 修复时优先做最小改动，不扩散成全局“兼容逻辑”。

## 高频根因

### 1. Overlay builder 里误用外层 context

这是本仓库最常见的一类。典型写法：

```dart
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(_t(context, '标题', 'Title')),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text(_t(context, '取消', 'Cancel')),
      ),
    ],
  ),
);
```

风险：

- dialog/sheet 已经在 overlay route 里，但内容仍然依赖外层页面的 inherited context。
- 一旦页面被重建、切换语言/主题、刷新 session、关闭当前 route，容易触发 inherited 依赖断言。

修复原则：

- `builder` 内只使用局部 `dialogContext` / `sheetContext` 读取 `Theme`、`MediaQuery`、`Localizations`、palette、`Navigator`。
- 如果文案是固定值，先在打开弹窗前算成字符串，再传进 builder。

### 2. await 之后页面已销毁，还继续 setState / showNotice / push

排查：

- 搜 `await` 后面的 `setState`、`context.showCenteredNotice(...)`、`context.push/go/pop(...)`。
- 每个异步边界后补 `if (!mounted) return;` 或 `if (!context.mounted) return;`。

### 3. 使用已失效 context 查 ancestor

典型症状：

- `Looking up a deactivated widget's ancestor is unsafe`
- 在 `pop()` 后继续 `Theme.of(context)`、`Navigator.of(context)`、`ScaffoldMessenger.of(context)`。

修复原则：

- `pop` 前完成所有 ancestor 查询。
- 或使用仍然有效的 overlay/local context。

### 4. 热重启后状态/控制器与树结构不一致

排查：

- 控制器、focus node、global key 是否在错误位置反复创建。
- 路由或页面结构是否在热重启后发生 reparent。

处理：

- 停止当前 `flutter run`，重新完整构建安装。

## `_dependents.isEmpty` 专项判断

当前 Flutter 3.44.1 中，这个断言来自 `InheritedElement.debugDeactivated()`，说明某个 inherited element 进入 deactivated 时，仍残留 dependents。

先读 `references/assert-signatures.md` 的 `_dependents.isEmpty` 条目，再按这个顺序查：

1. 当前页面所有 overlay builder 是否使用了外层 context。
2. 是否在 dialog / bottom sheet 打开期间刷新了 session、主题、语言或 route。
3. 是否有 `GlobalKey`、controller、focus node 在 build 中重建或跨 route 复用。
4. 是否是热重启后状态污染；若是，停止会话后重跑完整构建。

已知本仓库实例：`flutter_app/lib/features/me/presentation/settings_screen.dart` 的资料编辑、设备弹窗、退出确认等入口，出现过 builder 内依赖外层 context 的系统性写法。

## 验证要求

- 改完 Dart 文件先执行：

```bash
dart format flutter_app/lib/path/to/file.dart
git diff --check
```

- 运行验证必须二选一：

```bash
cd flutter_app
flutter run -d <device id> --dart-define=HELP_SUPPORT_API_BASE_URL=...
```

或：

```bash
cd flutter_app
./tool/build_ios_simulator.sh
```

- 最终回复要写清：
  - 触发原因
  - 改动文件
  - 实际运行验证方式
  - 如果没能复现，说明是“代码级高风险点修复”，不是“运行态完全复现确认”

## 何时读参考

- 看到具体断言文本、但不确定优先级时，读 `references/assert-signatures.md`。
- 需要把错误映射到本仓库常见修复动作时，也读该文件。
