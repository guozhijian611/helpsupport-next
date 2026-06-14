<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpOnboardingDemoPages extends AbstractMigration
{
    public function up(): void
    {
        foreach ($this->pages() as $page) {
            $this->execute(
                'INSERT INTO `sa_app_onboarding_page` (`scene`, `version`, `locale`, `title`, `description`, `image`, `button_text`, `action_type`, `action_value`, `sort`, `status`, `start_time`, `end_time`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT ' . $this->q($page['scene']) . ', ' . $this->q($page['version']) . ', ' . $this->q($page['locale']) . ', ' . $this->q($page['title']) . ', ' . $this->q($page['description']) . ', ' . $this->q($page['image']) . ', ' . $this->q($page['button_text']) . ', ' . $this->q($page['action_type']) . ', ' . $this->q($page['action_value']) . ', ' . (int) $page['sort'] . ', 1, NULL, NULL, 1, 1, NOW(), NOW(), NULL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM `sa_app_onboarding_page`
                     WHERE `scene` = ' . $this->q($page['scene']) . '
                       AND `version` = ' . $this->q($page['version']) . '
                       AND `locale` = ' . $this->q($page['locale']) . '
                       AND `action_value` = ' . $this->q($page['action_value']) . '
                       AND `delete_time` IS NULL
                 )'
            );
        }
    }

    public function down(): void
    {
        $this->execute("DELETE FROM `sa_app_onboarding_page` WHERE `action_value` LIKE 'demo:onboarding:%'");
    }

    /**
     * @return array<int, array<string, int|string>>
     */
    private function pages(): array
    {
        $zhPages = [
            [
                'title' => '欢迎来到 HelpSupport',
                'description' => '用清晰的康复计划、医生协作和情绪陪伴，帮你把每天的小目标落到实处。',
                'image' => 'https://picsum.photos/seed/helpsupport-care/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:welcome',
                'sort' => 10,
            ],
            [
                'title' => '连接医生与计划',
                'description' => '预约医生、查看治疗阶段和每日任务，把恢复进展同步给专业支持者。',
                'image' => 'https://picsum.photos/seed/helpsupport-plan/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:plan',
                'sort' => 20,
            ],
            [
                'title' => '开启本地陪伴',
                'description' => 'AI 聊天和本地模型入口会在你需要时提供记录、提醒与自助练习。',
                'image' => 'https://picsum.photos/seed/helpsupport-companion/900/700',
                'button_text' => '开始使用',
                'action_type' => 'skip',
                'action_value' => 'demo:onboarding:start',
                'sort' => 30,
            ],
        ];

        $enPages = [
            [
                'title' => 'Welcome to HelpSupport',
                'description' => 'Keep recovery plans, doctor collaboration, and emotional support in one daily workspace.',
                'image' => 'https://picsum.photos/seed/helpsupport-care/900/700',
                'button_text' => 'Continue',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:welcome',
                'sort' => 10,
            ],
            [
                'title' => 'Connect Care And Plans',
                'description' => 'Book appointments, follow treatment stages, and keep your progress visible to your support team.',
                'image' => 'https://picsum.photos/seed/helpsupport-plan/900/700',
                'button_text' => 'Continue',
                'action_type' => 'next',
                'action_value' => 'demo:onboarding:plan',
                'sort' => 20,
            ],
            [
                'title' => 'Start Local Companion',
                'description' => 'AI chat and local model tools are ready for journaling, reminders, and self-guided exercises.',
                'image' => 'https://picsum.photos/seed/helpsupport-companion/900/700',
                'button_text' => 'Get Started',
                'action_type' => 'skip',
                'action_value' => 'demo:onboarding:start',
                'sort' => 30,
            ],
        ];

        $pages = [];
        foreach (['zh', 'zh-CN'] as $locale) {
            foreach ($zhPages as $page) {
                $pages[] = $this->withLocale($page, $locale);
            }
        }
        foreach ($enPages as $page) {
            $pages[] = $this->withLocale($page, 'en-US');
        }

        return $pages;
    }

    /**
     * @param array<string, int|string> $page
     * @return array<string, int|string>
     */
    private function withLocale(array $page, string $locale): array
    {
        return array_merge([
            'scene' => 'first_launch',
            'version' => '',
            'locale' => $locale,
        ], $page);
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
