<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpOnboardingDemoPages extends AbstractMigration
{
    private const TABLE = 'sa_app_onboarding_page';
    private const MARK_PREFIX = 'demo:onboarding:';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach ($this->pages() as $page) {
            $this->insertPage($page);
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $this->execute(
            'DELETE FROM `' . self::TABLE . '`
             WHERE `scene` = ' . $this->q('first_launch') . '
               AND `version` = ' . $this->q('') . '
               AND `action_value` LIKE ' . $this->q(self::MARK_PREFIX . '%')
        );
    }

    private function insertPage(array $page): void
    {
        $this->execute(
            'INSERT INTO `' . self::TABLE . '` (`scene`, `version`, `locale`, `title`, `description`, `image`, `button_text`, `action_type`, `action_value`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT '
             . $this->q($page['scene']) . ', '
             . $this->q($page['version']) . ', '
             . $this->q($page['locale']) . ', '
             . $this->q($page['title']) . ', '
             . $this->q($page['description']) . ', '
             . $this->q($page['image']) . ', '
             . $this->q($page['button_text']) . ', '
             . $this->q($page['action_type']) . ', '
             . $this->q($page['action_value']) . ', '
             . (int) $page['sort'] . ', 1, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `' . self::TABLE . '`
                 WHERE `scene` = ' . $this->q($page['scene']) . '
                   AND `version` = ' . $this->q($page['version']) . '
                   AND `locale` = ' . $this->q($page['locale']) . '
                   AND `action_value` = ' . $this->q($page['action_value']) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function pages(): array
    {
        $zhPages = [
            [
                'title' => '欢迎来到 HelpSupport',
                'description' => '用清晰的康复计划、医生协作和情绪陪伴，帮你把每天的小目标落到实处。',
                'image' => 'https://picsum.photos/seed/helpsupport-care/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => self::MARK_PREFIX . 'welcome',
                'sort' => 10,
            ],
            [
                'title' => '连接医生与计划',
                'description' => '预约医生、查看治疗阶段和每日任务，把恢复进展同步给专业支持者。',
                'image' => 'https://picsum.photos/seed/helpsupport-plan/900/700',
                'button_text' => '继续',
                'action_type' => 'next',
                'action_value' => self::MARK_PREFIX . 'plan',
                'sort' => 20,
            ],
            [
                'title' => '开启本地陪伴',
                'description' => 'AI 聊天和本地模型入口会在你需要时提供记录、提醒与自助练习。',
                'image' => 'https://picsum.photos/seed/helpsupport-companion/900/700',
                'button_text' => '开始使用',
                'action_type' => 'skip',
                'action_value' => self::MARK_PREFIX . 'start',
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
                'action_value' => self::MARK_PREFIX . 'welcome',
                'sort' => 10,
            ],
            [
                'title' => 'Connect Care And Plans',
                'description' => 'Book appointments, follow treatment stages, and keep your progress visible to your support team.',
                'image' => 'https://picsum.photos/seed/helpsupport-plan/900/700',
                'button_text' => 'Continue',
                'action_type' => 'next',
                'action_value' => self::MARK_PREFIX . 'plan',
                'sort' => 20,
            ],
            [
                'title' => 'Start Local Companion',
                'description' => 'AI chat and local model tools are ready for journaling, reminders, and self-guided exercises.',
                'image' => 'https://picsum.photos/seed/helpsupport-companion/900/700',
                'button_text' => 'Get Started',
                'action_type' => 'skip',
                'action_value' => self::MARK_PREFIX . 'start',
                'sort' => 30,
            ],
        ];

        return [
            ...$this->localizedPages('zh', $zhPages),
            ...$this->localizedPages('zh-CN', $zhPages),
            ...$this->localizedPages('en-US', $enPages),
        ];
    }

    private function localizedPages(string $locale, array $pages): array
    {
        return array_map(
            static fn (array $page): array => [
                'scene' => 'first_launch',
                'version' => '',
                'locale' => $locale,
                ...$page,
            ],
            $pages
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
