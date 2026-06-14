<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMemberMessagePushPermission extends AbstractMigration
{
    private const REMARK = 'phinx:20260615060000_add_member_message_push_permission';

    public function up(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q('推送') . ', ' . $this->q('') . ', ' . $this->q('help:message:memberMessage:push') . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q('push') . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('help/message/memberMessage') . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `slug` = ' . $this->q('help:message:memberMessage:push') . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    public function down(): void
    {
        $this->execute(
            'DELETE FROM `sa_system_menu`
            WHERE `slug` = ' . $this->q('help:message:memberMessage:push') . '
              AND `remark` = ' . $this->q(self::REMARK)
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
