<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpDoctorAdminMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260614110000_add_help_doctor_admin_menus';

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
                'name' => '医生患者关系',
                'code' => 'help/doctor/patient',
                'path' => 'doctor/patient',
                'component' => '/plugin/help/doctor/patient/index',
                'icon' => 'ri:user-heart-line',
                'sort' => 140,
                'permissions' => $this->permissions('help:doctor:patient'),
            ],
            [
                'name' => '模板文件夹',
                'code' => 'help/doctor/taskTemplateFolder',
                'path' => 'doctor/taskTemplateFolder',
                'component' => '/plugin/help/doctor/taskTemplateFolder/index',
                'icon' => 'ri:folder-3-line',
                'sort' => 141,
                'permissions' => $this->permissions('help:doctor:taskTemplateFolder'),
            ],
            [
                'name' => '任务模板',
                'code' => 'help/doctor/taskTemplate',
                'path' => 'doctor/taskTemplate',
                'component' => '/plugin/help/doctor/taskTemplate/index',
                'icon' => 'ri:file-list-3-line',
                'sort' => 142,
                'permissions' => $this->permissions('help:doctor:taskTemplate'),
            ],
            [
                'name' => '评估量表',
                'code' => 'help/doctor/assessmentScale',
                'path' => 'doctor/assessmentScale',
                'component' => '/plugin/help/doctor/assessmentScale/index',
                'icon' => 'ri:survey-line',
                'sort' => 143,
                'permissions' => array_merge($this->permissions('help:doctor:assessmentScale'), [
                    ['name' => '发布', 'slug' => 'help:doctor:assessmentScale:publish', 'generate_key' => 'publish'],
                    ['name' => '禁用', 'slug' => 'help:doctor:assessmentScale:disable', 'generate_key' => 'disable'],
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
