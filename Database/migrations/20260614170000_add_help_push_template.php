<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpPushTemplate extends AbstractMigration
{
    private const TABLE = 'sa_push_template';
    private const REMARK = 'phinx:20260614170000_add_help_push_template';

    public function up(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `" . self::TABLE . "` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `template_code` varchar(80) NOT NULL COMMENT '模板编码',
                `template_name` varchar(120) NOT NULL COMMENT '模板名称',
                `scene` varchar(50) NOT NULL DEFAULT '' COMMENT '业务场景',
                `locale` varchar(20) NOT NULL DEFAULT 'en-US' COMMENT '语言',
                `message_type` tinyint(1) NOT NULL DEFAULT 5 COMMENT '消息类型:1关注,2回复,3任务,4预约,5系统',
                `title` varchar(160) NOT NULL COMMENT '标题模板',
                `content` varchar(1000) NOT NULL COMMENT '内容模板',
                `route` varchar(500) DEFAULT NULL COMMENT '默认跳转路由',
                `payload` json DEFAULT NULL COMMENT '默认推送载荷',
                `is_default` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否默认模板:1是,2否',
                `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
                `remark` varchar(255) DEFAULT NULL COMMENT '备注',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_template_locale` (`template_code`, `locale`) USING BTREE,
                KEY `idx_scene_status` (`scene`, `status`) USING BTREE,
                KEY `idx_type_status` (`message_type`, `status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 推送模板表'"
        );

        $this->seedTemplates();
        $this->insertMenu([
            'name' => '推送模板',
            'code' => 'help/push/template',
            'path' => 'push/template',
            'component' => '/plugin/help/push/template/index',
            'icon' => 'ri:notification-3-line',
            'sort' => 152,
            'permissions' => $this->permissions('help:push:template'),
        ]);
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->execute('DROP TABLE IF EXISTS `' . self::TABLE . '`');
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

    private function seedTemplates(): void
    {
        foreach ($this->templates() as $template) {
            $this->execute(
                'INSERT INTO `' . self::TABLE . '` (`template_code`, `template_name`, `scene`, `locale`, `message_type`, `title`, `content`, `route`, `payload`, `is_default`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT ' . $this->q($template['template_code']) . ', ' . $this->q($template['template_name']) . ', ' . $this->q($template['scene']) . ', ' . $this->q($template['locale']) . ', ' . (int) $template['message_type'] . ', ' . $this->q($template['title']) . ', ' . $this->q($template['content']) . ', ' . $this->q($template['route']) . ', ' . $this->q($template['payload']) . ', 1, ' . (int) $template['sort'] . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `' . self::TABLE . '`
                    WHERE `template_code` = ' . $this->q($template['template_code']) . '
                      AND `locale` = ' . $this->q($template['locale']) . '
                )'
            );
        }
    }

    private function templates(): array
    {
        return [
            [
                'template_code' => 'task_reminder',
                'template_name' => '任务提醒',
                'scene' => 'task_reminder',
                'locale' => 'zh-CN',
                'message_type' => 3,
                'title' => '今天的任务提醒',
                'content' => '你有一个待完成任务：{task_title}',
                'route' => '/pages/plan/tasks',
                'payload' => '{"scene":"task_reminder"}',
                'sort' => 10,
            ],
            [
                'template_code' => 'task_reminder',
                'template_name' => 'Task Reminder',
                'scene' => 'task_reminder',
                'locale' => 'en-US',
                'message_type' => 3,
                'title' => 'Task reminder',
                'content' => 'You have a pending task: {task_title}',
                'route' => '/pages/plan/tasks',
                'payload' => '{"scene":"task_reminder"}',
                'sort' => 10,
            ],
            [
                'template_code' => 'community_reply',
                'template_name' => '社区回复',
                'scene' => 'community_reply',
                'locale' => 'zh-CN',
                'message_type' => 2,
                'title' => '有人回复了你',
                'content' => '{nickname} 回复了你的内容',
                'route' => '/pages/community/detail',
                'payload' => '{"scene":"community_reply"}',
                'sort' => 20,
            ],
            [
                'template_code' => 'community_reply',
                'template_name' => 'Community Reply',
                'scene' => 'community_reply',
                'locale' => 'en-US',
                'message_type' => 2,
                'title' => 'New reply',
                'content' => '{nickname} replied to your post',
                'route' => '/pages/community/detail',
                'payload' => '{"scene":"community_reply"}',
                'sort' => 20,
            ],
            [
                'template_code' => 'appointment_update',
                'template_name' => '预约状态更新',
                'scene' => 'appointment_update',
                'locale' => 'zh-CN',
                'message_type' => 4,
                'title' => '预约状态更新',
                'content' => '你的预约状态已更新：{status_text}',
                'route' => '/pages/appointment/detail',
                'payload' => '{"scene":"appointment_update"}',
                'sort' => 30,
            ],
            [
                'template_code' => 'appointment_update',
                'template_name' => 'Appointment Update',
                'scene' => 'appointment_update',
                'locale' => 'en-US',
                'message_type' => 4,
                'title' => 'Appointment update',
                'content' => 'Your appointment status changed: {status_text}',
                'route' => '/pages/appointment/detail',
                'payload' => '{"scene":"appointment_update"}',
                'sort' => 30,
            ],
            [
                'template_code' => 'doctor_audit_result',
                'template_name' => '医生审核结果',
                'scene' => 'doctor_audit_result',
                'locale' => 'zh-CN',
                'message_type' => 5,
                'title' => '医生资质审核结果',
                'content' => '你的医生资质审核结果：{audit_status_text}',
                'route' => '/pages/me/doctor-certification',
                'payload' => '{"scene":"doctor_audit_result"}',
                'sort' => 40,
            ],
            [
                'template_code' => 'doctor_audit_result',
                'template_name' => 'Doctor Audit Result',
                'scene' => 'doctor_audit_result',
                'locale' => 'en-US',
                'message_type' => 5,
                'title' => 'Doctor verification result',
                'content' => 'Your doctor verification result: {audit_status_text}',
                'route' => '/pages/me/doctor-certification',
                'payload' => '{"scene":"doctor_audit_result"}',
                'sort' => 40,
            ],
            [
                'template_code' => 'system_notice',
                'template_name' => '系统公告',
                'scene' => 'system_notice',
                'locale' => 'zh-CN',
                'message_type' => 5,
                'title' => '{title}',
                'content' => '{content}',
                'route' => '/pages/message/detail',
                'payload' => '{"scene":"system_notice"}',
                'sort' => 50,
            ],
            [
                'template_code' => 'system_notice',
                'template_name' => 'System Notice',
                'scene' => 'system_notice',
                'locale' => 'en-US',
                'message_type' => 5,
                'title' => '{title}',
                'content' => '{content}',
                'route' => '/pages/message/detail',
                'payload' => '{"scene":"system_notice"}',
                'sort' => 50,
            ],
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

        foreach ($menu['permissions'] as $permission) {
            $this->insertPermission($menu['code'], $permission);
        }
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
