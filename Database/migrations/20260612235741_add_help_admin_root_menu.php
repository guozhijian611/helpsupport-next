<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpAdminRootMenu extends AbstractMigration
{
    private const REMARK = 'phinx:20260612235741_add_help_admin_root_menu';

    public function up(): void
    {
        $this->execute(
            "INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT 0, 'HelpSupport', 'HelpSupport', '/helpsupport', 1, '/helpsupport', '', NULL, 'ri:mental-health-line', 88, '', 2, 2, 2, 2, 2, 0, NULL, 1, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `sa_system_menu`
                WHERE `code` = 'HelpSupport'
                  AND `delete_time` IS NULL
            )"
        );
    }

    public function down(): void
    {
        $this->execute(
            "DELETE parent FROM `sa_system_menu` parent
            WHERE parent.`code` = 'HelpSupport'
              AND parent.`remark` = '" . self::REMARK . "'
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu` child
                  WHERE child.`parent_id` = parent.`id`
                    AND child.`delete_time` IS NULL
              )"
        );
    }
}
