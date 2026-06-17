<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddMaterialReportAndCommentAudit extends AbstractMigration
{
    private const REMARK = 'phinx:20260617203000_add_material_report_and_comment_audit';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';
    private const REPORT_MENU_CODE = 'help/material/report';
    private const REPORT_PERMISSION_PREFIX = 'help:material:report';
    private const COMMENT_AUDIT_PERMISSION = 'help:material:comment:audit';

    public function up(): void
    {
        $this->createReportTable();
        $this->addCommentAuditColumns();
        $this->insertReportMenu();
        $this->insertCommentAuditPermission();
        $this->grantOperatorRoleMenus();
        $this->clearAuthCaches();
    }

    public function down(): void
    {
        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE m.`remark` = ' . $this->q(self::REMARK)
        );
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->dropCommentAuditColumns();
        $this->execute('DROP TABLE IF EXISTS `sa_material_report`');
        $this->clearAuthCaches();
    }

    private function createReportTable(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_material_report` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '举报会员ID',
                `target_type` tinyint(1) NOT NULL COMMENT '举报类型 1素材 2评论',
                `target_id` bigint(20) unsigned NOT NULL COMMENT '举报目标ID',
                `reason` varchar(100) NOT NULL COMMENT '举报原因',
                `description` varchar(500) NOT NULL DEFAULT '' COMMENT '举报描述',
                `handle_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '处理状态 0待处理 1已处理 2已忽略',
                `handle_remark` varchar(500) NOT NULL DEFAULT '' COMMENT '处理备注',
                `handle_by` int(11) DEFAULT NULL COMMENT '处理人',
                `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_member_id` (`member_id`) USING BTREE,
                KEY `idx_target` (`target_type`, `target_id`) USING BTREE,
                KEY `idx_handle_status` (`handle_status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='素材举报表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function addCommentAuditColumns(): void
    {
        if (!$this->hasTable('sa_material_comment')) {
            return;
        }

        $table = $this->table('sa_material_comment');
        if (!$table->hasColumn('audit_status')) {
            $this->execute(
                "ALTER TABLE `sa_material_comment`
                 ADD COLUMN `audit_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核状态 0待审核 1已通过 2已拒绝 3AI预审标记' AFTER `like_count`"
            );
        }
        if (!$table->hasColumn('audit_remark')) {
            $this->execute(
                "ALTER TABLE `sa_material_comment`
                 ADD COLUMN `audit_remark` varchar(500) NOT NULL DEFAULT '' COMMENT '审核备注' AFTER `audit_status`"
            );
        }
        if (!$table->hasColumn('audit_by')) {
            $this->execute(
                "ALTER TABLE `sa_material_comment`
                 ADD COLUMN `audit_by` int(11) DEFAULT NULL COMMENT '审核人' AFTER `audit_remark`"
            );
        }
        if (!$table->hasColumn('audit_time')) {
            $this->execute(
                "ALTER TABLE `sa_material_comment`
                 ADD COLUMN `audit_time` datetime DEFAULT NULL COMMENT '审核时间' AFTER `audit_by`"
            );
        }
        $table = $this->table('sa_material_comment');
        if (!$table->hasIndex(['audit_status'])) {
            $table->addIndex(['audit_status'], ['name' => 'idx_audit_status']);
        }
        $table->update();
        $this->execute('UPDATE `sa_material_comment` SET `audit_status` = 1 WHERE `audit_status` IS NULL');
    }

    private function dropCommentAuditColumns(): void
    {
        if (!$this->hasTable('sa_material_comment')) {
            return;
        }

        $table = $this->table('sa_material_comment');
        if ($table->hasIndex(['audit_status'])) {
            $table->removeIndex(['audit_status']);
        }
        foreach (['audit_time', 'audit_by', 'audit_remark', 'audit_status'] as $column) {
            if ($table->hasColumn($column)) {
                $table->removeColumn($column);
            }
        }
        $table->update();
    }

    private function insertReportMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`,
                    ' . $this->q('素材举报管理') . ',
                    ' . $this->q(self::REPORT_MENU_CODE) . ',
                    NULL,
                    2,
                    CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN ' . $this->q('/helpsupport/material/report') . ' ELSE ' . $this->q('material/report') . ' END,
                    ' . $this->q('/plugin/help/material/report/index') . ',
                    NULL,
                    ' . $this->q('ri:flag-line') . ',
                    36,
                    ' . $this->q('') . ',
                    2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` IN (' . $this->q('help/material') . ', ' . $this->q('HelpSupport') . ')
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q(self::REPORT_MENU_CODE) . '
                     AND `delete_time` IS NULL
               )
             ORDER BY CASE WHEN parent.`code` = ' . $this->q('help/material') . ' THEN 0 ELSE 1 END
             LIMIT 1'
        );

        foreach ($this->reportPermissions() as $permission) {
            $this->insertPermission(self::REPORT_MENU_CODE, $permission);
        }
    }

    private function insertCommentAuditPermission(): void
    {
        $this->insertPermission('help/material/comment', [
            'name' => '审核',
            'slug' => self::COMMENT_AUDIT_PERMISSION,
            'generate_key' => 'audit',
        ]);
    }

    private function reportPermissions(): array
    {
        return [
            ['name' => '列表', 'slug' => self::REPORT_PERMISSION_PREFIX . ':index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => self::REPORT_PERMISSION_PREFIX . ':save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => self::REPORT_PERMISSION_PREFIX . ':update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => self::REPORT_PERMISSION_PREFIX . ':read', 'generate_key' => 'read'],
            ['name' => '处理', 'slug' => self::REPORT_PERMISSION_PREFIX . ':handle', 'generate_key' => 'handle'],
            ['name' => '删除', 'slug' => self::REPORT_PERMISSION_PREFIX . ':destroy', 'generate_key' => 'destroy'],
        ];
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

    private function grantOperatorRoleMenus(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND rm.`id` IS NULL
               AND (
                   m.`code` IN (' . $this->q('help/material') . ', ' . $this->q(self::REPORT_MENU_CODE) . ')
                   OR m.`slug` LIKE ' . $this->q(self::REPORT_PERMISSION_PREFIX . ':%') . '
                   OR m.`slug` = ' . $this->q(self::COMMENT_AUDIT_PERMISSION) . '
               )'
        );
    }

    private function clearAuthCaches(): void
    {
        try {
            if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
                \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
            }
            if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
                \plugin\saiadmin\app\cache\UserAuthCache::clear();
            }
        } catch (\Throwable) {
            // 缓存清理失败不阻断迁移，管理员重新登录后仍可刷新权限。
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
