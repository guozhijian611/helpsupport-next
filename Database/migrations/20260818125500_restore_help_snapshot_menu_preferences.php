<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 恢复 2026-08-16 SQL 快照中已经确认过的 HelpSupport 菜单展示状态。
 *
 * 这里只修复被 20260818121102 错误覆盖的两个字段组合；不删除数据、
 * 不重命名其他菜单，也不覆盖管理员后续维护的业务记录。
 */
final class RestoreHelpSnapshotMenuPreferences extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `parent_id` = 0,
                 `sort` = 83,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->quote('help/chat/robotProfile') . '
               AND `delete_time` IS NULL'
        );

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `is_hidden` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->quote('help/me/journal') . '
               AND `delete_time` IS NULL'
        );
    }

    public function down(): void
    {
        // 菜单展示状态属于实例配置，回滚代码版本时也不应覆盖管理员设置。
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
