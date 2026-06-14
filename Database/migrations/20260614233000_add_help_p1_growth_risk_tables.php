<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpP1GrowthRiskTables extends AbstractMigration
{
    private const REMARK = 'phinx:20260614233000_add_help_p1_growth_risk_tables';

    public function up(): void
    {
        foreach ($this->createTableSql() as $sql) {
            $this->execute($sql);
        }

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
        foreach ([
            'sa_sensitive_word_rule',
            'sa_member_memoir_config',
            'sa_member_point_log',
            'sa_member_badge',
            'sa_member_badge_rule',
        ] as $table) {
            $this->execute('DROP TABLE IF EXISTS `' . $table . '`');
        }
    }

    private function createTableSql(): array
    {
        return [
            "CREATE TABLE IF NOT EXISTS `sa_member_badge_rule` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `name` varchar(100) NOT NULL COMMENT '徽章名称',
                `code` varchar(80) NOT NULL COMMENT '徽章编码',
                `description` varchar(500) NOT NULL DEFAULT '' COMMENT '徽章说明',
                `icon` varchar(255) NOT NULL DEFAULT '' COMMENT '徽章图标',
                `trigger_type` varchar(40) NOT NULL DEFAULT 'task_count' COMMENT '触发类型',
                `trigger_value` int unsigned NOT NULL DEFAULT 1 COMMENT '触发阈值',
                `points_reward` int NOT NULL DEFAULT 0 COMMENT '奖励积分',
                `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `updated_by` int DEFAULT NULL COMMENT '更新人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '更新时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_code_delete` (`code`, `delete_time`),
                KEY `idx_trigger` (`trigger_type`, `status`),
                KEY `idx_sort` (`sort`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员荣誉徽章规则表'",

            "CREATE TABLE IF NOT EXISTS `sa_member_badge` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int unsigned NOT NULL COMMENT '会员ID',
                `rule_id` int unsigned NOT NULL DEFAULT 0 COMMENT '徽章规则ID',
                `badge_code` varchar(80) NOT NULL COMMENT '徽章编码',
                `badge_name` varchar(100) NOT NULL COMMENT '徽章名称',
                `source_type` varchar(40) NOT NULL DEFAULT '' COMMENT '来源类型',
                `source_id` int unsigned NOT NULL DEFAULT 0 COMMENT '来源ID',
                `award_time` datetime DEFAULT NULL COMMENT '获得时间',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1有效,2撤销',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `updated_by` int DEFAULT NULL COMMENT '更新人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '更新时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_member_badge_delete` (`member_id`, `badge_code`, `delete_time`),
                KEY `idx_member_status` (`member_id`, `status`),
                KEY `idx_rule_id` (`rule_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员荣誉徽章获得记录表'",

            "CREATE TABLE IF NOT EXISTS `sa_member_point_log` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int unsigned NOT NULL COMMENT '会员ID',
                `points` int NOT NULL COMMENT '积分变动值',
                `change_type` varchar(20) NOT NULL DEFAULT 'income' COMMENT '变动类型:income/expense/adjust',
                `source_type` varchar(40) NOT NULL DEFAULT 'manual' COMMENT '来源类型',
                `source_id` int unsigned NOT NULL DEFAULT 0 COMMENT '来源ID',
                `title` varchar(160) NOT NULL COMMENT '积分标题',
                `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
                `balance_after` int NOT NULL DEFAULT 0 COMMENT '变动后余额',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `updated_by` int DEFAULT NULL COMMENT '更新人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '更新时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                KEY `idx_member_time` (`member_id`, `create_time`),
                KEY `idx_source` (`source_type`, `source_id`),
                KEY `idx_change_type` (`change_type`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员积分流水表'",

            "CREATE TABLE IF NOT EXISTS `sa_member_memoir_config` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `name` varchar(100) NOT NULL COMMENT '配置名称',
                `code` varchar(80) NOT NULL COMMENT '配置编码',
                `generation_cycle` varchar(30) NOT NULL DEFAULT 'monthly' COMMENT '生成周期:weekly/monthly/quarterly',
                `source_type` varchar(40) NOT NULL DEFAULT 'journal' COMMENT '来源类型',
                `prompt_template` text COMMENT '生成提示词模板',
                `min_journal_count` int unsigned NOT NULL DEFAULT 3 COMMENT '最少日记数',
                `start_day` tinyint unsigned NOT NULL DEFAULT 1 COMMENT '周期开始日',
                `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `updated_by` int DEFAULT NULL COMMENT '更新人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '更新时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_code_delete` (`code`, `delete_time`),
                KEY `idx_cycle_status` (`generation_cycle`, `status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 回忆录生成配置表'",

            "CREATE TABLE IF NOT EXISTS `sa_sensitive_word_rule` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `scene` varchar(40) NOT NULL DEFAULT 'community' COMMENT '生效场景',
                `word` varchar(160) NOT NULL COMMENT '敏感词或规则内容',
                `match_type` varchar(20) NOT NULL DEFAULT 'contains' COMMENT '匹配方式:contains/exact/regex',
                `action` varchar(30) NOT NULL DEFAULT 'review' COMMENT '处理动作:review/reject/replace',
                `replacement` varchar(160) NOT NULL DEFAULT '' COMMENT '替换文本',
                `risk_level` tinyint unsigned NOT NULL DEFAULT 1 COMMENT '风险等级:1低,2中,3高',
                `hit_count` int unsigned NOT NULL DEFAULT 0 COMMENT '命中次数',
                `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
                `created_by` int DEFAULT NULL COMMENT '创建人',
                `updated_by` int DEFAULT NULL COMMENT '更新人',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '更新时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                KEY `idx_scene_status` (`scene`, `status`),
                KEY `idx_word` (`word`),
                KEY `idx_risk_level` (`risk_level`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 敏感词与风控规则表'",
        ];
    }

    private function menus(): array
    {
        return [
            [
                'name' => '荣誉徽章规则',
                'code' => 'help/gamification/badgeRule',
                'path' => 'gamification/badgeRule',
                'component' => '/plugin/help/gamification/badgeRule/index',
                'icon' => 'ri:medal-line',
                'sort' => 170,
                'permission_prefix' => 'help:gamification:badgeRule',
            ],
            [
                'name' => '积分流水',
                'code' => 'help/gamification/pointLog',
                'path' => 'gamification/pointLog',
                'component' => '/plugin/help/gamification/pointLog/index',
                'icon' => 'ri:coins-line',
                'sort' => 171,
                'permission_prefix' => 'help:gamification:pointLog',
            ],
            [
                'name' => '回忆录配置',
                'code' => 'help/me/memoirConfig',
                'path' => 'me/memoirConfig',
                'component' => '/plugin/help/me/memoirConfig/index',
                'icon' => 'ri:booklet-line',
                'sort' => 172,
                'permission_prefix' => 'help:me:memoirConfig',
            ],
            [
                'name' => '敏感词规则',
                'code' => 'help/risk/sensitiveWordRule',
                'path' => 'risk/sensitiveWordRule',
                'component' => '/plugin/help/risk/sensitiveWordRule/index',
                'icon' => 'ri:shield-keyhole-line',
                'sort' => 173,
                'permission_prefix' => 'help:risk:sensitiveWordRule',
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
