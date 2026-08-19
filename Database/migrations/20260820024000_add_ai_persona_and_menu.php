<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 互动角色、系统预设提示词、本地模型能力分类，以及 AI 管理菜单归位。
 */
final class AddAiPersonaAndMenu extends AbstractMigration
{
    private const REMARK = 'phinx:20260820024000_add_ai_persona_and_menu';
    private const ROOT_CODE = 'help/aiModel';
    private const PERSONA_CODE = 'help/chat/persona';

    public function up(): void
    {
        $this->createPersonaTable();
        $this->createPromptTable();
        $this->addLocalModelCapability();
        $this->seedPersonas();
        $this->reorganizeMenus();
        $this->grantRoleMenus();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        $this->restoreMenus();
        if ($this->hasTable('sa_local_model_catalog') && $this->table('sa_local_model_catalog')->hasColumn('capability')) {
            $this->table('sa_local_model_catalog')->removeColumn('capability')->update();
        }
        if ($this->hasTable('sa_ai_persona_prompt')) {
            $this->table('sa_ai_persona_prompt')->drop()->save();
        }
        if ($this->hasTable('sa_ai_persona')) {
            $this->table('sa_ai_persona')->drop()->save();
        }
        if ($this->hasTable('sa_system_role_menu')) {
            $this->execute(
                'DELETE rm FROM `sa_system_role_menu` rm
                 INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
                 WHERE m.`remark` = ' . $this->q(self::REMARK)
            );
        }
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->clearMenuCaches();
    }

    private function createPersonaTable(): void
    {
        if ($this->hasTable('sa_ai_persona')) {
            return;
        }
        $this->execute(
            "CREATE TABLE `sa_ai_persona` (
                `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `code` varchar(50) NOT NULL COMMENT '角色编码，写入会话 chat_mode',
                `is_system` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否内置 1是 2否',
                `title_i18n` json DEFAULT NULL COMMENT '多语言标题',
                `description_i18n` json DEFAULT NULL COMMENT '多语言简介',
                `tags_i18n` json DEFAULT NULL COMMENT '多语言标签',
                `cover` varchar(500) NOT NULL DEFAULT '' COMMENT '浅色封面/头像',
                `cover_dark` varchar(500) NOT NULL DEFAULT '' COMMENT '深色封面/头像',
                `allow_online` tinyint(1) NOT NULL DEFAULT 1 COMMENT '开放在线 1是 2否',
                `allow_local` tinyint(1) NOT NULL DEFAULT 1 COMMENT '开放本地 1是 2否',
                `allow_realtime` tinyint(1) NOT NULL DEFAULT 2 COMMENT '开放实时音视频 1是 2否',
                `allow_voice` tinyint(1) NOT NULL DEFAULT 1 COMMENT '开放语音 1是 2否',
                `allow_user_prompt` tinyint(1) NOT NULL DEFAULT 1 COMMENT '允许用户改提示词 1是 2否',
                `speech_runtime` varchar(20) NOT NULL DEFAULT 'online' COMMENT '语音运行时 online/local/auto',
                `online_config_id` int NOT NULL DEFAULT 0 COMMENT '默认在线文本模型',
                `realtime_config_id` int NOT NULL DEFAULT 0 COMMENT '角色绑定的 realtime 配置',
                `asr_config_id` int NOT NULL DEFAULT 0 COMMENT '在线 ASR 配置',
                `tts_config_id` int NOT NULL DEFAULT 0 COMMENT '在线 TTS 配置',
                `tts_voice` varchar(80) NOT NULL DEFAULT '' COMMENT '默认音色',
                `local_model_id` int NOT NULL DEFAULT 0 COMMENT '默认本地文本模型',
                `local_asr_id` int NOT NULL DEFAULT 0 COMMENT '端侧 ASR 目录ID',
                `local_tts_id` int NOT NULL DEFAULT 0 COMMENT '端侧 TTS 目录ID',
                `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int DEFAULT NULL COMMENT '创建者',
                `updated_by` int DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_code` (`code`),
                KEY `idx_status_sort` (`status`, `sort`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='互动聊天角色表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createPromptTable(): void
    {
        if ($this->hasTable('sa_ai_persona_prompt')) {
            return;
        }
        $this->execute(
            "CREATE TABLE `sa_ai_persona_prompt` (
                `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `persona_id` bigint unsigned NOT NULL COMMENT '角色ID',
                `runtime_mode` varchar(20) NOT NULL DEFAULT 'online' COMMENT 'online/local',
                `locale` varchar(20) NOT NULL DEFAULT 'zh-CN' COMMENT '语言',
                `title` varchar(160) NOT NULL DEFAULT '' COMMENT '提示词标题',
                `system_prompt` text COMMENT '系统预设提示词',
                `first_message` varchar(1000) NOT NULL DEFAULT '' COMMENT '默认开场白',
                `safety_prompt` text COMMENT '安全边界提示',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int DEFAULT NULL COMMENT '创建者',
                `updated_by` int DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_persona_runtime_locale` (`persona_id`, `runtime_mode`, `locale`),
                KEY `idx_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='互动角色系统预设提示词' ROW_FORMAT=DYNAMIC"
        );
    }

    private function addLocalModelCapability(): void
    {
        if (!$this->hasTable('sa_local_model_catalog')) {
            return;
        }
        $table = $this->table('sa_local_model_catalog');
        if (!$table->hasColumn('capability')) {
            $table->addColumn('capability', 'string', [
                'limit' => 20,
                'default' => 'llm',
                'null' => false,
                'comment' => '能力 llm/asr/tts',
                'after' => 'model_family',
            ])->update();
        }
    }

    private function seedPersonas(): void
    {
        if (!$this->hasTable('sa_ai_persona')) {
            return;
        }
        foreach ($this->systemPersonas() as $persona) {
            $this->execute(
                'INSERT INTO `sa_ai_persona` (`code`, `is_system`, `title_i18n`, `description_i18n`, `tags_i18n`, `cover`, `cover_dark`, `allow_online`, `allow_local`, `allow_realtime`, `allow_voice`, `allow_user_prompt`, `speech_runtime`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT ' . $this->q($persona['code']) . ', 1, ' . $this->q($persona['title_i18n']) . ', ' . $this->q($persona['description_i18n']) . ', ' . $this->q($persona['tags_i18n']) . ', ' . $this->q($persona['cover']) . ', ' . $this->q($persona['cover_dark']) . ', ' . (int) $persona['allow_online'] . ', ' . (int) $persona['allow_local'] . ', ' . (int) $persona['allow_realtime'] . ', 1, ' . (int) $persona['allow_user_prompt'] . ', ' . $this->q('online') . ', ' . (int) $persona['sort'] . ', 1, 1, 1, NOW(), NOW(), NULL
                WHERE NOT EXISTS (SELECT 1 FROM `sa_ai_persona` WHERE `code` = ' . $this->q($persona['code']) . ')'
            );
            $this->execute(
                'INSERT INTO `sa_ai_persona_prompt` (`persona_id`, `runtime_mode`, `locale`, `title`, `system_prompt`, `first_message`, `safety_prompt`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`)
                SELECT p.`id`, ' . $this->q('online') . ', ' . $this->q('zh-CN') . ', ' . $this->q($persona['prompt_title']) . ', ' . $this->q($persona['system_prompt']) . ', ' . $this->q($persona['first_message']) . ', ' . $this->q('') . ', 1, 1, 1, NOW(), NOW()
                FROM `sa_ai_persona` p
                WHERE p.`code` = ' . $this->q($persona['code']) . '
                  AND NOT EXISTS (
                      SELECT 1 FROM `sa_ai_persona_prompt` x
                      WHERE x.`persona_id` = p.`id` AND x.`runtime_mode` = ' . $this->q('online') . ' AND x.`locale` = ' . $this->q('zh-CN') . '
                  )'
            );
        }

        if ($this->hasTable('sa_ai_robot_profile')) {
            $this->execute(
                "UPDATE `sa_ai_persona` persona
                 INNER JOIN `sa_ai_robot_profile` profile
                         ON profile.`chat_mode` = persona.`code`
                        AND profile.`runtime_mode` = 'online'
                        AND profile.`delete_time` IS NULL
                 SET persona.`cover` = CASE WHEN persona.`cover` = '' THEN profile.`avatar` ELSE persona.`cover` END,
                     persona.`cover_dark` = CASE WHEN persona.`cover_dark` = '' THEN profile.`dark_avatar` ELSE persona.`cover_dark` END,
                     persona.`update_time` = NOW()
                 WHERE persona.`delete_time` IS NULL"
            );
        }
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function systemPersonas(): array
    {
        return [
            $this->persona('doctor', 'AI 心理医生', 'AI doctor', '谨慎、温和的心理支持助手', 'Careful and gentle mental health support', ['心理', '实时'], ['therapy'], 1, 2, 1, 2, 10, '心理医生预设', '你是一位谨慎、温和的 AI 心理医生助手。请优先安抚情绪、澄清问题、给出可执行建议。你不能冒充真实执业诊断。', '告诉我你现在最想处理的感受。'),
            $this->persona('companion', 'AI 心理陪伴', 'AI companion', '稳定、耐心的陪伴式支持助手', 'Steady and patient companion support', ['陪伴'], ['companion'], 1, 1, 2, 1, 20, '陪伴预设', '你是一位温柔、稳定、耐心的 AI 心理陪伴助手。请多倾听、多共情，避免说教。', '我在这里陪你。现在最想聊的是什么？'),
            $this->persona('patient', 'AI 模拟病人', 'AI patient', '用于角色演练和沟通练习的模拟病人', 'A simulated patient for role-play', ['演练'], ['roleplay'], 1, 1, 2, 1, 30, '模拟病人预设', '你是一位帮助用户整理病情和感受的 AI 助手。请帮助用户梳理症状、情绪和诱因。', '今天想练习哪一段沟通？'),
            $this->persona('ai_doctor', 'AI 医生', 'AI clinician', '帮助整理健康问题和就诊准备的 AI 助手', 'An AI assistant for visit preparation', ['健康'], ['health'], 1, 1, 2, 1, 40, 'AI医生预设', '你是一位谨慎的 AI 健康信息助手。请帮助用户整理症状和需要向医生询问的问题，不能做诊断或开药。', '告诉我你想为就诊准备什么。'),
        ];
    }

    /**
     * @param list<string> $tagsZh
     * @param list<string> $tagsEn
     * @return array<string, mixed>
     */
    private function persona(
        string $code,
        string $titleZh,
        string $titleEn,
        string $descZh,
        string $descEn,
        array $tagsZh,
        array $tagsEn,
        int $allowOnline,
        int $allowLocal,
        int $allowRealtime,
        int $allowUserPrompt,
        int $sort,
        string $promptTitle,
        string $systemPrompt,
        string $firstMessage
    ): array {
        $cover = 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=' . rawurlencode('HelpSupport ' . $code);

        return [
            'code' => $code,
            'title_i18n' => json_encode(['zh-CN' => $titleZh, 'en' => $titleEn], JSON_UNESCAPED_UNICODE),
            'description_i18n' => json_encode(['zh-CN' => $descZh, 'en' => $descEn], JSON_UNESCAPED_UNICODE),
            'tags_i18n' => json_encode(['zh-CN' => $tagsZh, 'en' => $tagsEn], JSON_UNESCAPED_UNICODE),
            'cover' => $cover,
            'cover_dark' => $cover,
            'allow_online' => $allowOnline,
            'allow_local' => $allowLocal,
            'allow_realtime' => $allowRealtime,
            'allow_user_prompt' => $allowUserPrompt,
            'sort' => $sort,
            'prompt_title' => $promptTitle,
            'system_prompt' => $systemPrompt,
            'first_message' => $firstMessage,
        ];
    }

    private function reorganizeMenus(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('AI 管理') . ',
                 `icon` = ' . $this->q('ri:brain-line') . ',
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q(self::ROOT_CODE) . '
               AND `delete_time` IS NULL'
        );

        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q('互动角色') . ', ' . $this->q(self::PERSONA_CODE) . ', NULL, 2, ' . $this->q('/helpsupport/chat/persona') . ', ' . $this->q('/plugin/help/chat/persona/index') . ', NULL, ' . $this->q('ri:user-star-line') . ', 5, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu`
             WHERE `code` = ' . $this->q(self::ROOT_CODE) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q(self::PERSONA_CODE) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );

        foreach ($this->personaPermissions() as $permission) {
            $this->execute(
                'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
                 FROM `sa_system_menu`
                 WHERE `code` = ' . $this->q(self::PERSONA_CODE) . '
                   AND `delete_time` IS NULL
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_menu`
                       WHERE `slug` = ' . $this->q($permission['slug']) . '
                         AND `delete_time` IS NULL
                   )
                 LIMIT 1'
            );
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('模型测试') . ',
                 `sort` = 90,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('saiai/chat/group') . '
               AND `delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('实时测试') . ',
                 `sort` = 91,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('saiai/realtime/test') . '
               AND `delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('在线模型') . ',
                 `sort` = 20,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('saiai/config/config') . '
               AND `delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q(self::ROOT_CODE) . '
                    AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`delete_time` IS NULL
               AND page.`code` IN (' . $this->q('saiai/config/config') . ', ' . $this->q('saiai/chat/group') . ', ' . $this->q('saiai/realtime/test') . ')'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `status` = 2,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` IN (' . $this->q('Saiai') . ', ' . $this->q('SaiManage') . ', ' . $this->q('help/chat/robotProfile') . ')
               AND `delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('用户改写提示词') . ',
                 `sort` = 40,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/chat/config') . '
               AND `delete_time` IS NULL'
        );
    }

    private function grantRoleMenus(): void
    {
        if (!$this->hasTable('sa_system_role_menu') || !$this->hasTable('sa_system_menu')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT DISTINCT rm.`role_id`, target.`id`
             FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` source ON source.`id` = rm.`menu_id` AND source.`delete_time` IS NULL
             INNER JOIN `sa_system_menu` target ON target.`remark` = ' . $this->q(self::REMARK) . ' AND target.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = target.`id`
             WHERE source.`code` IN (' . $this->q(self::ROOT_CODE) . ', ' . $this->q('saiai/config/config') . ')
               AND existing.`id` IS NULL'
        );
    }

    private function restoreMenus(): void
    {
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `name` = ' . $this->q('AI与模型') . ',
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q(self::ROOT_CODE)
        );
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q('SaiManage') . '
             SET page.`parent_id` = parent.`id`,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` IN (' . $this->q('saiai/config/config') . ', ' . $this->q('saiai/chat/group') . ', ' . $this->q('saiai/realtime/test') . ')'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `status` = 1,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` IN (' . $this->q('Saiai') . ', ' . $this->q('SaiManage') . ', ' . $this->q('help/chat/robotProfile') . ')'
        );
    }

    /**
     * @return list<array{name:string,slug:string,generate_key:string}>
     */
    private function personaPermissions(): array
    {
        $prefix = 'help:chat:persona';
        return [
            ['name' => '列表', 'slug' => $prefix . ':index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => $prefix . ':save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => $prefix . ':update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => $prefix . ':read', 'generate_key' => 'read'],
            ['name' => '删除', 'slug' => $prefix . ':destroy', 'generate_key' => 'destroy'],
        ];
    }

    private function clearMenuCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
            \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
