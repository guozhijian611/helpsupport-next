<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedAdminAppleLoginManual extends AbstractMigration
{
    private const MANUAL_MARKER = 'audience:admin-manual';
    private const CATEGORY_NAME = '运营配置';
    private const TITLE = 'Apple 登录配置与测试';
    private const AUTHOR = 'HelpSupport 后台手册';
    private const DESCRIPTION = '说明 Apple Developer App ID 能力、iOS entitlement、后台运行配置与 Flutter 真机验收方法。';
    private const SORT = 21;

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
<p>HelpSupport Flutter 的 iOS 客户端使用 Apple ID Token 登录：App 向 Apple 获取 <code>identityToken</code>，再提交到 <code>/app/help/auth/apple</code>；服务端校验 Apple 签名、签发方和 <code>aud</code> 后创建或绑定会员。</p>
<ul>
<li>Apple Developer Team ID：<code>33ZX95D3LJ</code>。</li>
<li>iOS Bundle ID：<code>com.openb8.helpsupportApp</code>。</li>
<li>当前只配置原生 iOS ID Token 流程，不需要 Services ID、Key ID 或 Sign in with Apple 私钥。</li>
<li>不要在操作说明、工单或聊天中粘贴 Apple 私钥、管理员 Cookie 或 Token。</li>
</ul>

<h2>一、在 Apple Developer 启用 App ID 能力</h2>
<ol>
<li>打开 <a href="https://developer.apple.com/account/resources/identifiers/list" target="_blank" rel="noopener">Certificates, Identifiers &amp; Profiles / Identifiers</a>，确认当前团队为 <code>33ZX95D3LJ</code>。</li>
<li>进入显式 App ID <code>com.openb8.helpsupportApp</code>，不要选择通配 App ID，也不要选择名称相近但 Bundle ID 不同的记录。</li>
<li>在 Capabilities 勾选「Sign In with Apple」，保持「Enable as a primary App ID」，然后点击 Save 并在确认弹窗中点击 Confirm。</li>
<li>重新进入该 App ID，确认「Sign In with Apple」仍为已勾选，不能只以保存前的页面状态作为成功。</li>
</ol>
<p>修改 App ID 能力会使包含该 App ID 的旧 provisioning profile 失效。当前 Runner 使用 Automatic Signing，下次真机构建时应由 Xcode 刷新描述文件；如生产发布使用手动签名，需在发布前重新生成并安装描述文件。</p>

<h2>二、配置 Xcode 签名能力</h2>
<p>Runner 目标必须同时具备 Sign in with Apple capability 和 entitlement。当前仓库的关键配置为：</p>
<ul>
<li><code>flutter_app/ios/Runner/Runner.entitlements</code> 包含 <code>com.apple.developer.applesignin</code>，值为 <code>Default</code>。</li>
<li>Runner 的 Debug、Release 和 Profile 均使用 <code>CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements</code>。</li>
<li>Development Team 为 <code>33ZX95D3LJ</code>，Product Bundle Identifier 为 <code>com.openb8.helpsupportApp</code>。</li>
</ul>
<p>如从 Xcode 手动操作，进入 Runner / Signing &amp; Capabilities，点击「+ Capability」后添加「Sign in with Apple」。Bundle ID、Team 或 entitlement 变更后必须停止旧调试会话并重新完整构建安装，不能只做热重载。</p>

<h2>三、填写 HelpSupport 后台配置</h2>
<p>进入「运营配置 / 登录推送配置 / Apple 登录」，按下列方式填写：</p>
<ul>
<li><strong>Team ID</strong>：<code>33ZX95D3LJ</code>。</li>
<li><strong>Bundle ID</strong>：<code>com.openb8.helpsupportApp</code>。服务端用它校验原生 iOS Token 的 <code>aud</code>。</li>
<li><strong>Service ID</strong>：当前原生 iOS 流程留空。</li>
<li><strong>Key ID</strong> 和 <strong>Private Key</strong>：当前原生 iOS ID Token 直连流程留空。</li>
<li><strong>启用状态</strong>：打开。</li>
<li><strong>回调策略</strong>：选「ID Token 直连」。</li>
<li><strong>绑定策略</strong>：默认选「已验证邮箱优先绑定，否则新建账号」。</li>
</ul>
<p>保存后重新进入 Apple 登录页签，并请求 <code>/app/help/common/app-config</code>，确认 <code>oauth.apple.enabled</code> 为 <code>true</code>，Team ID、Bundle ID 和 <code>callback_strategy=id_token</code> 均与后台一致。</p>

<h2>四、Services ID 与私钥什么时候才需要</h2>
<p>当前 Flutter 客户端在 iOS 上调用系统 Apple 授权，服务端直接验证 <code>identityToken</code>，所以不要为了「填满字段」创建无用的 Services ID 或上传私钥。</p>
<p>只有后续增加 Web 登录、Android 通过 Web 授权登录，或服务端需要与 Apple Token 端点交换 authorization code 时，才另行创建 Services ID、配置 Domains and Subdomains / Return URLs，并以安全配置注入 Key ID 和 <code>.p8</code> 私钥。那是新的登录链路，需要单独开发和验收，不应与当前原生 iOS 配置混用。</p>

<h2>五、真机测试与验收</h2>
<ol>
<li>使用已登录 Apple ID 且开启双重认证的 iPhone，重新完整构建并安装 App。</li>
<li>在登录页点击「使用 Apple 账号登录」，确认系统 Apple 授权面板能够打开。</li>
<li>首次授权时检查姓名、邮箱或「隐藏我的邮箱」选项；Apple 可能只在首次授权时返回姓名和邮箱，后续登录应依赖稳定的 Apple 用户标识，不能强制要求再次返回姓名。</li>
<li>授权后确认 <code>POST /app/help/auth/apple</code> 返回成功，App 进入已登录状态，且后台会员平台关系中出现 Apple 绑定。</li>
<li>退出 App 后再次使用同一 Apple ID 登录，确认复用原会员，不会重复创建账号。</li>
</ol>

<h2>常见错误定位</h2>
<ul>
<li><strong>当前平台不支持 Apple 登录</strong>：先用 iOS 真机验证，确认系统和 Apple ID 状态可用；当前未开发 Web/Android 授权回调链路。</li>
<li><strong>Apple 登录未启用</strong>：检查后台「启用状态」和对外 App 配置接口。</li>
<li><strong>Apple Bundle ID 或 Service ID 未配置</strong>：当前原生 iOS 流程应填写正确 Bundle ID，Service ID 可留空。</li>
<li><strong>Apple identityToken 受众不匹配</strong>：对比 App 实际 Bundle ID、Apple Developer App ID 与后台 Bundle ID，三者必须一致。</li>
<li><strong>真机签名或安装失败</strong>：检查 Runner entitlement、Team、Automatic Signing，并让 Xcode 刷新含 Sign in with Apple 能力的 provisioning profile。</li>
<li><strong>授权后没有再次获取姓名或邮箱</strong>：这不一定是错误；检查是否已授权过该 App，后续登录应按 Apple 用户标识查找既有会员。</li>
</ul>

<h2>变更安全</h2>
<p>不要随意删除、转移或分组正在使用的 Apple App ID，也不要直接替换线上 Bundle ID。发布前需同时核对 Apple Developer 能力、Xcode entitlement、签名描述文件、HelpSupport 后台字段和服务端实际登录结果。</p>
HTML;
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
