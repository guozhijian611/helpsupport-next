<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpPrivateMaterialAuditAdminMenu extends AbstractMigration
{
    private const REMARK = 'phinx:20260614175250_add_help_private_material_audit_admin_menu';

    public function up(): void
    {
        $this->insertMenu();
        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
    }

    private function insertMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q('私人素材审核') . ', ' . $this->q('help/material/privateMaterial') . ', NULL, 2, ' . $this->q('material/privateMaterial') . ', ' . $this->q('/plugin/help/material/privateMaterial/index') . ', NULL, ' . $this->q('ri:shield-user-line') . ', 116, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('HelpSupport') . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `code` = ' . $this->q('help/material/privateMaterial') . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    private function permissions(): array
    {
        return [
            ['name' => '列表', 'slug' => 'help:material:privateMaterial:index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => 'help:material:privateMaterial:save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => 'help:material:privateMaterial:update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => 'help:material:privateMaterial:read', 'generate_key' => 'read'],
            ['name' => '删除', 'slug' => 'help:material:privateMaterial:destroy', 'generate_key' => 'destroy'],
            ['name' => '审核', 'slug' => 'help:material:privateMaterial:audit', 'generate_key' => 'audit'],
        ];
    }

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('help/material/privateMaterial') . '
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
