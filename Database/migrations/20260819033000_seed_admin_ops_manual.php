<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedAdminOpsManual extends AbstractMigration
{
    private const REMARK = 'phinx:20260819033000_seed_admin_ops_manual';
    private const MARKER = 'audience:admin-manual';
    private const AUTHOR = 'HelpSupport 后台手册';
    private const ROOT_NAME = '后台操作手册';
    private const MENU_CODE = 'saiuser/cms/manual';
    private const MENU_SLUG = 'saiuser:cms:manual:index';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';

    public function up(): void
    {
        $this->seedRootCategory();
        foreach ($this->categories() as $category) {
            $this->seedChildCategory($category);
        }
        foreach ($this->articles() as $article) {
            $this->seedArticle($article);
        }
        $this->insertMenu();
        $this->insertPermission();
        $this->grantMenus();
        $this->clearCaches();
    }

    public function down(): void
    {
        if ($this->hasTable('sa_system_role_menu') && $this->hasTable('sa_system_menu')) {
            $this->execute(
                'DELETE rm FROM `sa_system_role_menu` rm
                 INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
                 WHERE m.`remark` = ' . $this->q(self::REMARK)
            );
        }
        if ($this->hasTable('sa_system_menu')) {
            $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        }
        if ($this->hasTable('sa_article')) {
            $this->execute(
                'DELETE FROM `sa_article`
                 WHERE `link_url` = ' . $this->q(self::MARKER) . '
                   AND `author` = ' . $this->q(self::AUTHOR)
            );
        }
        if ($this->hasTable('sa_article_category')) {
            $this->execute(
                'DELETE c FROM `sa_article_category` c
                 INNER JOIN `sa_article_category` p ON p.`id` = c.`parent_id`
                 WHERE p.`parent_id` = 0
                   AND p.`describe` LIKE ' . $this->q('%' . self::MARKER . '%')
            );
            $this->execute(
                'DELETE FROM `sa_article_category`
                 WHERE `parent_id` = 0
                   AND `describe` LIKE ' . $this->q('%' . self::MARKER . '%')
            );
        }
        $this->clearCaches();
    }

    private function seedRootCategory(): void
    {
        if (!$this->hasTable('sa_article_category')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_article_category` (`parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT 0, ' . $this->q(self::ROOT_NAME) . ', ' . $this->q('仅后台管理员可见，不会出现在用户端帮助中心。' . self::MARKER) . ', NULL, 5, 1, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_article_category`
                 WHERE `parent_id` = 0
                   AND `describe` LIKE ' . $this->q('%' . self::MARKER . '%') . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    /**
     * @param array{name: string, describe: string, sort: int} $category
     */
    private function seedChildCategory(array $category): void
    {
        if (!$this->hasTable('sa_article_category')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_article_category` (`parent_id`, `category_name`, `describe`, `image`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT p.`id`, ' . $this->q($category['name']) . ', ' . $this->q($category['describe']) . ', NULL, ' . (int) $category['sort'] . ', 1, 1, 1, NOW(), NOW(), NULL
             FROM `sa_article_category` p
             WHERE p.`parent_id` = 0
               AND p.`describe` LIKE ' . $this->q('%' . self::MARKER . '%') . '
               AND p.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_article_category` c
                   WHERE c.`parent_id` = p.`id`
                     AND c.`category_name` = ' . $this->q($category['name']) . '
                     AND c.`delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    /**
     * @param array{category: string, title: string, describe: string, content: string, sort: int, hot: int} $article
     */
    private function seedArticle(array $article): void
    {
        if (!$this->hasTable('sa_article') || !$this->hasTable('sa_article_category')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_article` (`category_id`, `title`, `author`, `image`, `describe`, `content`, `views`, `sort`, `status`, `is_link`, `link_url`, `is_hot`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT c.`id`, ' . $this->q($article['title']) . ', ' . $this->q(self::AUTHOR) . ', ' . $this->q('') . ', ' . $this->q($article['describe']) . ', ' . $this->q($article['content']) . ', 0, ' . (int) $article['sort'] . ', 1, 2, ' . $this->q(self::MARKER) . ', ' . (int) $article['hot'] . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_article_category` c
             INNER JOIN `sa_article_category` p ON p.`id` = c.`parent_id`
             WHERE c.`category_name` = ' . $this->q($article['category']) . '
               AND c.`delete_time` IS NULL
               AND p.`parent_id` = 0
               AND p.`describe` LIKE ' . $this->q('%' . self::MARKER . '%') . '
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_article` a
                   WHERE a.`title` = ' . $this->q($article['title']) . '
                     AND a.`link_url` = ' . $this->q(self::MARKER) . '
                     AND a.`delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function insertMenu(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT 0, ' . $this->q('操作说明') . ', ' . $this->q(self::MENU_CODE) . ', NULL, 2, ' . $this->q('/saiuser/cms/manual') . ', ' . $this->q('/plugin/saiuser/cms/manual/index') . ', NULL, ' . $this->q('ri:book-read-line') . ', 78, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_menu`
                 WHERE `code` = ' . $this->q(self::MENU_CODE) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function insertPermission(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q('查看手册') . ', ' . $this->q('') . ', ' . $this->q(self::MENU_SLUG) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q('index') . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu`
             WHERE `code` = ' . $this->q(self::MENU_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `slug` = ' . $this->q(self::MENU_SLUG) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function grantMenus(): void
    {
        if (!$this->hasTable('sa_system_role_menu') || !$this->hasTable('sa_system_role') || !$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`delete_time` IS NULL
               AND rm.`id` IS NULL
               AND m.`remark` = ' . $this->q(self::REMARK) . '
               AND (
                   r.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
                   OR EXISTS (
                       SELECT 1 FROM `sa_system_role_menu` existing
                       INNER JOIN `sa_system_menu` source ON source.`id` = existing.`menu_id`
                       WHERE existing.`role_id` = r.`id`
                         AND source.`delete_time` IS NULL
                         AND source.`code` IN (' . $this->q('Cms') . ', ' . $this->q('cms/article') . ', ' . $this->q('help/config') . ')
                   )
               )'
        );
    }

    private function clearCaches(): void
    {
        try {
            if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
                \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
            }
            if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
                \plugin\saiadmin\app\cache\UserAuthCache::clear();
            }
        } catch (\Throwable) {
            // 缓存清理失败不阻断迁移，管理员重新登录后仍可刷新权限。
        }
    }

    /**
     * @return list<array{name: string, describe: string, sort: int}>
     */
    private function categories(): array
    {
        return [
            ['name' => '入门与权限', 'describe' => '登录、角色权限、菜单缓存和日常操作注意点。', 'sort' => 10],
            ['name' => '运营配置', 'describe' => '运行配置、引导页和 App 下载入口说明。', 'sort' => 20],
            ['name' => '社区与素材', 'describe' => '社区帖子、评论举报和素材审核操作说明。', 'sort' => 30],
            ['name' => 'AI 与模型', 'describe' => 'AI 伴聊、机器人形象和本地模型管理说明。', 'sort' => 40],
            ['name' => '治疗计划与医生', 'describe' => '康复计划、每日任务、医生认证和预约协作说明。', 'sort' => 50],
            ['name' => '消息推送与风控', 'describe' => '推送模板、敏感词、徽章和用户成长数据说明。', 'sort' => 60],
            ['name' => '帮助内容维护', 'describe' => '用户端帮助中心与本手册的维护边界。', 'sort' => 70],
        ];
    }

    /**
     * @return list<array{category: string, title: string, describe: string, content: string, sort: int, hot: int}>
     */
    private function articles(): array
    {
        return [
            [
                'category' => '入门与权限',
                'title' => '后台登录、角色与菜单权限',
                'describe' => '说明超级管理员、运营管理员如何进入后台，以及菜单不显示时该如何处理。',
                'content' => $this->htmlLogin(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '入门与权限',
                'title' => '日常操作注意点',
                'describe' => '状态值、软删除、敏感信息和发布后验证的基本约定。',
                'content' => $this->htmlDaily(),
                'sort' => 20,
                'hot' => 2,
            ],
            [
                'category' => '运营配置',
                'title' => '运行配置、引导页与 App 下载',
                'describe' => '介绍运营配置、引导页和商店/TestFlight 下载链接的维护位置。',
                'content' => $this->htmlConfig(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '社区与素材',
                'title' => '社区帖子、评论与举报处理',
                'describe' => '说明社区内容审核、评论处理和举报跟进的操作路径。',
                'content' => $this->htmlCommunity(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '社区与素材',
                'title' => '素材内容、娱乐素材与私密素材审核',
                'describe' => '介绍公开素材、娱乐素材、评论举报和私密素材审核入口。',
                'content' => $this->htmlMaterial(),
                'sort' => 20,
                'hot' => 2,
            ],
            [
                'category' => 'AI 与模型',
                'title' => 'AI 伴聊、机器人形象与本地模型',
                'describe' => '说明伴聊配置、会话记录、机器人形象和本地模型目录的管理方式。',
                'content' => $this->htmlAi(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '治疗计划与医生',
                'title' => '康复计划、每日任务与评估量表',
                'describe' => '介绍治疗计划、阶段、每日任务和评估结果的后台查看方式。',
                'content' => $this->htmlPlan(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '治疗计划与医生',
                'title' => '医生认证、患者绑定与预约协作',
                'describe' => '说明医生资料审核、患者关系、排班和预约处理流程。',
                'content' => $this->htmlDoctor(),
                'sort' => 20,
                'hot' => 2,
            ],
            [
                'category' => '消息推送与风控',
                'title' => '消息推送、敏感词与用户成长',
                'describe' => '介绍推送模板、设备、敏感词规则、徽章和日记回忆录等数据入口。',
                'content' => $this->htmlPush(),
                'sort' => 10,
                'hot' => 1,
            ],
            [
                'category' => '帮助内容维护',
                'title' => '如何维护用户帮助中心和本手册',
                'describe' => '区分用户端帮助中心与后台操作手册，避免两类内容互相混入。',
                'content' => $this->htmlHelp(),
                'sort' => 10,
                'hot' => 1,
            ],
        ];
    }

    private function htmlLogin(): string
    {
        return '<h2>谁可以进入后台</h2>
<p>HelpSupport 后台使用 SaiAdmin 账号登录。超级管理员（用户 ID 为 1）可以看到全部菜单，不校验按钮权限；普通管理员按角色授权显示菜单。</p>
<p>系统预置了「HelpSupport运营管理员」角色，适合日常审核、配置和内容运营，不建议把超级管理员账号分给多人使用。</p>
<h2>菜单不显示时先查这几项</h2>
<ul>
<li>当前账号是否已分配对应角色。</li>
<li>角色是否勾选了目标菜单和按钮权限。</li>
<li>保存角色权限后，清一次菜单/权限缓存，并重新登录。</li>
</ul>
<p>权限改完后页面仍是旧菜单，通常是缓存或旧登录会话未刷新，不是代码没生效。</p>
<h2>建议</h2>
<p>不要多人共用同一后台账号。涉及医生审核、素材审核、社区处理时，尽量使用可追溯到个人的运营账号。</p>';
    }

    private function htmlDaily(): string
    {
        return '<h2>状态和删除</h2>
<p>后台大多数业务状态沿用字典：1 启用/正常，2 禁用。删除通常是软删除，列表里看不到不代表数据库物理删除。</p>
<p>处理社区、素材、评论时，先确认当前筛选条件，避免把“待审核”和“已屏蔽”数据弄混。</p>
<h2>敏感信息</h2>
<ul>
<li>不要在配置、备注、推送文案里填写真实密码、Token、完整证件照片。</li>
<li>反馈和日志里如果出现 Bearer、Cookie、验证码，按脱敏后的内容处理。</li>
<li>生产环境改数据库、执行迁移、覆盖安装前，必须先确认备份和回滚窗口。</li>
</ul>
<h2>改完以后怎么验证</h2>
<p>后台页面改菜单或权限后，重新登录再看。后端接口或配置变更后，Webman 是常驻进程，需要 reload/restart 后再验证，不要只刷新浏览器。</p>';
    }

    private function htmlConfig(): string
    {
        return '<h2>运行配置</h2>
<p>入口在「运营配置 / 运行配置」。这里集中维护登录、推送、AI 审核等运行开关，适合做环境级调整，不适合把一次性业务数据写进去。</p>
<p>保存后如果客户端没变化，先确认当前改的是哪套环境，再让 App 重新进入对应页面拉取配置。</p>
<h2>引导页</h2>
<p>入口在「运营配置」下的引导页管理。引导页面向用户端首次进入，请同时检查简体中文和英文内容，避免只改了一边。</p>
<h2>App 下载</h2>
<p>入口在「运营配置 / App 下载」。可维护商店链接、安装包和 TestFlight 公共/内部测试链接。链接留空时，用户端对应入口不会展示有效跳转。</p>
<p>上传安装包前确认文件类型已允许；不要把测试包和正式包链接填反。</p>';
    }

    private function htmlCommunity(): string
    {
        return '<h2>社区内容在哪里处理</h2>
<p>「社区管理」下可以处理帖子、评论、举报和标签。帖子和评论可能经过 AI 审核，后台仍需要人工复核明显误判、投诉和风险内容。</p>
<h2>建议处理顺序</h2>
<ol>
<li>先看举报列表，确认被举报内容和原因。</li>
<li>再打开原帖或原评论，核对上下文，不要只看摘要。</li>
<li>按实际情况通过、屏蔽、删除或继续观察，并保留处理记录。</li>
</ol>
<p>涉及人身安全、自伤或违法线索时，不要只在系统里点状态，应同步走线下应急流程。</p>
<h2>标签</h2>
<p>社区标签用于内容分类和关注关系。修改标签名称前，先确认是否已有帖子或用户在使用，避免前台分类突然错位。</p>';
    }

    private function htmlMaterial(): string
    {
        return '<h2>素材后台入口</h2>
<ul>
<li>素材内容：公开学习/康复内容。</li>
<li>娱乐素材：音乐等娱乐向内容，可能带歌词元数据。</li>
<li>素材分类：固定分类不要随意改名或删除。</li>
<li>素材评论 / 素材举报：用户反馈入口。</li>
<li>私密素材：需要审核后才能进入公开或指定可见范围。</li>
</ul>
<h2>审核注意</h2>
<p>私密素材和个人上传内容优先看来源、分类和敏感信息。不要把仅用于内部测试的内容直接标成对全部用户可见。</p>
<p>多语言字段如果同时存在中英文，请一起维护摘要和正文，避免 App 在英文环境下露出中文占位或空白。</p>';
    }

    private function htmlAi(): string
    {
        return '<h2>AI 伴聊</h2>
<p>「AI与模型」下可以查看伴聊配置、会话和聊天记录。医生模式通常有更严格的提示词和在线模型约束，不要把伴聊配置改成完全开放的自由对话。</p>
<p>查看聊天记录时注意脱敏，不要把完整对话复制到外部群或工单附件，除非已经去掉身份信息和敏感内容。</p>
<h2>机器人形象</h2>
<p>机器人形象会影响用户端展示名称、头像和介绍。修改后如果 App 仍显示旧形象，让用户重新进入聊天页或重启 App。</p>
<h2>本地模型</h2>
<p>本地模型目录、下载记录和提示词在「AI与模型」中维护。目录变更会影响用户能否下载和运行模型，测试模型不要标成默认生产模型。</p>
<p>提示词用于约束回复风格和安全边界。医生相关提示词不要对普通运营角色开放自由编辑。</p>';
    }

    private function htmlPlan(): string
    {
        return '<h2>计划结构</h2>
<p>康复计划通常包含计划、阶段、每日任务和评估结果。后台入口在「治疗计划」：</p>
<ul>
<li>治疗计划：查看患者当前计划。</li>
<li>治疗阶段：阶段目标和顺序。</li>
<li>每日任务：当天任务、完成状态和患者反馈。</li>
<li>评估结果：量表结果，只用于康复跟踪，不替代临床诊断。</li>
</ul>
<h2>操作建议</h2>
<p>不要直接删除仍在执行中的计划或阶段。需要调整时，优先停用、改状态或让医生在医生端更新，避免患者端当天任务突然消失。</p>
<p>任务模板在医生服务里维护，计划和任务实例在治疗计划里查看。两者不要当成同一张表来改。</p>';
    }

    private function htmlDoctor(): string
    {
        return '<h2>医生认证</h2>
<p>医生使用专业功能前需要提交认证资料，后台在「医生服务」中审核。审核通过前，不要手动把普通会员改成可接诊状态，除非你明确知道当前数据来源。</p>
<h2>患者与预约</h2>
<ul>
<li>患者列表：查看绑定关系、计划和基础资料。</li>
<li>医生排班：预约可选择的时间。</li>
<li>医生预约：确认、完成、拒绝或取消。</li>
<li>任务模板 / 模板目录：医生给患者布置任务时使用。</li>
</ul>
<p>处理预约时把状态变更原因留清楚。涉及医疗建议的内容以医生端记录为准，后台只做协作和审计，不代替诊疗。</p>';
    }

    private function htmlPush(): string
    {
        return '<h2>消息推送</h2>
<p>「消息推送」下可以维护推送模板、设备、偏好和会员消息。改模板前先确认语言、跳转目标和发送对象，避免把测试文案发给正式用户。</p>
<p>设备列表用于排查通知未送达。先看系统通知权限、设备是否仍注册，再查模板和发送记录。</p>
<h2>风控与成长</h2>
<ul>
<li>敏感词规则：社区、评论和部分文本入口会用到。</li>
<li>徽章 / 徽章规则 / 积分记录：用户成长激励，不代表医疗结果。</li>
<li>日记、回忆录、康复目标、触发因素：用户自己的记录，后台以查看和问题排查为主。</li>
</ul>
<p>风控规则过严会造成误伤，过松会漏掉风险内容。调整后用几条真实样本回归，不要只看规则条数。</p>';
    }

    private function htmlHelp(): string
    {
        return '<h2>两类内容不要混</h2>
<p>用户端帮助中心和本手册都使用内置 CMS（帮助分类 / 帮助文章），但面向的人不同：</p>
<ul>
<li>用户帮助中心：给患者、医生在 App 里阅读，分类如「账号与资料」「AI 伴聊与本地模型」等。</li>
<li>后台操作手册：给管理员在本页阅读，分类都挂在「后台操作手册」下面。</li>
</ul>
<p>用户端接口会自动排除带管理员手册标记的分类和文章，所以不要把后台操作步骤写进用户帮助分类。</p>
<h2>怎么改这份手册</h2>
<ol>
<li>打开「用户帮助中心 / 帮助分类」，确认「后台操作手册」及其子分类存在。</li>
<li>打开「帮助文章」，按子分类新增或修改文章，作者可保持「HelpSupport 后台手册」。</li>
<li>文章状态必须是启用，本页才会显示。</li>
<li>不要把手册文章的外链标记改掉，那是用来和用户端帮助隔离的内部标记。</li>
</ol>
<p>改完后回到左侧「操作说明」刷新即可。如果用户 App 里突然出现后台手册，说明分类被挪出了「后台操作手册」，或内部标记被删掉了，需要立刻改回。</p>';
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
