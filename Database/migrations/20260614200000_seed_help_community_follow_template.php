<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpCommunityFollowTemplate extends AbstractMigration
{
    private const TABLE = 'sa_push_template';
    private const REMARK = 'phinx:20260614200000_seed_help_community_follow_template';

    public function up(): void
    {
        foreach ($this->templates() as $template) {
            $this->execute(
                'INSERT INTO `' . self::TABLE . '` (`template_code`, `template_name`, `scene`, `locale`, `message_type`, `title`, `content`, `route`, `payload`, `is_default`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT ' . $this->q($template['template_code']) . ', ' . $this->q($template['template_name']) . ', ' . $this->q($template['scene']) . ', ' . $this->q($template['locale']) . ', ' . (int) $template['message_type'] . ', ' . $this->q($template['title']) . ', ' . $this->q($template['content']) . ', ' . $this->q($template['route']) . ', ' . $this->q($template['payload']) . ', 1, ' . (int) $template['sort'] . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `' . self::TABLE . '`
                    WHERE `template_code` = ' . $this->q($template['template_code']) . '
                      AND `locale` = ' . $this->q($template['locale']) . '
                )'
            );
        }
    }

    public function down(): void
    {
        $this->execute(
            'DELETE FROM `' . self::TABLE . '`
            WHERE `template_code` = ' . $this->q('community_follow') . '
              AND `remark` = ' . $this->q(self::REMARK)
        );
    }

    private function templates(): array
    {
        return [
            [
                'template_code' => 'community_follow',
                'template_name' => '社区新关注',
                'scene' => 'community_follow',
                'locale' => 'zh-CN',
                'message_type' => 1,
                'title' => '你有新的关注者',
                'content' => '{nickname} 关注了你',
                'route' => '/pages/community/profile',
                'payload' => '{"scene":"community_follow"}',
                'sort' => 25,
            ],
            [
                'template_code' => 'community_follow',
                'template_name' => 'New Follower',
                'scene' => 'community_follow',
                'locale' => 'en-US',
                'message_type' => 1,
                'title' => 'New follower',
                'content' => '{nickname} followed you',
                'route' => '/pages/community/profile',
                'payload' => '{"scene":"community_follow"}',
                'sort' => 25,
            ],
        ];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
