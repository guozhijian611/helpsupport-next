<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMemoirGeneratePermission extends AbstractMigration
{
    private const REMARK = 'phinx:20260615053000_add_help_memoir_generate_permission';

    public function up(): void
    {
        $this->insertPermission('help/me/memoirConfig', [
            'name' => '生成回忆录',
            'slug' => 'help:me:memoirConfig:generate',
            'generate_key' => 'generate',
        ]);
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
    }

    private function insertPermission(string $parentCode, array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q($parentCode) . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `slug` = ' . $this->q($permission['slug']) . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
