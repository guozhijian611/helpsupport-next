<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddPrivateMaterialCategoriesAndEntertainmentCrud extends AbstractMigration
{
    private const REMARK = 'phinx:20260616172000_add_private_material_categories_and_entertainment_crud';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';
    private const ENTERTAINMENT_CODE = 'help/material/entertainment';
    private const ENTERTAINMENT_PREFIX = 'help:material:entertainment';

    public function up(): void
    {
        $this->addCategoryMemberId();
        $this->insertEntertainmentMenu();
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
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `sort` = 30, `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/material/privateMaterial') . '
               AND `delete_time` IS NULL'
        );
        $this->dropCategoryMemberId();
        $this->clearAuthCaches();
    }

    private function addCategoryMemberId(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        $table = $this->table('sa_content_category');
        if (!$table->hasColumn('member_id')) {
            $table
                ->addColumn('member_id', 'integer', [
                    'signed' => false,
                    'null' => false,
                    'default' => 0,
                    'comment' => '分类所属会员ID,0为系统分类',
                    'after' => 'parent_id',
                ])
                ->update();
        }

        if (!$this->indexExists('sa_content_category', 'idx_type_member_status')) {
            $this->execute('ALTER TABLE `sa_content_category` ADD INDEX `idx_type_member_status` (`type`, `member_id`, `status`)');
        }
    }

    private function dropCategoryMemberId(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        if ($this->indexExists('sa_content_category', 'idx_type_member_status')) {
            $this->execute('ALTER TABLE `sa_content_category` DROP INDEX `idx_type_member_status`');
        }

        $table = $this->table('sa_content_category');
        if ($table->hasColumn('member_id')) {
            $table->removeColumn('member_id')->update();
        }
    }

    private function insertEntertainmentMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`,
                    ' . $this->q('娱乐素材') . ',
                    ' . $this->q(self::ENTERTAINMENT_CODE) . ',
                    NULL,
                    2,
                    CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN ' . $this->q('/helpsupport/material/entertainment') . ' ELSE ' . $this->q('material/entertainment') . ' END,
                    ' . $this->q('/plugin/help/material/entertainment/index') . ',
                    NULL,
                    ' . $this->q('ri:gamepad-line') . ',
                    30,
                    ' . $this->q('') . ',
                    2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` IN (' . $this->q('help/material') . ', ' . $this->q('HelpSupport') . ')
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q(self::ENTERTAINMENT_CODE) . '
                     AND `delete_time` IS NULL
               )
             ORDER BY CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN 0 ELSE 1 END
             LIMIT 1'
        );

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `sort` = 20, `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/material/content') . '
               AND `delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `sort` = 40, `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/material/privateMaterial') . '
               AND `delete_time` IS NULL'
        );

        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
    }

    private function permissions(): array
    {
        return [
            ['name' => '列表', 'slug' => self::ENTERTAINMENT_PREFIX . ':index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => self::ENTERTAINMENT_PREFIX . ':save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => self::ENTERTAINMENT_PREFIX . ':update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => self::ENTERTAINMENT_PREFIX . ':read', 'generate_key' => 'read'],
            ['name' => '删除', 'slug' => self::ENTERTAINMENT_PREFIX . ':destroy', 'generate_key' => 'destroy'],
            ['name' => '审核', 'slug' => self::ENTERTAINMENT_PREFIX . ':audit', 'generate_key' => 'audit'],
        ];
    }

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu`
             WHERE `code` = ' . $this->q(self::ENTERTAINMENT_CODE) . '
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
                   m.`code` IN (' . $this->q('help/material') . ', ' . $this->q(self::ENTERTAINMENT_CODE) . ')
                   OR m.`slug` LIKE ' . $this->q(self::ENTERTAINMENT_PREFIX . ':%') . '
               )'
        );
    }

    private function indexExists(string $table, string $index): bool
    {
        $row = $this->fetchRow(
            'SELECT 1
             FROM `information_schema`.`STATISTICS`
             WHERE `TABLE_SCHEMA` = DATABASE()
               AND `TABLE_NAME` = ' . $this->q($table) . '
               AND `INDEX_NAME` = ' . $this->q($index) . '
             LIMIT 1'
        );

        return $row !== false && $row !== [];
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
