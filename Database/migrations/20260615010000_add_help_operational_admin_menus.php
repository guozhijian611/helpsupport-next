<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpOperationalAdminMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260615010000_add_help_operational_admin_menus';

    public function up(): void
    {
        foreach ($this->menus() as $menu) {
            $this->insertMenu($menu);
            foreach ($this->permissions($menu['permission_prefix']) as $permission) {
                $this->insertPermission($menu['code'], $permission);
            }
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
    }

    private function menus(): array
    {
        return [
            [
                'name' => '社区标签',
                'code' => 'help/community/tag',
                'path' => 'community/tag',
                'component' => '/plugin/help/community/tag/index',
                'icon' => 'ri:price-tag-3-line',
                'sort' => 112,
                'permission_prefix' => 'help:community:tag',
            ],
            [
                'name' => '聊天会话',
                'code' => 'help/chat/session',
                'path' => 'chat/session',
                'component' => '/plugin/help/chat/session/index',
                'icon' => 'ri:chat-history-line',
                'sort' => 123,
                'permission_prefix' => 'help:chat:session',
            ],
            [
                'name' => '聊天记录',
                'code' => 'help/chat/record',
                'path' => 'chat/record',
                'component' => '/plugin/help/chat/record/index',
                'icon' => 'ri:message-3-line',
                'sort' => 124,
                'permission_prefix' => 'help:chat:record',
            ],
            [
                'name' => '会员日记',
                'code' => 'help/me/journal',
                'path' => 'me/journal',
                'component' => '/plugin/help/me/journal/index',
                'icon' => 'ri:edit-2-line',
                'sort' => 174,
                'permission_prefix' => 'help:me:journal',
            ],
            [
                'name' => '会员回忆录',
                'code' => 'help/me/memoir',
                'path' => 'me/memoir',
                'component' => '/plugin/help/me/memoir/index',
                'icon' => 'ri:book-open-line',
                'sort' => 175,
                'permission_prefix' => 'help:me:memoir',
            ],
            [
                'name' => '康复目标记录',
                'code' => 'help/me/recoveryGoal',
                'path' => 'me/recoveryGoal',
                'component' => '/plugin/help/me/recoveryGoal/index',
                'icon' => 'ri:flag-line',
                'sort' => 176,
                'permission_prefix' => 'help:me:recoveryGoal',
            ],
            [
                'name' => '触发因素记录',
                'code' => 'help/me/triggerLog',
                'path' => 'me/triggerLog',
                'component' => '/plugin/help/me/triggerLog/index',
                'icon' => 'ri:alarm-warning-line',
                'sort' => 177,
                'permission_prefix' => 'help:me:triggerLog',
            ],
            [
                'name' => '会员徽章',
                'code' => 'help/gamification/badge',
                'path' => 'gamification/badge',
                'component' => '/plugin/help/gamification/badge/index',
                'icon' => 'ri:award-line',
                'sort' => 178,
                'permission_prefix' => 'help:gamification:badge',
            ],
        ];
    }

    private function permissions(string $prefix): array
    {
        return [
            ['name' => '列表', 'slug' => $prefix . ':index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => $prefix . ':save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => $prefix . ':update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => $prefix . ':read', 'generate_key' => 'read'],
            ['name' => '删除', 'slug' => $prefix . ':destroy', 'generate_key' => 'destroy'],
            ['name' => '导入', 'slug' => $prefix . ':import', 'generate_key' => 'import'],
            ['name' => '导出', 'slug' => $prefix . ':export', 'generate_key' => 'export'],
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
