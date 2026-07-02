<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateSaiuserCmsHelpCenterContent extends AbstractMigration
{
    /**
     * @var array<int, array{name: string, icon: string}>
     */
    private const HELP_MENUS = [
        1057 => ['name' => '用户帮助中心', 'icon' => 'ri:question-answer-line'],
        1058 => ['name' => '帮助分类', 'icon' => 'ri:folder-2-line'],
        1064 => ['name' => '帮助轮播', 'icon' => 'ri:image-2-line'],
        1070 => ['name' => '帮助文章', 'icon' => 'ri:article-line'],
    ];

    /**
     * @var array<int, array{name: string, describe: string, sort: int}>
     */
    private const HELP_CATEGORIES = [
        1 => ['name' => '账号与资料', 'describe' => '注册登录、身份选择、个人资料、隐私与通知等基础使用说明。', 'sort' => 10],
        2 => ['name' => 'AI 伴聊与本地模型', 'describe' => '在线 AI 伴聊、本地模型、提示词配置和隐私边界说明。', 'sort' => 20],
        3 => ['name' => '康复计划与任务', 'describe' => '康复目标、每日任务、评估量表、情绪日记和触发因素记录说明。', 'sort' => 30],
        4 => ['name' => '医生协作与反馈', 'describe' => '医生认证、患者绑定、预约咨询、诊疗协作和问题反馈说明。', 'sort' => 40],
    ];

    /**
     * @var array<int, array{category_id: int, title: string, describe: string, content: string, sort: int, hot: int}>
     */
    private const HELP_ARTICLES = [
        1 => [
            'category_id' => 1,
            'title' => '首次使用 HelpSupport：注册、登录与角色选择',
            'describe' => '说明患者、医生等不同角色首次进入系统时的注册、登录、身份选择和基础资料完善流程。',
            'content' => '<p>HelpSupport 面向患者、医生和运营管理员提供不同入口。首次使用时，请先完成账号注册或第三方登录，并根据实际身份选择患者或医生角色。</p><p>患者侧主要用于 AI 伴聊、康复计划、每日任务、情绪记录和内容学习；医生侧主要用于患者绑定、计划制定、任务跟进和预约协作。</p><p>如果系统提示登录状态失效，请重新登录后再继续操作；为了账号安全，不建议多人共用同一个账号。</p>',
            'sort' => 10,
            'hot' => 1,
        ],
        2 => [
            'category_id' => 1,
            'title' => '个人资料、隐私与通知设置说明',
            'describe' => '介绍如何维护个人资料、调整隐私展示、管理推送通知和本地提醒。',
            'content' => '<p>在“我的”和“设置”页面中，可以维护昵称、头像、基础资料、隐私展示和通知偏好。</p><p>通知设置会影响康复任务提醒、日记提醒、系统消息和医生协作消息。部分提醒来自服务端推送，部分提醒由本机本地通知完成。</p><p>如果修改后没有立即生效，请重新进入设置页确认当前状态，并检查手机系统通知权限是否已允许。</p>',
            'sort' => 20,
            'hot' => 2,
        ],
        3 => [
            'category_id' => 2,
            'title' => 'AI 伴聊在线模式与本地模式有什么区别',
            'describe' => '解释在线 AI 伴聊、本地模型运行、医生模式限制以及隐私和能力差异。',
            'content' => '<p>在线模式使用服务器侧能力，适合需要更完整理解、连续对话和医生模式规则约束的场景。</p><p>本地模式会在设备上运行已下载模型，更适合隐私敏感或弱网场景，但能力、速度和可用功能会受设备性能与模型大小影响。</p><p>医生模式默认使用在线能力，以保证回复质量和业务规则一致；患者和陪伴场景可根据系统配置选择在线或本地模式。</p>',
            'sort' => 10,
            'hot' => 1,
        ],
        4 => [
            'category_id' => 2,
            'title' => '如何下载本地模型并管理提示词',
            'describe' => '说明本地模型目录、下载记录、运行检测和提示词调整的基本规则。',
            'content' => '<p>本地模型需要先在模型目录中选择并下载。下载完成后，系统会记录模型文件、大小、量化等级和运行状态。</p><p>提示词用于限定 AI 回复风格和业务边界。普通伴聊可按系统允许范围调整提示词；医生模式为了保证一致性，通常不开放自由编辑。</p><p>如果模型无法运行，请检查设备剩余空间、模型文件是否完整，以及当前设备是否满足最低内存要求。</p>',
            'sort' => 20,
            'hot' => 2,
        ],
        5 => [
            'category_id' => 3,
            'title' => '如何查看康复计划和完成每日任务',
            'describe' => '介绍康复计划、阶段目标、每日任务、积分和完成状态的使用方式。',
            'content' => '<p>康复计划由阶段、目标和每日任务组成。你可以在计划页面查看当前阶段、今日任务、任务说明和完成状态。</p><p>完成任务后，按页面提示提交状态或反馈。部分任务可能需要填写感受、上传记录或等待医生查看。</p><p>积分、徽章和连续完成情况只用于鼓励坚持，不代表医疗诊断结果。如任务内容与医生建议冲突，请以医生建议为准。</p>',
            'sort' => 10,
            'hot' => 1,
        ],
        6 => [
            'category_id' => 3,
            'title' => '如何记录情绪日记、触发因素和康复目标',
            'describe' => '说明日记、触发因素、康复目标和复诊准备信息如何帮助复盘。',
            'content' => '<p>情绪日记用于记录每天的状态变化、睡眠、情绪波动和关键事件。触发因素用于标记容易影响状态的场景或事件。</p><p>康复目标可以拆成短期目标和阶段目标，方便自己和医生持续跟踪。建议记录具体、可观察的变化，而不是只写模糊感受。</p><p>复诊前可以回看一周记录，把最明显的变化、稳定出现的触发点和想问医生的问题整理出来。</p>',
            'sort' => 20,
            'hot' => 2,
        ],
        7 => [
            'category_id' => 4,
            'title' => '医生认证、绑定患者与预约咨询流程',
            'describe' => '介绍医生提交认证、患者绑定、计划管理和预约处理的主要流程。',
            'content' => '<p>医生使用专业功能前需要提交认证资料，平台审核通过后才能进入医生工作台。</p><p>医生可在患者列表中管理已绑定患者，查看基础资料、康复计划、每日任务、评估结果和预约状态。</p><p>预约咨询需要按系统状态处理确认、完成、拒绝或取消。涉及医疗建议时，请保持记录清晰，便于患者后续回看。</p>',
            'sort' => 10,
            'hot' => 1,
        ],
        8 => [
            'category_id' => 4,
            'title' => '遇到问题时如何提交反馈和获取支持',
            'describe' => '说明遇到登录、内容、通知、AI 伴聊或医生协作问题时应如何反馈。',
            'content' => '<p>如果遇到登录失败、页面异常、通知未送达、AI 回复不符合预期或医生协作流程异常，请先记录发生时间、账号角色、页面位置和操作步骤。</p><p>在后台排查时，系统会优先查看请求记录、错误日志、菜单权限和相关业务数据。请不要在反馈中提交密码、验证码、Token 或完整身份证件照片。</p><p>紧急医疗或安全风险不应只依赖系统反馈入口，请及时联系医生、家属或当地紧急服务。</p>',
            'sort' => 20,
            'hot' => 2,
        ],
    ];

    /**
     * @var array<int, array{name: string, icon: string}>
     */
    private const LEGACY_MENUS = [
        1057 => ['name' => '帮助与反馈', 'icon' => 'ri:file-copy-2-line'],
        1058 => ['name' => '帮助分类', 'icon' => 'ri:home-2-line'],
        1064 => ['name' => '轮播列表', 'icon' => 'ri:home-2-line'],
        1070 => ['name' => '帮助内容', 'icon' => 'ri:home-2-line'],
    ];

    /**
     * @var array<int, array{name: string, describe: string, sort: int}>
     */
    private const LEGACY_CATEGORIES = [
        1 => ['name' => '大国科技', 'describe' => '', 'sort' => 100],
        2 => ['name' => '数字经济', 'describe' => '', 'sort' => 100],
        3 => ['name' => '科技快讯', 'describe' => '', 'sort' => 100],
        4 => ['name' => '低空经济', 'describe' => '', 'sort' => 100],
    ];

    /**
     * @var array<int, array{category_id: int, title: string, describe: string}>
     */
    private const LEGACY_ARTICLES = [
        1 => ['category_id' => 1, 'title' => '科技为农业强国建设插上腾飞之翼', 'describe' => '“十四五”规划提出，完善农业科技创新体系，创新农技推广服务方式，建设智慧农业。'],
        2 => ['category_id' => 1, 'title' => '商业航天稳步快跑 “太空旅游”渐行渐近', 'describe' => '业界普遍认为，以可复用火箭为代表的核心技术突破是商业航天提速的关键支撑。'],
        3 => ['category_id' => 2, 'title' => '以数字经济为引擎加快推进中国式现代化', 'describe' => '随着中国式现代化不断向前推进，中国迎来了数字经济发展的新机遇。'],
        4 => ['category_id' => 2, 'title' => '2025腾讯全球数字生态大会在深圳举行', 'describe' => '旧演示文章摘要，已被 HelpSupport 帮助中心内容替换。'],
        5 => ['category_id' => 3, 'title' => '秀我中国丨中国小机器人“勇闯”美国CES', 'describe' => '旧演示文章摘要，已被 HelpSupport 帮助中心内容替换。'],
        6 => ['category_id' => 3, 'title' => 'AI助力药物虚拟筛选提速百万倍 开启后AlphaFold时代创新药', 'describe' => '旧演示文章摘要，已被 HelpSupport 帮助中心内容替换。'],
        7 => ['category_id' => 4, 'title' => '高度重视低空经济为哪般', 'describe' => '旧演示文章摘要，已被 HelpSupport 帮助中心内容替换。'],
        8 => ['category_id' => 4, 'title' => '国家发改委成立低空经济发展司', 'describe' => '旧演示文章摘要，已被 HelpSupport 帮助中心内容替换。'],
    ];

    public function up(): void
    {
        $this->updateMenus(self::HELP_MENUS);
        $this->updateCategories(self::HELP_CATEGORIES);
        $this->updateArticles(self::HELP_ARTICLES);
    }

    public function down(): void
    {
        $this->updateMenus(self::LEGACY_MENUS);
        $this->updateCategories(self::LEGACY_CATEGORIES);
        $this->restoreLegacyArticles();
    }

    /**
     * @param array<int, array{name: string, icon: string}> $menus
     */
    private function updateMenus(array $menus): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ($menus as $id => $menu) {
            $this->execute(
                'UPDATE `sa_system_menu`
                SET `name` = ' . $this->q($menu['name']) . ',
                    `icon` = ' . $this->q($menu['icon']) . ',
                    `updated_by` = 1,
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $id . ' AND `delete_time` IS NULL'
            );
        }
    }

    /**
     * @param array<int, array{name: string, describe: string, sort: int}> $categories
     */
    private function updateCategories(array $categories): void
    {
        if (!$this->hasTable('sa_article_category')) {
            return;
        }

        foreach ($categories as $id => $category) {
            $this->execute(
                'UPDATE `sa_article_category`
                SET `category_name` = ' . $this->q($category['name']) . ',
                    `describe` = ' . $this->q($category['describe']) . ',
                    `sort` = ' . (int) $category['sort'] . ',
                    `status` = 1,
                    `updated_by` = 1,
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $id . ' AND `delete_time` IS NULL'
            );
        }
    }

    /**
     * @param array<int, array{category_id: int, title: string, describe: string, content: string, sort: int, hot: int}> $articles
     */
    private function updateArticles(array $articles): void
    {
        if (!$this->hasTable('sa_article')) {
            return;
        }

        foreach ($articles as $id => $article) {
            $this->execute(
                'UPDATE `sa_article`
                SET `category_id` = ' . (int) $article['category_id'] . ',
                    `title` = ' . $this->q($article['title']) . ',
                    `author` = ' . $this->q('HelpSupport 团队') . ',
                    `describe` = ' . $this->q($article['describe']) . ',
                    `content` = ' . $this->q($article['content']) . ',
                    `sort` = ' . (int) $article['sort'] . ',
                    `status` = 1,
                    `is_link` = 2,
                    `link_url` = ' . $this->q('') . ',
                    `is_hot` = ' . (int) $article['hot'] . ',
                    `updated_by` = 1,
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $id . ' AND `delete_time` IS NULL'
            );
        }
    }

    private function restoreLegacyArticles(): void
    {
        if (!$this->hasTable('sa_article')) {
            return;
        }

        foreach (self::LEGACY_ARTICLES as $id => $article) {
            $this->execute(
                'UPDATE `sa_article`
                SET `category_id` = ' . (int) $article['category_id'] . ',
                    `title` = ' . $this->q($article['title']) . ',
                    `author` = ' . $this->q('新华网') . ',
                    `describe` = ' . $this->q($article['describe']) . ',
                    `content` = ' . $this->q('<p>旧演示长文正文已由 HelpSupport 帮助中心内容替换，本迁移回滚不恢复旧第三方长文。</p>') . ',
                    `sort` = 100,
                    `status` = 1,
                    `is_link` = 2,
                    `link_url` = ' . $this->q('') . ',
                    `is_hot` = 2,
                    `updated_by` = 1,
                    `update_time` = NOW()
                WHERE `id` = ' . (int) $id . ' AND `delete_time` IS NULL'
            );
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
