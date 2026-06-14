<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateHelpAuditLog extends AbstractMigration
{
    public function up(): void
    {
        if ($this->hasTable('sa_help_audit_log')) {
            return;
        }

        $this->execute(
            "CREATE TABLE `sa_help_audit_log` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
                `target_type` varchar(50) NOT NULL COMMENT '审核对象类型',
                `target_id` int unsigned NOT NULL COMMENT '审核对象ID',
                `action` varchar(50) NOT NULL DEFAULT 'audit' COMMENT '动作',
                `before_status` varchar(50) DEFAULT NULL COMMENT '变更前状态',
                `after_status` varchar(50) NOT NULL COMMENT '变更后状态',
                `reason` varchar(500) DEFAULT NULL COMMENT '原因/备注',
                `operator_id` int DEFAULT NULL COMMENT '操作人ID',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_target` (`target_type`, `target_id`, `create_time`) USING BTREE,
                KEY `idx_action` (`action`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='HelpSupport审核操作日志' ROW_FORMAT=DYNAMIC"
        );
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_help_audit_log')) {
            return;
        }

        $row = $this->fetchRow('SELECT COUNT(*) AS `total` FROM `sa_help_audit_log`');
        if ((int) ($row['total'] ?? 0) > 0) {
            return;
        }

        $this->table('sa_help_audit_log')->drop()->save();
    }
}
