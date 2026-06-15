<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateHelpMemberDiagnosticLog extends AbstractMigration
{
    public function up(): void
    {
        $this->execute(<<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_diagnostic_log` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `device_id` varchar(64) NOT NULL DEFAULT '' COMMENT '设备标识',
    `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端平台 ios/android',
    `app_version` varchar(40) NOT NULL DEFAULT '' COMMENT 'App版本',
    `locale` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端语言',
    `timezone` varchar(64) NOT NULL DEFAULT '' COMMENT '客户端时区',
    `source` varchar(20) NOT NULL DEFAULT 'manual' COMMENT '上传来源 manual/auto',
    `entry_count` int unsigned NOT NULL DEFAULT 0 COMMENT '日志条数',
    `first_log_time` datetime DEFAULT NULL COMMENT '首条日志时间',
    `last_log_time` datetime DEFAULT NULL COMMENT '末条日志时间',
    `log_summary` varchar(255) NOT NULL DEFAULT '' COMMENT '日志摘要',
    `log_entries` longtext NOT NULL COMMENT '日志内容 JSON',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1有效 2忽略',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int DEFAULT NULL COMMENT '创建者',
    `updated_by` int DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_create_time` (`member_id`, `create_time`),
    KEY `idx_device_create_time` (`device_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员客户端诊断日志上传表'
SQL);
    }

    public function down(): void
    {
        $this->execute('DROP TABLE IF EXISTS `sa_member_diagnostic_log`');
    }
}
