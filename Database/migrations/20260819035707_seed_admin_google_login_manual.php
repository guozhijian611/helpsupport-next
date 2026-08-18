<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedAdminGoogleLoginManual extends AbstractMigration
{
    private const MANUAL_MARKER = 'audience:admin-manual';
    private const CATEGORY_NAME = '运营配置';
    private const TITLE = 'Google 登录配置与测试';
    private const AUTHOR = 'HelpSupport 后台手册';
    private const DESCRIPTION = '说明 Google Auth Platform 客户端、测试用户、后台运行配置与 Flutter 验收方法。';
    private const SORT = 20;

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
<p>HelpSupport Flutter 使用 Google ID Token 登录：App 向 Google 获取 ID Token，再提交到 <code>/app/help/auth/google</code>，服务端校验签名、签发方和 <code>aud</code> 后创建或绑定会员。</p>
<ul>
<li>Google Cloud 项目：<code>helpsupport-499505</code>。</li>
<li>iOS Bundle ID：<code>com.openb8.helpsupportApp</code>。</li>
<li>Android 包名：<code>com.openb8.helpsupport_app</code>。</li>
<li>当前移动端不需要 Web 重定向 URI，Web 客户端用作 <code>serverClientId</code> 和服务端 <code>aud</code> 校验。</li>
</ul>

<h2>一、在 Google Auth Platform 创建客户端</h2>
<p>打开 <a href="https://console.cloud.google.com/auth/clients?project=helpsupport-499505" target="_blank" rel="noopener">Google Auth Platform / 客户端</a>，确认右上角项目是 <code>helpsupport-499505</code>。移动端需要分平台创建，不要用一个 Client ID 替代所有类型。</p>
<ol>
<li><strong>Web 应用</strong>：建议命名为「HelpSupport Flutter Server」。移动端 ID Token 方案不用填 JavaScript 来源和重定向 URI。</li>
<li><strong>iOS</strong>：软件包 ID 填 <code>com.openb8.helpsupportApp</code>。App Store ID 未发布时可留空。</li>
<li><strong>Android</strong>：软件包名填 <code>com.openb8.helpsupport_app</code>，SHA-1 必须来自实际测试包的签名证书。</li>
</ol>
<p>Android 本机 Debug SHA-1 可用下面的命令查看。换电脑、换签名文件或上架 Google Play 后，都要增加对应证书的 Android OAuth 客户端。</p>
<pre><code>keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android</code></pre>

<h2>二、测试状态与测试用户</h2>
<p>在「Google Auth Platform / 目标对象」中确认用户类型为「外部」。应用保持「测试」状态时，只有加入测试用户列表的 Google 账号能完成授权。</p>
<p>测试账号是可登录范围，不是后台管理员权限。要增加测试人员，只添加对方明确提供的 Google 邮箱，不要把不相关用户批量加入。</p>

<h2>三、填写 HelpSupport 后台配置</h2>
<p>进入「运营配置 / 登录推送配置 / Google 登录」，将 Google Cloud 中的三个 Client ID 按类型一一对应：</p>
<ul>
<li><strong>Web Client ID</strong>：填「Web 应用」客户端 ID，也是 Flutter 的 <code>serverClientId</code>。</li>
<li><strong>iOS Client ID</strong>：填 iOS 客户端 ID。</li>
<li><strong>Android Client ID</strong>：填包名和 SHA-1 匹配的 Android 客户端 ID。</li>
<li><strong>启用状态</strong>：打开。</li>
<li><strong>回调策略</strong>：选「ID Token 直连」。</li>
<li><strong>绑定策略</strong>：默认选「已验证邮箱优先绑定，否则新建账号」。</li>
</ul>
<p>保存后重新进入本页，确认三个字段没有回到空值或测试占位值。<strong>不要把 Web 客户端密钥填入后台</strong>；当前 ID Token 登录只需 Client ID，不需要 Client Secret。</p>

<h2>四、Flutter 端对接要点</h2>
<p>当前仓库已接入 Google Sign-In。如果更换 Google Cloud 项目或重建客户端，需由开发人员同步以下位置，不能只改后台：</p>
<ul>
<li>iOS <code>Info.plist</code>：<code>GIDClientID</code>、<code>GIDServerClientID</code> 和反转后的 <code>CFBundleURLSchemes</code>。</li>
<li>Flutter <code>GoogleSignIn.initialize</code>：<code>serverClientId</code> 必须使用 Web Client ID。</li>
<li>Android：包名、实际签名 SHA-1 与 Google Cloud Android 客户端必须一致。</li>
</ul>
<p>iOS URL Scheme 或客户端配置变更后要停止旧调试会话并重新完整构建安装，不要只做热重载。</p>

<h2>五、测试与验收</h2>
<ol>
<li>等待 Google Cloud 配置传播，通常需要几分钟，极端情况可能更久。</li>
<li>使用已加入「测试用户」的 Google 账号，在 App 登录页点「使用 Google 账号登录」。</li>
<li>确认出现 Google 账号选择页，授权后 App 进入已登录状态。</li>
<li>确认 <code>POST /app/help/auth/google</code> 返回成功，且后台会员平台关系中出现 Google 绑定；不能只以「打开了账号选择页」作为成功。</li>
</ol>

<h2>常见错误定位</h2>
<ul>
<li><strong>Google 登录未启用</strong>：检查后台「启用状态」。</li>
<li><strong>Google Client ID 未配置</strong>：检查三个 Client ID 是否保存成功。</li>
<li><strong>Google ID Token 受众不匹配</strong>：对比 App 使用的 iOS/Web Client ID 与后台字段，通常是 Web Client ID 填错或 App 仍使用旧配置。</li>
<li><strong>Android 选账号后取消或 clientConfigurationError</strong>：检查包名、Debug/Release SHA-1 和 Web <code>serverClientId</code>。</li>
<li><strong>iOS 授权后无法回到 App</strong>：检查 Bundle ID、<code>GIDClientID</code> 和反转 URL Scheme，然后重新完整构建。</li>
<li><strong>非测试用户被拒绝</strong>：应用仍在「测试」状态，先把账号加入测试用户；准备对外发布时再评估权限请求页和 Google 验证。</li>
</ul>

<h2>变更安全</h2>
<p>删除或重建正在使用的 OAuth 客户端会让旧 App 立即无法登录。生产环境要先记录原 Client ID、确认回滚方案，再同步修改 Google Cloud、HelpSupport 后台和 Flutter 客户端。不要在操作说明、工单或聊天里粘贴 Client Secret、Cookie 或管理员 Token。</p>
HTML;
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
