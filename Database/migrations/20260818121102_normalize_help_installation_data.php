<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class NormalizeHelpInstallationData extends AbstractMigration
{
    private const ROOT_CODE = 'HelpSupport';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';
    private const REMARK = 'phinx:20260818121102_normalize_help_installation_data';

    /** @var int[] */
    private const DEMO_MEMBER_IDS = [
        986170009,
        986170020,
        986170021,
        986170022,
        986170023,
        986170024,
        986170025,
    ];

    public function up(): void
    {
        $this->normalizeMenuHierarchy();
        $this->grantHelpMenusToOperatorRole();
        $this->normalizeOnboardingPages();
        $this->removeHelpDemoData();
    }

    public function down(): void
    {
        throw new RuntimeException(
            '该迁移会永久清理已明确标记的 HelpSupport 演示数据，不支持自动回滚；如需恢复，请使用迁移前备份。'
        );
    }

    private function normalizeMenuHierarchy(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ($this->menuGroups() as $group) {
            $this->ensureMenuGroup($group);
        }

        foreach ($this->menuFamilies() as $groupCode => $prefixes) {
            $this->moveMenuFamily($groupCode, $prefixes);
        }

        $this->execute(
            'UPDATE `sa_system_menu` root
             LEFT JOIN `sa_system_menu` child
                    ON child.`parent_id` = root.`id`
                   AND child.`delete_time` IS NULL
             SET root.`status` = 2,
                 root.`updated_by` = 1,
                 root.`update_time` = NOW(),
                 root.`delete_time` = COALESCE(root.`delete_time`, NOW())
             WHERE root.`code` = ' . $this->q(self::ROOT_CODE) . '
               AND child.`id` IS NULL'
        );
    }

    /**
     * @return array<int, array{name: string, code: string, path: string, icon: string, sort: int}>
     */
    private function menuGroups(): array
    {
        return [
            ['name' => '运营配置', 'code' => 'help/config', 'path' => '/helpsupport/config', 'icon' => 'ri:settings-4-line', 'sort' => 80],
            ['name' => '社区管理', 'code' => 'help/community', 'path' => '/helpsupport/community', 'icon' => 'ri:community-line', 'sort' => 81],
            ['name' => '素材内容', 'code' => 'help/material', 'path' => '/helpsupport/material', 'icon' => 'ri:book-open-line', 'sort' => 82],
            ['name' => 'AI与模型', 'code' => 'help/aiModel', 'path' => '/helpsupport/ai-model', 'icon' => 'ri:brain-line', 'sort' => 84],
            ['name' => '治疗计划', 'code' => 'help/plan', 'path' => '/helpsupport/plan', 'icon' => 'ri:calendar-check-line', 'sort' => 85],
            ['name' => '医生服务', 'code' => 'help/doctor', 'path' => '/helpsupport/doctor', 'icon' => 'ri:user-heart-line', 'sort' => 86],
            ['name' => '消息推送', 'code' => 'help/push', 'path' => '/helpsupport/push', 'icon' => 'ri:notification-3-line', 'sort' => 87],
            ['name' => '用户成长与风控', 'code' => 'help/growth', 'path' => '/helpsupport/growth', 'icon' => 'ri:shield-star-line', 'sort' => 88],
        ];
    }

    /**
     * @return array<string, string[]>
     */
    private function menuFamilies(): array
    {
        return [
            'help/config' => ['help/config/'],
            'help/community' => ['help/community/'],
            'help/material' => ['help/material/'],
            'help/aiModel' => ['help/chat/', 'help/localModel/'],
            'help/plan' => ['help/plan/'],
            'help/doctor' => ['help/audit/', 'help/doctor/', 'help/appointment/'],
            'help/push' => ['help/message/', 'help/push/'],
            'help/growth' => ['help/gamification/', 'help/me/', 'help/risk/'],
        ];
    }

    /**
     * @param array{name: string, code: string, path: string, icon: string, sort: int} $group
     */
    private function ensureMenuGroup(array $group): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT 0, ' . $this->q($group['name']) . ', ' . $this->q($group['code']) . ', NULL, 1, ' . $this->q($group['path']) . ', ' . $this->q('') . ', NULL, ' . $this->q($group['icon']) . ', ' . (int) $group['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_menu`
                 WHERE `code` = ' . $this->q($group['code']) . '
                   AND `delete_time` IS NULL
             )'
        );

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `parent_id` = 0,
                 `name` = ' . $this->q($group['name']) . ',
                 `type` = 1,
                 `path` = ' . $this->q($group['path']) . ',
                 `component` = ' . $this->q('') . ',
                 `icon` = ' . $this->q($group['icon']) . ',
                 `sort` = ' . (int) $group['sort'] . ',
                 `status` = 1,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q($group['code']) . '
               AND `delete_time` IS NULL'
        );
    }

    /**
     * @param string[] $prefixes
     */
    private function moveMenuFamily(string $groupCode, array $prefixes): void
    {
        $conditions = [];
        foreach ($prefixes as $prefix) {
            $conditions[] = 'page.`code` LIKE ' . $this->q($prefix . '%');
        }

        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q($groupCode) . '
                    AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`path` = CASE
                     WHEN page.`path` LIKE ' . $this->q('/helpsupport/%') . ' THEN page.`path`
                     ELSE CONCAT(' . $this->q('/helpsupport/') . ', TRIM(LEADING ' . $this->q('/') . ' FROM page.`path`))
                 END,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`type` = 2
               AND page.`delete_time` IS NULL
               AND (' . implode(' OR ', $conditions) . ')'
        );
    }

    private function grantHelpMenusToOperatorRole(): void
    {
        if (!$this->hasTable('sa_system_role') || !$this->hasTable('sa_system_role_menu')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT role.`id`, menu.`id`
             FROM `sa_system_role` role
             INNER JOIN `sa_system_menu` menu
                     ON menu.`delete_time` IS NULL
                    AND menu.`status` = 1
                    AND (menu.`code` LIKE ' . $this->q('help/%') . ' OR menu.`slug` LIKE ' . $this->q('help:%') . ')
             LEFT JOIN `sa_system_role_menu` existing
                    ON existing.`role_id` = role.`id`
                   AND existing.`menu_id` = menu.`id`
             WHERE role.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
               AND role.`delete_time` IS NULL
               AND existing.`id` IS NULL'
        );
    }

    private function normalizeOnboardingPages(): void
    {
        if (!$this->hasTable('sa_app_onboarding_page')) {
            return;
        }

        foreach ($this->onboardingPages() as $locale => $pages) {
            foreach ($pages as $page) {
                $this->execute(
                    'UPDATE `sa_app_onboarding_page`
                     SET `title` = ' . $this->q($page['title']) . ',
                         `description` = ' . $this->q($page['description']) . ',
                         `image` = ' . $this->q($page['image']) . ',
                         `button_text` = ' . $this->q($page['button_text']) . ',
                         `action_type` = ' . $this->q($page['action_type']) . ',
                         `action_value` = ' . $this->q('') . ',
                         `status` = 1,
                         `updated_by` = 1,
                         `update_time` = NOW()
                     WHERE `scene` = ' . $this->q('first_launch') . '
                       AND `version` = ' . $this->q('') . '
                       AND `locale` = ' . $this->q($locale) . '
                       AND `sort` = ' . (int) $page['sort'] . '
                       AND `delete_time` IS NULL
                       AND (`action_value` LIKE ' . $this->q('demo:onboarding:%') . '
                            OR `image` LIKE ' . $this->q('https://picsum.photos/%') . ')'
                );

                $this->execute(
                    'INSERT INTO `sa_app_onboarding_page` (`scene`, `version`, `locale`, `title`, `description`, `image`, `button_text`, `action_type`, `action_value`, `sort`, `status`, `start_time`, `end_time`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                     SELECT ' . $this->q('first_launch') . ', ' . $this->q('') . ', ' . $this->q($locale) . ', ' . $this->q($page['title']) . ', ' . $this->q($page['description']) . ', ' . $this->q($page['image']) . ', ' . $this->q($page['button_text']) . ', ' . $this->q($page['action_type']) . ', ' . $this->q('') . ', ' . (int) $page['sort'] . ', 1, NULL, NULL, 1, 1, NOW(), NOW(), NULL
                     WHERE NOT EXISTS (
                         SELECT 1 FROM `sa_app_onboarding_page`
                         WHERE `scene` = ' . $this->q('first_launch') . '
                           AND `version` = ' . $this->q('') . '
                           AND `locale` = ' . $this->q($locale) . '
                           AND `sort` = ' . (int) $page['sort'] . '
                           AND `delete_time` IS NULL
                     )'
                );
            }
        }
    }

    /**
     * @return array<string, array<int, array{sort: int, title: string, description: string, image: string, button_text: string, action_type: string}>>
     */
    private function onboardingPages(): array
    {
        $images = [
            10 => 'https://r2.openb8.com/openb8/helpsupport/c2688de2e90ee6e207d38c48695b8ce1.png',
            20 => 'https://r2.openb8.com/openb8/helpsupport/41a662486cab2447470d695cf1f1e27d.png',
            30 => 'https://r2.openb8.com/openb8/helpsupport/866a78dfcfdbf3cc84241ed132aa3d72.png',
        ];

        $zh = [
            ['sort' => 10, 'title' => '通往新生，每一步都算数', 'description' => '“每一次认真的自我评估，都是向内观照的足迹；每一份被记录的情绪数据，都在描绘你康复的轨迹”', 'image' => $images[10], 'button_text' => '继续', 'action_type' => 'next'],
            ['sort' => 20, 'title' => '戒断，是告别，更是开始', 'description' => '“告别过去的挣扎，开始科学的康复。洞察自身变化，在医生的指引下，主动掌控健康。”', 'image' => $images[20], 'button_text' => '继续', 'action_type' => 'next'],
            ['sort' => 30, 'title' => '你的康复之路，不再独行', 'description' => '“你的每一条记录，医生都在云端关切；你的每一次波动，都有专业工具为你解读。我们，是你24小时在线的支持系统。”', 'image' => $images[30], 'button_text' => '开启个人定制专属陪伴', 'action_type' => 'skip'],
        ];

        $en = [
            ['sort' => 10, 'title' => 'Every step toward renewal matters', 'description' => 'Every thoughtful self-assessment and every recorded emotion helps reveal the path of your recovery.', 'image' => $images[10], 'button_text' => 'Continue', 'action_type' => 'next'],
            ['sort' => 20, 'title' => 'Recovery is both a farewell and a beginning', 'description' => 'Understand your changes, follow professional guidance, and take an active role in your health.', 'image' => $images[20], 'button_text' => 'Continue', 'action_type' => 'next'],
            ['sort' => 30, 'title' => 'You do not have to recover alone', 'description' => 'Your records stay connected with professional support and practical tools whenever you need them.', 'image' => $images[30], 'button_text' => 'Start personalized support', 'action_type' => 'skip'],
        ];

        return ['zh' => $zh, 'zh-CN' => $zh, 'en-US' => $en];
    }

    private function removeHelpDemoData(): void
    {
        $this->deleteDemoContentInteractions();
        $this->deleteComprehensiveSeedIds();
        $this->deleteRowsOwnedByDemoMembers();
        $this->deleteRowsMarkedAsDemo();
        $this->deleteExplicitTestFixtures();
        $this->deleteDemoMembers();
        $this->syncMemberPointsBalance(986170008);
    }

    private function deleteDemoContentInteractions(): void
    {
        $ids = $this->integerList(self::DEMO_MEMBER_IDS);
        $materialIds = $this->integerList(range(8911, 8924));

        $queries = [
            'DELETE target FROM `sa_community_like` target INNER JOIN `sa_community_post` post ON target.`target_type` = 1 AND target.`target_id` = post.`id` WHERE post.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_community_report` target INNER JOIN `sa_community_post` post ON target.`target_type` = 1 AND target.`target_id` = post.`id` WHERE post.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_community_collect` target INNER JOIN `sa_community_post` post ON target.`post_id` = post.`id` WHERE post.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_community_like` target INNER JOIN `sa_community_comment` comment ON target.`target_type` = 2 AND target.`target_id` = comment.`id` WHERE comment.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_community_report` target INNER JOIN `sa_community_comment` comment ON target.`target_type` = 2 AND target.`target_id` = comment.`id` WHERE comment.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_material_comment_like` target INNER JOIN `sa_material_comment` comment ON target.`comment_id` = comment.`id` WHERE comment.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_material_like` target INNER JOIN `sa_content_material` material ON target.`material_id` = material.`id` WHERE material.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_material_collect` target INNER JOIN `sa_content_material` material ON target.`material_id` = material.`id` WHERE material.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_material_comment` target INNER JOIN `sa_content_material` material ON target.`material_id` = material.`id` WHERE material.`member_id` IN (' . $ids . ')',
            'DELETE target FROM `sa_material_comment_like` target INNER JOIN `sa_material_comment` comment ON target.`comment_id` = comment.`id` WHERE comment.`material_id` IN (' . $materialIds . ')',
            'DELETE target FROM `sa_material_report` target INNER JOIN `sa_material_comment` comment ON target.`target_type` = 2 AND target.`target_id` = comment.`id` WHERE comment.`material_id` IN (' . $materialIds . ')',
        ];

        foreach ($queries as $query) {
            $table = $this->tableNameFromDelete($query);
            if ($table !== null && $this->hasTable($table)) {
                $this->execute($query);
            }
        }

        $directQueries = [
            'sa_material_like' => '`material_id` IN (' . $materialIds . ')',
            'sa_material_collect' => '`material_id` IN (' . $materialIds . ')',
            'sa_material_comment' => '`material_id` IN (' . $materialIds . ')',
            'sa_material_report' => '`target_type` = 1 AND `target_id` IN (' . $materialIds . ')',
            'sa_member_content_history' => '`content_type` = ' . $this->q('material') . ' AND `content_id` IN (' . $materialIds . ')',
        ];
        foreach ($directQueries as $table => $condition) {
            if ($this->hasTable($table)) {
                $this->execute('DELETE FROM `' . $table . '` WHERE ' . $condition);
            }
        }
    }

    private function deleteComprehensiveSeedIds(): void
    {
        $rows = [
            'sa_local_model_download_log' => [9221, 9222, 9223, 9224],
            'sa_local_model_prompt' => [9211, 9212, 9213, 9214, 9215, 9216],
            'sa_member_chat_record' => range(9121, 9140),
            'sa_member_chat_session' => range(9111, 9115),
            'sa_member_chat_config' => range(9101, 9107),
            'sa_community_like' => range(9041, 9048),
            'sa_community_collect' => range(9051, 9053),
            'sa_community_comment' => range(9031, 9038),
            'sa_community_post' => range(9021, 9026),
            'sa_community_follow_tag' => range(9011, 9018),
            'sa_community_follow_member' => range(9061, 9065),
            'sa_community_tag' => range(9001, 9005),
            'sa_material_collect' => range(8931, 8934),
            'sa_member_content_history' => range(8921, 8926),
            'sa_content_material' => range(8911, 8918),
            'sa_content_category' => range(8901, 8904),
            'sa_member_memoir' => range(8811, 8813),
            'sa_member_memoir_config' => range(8801, 8802),
            'sa_member_journal' => range(8701, 8710),
            'sa_member_badge' => range(8601, 8604),
            'sa_member_point_log' => range(8501, 8508),
            'sa_member_message' => range(8401, 8410),
            'sa_daily_task' => range(8331, 8342),
            'sa_treatment_stage' => range(8311, 8317),
            'sa_treatment_plan' => range(8301, 8303),
            'sa_doctor_patient' => range(9231, 9234),
            'sa_doctor_appointment' => range(8201, 8204),
            'sa_doctor_schedule' => range(8101, 8107),
            'sa_member_login_log' => range(9241, 9246),
            'sa_member_push_preference' => range(9251, 9254),
            'sa_help_doctor_profile' => range(9311, 9312),
            'sa_help_member_profile' => range(9301, 9306),
            'sa_local_model_catalog' => range(9201, 9202),
        ];

        foreach ($rows as $table => $ids) {
            $this->deleteIds($table, $ids);
        }
    }

    private function deleteRowsOwnedByDemoMembers(): void
    {
        $columns = [
            'sa_community_collect' => ['member_id'],
            'sa_community_comment' => ['member_id', 'reply_to_member_id'],
            'sa_community_follow_member' => ['member_id', 'target_member_id'],
            'sa_community_follow_tag' => ['member_id'],
            'sa_community_like' => ['member_id'],
            'sa_community_post' => ['member_id'],
            'sa_community_report' => ['member_id'],
            'sa_content_category' => ['member_id'],
            'sa_content_material' => ['member_id'],
            'sa_daily_task' => ['member_id'],
            'sa_doctor_appointment' => ['member_id', 'doctor_id'],
            'sa_doctor_assessment_scale' => ['doctor_id'],
            'sa_doctor_patient' => ['doctor_id', 'member_id'],
            'sa_doctor_schedule' => ['doctor_id'],
            'sa_doctor_task_template' => ['doctor_id'],
            'sa_doctor_task_template_folder' => ['doctor_id'],
            'sa_help_doctor_profile' => ['member_id'],
            'sa_help_member_profile' => ['member_id'],
            'sa_local_model_download_log' => ['member_id'],
            'sa_material_collect' => ['member_id'],
            'sa_material_comment' => ['member_id'],
            'sa_material_comment_like' => ['member_id'],
            'sa_material_like' => ['member_id'],
            'sa_material_report' => ['member_id'],
            'sa_member_assessment_result' => ['member_id', 'doctor_id'],
            'sa_member_badge' => ['member_id'],
            'sa_member_chat_config' => ['member_id'],
            'sa_member_chat_record' => ['member_id'],
            'sa_member_chat_session' => ['member_id'],
            'sa_member_content_history' => ['member_id'],
            'sa_member_diagnostic_log' => ['member_id'],
            'sa_member_journal' => ['member_id'],
            'sa_member_login_log' => ['member_id'],
            'sa_member_memoir' => ['member_id'],
            'sa_member_message' => ['member_id'],
            'sa_member_platform_rel' => ['member_id'],
            'sa_member_point_log' => ['member_id'],
            'sa_member_points_log' => ['member_id'],
            'sa_member_push_device' => ['member_id'],
            'sa_member_push_preference' => ['member_id'],
            'sa_member_recovery_goal_log' => ['member_id'],
            'sa_member_trigger_log' => ['member_id'],
            'sa_treatment_plan' => ['member_id', 'doctor_id'],
            'sa_treatment_stage' => ['member_id'],
            'saipay_order' => ['member_id'],
        ];

        $ids = $this->integerList(self::DEMO_MEMBER_IDS);
        foreach ($columns as $table => $tableColumns) {
            if (!$this->hasTable($table)) {
                continue;
            }

            $conditions = [];
            foreach ($tableColumns as $column) {
                if ($this->table($table)->hasColumn($column)) {
                    $conditions[] = '`' . $column . '` IN (' . $ids . ')';
                }
            }

            if ($conditions !== []) {
                $this->execute('DELETE FROM `' . $table . '` WHERE ' . implode(' OR ', $conditions));
            }
        }
    }

    private function deleteRowsMarkedAsDemo(): void
    {
        $tables = [
            'sa_content_category',
            'sa_content_material',
            'sa_daily_task',
            'sa_doctor_appointment',
            'sa_doctor_patient',
            'sa_doctor_schedule',
            'sa_local_model_download_log',
            'sa_member_journal',
            'sa_member_memoir',
            'sa_member_message',
            'sa_member_point_log',
            'sa_treatment_plan',
            'sa_treatment_stage',
        ];

        foreach ($tables as $table) {
            if (!$this->hasTable($table) || !$this->table($table)->hasColumn('remark')) {
                continue;
            }
            $this->execute(
                'DELETE FROM `' . $table . '`
                 WHERE `remark` LIKE ' . $this->q('demo:help-comprehensive:%') . '
                    OR `remark` LIKE ' . $this->q('demo:entertainment-seed:%') . '
                    OR `remark` LIKE ' . $this->q('demo-seed%')
            );
        }
    }

    private function deleteExplicitTestFixtures(): void
    {
        if ($this->hasTable('sa_local_model_catalog')) {
            $this->execute(
                'DELETE FROM `sa_local_model_catalog`
                 WHERE `code` = ' . $this->q('smollm2-135m-instruct-q2-k') . '
                   AND `download_url` = ' . $this->q('https://huggingface.co/unsloth/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q2_K.gguf')
            );
        }

        if ($this->hasTable('saiai_config')) {
            $this->execute(
                'DELETE FROM `saiai_config`
                 WHERE `name` = ' . $this->q('deepseektest') . '
                   AND `type` = ' . $this->q('deepseek') . '
                   AND `model` = ' . $this->q('deepseek-chat') . '
                   AND `is_default` <> 1
                   AND COALESCE(`remark`, ' . $this->q('') . ') = ' . $this->q('')
            );
        }

        if ($this->hasTable('sa_content_material')) {
            $this->execute(
                'DELETE FROM `sa_content_material`
                 WHERE `title` = ' . $this->q('测试') . '
                   AND `remark` IS NULL
                   AND `delete_time` IS NOT NULL'
            );
        }

        if ($this->hasTable('sa_doctor_task_template_folder') && $this->hasTable('sa_doctor_task_template')) {
            $this->execute(
                'DELETE folder FROM `sa_doctor_task_template_folder` folder
                 LEFT JOIN `sa_doctor_task_template` template
                        ON template.`folder_id` = folder.`id`
                       AND template.`delete_time` IS NULL
                 WHERE folder.`name` = ' . $this->q('测试') . '
                   AND folder.`remark` IS NULL
                   AND folder.`delete_time` IS NOT NULL
                   AND template.`id` IS NULL'
            );
        }

        if ($this->hasTable('saiai_chat_group') && $this->hasTable('saiai_chat')) {
            $this->execute(
                'DELETE chat FROM `saiai_chat` chat
                 INNER JOIN `saiai_chat_group` chat_group ON chat_group.`id` = chat.`group_id`
                 WHERE chat_group.`title` = ' . $this->q('sse test') . '
                   AND chat_group.`delete_time` IS NOT NULL'
            );
            $this->execute(
                'DELETE FROM `saiai_chat_group`
                 WHERE `title` = ' . $this->q('sse test') . '
                   AND `delete_time` IS NOT NULL'
            );
        }

        if ($this->hasTable('sa_content_material') && $this->table('sa_content_material')->hasColumn('lyric_url')) {
            $this->execute(
                'UPDATE `sa_content_material`
                 SET `lyric_url` = NULL, `updated_by` = 1, `update_time` = NOW()
                 WHERE `content_url` = ' . $this->q('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3') . '
                   AND `lyric_url` = ' . $this->q('/demo/material/soundhelix-song-1.lrc')
            );
        }
    }

    private function deleteDemoMembers(): void
    {
        if (!$this->hasTable('sa_member')) {
            return;
        }

        $this->execute(
            'DELETE FROM `sa_member`
             WHERE `id` IN (' . $this->integerList(self::DEMO_MEMBER_IDS) . ')
               AND (`remark` = ' . $this->q('demo-seed') . '
                    OR `remark` = ' . $this->q('demo:help-comprehensive:member') . '
                    OR `email` LIKE ' . $this->q('%@helpsupport.test') . ')'
        );
    }

    private function syncMemberPointsBalance(int $memberId): void
    {
        if (!$this->hasTable('sa_member') || !$this->hasTable('sa_member_point_log')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_member` member
             SET member.`points_balance` = COALESCE((
                     SELECT SUM(log.`points`)
                     FROM `sa_member_point_log` log
                     WHERE log.`member_id` = ' . $memberId . '
                       AND log.`delete_time` IS NULL
                 ), 0),
                 member.`update_time` = NOW()
             WHERE member.`id` = ' . $memberId . '
               AND member.`delete_time` IS NULL'
        );
    }

    /**
     * @param int[] $ids
     */
    private function deleteIds(string $table, array $ids): void
    {
        if ($ids === [] || !$this->hasTable($table)) {
            return;
        }

        $this->execute(
            'DELETE FROM `' . $table . '` WHERE `id` IN (' . $this->integerList($ids) . ')'
        );
    }

    /**
     * @param int[] $values
     */
    private function integerList(array $values): string
    {
        return implode(',', array_map('intval', $values));
    }

    private function tableNameFromDelete(string $query): ?string
    {
        if (preg_match('/^DELETE target FROM `([^`]+)`/', $query, $matches) !== 1) {
            return null;
        }

        return $matches[1];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
