<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedAdminFirebasePushManual extends AbstractMigration
{
    private const MANUAL_MARKER = 'audience:admin-manual';
    private const CATEGORY_NAME = '运营配置';
    private const TITLE = 'Firebase 推送配置与测试';
    private const AUTHOR = 'HelpSupport 后台手册';
    private const DESCRIPTION = '说明 Firebase iOS/Android 应用、APNs 密钥、最小权限服务账号、后台运行配置与真机验收方法。';
    private const SORT = 22;

    public function up(): void
    {
        if (!$this->hasTable('sa_article') || !$this->hasTable('sa_article_category')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_article` (`category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT c.`id`, ' . $this->q(self::TITLE) . ', ' . $this->q(self::AUTHOR) . ', ' . $this->q('') . ', ' . $this->q(self::DESCRIPTION) . ', ' . $this->q($this->content()) . ', 0, ' . self::SORT . ', 1, 2, ' . $this->q(self::MANUAL_MARKER) . ', 1, 1, 1, NOW(), NOW(), NULL
             FROM `sa_article_category` c
             INNER JOIN `sa_article_category` p ON p.`id` = c.`parent_id`
             WHERE c.`category_name` = ' . $this->q(self::CATEGORY_NAME) . '
               AND c.`delete_time` IS NULL
               AND p.`parent_id` = 0
               AND p.`describe` LIKE ' . $this->q('%' . self::MANUAL_MARKER . '%') . '
               AND p.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_article` a
                   WHERE a.`title` = ' . $this->q(self::TITLE) . '
                     AND a.`link_url` = ' . $this->q(self::MANUAL_MARKER) . '
                     AND a.`delete_time` IS NULL
               )
             ORDER BY c.`id` ASC
             LIMIT 1'
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_article') || !$this->hasTable('sa_article_category')) {
            return;
        }

        $this->execute(
            'DELETE a FROM `sa_article` a
             INNER JOIN `sa_article_category` c ON c.`id` = a.`category_id`
             INNER JOIN `sa_article_category` p ON p.`id` = c.`parent_id`
             WHERE a.`title` = ' . $this->q(self::TITLE) . '
               AND a.`author` = ' . $this->q(self::AUTHOR) . '
               AND a.`describe` = ' . $this->q(self::DESCRIPTION) . '
               AND a.`content` = ' . $this->q($this->content()) . '
               AND a.`sort` = ' . self::SORT . '
               AND a.`status` = 1
               AND a.`is_link` = 2
               AND a.`link_url` = ' . $this->q(self::MANUAL_MARKER) . '
               AND a.`is_hot` = 1
               AND a.`delete_time` IS NULL
               AND c.`category_name` = ' . $this->q(self::CATEGORY_NAME) . '
               AND p.`parent_id` = 0
               AND p.`describe` LIKE ' . $this->q('%' . self::MANUAL_MARKER . '%')
        );
    }

    private function content(): string
    {
        return <<<'HTML'
<h2>配置前先确认</h2>
<p>HelpSupport 使用 Firebase Cloud Messaging HTTP v1：Flutter 客户端获取 FCM Token，登录后提交到 <code>/app/help/push/device/register</code>；服务端使用短期 OAuth 2.0 Access Token 调用 FCM，再由 Android 或 APNs 将消息送达设备。</p>
<ul>
<li>Google Cloud / Firebase 项目：<code>helpsupport-499505</code>，项目编号与 Sender ID：<code>1020489387914</code>。</li>
<li>iOS Bundle ID：<code>com.openb8.helpsupportApp</code>；Firebase App ID：<code>1:1020489387914:ios:b09f0bdb343d32071ec273</code>。</li>
<li>Android 包名：<code>com.openb8.helpsupport_app</code>；Firebase App ID：<code>1:1020489387914:android:7ccd30e3a23bb4e51ec273</code>。</li>
<li>服务端只使用 HTTP v1，不启用旧版 Server Key 接口。</li>
</ul>

<h2>一、Firebase 项目与移动应用</h2>
<ol>
<li>打开 <a href="https://console.firebase.google.com/project/helpsupport-499505/settings/general" target="_blank" rel="noopener">Firebase / 项目设置 / 常规</a>，确认项目 ID 为 <code>helpsupport-499505</code>。</li>
<li>确认 iOS 应用的 Bundle ID、Android 应用的包名与上面完全一致；大小写、下划线和点都不能改。</li>
<li>iOS 下载 <code>GoogleService-Info.plist</code>，加入 Runner 目标并勾选 Copy Bundle Resources。</li>
<li>Android 下载 <code>google-services.json</code>，放到 <code>flutter_app/android/app/</code>，并应用 <code>com.google.gms.google-services</code> 插件。</li>
<li>在 Google Cloud API 中确认 Firebase Management API 与 Firebase Cloud Messaging API (V1) 已启用。</li>
</ol>
<p>两个移动端配置文件包含客户端项目标识，允许随 App 打包；服务账号 JSON 和 APNs <code>.p8</code> 是私钥，绝不能放入 App、Git、后台文章或公开下载目录。</p>

<h2>二、iOS APNs 配置</h2>
<ol>
<li>在 Apple Developer / Keys 创建仅启用 Apple Push Notifications service (APNs) 的密钥；当前 Key ID 为 <code>62993N9NAP</code>，Team ID 为 <code>33ZX95D3LJ</code>。</li>
<li><code>.p8</code> 只能下载一次，应立即离线备份并限制文件权限。不要把它改名为移动端资源或提交 Git。</li>
<li>打开 <a href="https://console.firebase.google.com/project/helpsupport-499505/settings/cloudmessaging" target="_blank" rel="noopener">Firebase / 项目设置 / Cloud Messaging</a>，选择 HelpSupport iOS 应用。</li>
<li>将同一枚支持 Sandbox &amp; Production 的 APNs 密钥分别上传到开发版和正式版位置，填写 Key ID 与 Team ID；保存后重新进入页面，确认两行都显示正确 ID。</li>
</ol>
<p>Runner 必须启用 Push Notifications、Background Modes / Background fetch、Background Modes / Remote notifications。<code>Runner.entitlements</code> 需要 <code>aps-environment</code>，<code>Info.plist</code> 需要对应 <code>UIBackgroundModes</code>。Firebase Messaging 的 Apple 平台 Method Swizzling 必须保持启用。</p>

<h2>三、服务端最小权限凭据</h2>
<ol>
<li>在 Google Cloud IAM 创建专用服务账号 <code>helpsupport-fcm-sender@helpsupport-499505.iam.gserviceaccount.com</code>。</li>
<li>只授予 <strong>Firebase Cloud Messaging API Admin</strong>，不要为了方便授予 Owner、Editor 或 Firebase Admin。</li>
<li>生成 JSON 密钥后放到服务器非 Web 目录，例如 <code>/www/secure/helpsupport-next/firebase-service-account.json</code>。</li>
<li>目录权限建议 <code>0700</code>，JSON 文件权限必须为 <code>0600</code>，属主应与 Webman 运行用户匹配。</li>
<li>在 <code>server/.env</code> 设置 <code>GOOGLE_APPLICATION_CREDENTIALS = /www/secure/helpsupport-next/firebase-service-account.json</code>，修改后重启 Webman。</li>
</ol>
<p>服务账号 JSON 不写入数据库。后台的 Service Account JSON 字段保持空白，避免私钥进入数据库备份、接口响应和后台审计链路。轮换密钥时先部署新文件并验证 OAuth，再删除旧密钥。</p>

<h2>四、填写 HelpSupport 后台配置</h2>
<p>进入「运营配置 / 登录推送配置 / Firebase 推送」：</p>
<ul>
<li><strong>Firebase Project ID</strong>：<code>helpsupport-499505</code>。</li>
<li><strong>Service Account JSON</strong>：留空，生产凭据由服务器环境变量指向私有文件。</li>
<li><strong>启用状态</strong>：打开。</li>
</ul>
<p>保存后重新进入页签，并请求 <code>GET /app/help/common/app-config</code>，确认 <code>push.firebase_enabled=true</code>、<code>push.firebase_project_id=helpsupport-499505</code>，同时确认响应中没有私钥。</p>

<h2>五、Flutter 设备注册链路</h2>
<ul>
<li>App 启动时调用 <code>Firebase.initializeApp()</code>。</li>
<li>用户开启通知权限后，App 会重新注册当前设备。</li>
<li>iOS 必须先拿到 APNs Token，再请求 FCM Token；不能假设两个 Token 会同时到达。</li>
<li>设备注册接口保存 <code>device_id</code>、<code>platform</code>、<code>fcm_token</code>、<code>apns_token</code>、App 版本、语言和时区。</li>
<li>FCM Token 刷新、重装 App 或更换账号后，应重新登记；退出登录时注销当前设备记录。</li>
</ul>

<h2>六、真机测试与验收</h2>
<ol>
<li>在 <code>flutter_app/</code> 执行 <code>flutter devices</code>，再使用 <code>flutter run -d &lt;iPhone 真机 device id&gt;</code> 完整安装。远程推送优先使用真机，不以模拟器结果替代。</li>
<li>登录 App，进入「设置 / 通知设置 / 通知权限」并允许通知。</li>
<li>在后台「消息推送 / 推送设备」确认当前会员有非空 FCM Token；iOS 还应有 APNs Token。</li>
<li>在后台「消息推送 / 消息管理」创建或选择消息并执行推送，确认手机收到通知。</li>
<li>回到消息详情检查 <code>push_status</code> 与 <code>ext.push_results</code>：必须存在 HTTP 2xx 成功结果，不能只以消息记录已创建作为成功。</li>
<li>分别验证 App 前台、后台和被系统终止后的通知表现，以及点击通知后的页面路由。</li>
</ol>

<h2>常见错误定位</h2>
<ul>
<li><strong>missing_fcm_token_or_project_id</strong>：后台 Project ID 为空，或设备未登记 FCM Token。</li>
<li><strong>missing_firebase_access_token</strong>：环境变量未加载、JSON 不可读、JSON 格式错误、私钥失效，或 Webman 未重启。</li>
<li><strong>SENDER_ID_MISMATCH</strong>：客户端 Token 与服务端项目不是同一 Firebase 项目，核对两端配置文件和 Project ID。</li>
<li><strong>UNREGISTERED</strong>：Token 已失效，常见于卸载重装、清除数据或 Token 轮换；系统会停用无效设备，客户端需重新登记。</li>
<li><strong>iOS 有 FCM Token 但收不到</strong>：核对 APNs 开发/生产密钥、Team ID、Bundle ID、entitlement、描述文件和通知权限。</li>
<li><strong>Android 构建找不到客户端</strong>：核对 <code>google-services.json</code> 位置、包名和 Google Services Gradle 插件。</li>
<li><strong>前台无横幅</strong>：核对 <code>setForegroundNotificationPresentationOptions</code> 和系统通知权限。</li>
</ul>

<h2>变更安全</h2>
<p>删除 APNs Key 或 Google 服务账号密钥会立即影响线上推送。操作前应确认目标项目、当前密钥 ID、服务器文件、回滚窗口和至少一台真机。不得在操作说明、Git、日志、工单或聊天中粘贴服务账号私钥、OAuth Access Token、FCM Token、APNs Token 或 <code>.p8</code> 内容。</p>
HTML;
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
