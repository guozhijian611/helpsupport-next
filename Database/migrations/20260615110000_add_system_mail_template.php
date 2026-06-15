<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddSystemMailTemplate extends AbstractMigration
{
    private const REMARK = 'phinx:20260615110000_add_system_mail_template';

    public function up(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_system_mail_template` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
                `name` varchar(100) NOT NULL DEFAULT '' COMMENT '模板名称',
                `code` varchar(100) NOT NULL DEFAULT '' COMMENT '模板标识',
                `subject` varchar(255) NOT NULL DEFAULT '' COMMENT '邮件主题',
                `content` text COMMENT '邮件内容',
                `variables` text COMMENT '变量说明',
                `sort` int(11) NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_code` (`code`) USING BTREE,
                KEY `idx_status_sort` (`status`, `sort`) USING BTREE,
                KEY `idx_create_time` (`create_time`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='邮件发信模板表' ROW_FORMAT=DYNAMIC"
        );

        $this->insertMenu();
        $this->insertPermission('数据列表', 'core:email-template:index');
        $this->insertPermission('读取', 'core:email-template:read');
        $this->insertPermission('添加', 'core:email-template:save');
        $this->insertPermission('修改', 'core:email-template:update');
        $this->insertPermission('删除', 'core:email-template:destroy');
    }

    public function down(): void
    {
        $this->execute("DELETE FROM `sa_system_menu` WHERE `remark` = '" . self::REMARK . "'");
        $this->execute('DROP TABLE IF EXISTS `sa_system_mail_template`');
    }

    private function insertMenu(): void
    {
        $this->execute(
            "INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, '邮件模板', 'EmailTemplate', '', 2, 'email-template', '/system/email-template', NULL, 'ri:mail-settings-line', 95, '', 2, 2, 2, 2, 2, 0, NULL, 1, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = 'System'
              AND `delete_time` IS NULL
              AND NOT EXISTS (SELECT 1 FROM `sa_system_menu` WHERE `code` = 'EmailTemplate' AND `delete_time` IS NULL)
            LIMIT 1"
        );
    }

    private function insertPermission(string $name, string $slug): void
    {
        $this->execute(
            "INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, '{$name}', '', '{$slug}', 3, '', '', NULL, '', 100, '', 2, 2, 2, 2, 2, 0, NULL, 1, '" . self::REMARK . "', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = 'EmailTemplate'
              AND `delete_time` IS NULL
              AND NOT EXISTS (SELECT 1 FROM `sa_system_menu` WHERE `slug` = '{$slug}' AND `delete_time` IS NULL)
            LIMIT 1"
        );
    }
}
