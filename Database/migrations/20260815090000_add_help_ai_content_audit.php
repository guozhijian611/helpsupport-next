<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpAiContentAudit extends AbstractMigration
{
    private const REMARK = 'phinx:20260815090000_add_help_ai_content_audit';
    private const CONFIG_GROUP = 'help_ai_audit';
    private const QUEUE_NAME = 'help_ai_audit';

    public function up(): void
    {
        $this->createAuditTaskTable();
        $this->extendAuditLog();
        $this->seedAuditConfig();
        $this->seedAuditQueue();
        $this->seedPermissions();
    }

    public function down(): void
    {
        if ($this->hasTable('sa_help_ai_audit_task')) {
            $row = $this->fetchRow('SELECT COUNT(*) AS `total` FROM `sa_help_ai_audit_task`');
            if ((int) ($row['total'] ?? 0) > 0) {
                throw new RuntimeException('存在AI审核任务记录，为避免丢失审计数据，请先完成备份和清理后再回滚。');
            }
        }

        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));

        if ($this->hasTable('sa_tool_queue_config')) {
            $this->execute(
                'DELETE FROM `sa_tool_queue_config`
                 WHERE `queue_name` = ' . $this->q(self::QUEUE_NAME) . '
                   AND `remark` = ' . $this->q(self::REMARK) . '
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_tool_queue`
                       WHERE `sa_tool_queue`.`config_id` = `sa_tool_queue_config`.`id`
                   )'
            );
        }

        if ($this->hasTable('sa_system_config') && $this->hasTable('sa_system_config_group')) {
            $this->execute(
                'DELETE FROM `sa_system_config`
                 WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND `group_id` IN (
                       SELECT `id` FROM `sa_system_config_group`
                       WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   )'
            );
            $this->execute(
                'DELETE FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_config`
                       WHERE `sa_system_config`.`group_id` = `sa_system_config_group`.`id`
                   )'
            );
        }

        if ($this->hasTable('sa_help_ai_audit_task')) {
            $this->table('sa_help_ai_audit_task')->drop()->save();
        }

        if ($this->hasTable('sa_help_audit_log')) {
            $table = $this->table('sa_help_audit_log');
            foreach (['metadata', 'operator_type'] as $column) {
                if ($table->hasColumn($column)) {
                    $table->removeColumn($column)->save();
                }
            }
        }
    }

    private function createAuditTaskTable(): void
    {
        if ($this->hasTable('sa_help_ai_audit_task')) {
            return;
        }

        $this->execute(
            "CREATE TABLE `sa_help_ai_audit_task` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `request_key` char(64) NOT NULL COMMENT '目标内容版本幂等键',
                `target_type` varchar(50) NOT NULL COMMENT '审核对象类型',
                `target_id` bigint(20) unsigned NOT NULL COMMENT '审核对象ID',
                `content_hash` char(64) NOT NULL COMMENT '待审核内容哈希',
                `task_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '任务状态 0排队 1处理中 2完成 3失败 4已过期',
                `decision` varchar(20) NOT NULL DEFAULT '' COMMENT 'AI结论 pass/review/reject',
                `risk_level` varchar(20) NOT NULL DEFAULT '' COMMENT '风险等级 low/medium/high',
                `confidence` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '置信度0-1',
                `categories` json DEFAULT NULL COMMENT '风险分类',
                `matched_segments` json DEFAULT NULL COMMENT '风险片段',
                `reason` varchar(500) NOT NULL DEFAULT '' COMMENT '审核原因',
                `rule_result` json DEFAULT NULL COMMENT '系统违禁词审核结果',
                `model_config_id` int(11) DEFAULT NULL COMMENT 'AI模型配置ID',
                `model_name` varchar(100) NOT NULL DEFAULT '' COMMENT '模型名称',
                `platform_type` varchar(30) NOT NULL DEFAULT '' COMMENT '模型平台',
                `prompt_version` varchar(50) NOT NULL DEFAULT 'v1' COMMENT '提示词版本',
                `queue_task_id` bigint(20) unsigned DEFAULT NULL COMMENT '最近一次队列任务ID',
                `attempt_count` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '已尝试次数',
                `latency_ms` int unsigned NOT NULL DEFAULT 0 COMMENT '模型调用耗时毫秒',
                `error_message` varchar(1000) NOT NULL DEFAULT '' COMMENT '失败原因',
                `started_at` datetime DEFAULT NULL COMMENT '开始时间',
                `finished_at` datetime DEFAULT NULL COMMENT '完成时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_request_key` (`request_key`) USING BTREE,
                KEY `idx_target` (`target_type`, `target_id`, `id`) USING BTREE,
                KEY `idx_status_time` (`task_status`, `create_time`) USING BTREE,
                KEY `idx_queue_task` (`queue_task_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='HelpSupport AI内容审核任务表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function extendAuditLog(): void
    {
        if (!$this->hasTable('sa_help_audit_log')) {
            return;
        }

        $table = $this->table('sa_help_audit_log');
        if (!$table->hasColumn('operator_type')) {
            $table->addColumn('operator_type', 'string', [
                'limit' => 20,
                'default' => 'admin',
                'null' => false,
                'comment' => '操作来源 system/ai/doctor/admin',
                'after' => 'operator_id',
            ])->save();
        }
        if (!$table->hasColumn('metadata')) {
            $table->addColumn('metadata', 'json', [
                'null' => true,
                'comment' => '审核扩展信息',
                'after' => 'operator_type',
            ])->save();
        }
    }

    private function seedAuditConfig(): void
    {
        if (!$this->hasTable('sa_system_config_group') || !$this->hasTable('sa_system_config')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_system_config_group` (`name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q('AI 内容审核') . ', ' . $this->q(self::CONFIG_GROUP) . ', ' . $this->q(self::REMARK . ':社区内容大模型审核策略。') . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   AND `delete_time` IS NULL
             )'
        );

        $enabledOptions = [
            ['label' => '启用', 'value' => '1'],
            ['label' => '禁用', 'value' => '2'],
        ];
        $items = [
            ['enabled', 'AI审核总开关', '2', 'radio', 120, '启用后，帖子和评论先进入AI审核队列。', $enabledOptions],
            ['ai_config_id', '审核模型', '0', 'select', 110, '选择已启用的SAIAI模型配置。', null],
            ['audit_posts', '审核社区帖子', '1', 'radio', 100, '1启用 2禁用。', $enabledOptions],
            ['audit_comments', '审核社区评论', '1', 'radio', 90, '1启用 2禁用。', $enabledOptions],
            ['auto_pass_enabled', '高置信度自动通过', '1', 'radio', 80, '达到阈值的pass结论自动公开。', $enabledOptions],
            ['auto_pass_confidence', '自动通过阈值', '0.95', 'number', 70, '范围0.50-1.00。', null],
            ['auto_reject_enabled', '高置信度自动拒绝', '2', 'radio', 60, '第一版建议关闭，明确违规仍进入人工复核。', $enabledOptions],
            ['auto_reject_confidence', '自动拒绝阈值', '0.99', 'number', 50, '范围0.80-1.00。', null],
            ['max_attempts', '最大尝试次数', '3', 'number', 40, '模型或网络异常时的最大尝试次数。', null],
            ['retry_delay_seconds', '重试间隔秒数', '10', 'number', 30, '每次失败后的基础延迟。', null],
            ['prompt_policy', '补充审核政策', '', 'textarea', 20, '追加到系统审核政策，不应填写密钥或个人信息。', null],
        ];

        foreach ($items as $item) {
            [$key, $name, $value, $inputType, $sort, $remark, $options] = $item;
            $selectData = $options === null
                ? 'NULL'
                : $this->q(json_encode($options, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]');
            $this->execute(
                'INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', ' . $selectData . ', ' . (int) $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
                 FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   AND `delete_time` IS NULL
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_config`
                       WHERE `group_id` = `sa_system_config_group`.`id`
                         AND `key` = ' . $this->q($key) . '
                         AND `delete_time` IS NULL
                   )
                 LIMIT 1'
            );
        }
    }

    private function seedAuditQueue(): void
    {
        if (!$this->hasTable('sa_tool_queue_config')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_tool_queue_config` (`name`, `driver`, `message_mode`, `connection`, `queue_name`, `exchange_name`, `exchange_type`, `routing_key`, `is_delayed`, `delay_mode`, `dead_letter_exchange`, `dead_letter_routing_key`, `prefetch_count`, `consumer_count`, `max_attempts`, `retry_delay_seconds`, `arguments`, `builder_class`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q('HelpSupport AI审核队列') . ', ' . $this->q('redis') . ', ' . $this->q('internal_job') . ', ' . $this->q('default') . ', ' . $this->q(self::QUEUE_NAME) . ', ' . $this->q('') . ', ' . $this->q('direct') . ', ' . $this->q('') . ', 2, ' . $this->q('none') . ', ' . $this->q('') . ', ' . $this->q('') . ', 1, 1, 3, 10, ' . $this->q('{}') . ', ' . $this->q('') . ', 65, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_tool_queue_config`
                 WHERE `driver` = ' . $this->q('redis') . '
                   AND `connection` = ' . $this->q('default') . '
                   AND `queue_name` = ' . $this->q(self::QUEUE_NAME) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function seedPermissions(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ([
            ['help/community/post', '重新AI审核', 'help:community:post:aiAudit', 'aiAudit'],
            ['help/community/comment', '重新AI审核', 'help:community:comment:aiAudit', 'aiAudit'],
        ] as [$parentCode, $name, $slug, $generateKey]) {
            $this->execute(
                'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT `id`, ' . $this->q($name) . ', ' . $this->q('') . ', ' . $this->q($slug) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 90, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($generateKey) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
                 FROM `sa_system_menu`
                 WHERE `code` = ' . $this->q($parentCode) . '
                   AND `delete_time` IS NULL
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_menu`
                       WHERE `slug` = ' . $this->q($slug) . '
                         AND `delete_time` IS NULL
                   )
                 LIMIT 1'
            );
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
