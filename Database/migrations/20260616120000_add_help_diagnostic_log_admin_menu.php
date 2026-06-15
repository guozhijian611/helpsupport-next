<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpDiagnosticLogAdminMenu extends AbstractMigration
{
    private const REMARK = 'phinx:20260616120000_add_help_diagnostic_log_admin_menu';
    private const PAGE_CODE = 'help/me/diagnosticLog';
    private const PAGE_COMPONENT = '/plugin/help/me/diagnosticLog/index';
    private const PAGE_PERMISSION_PREFIX = 'help:me:diagnosticLog';
    private const SOURCE_PAGE_CODE = 'help/me/triggerLog';
    private const SOURCE_PERMISSION_PREFIX = 'help:me:triggerLog:';

    public function up(): void
    {
        $this->insertMenu();

        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }

        $this->grantRoleMenus();
        $this->clearAuthCaches();
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE m.`remark` = ' . $this->q(self::REMARK)
        );

        $this->execute(
            'DELETE FROM `sa_system_menu`
             WHERE `remark` = ' . $this->q(self::REMARK)
        );

        $this->clearAuthCaches();
    }

    private function permissions(): array
    {
        return [
            ['name' => '列表', 'slug' => self::PAGE_PERMISSION_PREFIX . ':index', 'generate_key' => 'index'],
            ['name' => '读取', 'slug' => self::PAGE_PERMISSION_PREFIX . ':read', 'generate_key' => 'read'],
        ];
    }

    private function insertMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`, ' . $this->q('诊断日志') . ', ' . $this->q(self::PAGE_CODE) . ', NULL, 2,
                    CASE parent.`code`
                        WHEN ' . $this->q('help/growth') . ' THEN ' . $this->q('/helpsupport/me/diagnosticLog') . '
                        ELSE ' . $this->q('me/diagnosticLog') . '
                    END,
                    ' . $this->q(self::PAGE_COMPONENT) . ', NULL, ' . $this->q('ri:bug-line') . ',
                    CASE parent.`code`
                        WHEN ' . $this->q('help/growth') . ' THEN 85
                        ELSE 179
                    END,
                    ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` IN (' . $this->q('help/growth') . ', ' . $this->q('HelpSupport') . ')
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q(self::PAGE_CODE) . '
                     AND `delete_time` IS NULL
               )
             ORDER BY CASE parent.`code`
                 WHEN ' . $this->q('help/growth') . ' THEN 0
                 ELSE 1
             END
             LIMIT 1'
        );
    }

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu`
             WHERE `code` = ' . $this->q(self::PAGE_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `slug` = ' . $this->q($permission['slug']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function grantRoleMenus(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT DISTINCT rm.`role_id`, target.`id`
             FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` source ON source.`id` = rm.`menu_id` AND source.`delete_time` IS NULL
             INNER JOIN `sa_system_menu` target ON target.`remark` = ' . $this->q(self::REMARK) . ' AND target.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = target.`id`
             WHERE (
                    source.`code` = ' . $this->q(self::SOURCE_PAGE_CODE) . '
                    OR source.`slug` LIKE ' . $this->q(self::SOURCE_PERMISSION_PREFIX . '%') . '
             )
               AND existing.`id` IS NULL'
        );
    }

    private function clearAuthCaches(): void
    {
        try {
            if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
                \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
            }
            if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
                \plugin\saiadmin\app\cache\UserAuthCache::clear();
            }
        } catch (\Throwable) {
            // 缓存清理失败不阻断迁移，重新登录后仍可刷新权限。
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
