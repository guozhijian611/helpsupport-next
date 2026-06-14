<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateHelpOnboardingDefaultZhPages extends AbstractMigration
{
    public function up(): void
    {
        foreach (['zh', 'zh-CN'] as $locale) {
            foreach ($this->currentPages() as $page) {
                $this->upsertPage($locale, $page);
            }
        }
    }

    public function down(): void
    {
        foreach (['zh', 'zh-CN'] as $locale) {
            foreach ($this->demoPages() as $page) {
                $this->upsertPage($locale, $page);
            }
        }
    }

    /**
     * @param array<string, int|string> $page
     */
    private function upsertPage(string $locale, array $page): void
    {
        $this->execute(
            'UPDATE `sa_app_onboarding_page`
             SET `title` = ' . $this->q($page['title']) . ',
                 `description` = ' . $this->q($page['description']) . ',
                 `image` = ' . $this->q($page['image']) . ',
                 `button_text` = ' . $this->q($page['button_text']) . ',
                 `action_type` = ' . $this->q($page['action_type']) . ',
                 `action_value` = ' . $this->q($page['action_value']) . ',
                 `status` = 1,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `scene` = ' . $this->q('first_launch') . '
               AND `version` = ' . $this->q('') . '
               AND `locale` = ' . $this->q($locale) . '
               AND `sort` = ' . (int) $page['sort'] . '
               AND `delete_time` IS NULL'
        );

        $this->execute(
            'INSERT INTO `sa_app_onboarding_page` (`scene`, `version`, `locale`, `title`, `description`, `image`, `button_text`, `action_type`, `action_value`, `sort`, `status`, `start_time`, `end_time`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q('first_launch') . ', ' . $this->q('') . ', ' . $this->q($locale) . ', ' . $this->q($page['title']) . ', ' . $this->q($page['description']) . ', ' . $this->q($page['image']) . ', ' . $this->q($page['button_text']) . ', ' . $this->q($page['action_type']) . ', ' . $this->q($page['action_value']) . ', ' . (int) $page['sort'] . ', 1, NULL, NULL, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_app_onboarding_page`
                 WHERE `scene` = ' . $this->q('first_launch') . '
                   AND `version` = ' . $this->q('') . '
                   AND `locale` = ' . $this->q($locale) . '
                   AND `sort` = ' . (int) $page['sort'] . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    /**
     * @return array<int, array<string, int|string>>
     */
    private function currentPages(): array
    {
        return [
            [
                'sort' => 10,
                'title' => '通往新生，每一步都算数',
                'description' => '“每一次认真的自我评估，都是向内观照的足迹；每一份被记录的情绪数据，都在描绘你康复的轨迹”',
                'image' => 'https://r2.openb8.com/openb8/helpsupport/c2688de2e90ee6e207d38c48695b8ce1.png',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => '',
            ],
            [
                'sort' => 20,
                'title' => '戒断，是告别，更是开始',
                'description' => '“告别过去的挣扎，开始科学的康复。洞察自身变化，在医生的指引下，主动掌控健康。”',
                'image' => 'https://r2.openb8.com/openb8/helpsupport/41a662486cab2447470d695cf1f1e27d.png',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => '',
            ],
            [
                'sort' => 30,
                'title' => '你的康复之路，不再独行',
                'description' => '“你的每一条记录，医生都在云端关切；你的每一次波动，都有专业工具为你解读。我们，是你24小时在线的支持系统。”',
                'image' => 'https://r2.openb8.com/openb8/helpsupport/866a78dfcfdbf3cc84241ed132aa3d72.png',
                'button_text' => '开启个人定制专属陪伴',
                'action_type' => 'skip',
                'action_value' => '',
            ],
        ];
    }

    /**
     * @return array<int, array<string, int|string>>
     */
    private function demoPages(): array
    {
        return [
            [
                'sort' => 10,
                'title' => '欢迎来到 HelpSupport',
                'description' => '用清晰的康复计划、医生协作和情绪陪伴，帮你把每天的小目标落到实处。',
                'image' => 'https://picsum.photos/seed/helpsupport-care/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:welcome',
            ],
            [
                'sort' => 20,
                'title' => '连接医生与计划',
                'description' => '预约医生、查看治疗阶段和每日任务，把恢复进展同步给专业支持者。',
                'image' => 'https://picsum.photos/seed/helpsupport-plan/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:plan',
            ],
            [
                'sort' => 30,
                'title' => '开启本地陪伴',
                'description' => 'AI 聊天和本地模型入口会在你需要时提供记录、提醒与自助练习。',
                'image' => 'https://picsum.photos/seed/helpsupport-companion/900/700',
                'button_text' => '开始使用',
                'action_type' => 'skip',
                'action_value' => 'demo:onboarding:start',
            ],
        ];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
