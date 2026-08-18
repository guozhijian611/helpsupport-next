# HelpSupport Firebase 推送配置指南

## 1. 适用范围

本文说明 HelpSupport Flutter iOS/Android 客户端与 Webman 服务端的 Firebase Cloud Messaging 配置、凭据边界、设备登记、消息发送和真机验收方法。

当前链路：

```text
Flutter Firebase Messaging
  -> FCM Token（iOS 同时有 APNs Token）
  -> POST /app/help/push/device/register
  -> sa_member_push_device
  -> HelpPushService 生成 OAuth 2.0 Access Token
  -> FCM HTTP v1 messages:send
  -> Android / APNs
  -> 设备通知
```

服务端只使用 FCM HTTP v1，不使用旧版 Server Key。HTTP v1 官方鉴权说明支持以 `GOOGLE_APPLICATION_CREDENTIALS` 指向服务账号 JSON，并要求 `https://www.googleapis.com/auth/firebase.messaging` scope：[FCM HTTP v1 授权](https://firebase.google.com/docs/cloud-messaging/send/v1-api)。

## 2. 当前云端资源

| 项目 | 当前值 |
| --- | --- |
| Google Cloud / Firebase Project ID | `helpsupport-499505` |
| Project Number / Sender ID | `1020489387914` |
| iOS Bundle ID | `com.openb8.helpsupportApp` |
| iOS Firebase App ID | `1:1020489387914:ios:b09f0bdb343d32071ec273` |
| Android 包名 | `com.openb8.helpsupport_app` |
| Android Firebase App ID | `1:1020489387914:android:7ccd30e3a23bb4e51ec273` |
| Apple Team ID | `33ZX95D3LJ` |
| APNs Key ID | `62993N9NAP` |
| FCM 服务账号 | `helpsupport-fcm-sender@helpsupport-499505.iam.gserviceaccount.com` |
| 服务账号角色 | Firebase Cloud Messaging API Admin |
| 线上凭据路径 | `/www/secure/helpsupport-next/firebase-service-account.json` |

API Key、Firebase App ID 和 Sender ID 是移动端项目配置，会随 App 打包；服务账号 JSON、APNs `.p8`、FCM Token、APNs Token 和 OAuth Access Token 属于敏感数据。

## 3. Firebase 项目配置

### 3.1 将 Google Cloud 项目加入 Firebase

如果项目尚未启用 Firebase，在 [Firebase Console](https://console.firebase.google.com/) 选择“添加项目”，复用现有 Google Cloud 项目 `helpsupport-499505`。不要创建同名新项目。

HelpSupport 当前不依赖 Firebase Analytics；是否启用 Analytics 应按产品需求单独决定，不是 FCM 的必选项。

### 3.2 启用 API

在 Google Cloud Console 的 API 和服务中确认：

- Firebase Management API 已启用。
- Firebase Cloud Messaging API (V1) 已启用。
- Cloud Messaging API（旧版）保持停用。

### 3.3 注册 iOS 应用

1. 打开 [Firebase 项目设置 / 常规](https://console.firebase.google.com/project/helpsupport-499505/settings/general)。
2. 注册 Apple 应用，Bundle ID 填 `com.openb8.helpsupportApp`。
3. 下载 `GoogleService-Info.plist`。
4. 文件放到 [`flutter_app/ios/Runner/GoogleService-Info.plist`](../flutter_app/ios/Runner/GoogleService-Info.plist)。
5. 确认它属于 Runner target，并出现在 Copy Bundle Resources。

### 3.4 注册 Android 应用

1. 在同一 Firebase 项目注册 Android 应用。
2. 包名填 `com.openb8.helpsupport_app`。
3. 下载 `google-services.json`。
4. 文件放到 [`flutter_app/android/app/google-services.json`](../flutter_app/android/app/google-services.json)。
5. 在 [`settings.gradle.kts`](../flutter_app/android/settings.gradle.kts) 声明 Google Services 插件。
6. 在 [`app/build.gradle.kts`](../flutter_app/android/app/build.gradle.kts) 应用插件。

验证 Android 配置解析：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app/android
./gradlew :app:processDebugGoogleServices --no-daemon
```

任务必须执行成功；依赖插件的弃用警告不能掩盖真正的配置错误。

## 4. iOS APNs 配置

Firebase 官方 Flutter FCM 指南要求 Apple 应用启用 Push Notifications、Background fetch、Remote notifications，并在 Firebase 上传 APNs authentication key：[Flutter FCM Apple 配置](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)。

### 4.1 创建 APNs Key

1. 打开 Apple Developer / Certificates, Identifiers & Profiles / Keys。
2. 创建专用于 HelpSupport 的 Key。
3. 只启用 Apple Push Notifications service (APNs)。
4. 环境选择支持 Sandbox & Production。
5. 当前 Key ID 为 `62993N9NAP`，Team ID 为 `33ZX95D3LJ`。
6. 下载 `.p8` 后立即离线备份；Apple 通常只允许下载一次。

### 4.2 上传 Firebase

打开 [Firebase 项目设置 / Cloud Messaging](https://console.firebase.google.com/project/helpsupport-499505/settings/cloudmessaging)，选择 HelpSupport iOS 应用：

1. 在开发版 APNs 身份验证密钥位置上传 `.p8`，填写 Key ID 和 Team ID。
2. 在正式版位置上传同一枚支持 Sandbox & Production 的密钥。
3. 重新加载页面，确认开发版与正式版两行都显示 `62993N9NAP / 33ZX95D3LJ`。

### 4.3 Runner 能力

| 文件 | 当前要求 |
| --- | --- |
| [`project.pbxproj`](../flutter_app/ios/Runner.xcodeproj/project.pbxproj) | Push Notifications 与 Background Modes capability |
| [`Runner.entitlements`](../flutter_app/ios/Runner/Runner.entitlements) | `aps-environment` |
| [`Info.plist`](../flutter_app/ios/Runner/Info.plist) | `UIBackgroundModes` 包含 `fetch`、`remote-notification` |
| [`GoogleService-Info.plist`](../flutter_app/ios/Runner/GoogleService-Info.plist) | Bundle ID 与 Firebase 项目正确 |

不要设置 `FirebaseAppDelegateProxyEnabled=false`，除非同时完整实现 Firebase Messaging 所需的 AppDelegate 转发。当前实现依赖默认 Method Swizzling。

## 5. 最小权限服务账号

### 5.1 创建账号与角色

在 Google Cloud IAM / 服务账号中：

1. 创建 `HelpSupport FCM Sender`。
2. 服务账号 ID 使用 `helpsupport-fcm-sender`。
3. 只授予 `Firebase Cloud Messaging API Admin`。
4. 不授予 Owner、Editor、Firebase Admin 或与消息发送无关的角色。

### 5.2 生成与部署 JSON

生成 JSON 私钥后，不打开、不复制私钥内容到聊天或工单。部署到服务器非 Web 目录：

```text
/www/secure/helpsupport-next/firebase-service-account.json
```

权限基线：

```bash
install -d -m 700 -o www -g www /www/secure/helpsupport-next
chown www:www /www/secure/helpsupport-next/firebase-service-account.json
chmod 600 /www/secure/helpsupport-next/firebase-service-account.json
```

然后在 `server/.env` 配置：

```dotenv
GOOGLE_APPLICATION_CREDENTIALS = /www/secure/helpsupport-next/firebase-service-account.json
```

不要覆盖整份 `.env`，只维护该键。修改 PHP 或 `.env` 后重启 Webman：

```bash
cd /www/wwwroot/helpsupport-next/server
php webman restart -d
```

[`HelpPushService.php`](../server/plugin/help/app/service/HelpPushService.php) 优先读取该环境变量指向的 JSON，并用短期 JWT assertion 换取 OAuth Access Token。Access Token 只用于运行时，不落库、不输出日志。

## 6. HelpSupport 后台配置

进入“运营配置 / 登录推送配置 / Firebase 推送”：

| 字段 | 当前填写方式 |
| --- | --- |
| Firebase Project ID | `helpsupport-499505` |
| Service Account JSON | 留空 |
| 启用状态 | 启用 |

Service Account JSON 留空是有意的安全设计：生产凭据只存在服务器私有文件中，避免进入数据库备份和后台接口。

公开配置验证：

```bash
curl -fsS https://help.openb8.org/app/help/common/app-config \
  | jq '.data.push'
```

期望：

```json
{
  "firebase_enabled": true,
  "firebase_project_id": "helpsupport-499505"
}
```

响应不得包含服务账号邮箱、私钥或文件路径。

## 7. Flutter Token 与设备登记

[`FirebasePushService`](../flutter_app/lib/core/push/firebase_push_service.dart) 负责：

- `Firebase.initializeApp()`。
- 前台通知展示选项。
- 系统通知权限请求。
- 等待 iOS APNs Token。
- 获取 FCM Token 与 Token 刷新流。

Firebase 官方特别说明：Apple 平台在调用 FCM API 前必须确保 APNs Token 已可用；APNs Token 到达时间不能被假设。当前实现会等待 APNs Token，再获取 FCM Token。

[`DeviceRegistrationService`](../flutter_app/lib/features/auth/data/device_registration_service.dart) 调用：

```text
POST /app/help/push/device/register
```

字段包括：

- `device_id`
- `platform`：`ios` 或 `android`
- `fcm_token`
- `apns_token`
- `app_version`
- `locale`
- `timezone`

用户登录后会登记设备；在设置页开启通知权限后会再次登记。退出登录调用 `/app/help/push/device/unregister`。

## 8. 服务端发送与结果判定

[`HelpPushService.php`](../server/plugin/help/app/service/HelpPushService.php) 的发送条件：

1. Firebase 后台配置启用。
2. Project ID 非空。
3. 用户推送偏好允许当前场景。
4. 当前时间不在免打扰窗口。
5. 存在有效、非空 FCM Token 的设备。
6. 服务账号凭据能换取 OAuth Access Token。

发送地址：

```text
POST https://fcm.googleapis.com/v1/projects/helpsupport-499505/messages:send
```

服务端只有在 HTTP 状态为 2xx 时标记设备发送成功。结果写入 `sa_member_message.ext.push_results`；`UNREGISTERED`、`INVALID_ARGUMENT` 或 `SENDER_ID_MISMATCH` 等无效 Token 错误会触发设备停用判断。

## 9. 真机验收

### 9.1 安装与授权

按照项目规范由用户在本机启动真实设备：

```bash
cd /Users/openb8/Downloads/项目/helpsupport-next/flutter_app
flutter devices
flutter run -d <device-id>
```

iOS 远程推送必须优先使用真实 iPhone。不要把模拟器的本地通知表现当作 APNs/FCM 已成功。

1. 登录 App。
2. 进入“设置 / 通知设置 / 通知权限”。
3. 允许通知。
4. 等待设备重新登记。

### 9.2 后台核对设备

进入“消息推送 / 推送设备”，确认：

- 会员 ID 正确。
- `platform` 与设备一致。
- FCM Token 非空。
- iOS APNs Token 非空。
- 设备状态有效。
- 最近活跃时间已更新。

只读数据库核对：

```sql
SELECT id, member_id, platform, device_id,
       CHAR_LENGTH(fcm_token) AS fcm_token_length,
       CHAR_LENGTH(apns_token) AS apns_token_length,
       is_active, last_active_time
FROM sa_member_push_device
WHERE delete_time IS NULL
ORDER BY id DESC
LIMIT 20;
```

不要在查询结果截图或工单中展示 Token 原文。

### 9.3 发送测试消息

1. 在后台“消息推送 / 消息管理”创建或选择一条测试消息。
2. 目标会员选择刚登记的真机账号。
3. 执行推送。
4. 验证 App 前台、后台和被系统终止三种状态。
5. 点击通知，验证业务路由和消息中心记录。
6. 查看消息详情中的 `push_status`、`push_time` 和 `ext.push_results`。

成功必须同时满足：FCM 返回 HTTP 2xx、消息记录保存成功、目标真机实际收到通知。任意一项缺失都不能判定端到端完成。

### 9.4 App 开发者工具

登录后进入“关于 / 开发者工具”，可在本机对照推送链路：

- 查看 Firebase 初始化、Project ID、Sender ID、通知授权、APNs 环境、APNs/FCM Token 长度。
- 核对服务器是否启用 Firebase、服务账号是否加载、当前设备是否已登记。
- 点“发送测试推送”调用 `POST /app/help/push/device/test`，页面会显示 FCM HTTP 结果；接口不返回 Token 原文。
- 前台收到的远程消息会列在同一卡片中，便于确认到达而不是只看发送成功。

iOS 远程推送仍以真机为准。模拟器上的本地通知成功不能代替 APNs/FCM。

## 10. 常见错误

### `missing_fcm_token_or_project_id`

后台 Project ID 为空或目标设备没有 FCM Token。检查公开配置和设备登记。

### `missing_firebase_access_token`

检查：

- `GOOGLE_APPLICATION_CREDENTIALS` 是否加载。
- JSON 文件是否存在、权限是否允许 Webman 读取。
- JSON 是否来自正确项目和服务账号。
- Webman 是否在 `.env` 修改后重启。
- 服务账号密钥是否仍为 Active。

### `SENDER_ID_MISMATCH`

客户端 Token 与服务端 Project ID 不属于同一项目。对比 iOS/Android Firebase 配置文件与后台 Project ID。

### `UNREGISTERED`

Token 已失效，通常是卸载重装、清除应用数据或 Firebase Token 轮换。客户端需要重新登记，旧设备记录应被停用。

### iOS 收不到通知

逐项检查：

- APNs 开发版与正式版 Key ID / Team ID。
- Bundle ID。
- Push Notifications capability。
- `aps-environment` 与签名描述文件。
- Background Modes。
- 系统通知权限。
- APNs Token 是否登记。

### Android `processDebugGoogleServices` 失败

检查 `google-services.json` 是否位于 `android/app/`、包名是否为 `com.openb8.helpsupport_app`，以及 Google Services 插件是否声明并应用。

### 前台收到数据但没有横幅

检查系统通知权限与 `setForegroundNotificationPresentationOptions`。Android 还需确认系统通知渠道与 Android 13+ 通知权限。

## 11. 密钥轮换与回滚

### 服务账号 JSON

1. 创建新密钥。
2. 部署为新的私有文件或原子替换现有文件。
3. 保持 `0600` 权限。
4. 重启 Webman，并验证 OAuth 与一次真实推送。
5. 成功后再删除旧 Google Cloud 密钥。

### APNs Key

1. 创建新 APNs Key，并安全下载。
2. 上传 Firebase 开发版与正式版位置。
3. 用 Debug 与 Release/TestFlight 真机分别验证。
4. 成功后再撤销旧 Key。

删除仍在使用的密钥会立即中断推送。轮换期间不得把私钥放入 Git、数据库、Web 根目录、日志、聊天或工单。

后台“操作说明”文章由迁移 [`20260819055302_seed_admin_firebase_push_manual.php`](../Database/migrations/20260819055302_seed_admin_firebase_push_manual.php) 初始化。
