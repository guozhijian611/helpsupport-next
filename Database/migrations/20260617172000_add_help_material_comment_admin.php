<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMaterialCommentAdmin extends AbstractMigration
{
    private const REMARK = 'phinx:20260617172000_add_help_material_comment_admin';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';
    private const MENU_CODE = 'help/material/comment';
    private const PERMISSION_PREFIX = 'help:material:comment';

    public function up(): void
    {
        $this->insertCommentMenu();
        $this->grantOperatorRoleMenus();
        $this->clearAuthCaches();
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE m.`remark` = ' . $this->q(self::REMARK)
        );
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->clearAuthCaches();
    }

    private function insertCommentMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`,
                    ' . $this->q('素材评论管理') . ',
                    ' . $this->q(self::MENU_CODE) . ',
                    NULL,
                    2,
                    CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN ' . $this->q('/helpsupport/material/comment') . ' ELSE ' . $this->q('material/comment') . ' END,
                    ' . $this->q('/plugin/help/material/comment/index') . ',
                    NULL,
                    ' . $this->q('ri:chat-3-line') . ',
                    35,
                    ' . $this->q('') . ',
                    2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` IN (' . $this->q('help/material') . ', ' . $this->q('HelpSupport') . ')
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q(self::MENU_CODE) . '
                     AND `delete_time` IS NULL
               )
             ORDER BY CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN 0 ELSE 1 END
             LIMIT 1'
        );

        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
    }

    private function permissions(): array
    {
        return [
            ['name' => '列表', 'slug' => self::PERMISSION_PREFIX . ':index', 'generate_key' => 'index'],
            ['name' => '读取', 'slug' => self::PERMISSION_PREFIX . ':read', 'generate_key' => 'read'],
            ['name' => '状态', 'slug' => self::PERMISSION_PREFIX . ':status', 'generate_key' => 'status'],
            ['name' => '删除', 'slug' => self::PERMISSION_PREFIX . ':destroy', 'generate_key' => 'destroy'],
        ];
    }

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu`
             WHERE `code` = ' . $this->q(self::MENU_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `slug` = ' . $this->q($permission['slug']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function grantOperatorRoleMenus(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND rm.`id` IS NULL
               AND (
                   m.`code` IN (' . $this->q('help/material') . ', ' . $this->q(self::MENU_CODE) . ')
                   OR m.`slug` LIKE ' . $this->q(self::PERMISSION_PREFIX . ':%') . '
               )'
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
            // 缓存清理失败不阻断迁移，管理员重新登录后仍可刷新权限。
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
