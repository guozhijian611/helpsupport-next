# HelpSupport Google 登录配置指南

## 1. 适用范围

本文面向 HelpSupport 运维与开发人员，说明当前 Flutter iOS/Android 客户端的 Google ID Token 登录链路。当前实现不是 Web OAuth 回调：客户端完成 Google 授权后取得 ID Token，再由 HelpSupport 服务端验证 Google 签名、签发方和受众并签发本站登录 Token。

链路如下：

```text
Flutter Google Sign-In
  -> Google ID Token
  -> POST /app/help/auth/google
  -> HelpAuthService 校验 iss/aud/sub/email_verified
  -> 创建或绑定 sa_member_platform_rel
  -> 返回 HelpSupport access_token / refresh_token
```

## 2. 当前项目标识

| 项目 | 当前值 | 用途 |
| --- | --- | --- |
| Google Cloud 项目 | `helpsupport-499505` | OAuth 客户端所属项目 |
| iOS Bundle ID | `com.openb8.helpsupportApp` | iOS OAuth 客户端与 Runner |
| Android 包名 | `com.openb8.helpsupport_app` | Android OAuth 客户端 |
| Web Client ID | `1020489387914-avjt5l5js2s41up03rertberrc0bg41e.apps.googleusercontent.com` | Flutter `serverClientId` 与服务端 `aud` |
| iOS Client ID | `1020489387914-boc2emhbapt84i7gm5165c31do7mj95r.apps.googleusercontent.com` | iOS 客户端身份 |
| Android Client ID | `1020489387914-v98ukilrc5k34seu1c1660qgaqe2cduj.apps.googleusercontent.com` | Android 包名与签名身份 |

OAuth Client ID 是客户端标识，可以出现在 App 配置中；Client Secret、Cookie、管理员 Token 不得写入本文、Git 或后台配置。

## 3. Google Cloud 配置

### 3.1 选择正确项目

打开 [Google Auth Platform / 客户端](https://console.cloud.google.com/auth/clients?project=helpsupport-499505)，先确认项目为 `helpsupport-499505`。不要在名称相似的其他项目创建客户端。

### 3.2 创建 Web 客户端

1. 点击“创建客户端”。
2. 应用类型选择“Web 应用”。
3. 建议命名为 `HelpSupport Flutter Server`。
4. 当前移动端 ID Token 直连不需要 JavaScript 来源或重定向 URI。
5. 保存 Client ID；它必须同时写入 Flutter `serverClientId` 和后台 Web Client ID。

Web 客户端在当前链路中代表服务端受众，不表示项目已经实现网页端登录。

### 3.3 创建 iOS 客户端

1. 应用类型选择 iOS。
2. Bundle ID 填 `com.openb8.helpsupportApp`。
3. App Store ID 尚未发布时可以留空。
4. 保存并下载/记录 iOS Client ID。

iOS 客户端还需要 URL Scheme。当前 [`Info.plist`](../flutter_app/ios/Runner/Info.plist) 中应同时存在：

- `GIDClientID`：iOS Client ID。
- `GIDServerClientID`：Web Client ID。
- `CFBundleURLSchemes`：iOS Client ID 的反转形式。

### 3.4 创建 Android 客户端

Android OAuth 客户端由“包名 + SHA-1 签名证书”共同识别。Google 的官方 Android 指南也要求分别准备 Web 客户端与绑定包名/SHA-1 的 Android 客户端：[Google Sign-In Android OAuth 客户端说明](https://codelabs.developers.google.com/sign-in-with-google-android)。

1. 应用类型选择 Android。
2. 包名填 `com.openb8.helpsupport_app`。
3. 填写当前测试包签名证书的 SHA-1。
4. Debug、正式签名、Google Play App Signing 使用不同证书时，要为每个实际证书增加匹配的 Android 客户端。

本机 Debug SHA-1：

```bash
keytool -list -v \
  -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android \
  -keypass android
```

正式包应从实际 keystore 或 Google Play Console 的 App Signing 页面获取证书指纹，不能拿 Debug SHA-1 代替。

### 3.5 配置目标对象与测试用户

在 Google Auth Platform 中完成品牌信息、目标对象和所需数据访问范围。应用处于“测试”状态时，只有测试用户列表中的 Google 账号可授权。

检查要点：

- 用户类型与产品发布范围一致。
- 测试人员明确提供自己的 Google 邮箱后再加入。
- 不把测试用户误当成后台管理员授权。
- 准备公开发布时，重新检查品牌、隐私政策、权限范围和 Google 验证要求。

## 4. HelpSupport 后台配置

进入“运营配置 / 登录推送配置 / Google 登录”：

| 字段 | 填写方式 |
| --- | --- |
| Web Client ID | Web 应用客户端 ID，也是 Flutter `serverClientId` |
| iOS Client ID | Bundle ID 为 `com.openb8.helpsupportApp` 的客户端 ID |
| Android Client ID | 包名与实际 SHA-1 匹配的客户端 ID |
| 启用状态 | 启用 |
| 回调策略 | `id_token` / ID Token 直连 |
| 绑定策略 | `verified_email_or_create` / 已验证邮箱优先绑定，否则新建账号 |

当前服务端允许 Token 的 `aud` 命中 Web、iOS、Android 三个配置值之一，并拒绝不可信签发方、缺少 `sub` 或 Google 声明为未验证的邮箱。

保存后用公开接口核对，不要只看表单提示：

```bash
curl -fsS https://help.openb8.org/app/help/common/app-config \
  | jq '.data.oauth.google'
```

期望 `enabled=true`、三个 Client ID 与 Google Cloud 一致、`callback_strategy=id_token`。

## 5. Flutter 与服务端实现位置

| 文件 | 职责 |
| --- | --- |
| [`auth_repository.dart`](../flutter_app/lib/features/auth/data/auth_repository.dart) | 初始化 Google Sign-In、取得 ID Token、请求登录接口 |
| [`Info.plist`](../flutter_app/ios/Runner/Info.plist) | iOS Client ID、Server Client ID 与 URL Scheme |
| [`google-services.json`](../flutter_app/android/app/google-services.json) | Android Google/Firebase 客户端项目配置 |
| [`HelpAuthService.php`](../server/plugin/help/app/service/HelpAuthService.php) | Google JWT 签名、`iss`、`aud`、`sub`、邮箱验证与会员绑定 |
| [`AuthController.php`](../server/plugin/help/app/api/controller/AuthController.php) | `POST /app/help/auth/google` 接口入口 |

更换项目或重建客户端时必须同步 Google Cloud、后台和客户端代码。只改其中一个位置会导致 `aud` 不匹配或 App 无法回调。

## 6. 真机验收

Flutter 运行由本机操作，优先使用实际需要支持的平台设备：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
flutter devices
flutter run -d <device-id>
```

验收步骤：

1. 彻底停止旧调试会话并重新构建安装，不能只热重载 OAuth 配置。
2. 使用已加入测试用户的 Google 账号点击“使用 Google 账号登录”。
3. 确认出现由 Google 提供的账号选择/授权界面。
4. 授权后确认 `POST /app/help/auth/google` 返回业务成功和 HelpSupport Token。
5. 确认 App 进入已登录状态，刷新会话与退出登录正常。
6. 在数据库或后台确认 Google 平台关系已建立；再次登录应复用同一会员。

只读数据库核对示例：

```sql
SELECT id, platform_name, platform_code, status
FROM sa_member_platform
WHERE platform_code = 'GOOGLE' AND delete_time IS NULL;

SELECT rel.member_id, rel.platform_id, rel.platform_openid, rel.create_time
FROM sa_member_platform_rel rel
JOIN sa_member_platform p ON p.id = rel.platform_id
WHERE p.platform_code = 'GOOGLE'
  AND rel.delete_time IS NULL
ORDER BY rel.id DESC
LIMIT 10;
```

`platform_openid` 属于用户身份数据，截图或工单中应脱敏。

## 7. 常见问题

### Google 登录未启用

检查后台启用状态与公开 App 配置，确认不是保存到了其他环境。

### Google Client ID 未配置

检查三个字段是否保存成功；当前链路至少要有可用于验证 `aud` 的 Client ID。

### Google ID Token 受众不匹配

对比 Token 实际 `aud`、Flutter `serverClientId`、iOS Client ID 与后台配置。最常见原因是 App 仍打包旧配置或 Web Client ID 填错。

### Android `clientConfigurationError`

核对包名、当前 APK 的 SHA-1、Android Client ID 和 Web `serverClientId`。换电脑、换 keystore 或开启 Play App Signing 后通常需要新增对应客户端。

### iOS 授权后无法返回 App

核对 Bundle ID、`GIDClientID` 与反转 URL Scheme。修改后停止旧会话并重新完整构建安装。

### 非测试用户被拒绝

确认 Google Auth Platform 的发布状态与测试用户列表。不要通过分享管理员账号绕过测试用户限制。

## 8. 变更与回滚

- 不要直接删除正在使用的 OAuth 客户端；旧版本 App 会立即失效。
- 轮换客户端时先新增并让新版本 App/后台同时接受，再确认旧版本退出窗口。
- 生产变更前记录旧 Client ID、受影响平台、发布版本与回滚步骤。
- Client Secret、Cookie、Bearer Token、用户 ID Token 不得写入 Git、日志、文档或工单。

后台“操作说明”中的对应文章由迁移 [`20260819035707_seed_admin_google_login_manual.php`](../Database/migrations/20260819035707_seed_admin_google_login_manual.php) 初始化。
