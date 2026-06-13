<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpAdminCrudMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260613080200_seed_help_admin_crud_menus';

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
                'name' => 'App引导页配置',
                'code' => 'help/config/page',
                'path' => 'config/page',
                'component' => '/plugin/help/config/page/index',
                'permission_prefix' => 'help:config:page',
            ],
            [
                'name' => '医生资质审核',
                'code' => 'help/audit/profile',
                'path' => 'audit/profile',
                'component' => '/plugin/help/audit/profile/index',
                'permission_prefix' => 'help:audit:profile',
            ],
            [
                'name' => '社区内容审核',
                'code' => 'help/community/post',
                'path' => 'community/post',
                'component' => '/plugin/help/community/post/index',
                'permission_prefix' => 'help:community:post',
            ],
            [
                'name' => 'AI聊天配置',
                'code' => 'help/chat/config',
                'path' => 'chat/config',
                'component' => '/plugin/help/chat/config/index',
                'permission_prefix' => 'help:chat:config',
            ],
            [
                'name' => '本地模型目录',
                'code' => 'help/localModel/catalog',
                'path' => 'localModel/catalog',
                'component' => '/plugin/help/localModel/catalog/index',
                'permission_prefix' => 'help:localModel:catalog',
            ],
            [
                'name' => '本地模型提示词',
                'code' => 'help/localModel/prompt',
                'path' => 'localModel/prompt',
                'component' => '/plugin/help/localModel/prompt/index',
                'permission_prefix' => 'help:localModel:prompt',
            ],
            [
                'name' => '推送设备',
                'code' => 'help/push/device',
                'path' => 'push/device',
                'component' => '/plugin/help/push/device/index',
                'permission_prefix' => 'help:push:device',
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
            SELECT `id`, ' . $this->q($menu['name']) . ', ' . $this->q($menu['code']) . ', NULL, 2, ' . $this->q($menu['path']) . ', ' . $this->q($menu['component']) . ', NULL, ' . $this->q('ri:home-2-line') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
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
