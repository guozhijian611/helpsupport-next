<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpSupportOperatorRole extends AbstractMigration
{
    private const ROLE_CODE = 'helpsupport_operator';
    private const REMARK = 'phinx:20260615080000_add_help_support_operator_role';

    public function up(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_role` (`name`, `code`, `level`, `data_scope`, `remark`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q('HelpSupport运营管理员') . ', ' . $this->q(self::ROLE_CODE) . ', 20, 1, ' . $this->q(self::REMARK) . ', 100, 1, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_role`
                 WHERE `code` = ' . $this->q(self::ROLE_CODE) . '
                   AND `delete_time` IS NULL
             )'
        );

        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND rm.`id` IS NULL
               AND (
                   m.`code` = ' . $this->q('HelpSupport') . '
                   OR m.`code` LIKE ' . $this->q('help/%') . '
                   OR m.`slug` LIKE ' . $this->q('help:%') . '
               )'
        );
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_role` r ON r.`id` = rm.`role_id`
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE r.`code` = ' . $this->q(self::ROLE_CODE) . '
               AND r.`remark` = ' . $this->q(self::REMARK) . '
               AND (
                   m.`code` = ' . $this->q('HelpSupport') . '
                   OR m.`code` LIKE ' . $this->q('help/%') . '
                   OR m.`slug` LIKE ' . $this->q('help:%') . '
               )'
        );

        $this->execute(
            'DELETE r FROM `sa_system_role` r
             LEFT JOIN `sa_system_user_role` ur ON ur.`role_id` = r.`id`
             WHERE r.`code` = ' . $this->q(self::ROLE_CODE) . '
               AND r.`remark` = ' . $this->q(self::REMARK) . '
               AND ur.`id` IS NULL'
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
