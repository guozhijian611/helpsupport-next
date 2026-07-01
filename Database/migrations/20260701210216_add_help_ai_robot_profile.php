<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpAiRobotProfile extends AbstractMigration
{
    private const REMARK = 'phinx:20260701210216_add_help_ai_robot_profile';

    public function up(): void
    {
        $this->createTable();
        $this->seedProfiles();
        $this->insertMenu();
        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->execute('DROP TABLE IF EXISTS `sa_ai_robot_profile`');
    }

    private function createTable(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_ai_robot_profile` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `chat_mode` varchar(50) NOT NULL COMMENT '聊天模式 doctor/companion/patient',
                `runtime_mode` varchar(20) NOT NULL DEFAULT 'online' COMMENT '运行模式 online/local',
                `display_name` varchar(80) NOT NULL DEFAULT '' COMMENT '显示名称',
                `display_name_en` varchar(80) NOT NULL DEFAULT '' COMMENT '英文显示名称',
                `description` varchar(500) NOT NULL DEFAULT '' COMMENT '简介',
                `description_en` varchar(500) NOT NULL DEFAULT '' COMMENT '英文简介',
                `avatar` varchar(500) NOT NULL DEFAULT '' COMMENT '浅色头像',
                `dark_avatar` varchar(500) NOT NULL DEFAULT '' COMMENT '深色头像',
                `sort` int(11) NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_mode_runtime` (`chat_mode`, `runtime_mode`) USING BTREE,
                KEY `idx_runtime_status_sort` (`runtime_mode`, `status`, `sort`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI机器人形象配置表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function seedProfiles(): void
    {
        foreach ($this->profiles() as $profile) {
            $this->execute(
                'INSERT INTO `sa_ai_robot_profile` (`chat_mode`, `runtime_mode`, `display_name`, `display_name_en`, `description`, `description_en`, `avatar`, `dark_avatar`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT ' . $this->q($profile['chat_mode']) . ', ' . $this->q($profile['runtime_mode']) . ', ' . $this->q($profile['display_name']) . ', ' . $this->q($profile['display_name_en']) . ', ' . $this->q($profile['description']) . ', ' . $this->q($profile['description_en']) . ', ' . $this->q($profile['avatar']) . ', ' . $this->q($profile['dark_avatar']) . ', ' . (int) $profile['sort'] . ', 1, 1, 1, NOW(), NOW(), NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `sa_ai_robot_profile`
                    WHERE `chat_mode` = ' . $this->q($profile['chat_mode']) . '
                      AND `runtime_mode` = ' . $this->q($profile['runtime_mode']) . '
                      AND `delete_time` IS NULL
                )'
            );
        }
    }

    private function profiles(): array
    {
        return [
            $this->profile('doctor', 'online', 'AI 心理医生', 'AI doctor', '谨慎、温和的心理支持助手', 'Careful and gentle mental health support', 'HelpSupport Doctor', 10),
            $this->profile('companion', 'online', 'AI 心理陪伴', 'AI companion', '稳定、耐心的陪伴式支持助手', 'Steady and patient companion support', 'HelpSupport Companion', 20),
            $this->profile('patient', 'online', 'AI 模拟病人', 'AI patient', '用于角色演练和沟通练习的模拟病人', 'A simulated patient for role-play and communication practice', 'HelpSupport Patient', 30),
            $this->profile('doctor', 'local', '本地 AI 心理医生', 'Local AI doctor', '本地心理医生形象，当前客户端默认不开放入口', 'Local AI doctor profile, currently hidden by client entry rules', 'HelpSupport Local Doctor', 40),
            $this->profile('companion', 'local', '本地 AI 心理陪伴', 'Local AI companion', '使用本地模型的私密陪伴式支持助手', 'Private companion support powered by on-device models', 'HelpSupport Local Companion', 50),
            $this->profile('patient', 'local', '本地 AI 模拟病人', 'Local AI patient', '使用本地模型进行角色演练和沟通练习', 'On-device role-play and communication practice', 'HelpSupport Local Patient', 60),
        ];
    }

    private function profile(
        string $chatMode,
        string $runtimeMode,
        string $displayName,
        string $displayNameEn,
        string $description,
        string $descriptionEn,
        string $seed,
        int $sort
    ): array {
        $avatar = 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=' . rawurlencode($seed);

        return [
            'chat_mode' => $chatMode,
            'runtime_mode' => $runtimeMode,
            'display_name' => $displayName,
            'display_name_en' => $displayNameEn,
            'description' => $description,
            'description_en' => $descriptionEn,
            'avatar' => $avatar,
            'dark_avatar' => $avatar,
            'sort' => $sort,
        ];
    }

    private function insertMenu(): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q('机器人形象') . ', ' . $this->q('help/chat/robotProfile') . ', NULL, 2, ' . $this->q('chat/robotProfile') . ', ' . $this->q('/plugin/help/chat/robotProfile/index') . ', NULL, ' . $this->q('ri:robot-2-line') . ', 122, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('HelpSupport') . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `code` = ' . $this->q('help/chat/robotProfile') . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    private function permissions(): array
    {
        $prefix = 'help:chat:robotProfile';
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

    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('help/chat/robotProfile') . '
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
