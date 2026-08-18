# HelpSupport Apple 登录配置指南

## 1. 适用范围

本文说明 HelpSupport 当前原生 iOS“通过 Apple 登录”实现。Flutter 调用系统 Apple 授权面板获取 `identityToken`，服务端验证 Apple JWT 后创建或绑定会员。

```text
iOS Sign in with Apple
  -> Apple identityToken
  -> POST /app/help/auth/apple
  -> HelpAuthService 校验 iss/aud/sub
  -> 创建或绑定 sa_member_platform_rel
  -> 返回 HelpSupport access_token / refresh_token
```

当前没有实现 Web 或 Android 的 Apple Web OAuth 回调，也不需要服务端用 authorization code 交换 Token。因此不要为了填满后台字段额外创建 Services ID 或上传 Sign in with Apple 私钥。

## 2. 当前项目标识

| 项目 | 当前值 | 用途 |
| --- | --- | --- |
| Apple Developer Team ID | `33ZX95D3LJ` | 签名团队 |
| iOS Bundle ID / App ID | `com.openb8.helpsupportApp` | Runner、Apple App ID 与 Token `aud` |
| Service ID | 留空 | 当前未实现 Web/Android 回调 |
| Sign in with Apple Key ID | 留空 | 当前不调用 Apple Token 交换接口 |
| 回调策略 | `id_token` | 原生 identityToken 直连 |

## 3. Apple Developer 配置

Apple 官方要求先在 App ID 上启用 Sign in with Apple，也可由 Xcode添加对应 capability：[About Sign in with Apple](https://developer.apple.com/help/account/capabilities/about-sign-in-with-apple/)。

### 3.1 选择显式 App ID

1. 打开 [Certificates, Identifiers & Profiles / Identifiers](https://developer.apple.com/account/resources/identifiers/list)。
2. 确认团队是 `33ZX95D3LJ`。
3. 找到显式 App ID `com.openb8.helpsupportApp`。
4. 不要选择通配 App ID，也不要选择名称相似但 Bundle ID 不同的记录。

### 3.2 启用 Sign in with Apple

1. 编辑 App ID。
2. 勾选“Sign In with Apple”。
3. 当前独立 App 选择“Enable as a primary App ID”。
4. 保存；出现确认弹窗时再次确认。
5. 重新进入 App ID，确认能力仍为启用状态。

Apple 的能力配置说明指出，修改 App ID capability 会影响相关 provisioning profile，需要重新生成或刷新描述文件：[Enable app capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/)。当前 Runner 使用 Automatic Signing，完整真机构建时由 Xcode 刷新；手动签名发布则需重新生成描述文件。

### 3.3 什么时候使用分组

只有同一产品存在多个 Apple 平台 App 或网站，并希望共享 Apple 用户关系时，才评估将相关 App ID/Services ID 与主 App ID 分组。错误分组或解除分组可能改变用户标识迁移要求，不应作为普通故障排查手段。

官方参考：[Group apps for Sign in with Apple](https://developer.apple.com/help/account/capabilities/group-apps-for-sign-in-with-apple/)。

## 4. Xcode 与 Flutter 配置

Runner 目标必须同时有 capability 与 entitlement：

| 文件 | 要求 |
| --- | --- |
| [`Runner.entitlements`](../flutter_app/ios/Runner/Runner.entitlements) | `com.apple.developer.applesignin` 数组包含 `Default` |
| [`project.pbxproj`](../flutter_app/ios/Runner.xcodeproj/project.pbxproj) | Runner SystemCapabilities 启用 Sign in with Apple |
| Runner Debug/Release/Profile | `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` |
| Runner 签名 | Team `33ZX95D3LJ`，Bundle ID `com.openb8.helpsupportApp` |

从 Xcode 操作时：

1. 打开 `flutter_app/ios/Runner.xcworkspace`。
2. 选择 Runner Target / Signing & Capabilities。
3. 点击 `+ Capability`，添加 Sign in with Apple。
4. 检查 Team、Bundle Identifier 和 Automatically manage signing。

Flutter 登录实现位于 [`auth_repository.dart`](../flutter_app/lib/features/auth/data/auth_repository.dart)，请求 `email` 与 `fullName` scope，并把 Apple `identityToken` 提交给服务端。

Apple 通常只在用户首次授权时返回姓名和邮箱。服务端与客户端必须依赖稳定的 Apple `sub` 绑定用户，不能把后续没有姓名或邮箱当成登录失败。

## 5. HelpSupport 后台配置

进入“运营配置 / 登录推送配置 / Apple 登录”：

| 字段 | 当前填写方式 |
| --- | --- |
| Team ID | `33ZX95D3LJ` |
| Bundle ID | `com.openb8.helpsupportApp` |
| Service ID | 留空 |
| Key ID | 留空 |
| Private Key | 留空 |
| 启用状态 | 启用 |
| 回调策略 | `id_token` / ID Token 直连 |
| 绑定策略 | `verified_email_or_create` / 已验证邮箱优先绑定，否则新建账号 |

服务端允许 Apple Token 的 `aud` 命中 Bundle ID 或 Service ID。当前原生流程只填写 Bundle ID，避免错误 Service ID 扩大可接受受众。

保存后请求公开配置：

```bash
curl -fsS https://help.openb8.org/app/help/common/app-config \
  | jq '.data.oauth.apple'
```

期望：

- `enabled=true`
- `team_id=33ZX95D3LJ`
- `bundle_id=com.openb8.helpsupportApp`
- `service_id`、`key_id` 为空
- `callback_strategy=id_token`

公开接口不得返回 Private Key。

## 6. 服务端验证逻辑

[`HelpAuthService.php`](../server/plugin/help/app/service/HelpAuthService.php) 会执行：

1. 检查 Apple 登录启用状态与回调策略。
2. 从 Apple JWKS 获取公钥并验证 JWT 签名。
3. 要求 `iss=https://appleid.apple.com`。
4. 要求 `aud` 命中后台 Bundle ID/Service ID。
5. 要求 `sub` 非空。
6. 按 Apple 平台与 `sub` 查找或创建会员关系。
7. 仅在 Apple 声明邮箱已验证时，按绑定策略同步邮箱。

接口入口为 `POST /app/help/auth/apple`，请求字段至少包含 `identity_token`，首次授权可同时提交 `full_name`。

## 7. 真机验收

Apple 登录必须优先使用真实 iPhone 验证：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
flutter devices
flutter run -d <iPhone-device-id>
```

验收步骤：

1. 确认 iPhone 已登录 Apple Account，账号状态正常；Apple 通常要求双重认证。
2. 停止旧调试会话并重新完整构建安装。
3. 在登录页点击“使用 Apple 账号登录”。
4. 确认系统 Apple 授权面板出现，而不是应用自绘账号密码页面。
5. 首次授权分别测试共享邮箱和“隐藏我的邮箱”。
6. 确认 `POST /app/help/auth/apple` 返回成功，App 进入登录状态。
7. 退出后再次使用同一 Apple Account 登录，必须复用既有会员。
8. 在后台或数据库确认 Apple 平台关系存在。

只读数据库核对：

```sql
SELECT id, platform_name, platform_code, status
FROM sa_member_platform
WHERE platform_code = 'APPLE' AND delete_time IS NULL;

SELECT rel.member_id, rel.platform_id, rel.platform_openid, rel.create_time
FROM sa_member_platform_rel rel
JOIN sa_member_platform p ON p.id = rel.platform_id
WHERE p.platform_code = 'APPLE'
  AND rel.delete_time IS NULL
ORDER BY rel.id DESC
LIMIT 10;
```

Apple `platform_openid/sub` 与邮箱属于用户身份数据，输出或截图应脱敏。

## 8. Services ID 与私钥扩展边界

以下场景才需要新增 Services ID、Domains and Subdomains、Return URLs、Key ID 和 Sign in with Apple `.p8` 私钥：

- 网页端使用 Apple 登录。
- Android 通过浏览器完成 Apple 授权。
- 服务端接收 authorization code 并调用 Apple Token 端点。

这是一条新的 OAuth 回调链路，至少需要：

- 明确回调 URL 与域名验证。
- 服务端生成 client secret JWT。
- 私钥通过服务器安全文件或密钥管理系统注入。
- state/nonce、重放保护与回调错误处理。
- Web/Android 独立验收。

不得把该扩展流程与当前 iOS 原生 ID Token 直连混用。

## 9. 常见问题

### 当前平台不支持 Apple 登录

先确认是真实 iOS 设备、系统版本与 Apple Account 状态。当前未实现 Android/Web Apple 回调。

### Apple 登录未启用

检查后台启用状态和公开配置，确认修改的是当前线上环境。

### Apple identityToken 受众不匹配

对比 Runner 实际 Bundle ID、Apple Developer App ID 和后台 Bundle ID，三者必须完全一致。

### 真机签名或安装失败

检查 entitlement、Team、Automatic Signing，以及 provisioning profile 是否包含 Sign in with Apple 能力。

### 后续登录没有姓名或邮箱

这通常是 Apple 的正常行为。检查第一次授权时是否已保存用户资料，并按 `sub` 查找既有会员。

### 想重新测试首次授权

在 Apple Account 的“使用 Apple 登录的 App”中撤销该 App 授权后再测试。该操作会影响当前测试账号关系，执行前先确认不会误操作生产账号。

## 10. 变更与回滚

- 不要直接删除、转移或错误分组生产 App ID。
- 修改 capability 前记录当前描述文件和发布版本。
- Bundle ID 不应作为普通配置项随意替换。
- 如果未来创建 Apple 私钥，`.p8` 只能安全保存，不进入 Git、数据库、日志或工单。

后台“操作说明”中的对应文章由迁移 [`20260819043643_seed_admin_apple_login_manual.php`](../Database/migrations/20260819043643_seed_admin_apple_login_manual.php) 初始化。
