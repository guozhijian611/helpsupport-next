<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class GrantHelpPrivateMaterialAuditRoleMenus extends AbstractMigration
{
    private const ROLE_CODE = 'helpsupport_operator';
    private const MENU_REMARK = 'phinx:20260614175250_add_help_private_material_audit_admin_menu';

    public function up(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND m.`remark` = ' . $this->q(self::MENU_REMARK) . '
               AND rm.`id` IS NULL'
        );
        $this->clearSaiadminAuthCaches();
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_role` r ON r.`id` = rm.`role_id`
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE r.`code` = ' . $this->q(self::ROLE_CODE) . '
               AND m.`remark` = ' . $this->q(self::MENU_REMARK)
        );
        $this->clearSaiadminAuthCaches();
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }

    private function clearSaiadminAuthCaches(): void
    {
        try {
            if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
                \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
            }
            if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
                \plugin\saiadmin\app\cache\UserAuthCache::clear();
            }
        } catch (\Throwable) {
            // 缓存清理失败不应阻断菜单权限迁移，管理员重新登录后仍可刷新权限。
        }
    }
}
