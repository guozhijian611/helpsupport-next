<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 关掉已停用 SAIAI 根菜单下仍启用的「AI对话」，避免它冒成顶级菜单。
 */
final class DisableLegacySaiaiChatMenu extends AbstractMigration
{
    private const REMARK = 'phinx:20260820050000_disable_legacy_saiai_chat_menu';

    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `status` = 2,
                 `remark` = CASE
                     WHEN `remark` IS NULL OR `remark` = ' . $this->q('') . ' THEN ' . $this->q(self::REMARK) . '
                     ELSE `remark`
                 END,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('AiChat') . '
               AND `delete_time` IS NULL
               AND `status` = 1'
        );
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `status` = 1,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('AiChat') . '
               AND `delete_time` IS NULL
               AND `status` = 2
               AND (`remark` = ' . $this->q(self::REMARK) . ' OR `remark` IS NULL OR `remark` = ' . $this->q('') . ')'
        );
        $this->clearMenuCaches();
    }

    private function clearMenuCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
            \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
