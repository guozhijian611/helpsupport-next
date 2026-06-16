# Flutter 断言签名索引

## `_dependents.isEmpty`

含义：

- Flutter debug 模式下，某个 `InheritedElement` 在 deactivated 时仍然挂着 dependents。
- Flutter 3.44.1 对应 `framework.dart` 的 `InheritedElement.debugDeactivated()`。

在本仓库优先怀疑：

1. `showDialog` / `showModalBottomSheet` / `showDatePicker` 的 `builder` 内继续使用外层页面 `context`。
2. 打开 overlay 后刷新 session、切换语言/主题、路由跳转，导致外层 inherited 树重建。
3. 热重启后页面状态、controller、focus tree 与当前 widget tree 不一致。

搜索命令：

```bash
rg -n "showDialog|showModalBottomSheet|showDatePicker|Theme\\.of\\(context\\)|MediaQuery|_t\\(context|Navigator\\.of\\(context\\)" flutter_app/lib/features -S
```

修复优先级：

1. 先把 builder 内 inherited 读取切到 `dialogContext` / `sheetContext`。
2. 再补全 `mounted` / `context.mounted`。
3. 若只发生在热重启后，直接重启运行会话再验证。

## `setState() called after dispose()`

含义：

- 异步回调、timer、stream、future 完成时，页面已销毁但仍在更新状态。

修复：

- 每个 `await` / 回调后加 `if (!mounted) return;`。
- `dispose()` 里及时取消 timer、listener、stream subscription、controller。

## `Looking up a deactivated widget's ancestor is unsafe`

含义：

- 在已失效 context 上调用了 ancestor 查询。

常见触发：

- `Navigator.pop` 后继续 `Theme.of(context)` / `ScaffoldMessenger.of(context)` / `showDialog(context: context)`。

修复：

- 先读完 ancestor，再 `pop`。
- 或使用仍然有效的局部 overlay context。

## 热重启后才出现、冷启动消失

优先判断为：

- 状态树污染
- controller / key / focus node 生命周期不正确
- 生成缓存或资源未同步

处理：

- 停止 `flutter run`
- 重新运行真机联调或 `./tool/build_ios_simulator.sh`
- 不要为了绕过异常新增 fallback 入口或兼容分支
