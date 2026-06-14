<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpMessagePushAdminMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260614130000_add_help_message_push_admin_menus';

    public function up(): void
    {
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
    }

    private function menus(): array
    {
        return [
            [
                'name' => '推送偏好',
                'code' => 'help/push/preference',
                'path' => 'push/preference',
                'component' => '/plugin/help/push/preference/index',
                'icon' => 'ri:notification-badge-line',
                'sort' => 150,
                'permissions' => array_merge($this->permissions('help:push:preference'), [
                    ['name' => '启用', 'slug' => 'help:push:preference:enable', 'generate_key' => 'enable'],
                    ['name' => '停用', 'slug' => 'help:push:preference:disable', 'generate_key' => 'disable'],
                ]),
            ],
            [
                'name' => '消息管理',
                'code' => 'help/message/memberMessage',
                'path' => 'message/memberMessage',
                'component' => '/plugin/help/message/memberMessage/index',
                'icon' => 'ri:message-3-line',
                'sort' => 151,
                'permissions' => array_merge($this->permissions('help:message:memberMessage'), [
                    ['name' => '标记已读', 'slug' => 'help:message:memberMessage:markRead', 'generate_key' => 'markRead'],
                    ['name' => '标记推送成功', 'slug' => 'help:message:memberMessage:markPushed', 'generate_key' => 'markPushed'],
                    ['name' => '标记推送失败', 'slug' => 'help:message:memberMessage:markFailed', 'generate_key' => 'markFailed'],
                ]),
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
