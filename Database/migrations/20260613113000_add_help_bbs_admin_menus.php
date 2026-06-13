<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpBbsAdminMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260613113000_add_help_bbs_admin_menus';

    public function up(): void
    {
        $this->execute(
            "UPDATE `sa_system_menu`
            SET `name` = '社区帖子审核', `update_time` = NOW()
            WHERE `code` = 'help/community/post'
              AND `name` = '社区内容审核'
              AND `delete_time` IS NULL"
        );

        $this->insertPermission('help/community/post', [
            'name' => '审核',
            'slug' => 'help:community:post:audit',
            'generate_key' => 'audit',
        ]);

        foreach ($this->menus() as $menu) {
            $this->insertMenu($menu);
            foreach ($menu['permissions'] as $permission) {
                $this->insertPermission($menu['code'], $permission);
            }
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->execute(
            "UPDATE `sa_system_menu`
            SET `name` = '社区内容审核', `update_time` = NOW()
            WHERE `code` = 'help/community/post'
              AND `name` = '社区帖子审核'
              AND `delete_time` IS NULL"
        );
    }

    private function menus(): array
    {
        return [
            [
                'name' => '社区评论管理',
                'code' => 'help/community/comment',
                'path' => 'community/comment',
                'component' => '/plugin/help/community/comment/index',
                'icon' => 'ri:chat-3-line',
                'sort' => 121,
                'permissions' => [
                    ['name' => '列表', 'slug' => 'help:community:comment:index', 'generate_key' => 'index'],
                    ['name' => '读取', 'slug' => 'help:community:comment:read', 'generate_key' => 'read'],
                    ['name' => '删除', 'slug' => 'help:community:comment:destroy', 'generate_key' => 'destroy'],
                    ['name' => '审核', 'slug' => 'help:community:comment:audit', 'generate_key' => 'audit'],
                ],
            ],
            [
                'name' => '社区举报处理',
                'code' => 'help/community/report',
                'path' => 'community/report',
                'component' => '/plugin/help/community/report/index',
                'icon' => 'ri:alarm-warning-line',
                'sort' => 122,
                'permissions' => [
                    ['name' => '列表', 'slug' => 'help:community:report:index', 'generate_key' => 'index'],
                    ['name' => '读取', 'slug' => 'help:community:report:read', 'generate_key' => 'read'],
                    ['name' => '删除', 'slug' => 'help:community:report:destroy', 'generate_key' => 'destroy'],
                    ['name' => '处理', 'slug' => 'help:community:report:handle', 'generate_key' => 'handle'],
                ],
            ],
        ];
    }

    private function insertMenu(array $menu): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($menu['name']) . ', ' . $this->q($menu['code']) . ', NULL, 2, ' . $this->q($menu['path']) . ', ' . $this->q($menu['component']) . ', NULL, ' . $this->q($menu['icon']) . ', ' . (int) $menu['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('HelpSupport') . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `code` = ' . $this->q($menu['code']) . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
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
