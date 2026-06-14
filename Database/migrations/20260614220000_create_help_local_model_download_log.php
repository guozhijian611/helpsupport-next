<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateHelpLocalModelDownloadLog extends AbstractMigration
{
    public function up(): void
    {
        $this->execute(<<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_local_model_download_log` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `model_id` int unsigned NOT NULL DEFAULT 0 COMMENT '模型目录ID',
    `model_code` varchar(80) NOT NULL DEFAULT '' COMMENT '模型编码',
    `model_name` varchar(120) NOT NULL DEFAULT '' COMMENT '模型名称快照',
    `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端平台:ios/android',
    `app_version` varchar(40) NOT NULL DEFAULT '' COMMENT 'App版本',
    `locale` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端语言',
    `download_status` varchar(20) NOT NULL DEFAULT 'started' COMMENT '下载状态:started/success/failed/canceled',
    `file_size` bigint unsigned NOT NULL DEFAULT 0 COMMENT '模型文件大小',
    `downloaded_size` bigint unsigned NOT NULL DEFAULT 0 COMMENT '已下载大小',
    `sha256` varchar(80) NOT NULL DEFAULT '' COMMENT '客户端校验SHA256',
    `duration_seconds` int unsigned NOT NULL DEFAULT 0 COMMENT '下载耗时秒',
    `error_code` varchar(80) NOT NULL DEFAULT '' COMMENT '错误码',
    `error_message` varchar(500) NOT NULL DEFAULT '' COMMENT '错误摘要',
    `started_at` datetime DEFAULT NULL COMMENT '开始时间',
    `finished_at` datetime DEFAULT NULL COMMENT '结束时间',
    `ext` json DEFAULT NULL COMMENT '扩展信息，不保存对话内容',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1有效,2忽略',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int DEFAULT NULL COMMENT '创建者',
    `updated_by` int DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_model` (`member_id`, `model_id`),
    KEY `idx_model_code_status` (`model_code`, `download_status`),
    KEY `idx_member_create_time` (`member_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 本地模型下载日志表'
SQL);
    }

    public function down(): void
    {
        $this->execute('DROP TABLE IF EXISTS `sa_local_model_download_log`');
    }
}
