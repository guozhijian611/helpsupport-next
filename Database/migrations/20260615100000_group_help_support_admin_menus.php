<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class GroupHelpSupportAdminMenus extends AbstractMigration
{
    private const ROOT_CODE = 'HelpSupport';
    private const REMARK = 'phinx:20260615100000_group_help_support_admin_menus';
    private const ROOT_SORTS = [
        'help/config/page' => 100,
        'help/audit/profile' => 100,
        'help/community/post' => 100,
        'help/chat/config' => 100,
        'help/localModel/catalog' => 100,
        'help/localModel/prompt' => 100,
        'help/push/device' => 100,
        'help/config/runtime' => 101,
        'help/community/tag' => 112,
        'help/material/category' => 114,
        'help/material/content' => 115,
        'help/material/privateMaterial' => 116,
        'help/community/comment' => 121,
        'help/community/report' => 122,
        'help/chat/session' => 123,
        'help/chat/record' => 124,
        'help/plan/treatmentPlan' => 130,
        'help/plan/treatmentStage' => 131,
        'help/plan/dailyTask' => 132,
        'help/plan/assessmentResult' => 133,
        'help/doctor/patient' => 140,
        'help/doctor/taskTemplateFolder' => 141,
        'help/doctor/taskTemplate' => 142,
        'help/doctor/assessmentScale' => 143,
        'help/push/preference' => 150,
        'help/message/memberMessage' => 151,
        'help/push/template' => 152,
        'help/appointment/doctorAppointment' => 160,
        'help/appointment/doctorSchedule' => 161,
        'help/gamification/badgeRule' => 170,
        'help/gamification/pointLog' => 171,
        'help/me/memoirConfig' => 172,
        'help/risk/sensitiveWordRule' => 173,
        'help/me/journal' => 174,
        'help/me/memoir' => 175,
        'help/me/recoveryGoal' => 176,
        'help/me/triggerLog' => 177,
        'help/gamification/badge' => 178,
    ];

    public function up(): void
    {
        foreach ($this->groups() as $group) {
            $this->insertGroup($group);
        }

        foreach ($this->pageMappings() as $page) {
            $this->movePageToGroup($page);
        }

        $this->grantGroupMenusToExistingRoles();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        foreach ($this->pageMappings() as $page) {
            $this->movePageToRoot($page);
        }

        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE m.`remark` = ' . $this->q(self::REMARK)
        );

        $this->execute(
            'DELETE parent FROM `sa_system_menu` parent
             WHERE parent.`remark` = ' . $this->q(self::REMARK) . '
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu` child
                   WHERE child.`parent_id` = parent.`id`
                     AND child.`delete_time` IS NULL
               )'
        );

        $this->clearMenuCaches();
    }

    private function groups(): array
    {
        return [
            [
                'name' => '运营配置',
                'code' => 'help/config',
                'path' => 'config',
                'icon' => 'ri:settings-4-line',
                'sort' => 100,
            ],
            [
                'name' => '社区管理',
                'code' => 'help/community',
                'path' => 'community',
                'icon' => 'ri:community-line',
                'sort' => 110,
            ],
            [
                'name' => '素材内容',
                'code' => 'help/material',
                'path' => 'material',
                'icon' => 'ri:book-open-line',
                'sort' => 120,
            ],
            [
                'name' => 'AI与模型',
                'code' => 'help/aiModel',
                'path' => 'ai-model',
                'icon' => 'ri:brain-line',
                'sort' => 130,
            ],
            [
                'name' => '治疗计划',
                'code' => 'help/plan',
                'path' => 'plan',
                'icon' => 'ri:calendar-check-line',
                'sort' => 140,
            ],
            [
                'name' => '医生服务',
                'code' => 'help/doctor',
                'path' => 'doctor',
                'icon' => 'ri:user-heart-line',
                'sort' => 150,
            ],
            [
                'name' => '消息推送',
                'code' => 'help/push',
                'path' => 'push',
                'icon' => 'ri:notification-3-line',
                'sort' => 160,
            ],
            [
                'name' => '用户成长与风控',
                'code' => 'help/growth',
                'path' => 'growth',
                'icon' => 'ri:shield-star-line',
                'sort' => 170,
            ],
        ];
    }

    private function pageMappings(): array
    {
        return [
            ['code' => 'help/config/page', 'group_code' => 'help/config', 'path' => 'config/page', 'absolute_path' => '/helpsupport/config/page', 'sort' => 10],
            ['code' => 'help/config/runtime', 'group_code' => 'help/config', 'path' => 'config/runtime', 'absolute_path' => '/helpsupport/config/runtime', 'sort' => 20],

            ['code' => 'help/community/tag', 'group_code' => 'help/community', 'path' => 'community/tag', 'absolute_path' => '/helpsupport/community/tag', 'sort' => 10],
            ['code' => 'help/community/post', 'group_code' => 'help/community', 'path' => 'community/post', 'absolute_path' => '/helpsupport/community/post', 'sort' => 20],
            ['code' => 'help/community/comment', 'group_code' => 'help/community', 'path' => 'community/comment', 'absolute_path' => '/helpsupport/community/comment', 'sort' => 30],
            ['code' => 'help/community/report', 'group_code' => 'help/community', 'path' => 'community/report', 'absolute_path' => '/helpsupport/community/report', 'sort' => 40],

            ['code' => 'help/material/category', 'group_code' => 'help/material', 'path' => 'material/category', 'absolute_path' => '/helpsupport/material/category', 'sort' => 10],
            ['code' => 'help/material/content', 'group_code' => 'help/material', 'path' => 'material/content', 'absolute_path' => '/helpsupport/material/content', 'sort' => 20],
            ['code' => 'help/material/privateMaterial', 'group_code' => 'help/material', 'path' => 'material/privateMaterial', 'absolute_path' => '/helpsupport/material/privateMaterial', 'sort' => 30],

            ['code' => 'help/chat/config', 'group_code' => 'help/aiModel', 'path' => 'chat/config', 'absolute_path' => '/helpsupport/chat/config', 'sort' => 10],
            ['code' => 'help/chat/session', 'group_code' => 'help/aiModel', 'path' => 'chat/session', 'absolute_path' => '/helpsupport/chat/session', 'sort' => 20],
            ['code' => 'help/chat/record', 'group_code' => 'help/aiModel', 'path' => 'chat/record', 'absolute_path' => '/helpsupport/chat/record', 'sort' => 30],
            ['code' => 'help/localModel/catalog', 'group_code' => 'help/aiModel', 'path' => 'localModel/catalog', 'absolute_path' => '/helpsupport/localModel/catalog', 'sort' => 40],
            ['code' => 'help/localModel/prompt', 'group_code' => 'help/aiModel', 'path' => 'localModel/prompt', 'absolute_path' => '/helpsupport/localModel/prompt', 'sort' => 50],

            ['code' => 'help/plan/treatmentPlan', 'group_code' => 'help/plan', 'path' => 'plan/treatmentPlan', 'absolute_path' => '/helpsupport/plan/treatmentPlan', 'sort' => 10],
            ['code' => 'help/plan/treatmentStage', 'group_code' => 'help/plan', 'path' => 'plan/treatmentStage', 'absolute_path' => '/helpsupport/plan/treatmentStage', 'sort' => 20],
            ['code' => 'help/plan/dailyTask', 'group_code' => 'help/plan', 'path' => 'plan/dailyTask', 'absolute_path' => '/helpsupport/plan/dailyTask', 'sort' => 30],
            ['code' => 'help/plan/assessmentResult', 'group_code' => 'help/plan', 'path' => 'plan/assessmentResult', 'absolute_path' => '/helpsupport/plan/assessmentResult', 'sort' => 40],

            ['code' => 'help/audit/profile', 'group_code' => 'help/doctor', 'path' => 'audit/profile', 'absolute_path' => '/helpsupport/audit/profile', 'sort' => 10],
            ['code' => 'help/doctor/patient', 'group_code' => 'help/doctor', 'path' => 'doctor/patient', 'absolute_path' => '/helpsupport/doctor/patient', 'sort' => 20],
            ['code' => 'help/doctor/taskTemplateFolder', 'group_code' => 'help/doctor', 'path' => 'doctor/taskTemplateFolder', 'absolute_path' => '/helpsupport/doctor/taskTemplateFolder', 'sort' => 30],
            ['code' => 'help/doctor/taskTemplate', 'group_code' => 'help/doctor', 'path' => 'doctor/taskTemplate', 'absolute_path' => '/helpsupport/doctor/taskTemplate', 'sort' => 40],
            ['code' => 'help/doctor/assessmentScale', 'group_code' => 'help/doctor', 'path' => 'doctor/assessmentScale', 'absolute_path' => '/helpsupport/doctor/assessmentScale', 'sort' => 50],
            ['code' => 'help/appointment/doctorAppointment', 'group_code' => 'help/doctor', 'path' => 'appointment/doctorAppointment', 'absolute_path' => '/helpsupport/appointment/doctorAppointment', 'sort' => 60],
            ['code' => 'help/appointment/doctorSchedule', 'group_code' => 'help/doctor', 'path' => 'appointment/doctorSchedule', 'absolute_path' => '/helpsupport/appointment/doctorSchedule', 'sort' => 70],

            ['code' => 'help/message/memberMessage', 'group_code' => 'help/push', 'path' => 'message/memberMessage', 'absolute_path' => '/helpsupport/message/memberMessage', 'sort' => 10],
            ['code' => 'help/push/device', 'group_code' => 'help/push', 'path' => 'push/device', 'absolute_path' => '/helpsupport/push/device', 'sort' => 20],
            ['code' => 'help/push/preference', 'group_code' => 'help/push', 'path' => 'push/preference', 'absolute_path' => '/helpsupport/push/preference', 'sort' => 30],
            ['code' => 'help/push/template', 'group_code' => 'help/push', 'path' => 'push/template', 'absolute_path' => '/helpsupport/push/template', 'sort' => 40],

            ['code' => 'help/gamification/badgeRule', 'group_code' => 'help/growth', 'path' => 'gamification/badgeRule', 'absolute_path' => '/helpsupport/gamification/badgeRule', 'sort' => 10],
            ['code' => 'help/gamification/pointLog', 'group_code' => 'help/growth', 'path' => 'gamification/pointLog', 'absolute_path' => '/helpsupport/gamification/pointLog', 'sort' => 20],
            ['code' => 'help/gamification/badge', 'group_code' => 'help/growth', 'path' => 'gamification/badge', 'absolute_path' => '/helpsupport/gamification/badge', 'sort' => 30],
            ['code' => 'help/me/memoirConfig', 'group_code' => 'help/growth', 'path' => 'me/memoirConfig', 'absolute_path' => '/helpsupport/me/memoirConfig', 'sort' => 40],
            ['code' => 'help/me/journal', 'group_code' => 'help/growth', 'path' => 'me/journal', 'absolute_path' => '/helpsupport/me/journal', 'sort' => 50],
            ['code' => 'help/me/memoir', 'group_code' => 'help/growth', 'path' => 'me/memoir', 'absolute_path' => '/helpsupport/me/memoir', 'sort' => 60],
            ['code' => 'help/me/recoveryGoal', 'group_code' => 'help/growth', 'path' => 'me/recoveryGoal', 'absolute_path' => '/helpsupport/me/recoveryGoal', 'sort' => 70],
            ['code' => 'help/me/triggerLog', 'group_code' => 'help/growth', 'path' => 'me/triggerLog', 'absolute_path' => '/helpsupport/me/triggerLog', 'sort' => 80],
            ['code' => 'help/risk/sensitiveWordRule', 'group_code' => 'help/growth', 'path' => 'risk/sensitiveWordRule', 'absolute_path' => '/helpsupport/risk/sensitiveWordRule', 'sort' => 90],
        ];
    }

    private function insertGroup(array $group): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT root.`id`, ' . $this->q($group['name']) . ', ' . $this->q($group['code']) . ', NULL, 2, ' . $this->q($group['path']) . ', ' . $this->q('') . ', NULL, ' . $this->q($group['icon']) . ', ' . (int) $group['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` root
             WHERE root.`code` = ' . $this->q(self::ROOT_CODE) . '
               AND root.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q($group['code']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function movePageToGroup(array $page): void
    {
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent ON parent.`code` = ' . $this->q($page['group_code']) . ' AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`path` = ' . $this->q($page['absolute_path']) . ',
                 page.`sort` = ' . (int) $page['sort'] . ',
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q($page['code']) . '
               AND page.`delete_time` IS NULL'
        );
    }

    private function movePageToRoot(array $page): void
    {
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` root ON root.`code` = ' . $this->q(self::ROOT_CODE) . ' AND root.`delete_time` IS NULL
             SET page.`parent_id` = root.`id`,
                 page.`path` = ' . $this->q($page['path']) . ',
                 page.`sort` = ' . $this->rootSort($page) . ',
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q($page['code']) . '
               AND page.`delete_time` IS NULL'
        );
    }

    private function rootSort(array $page): int
    {
        return self::ROOT_SORTS[$page['code']] ?? (int) $page['sort'];
    }

    private function grantGroupMenusToExistingRoles(): void
    {
        foreach ($this->groups() as $group) {
            $childCodes = array_values(array_map(
                fn (array $page): string => $page['code'],
                array_filter($this->pageMappings(), fn (array $page): bool => $page['group_code'] === $group['code'])
            ));
            if ($childCodes === []) {
                continue;
            }

            $this->execute(
                'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
                 SELECT DISTINCT rm.`role_id`, parent.`id`
                 FROM `sa_system_role_menu` rm
                 INNER JOIN `sa_system_menu` child ON child.`id` = rm.`menu_id` AND child.`delete_time` IS NULL
                 INNER JOIN `sa_system_menu` parent ON parent.`code` = ' . $this->q($group['code']) . ' AND parent.`delete_time` IS NULL
                 LEFT JOIN `sa_system_role_menu` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = parent.`id`
                 WHERE child.`code` IN (' . $this->quotedList($childCodes) . ')
                   AND existing.`id` IS NULL'
            );
        }
    }

    private function clearMenuCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
            \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
        }
    }

    private function quotedList(array $values): string
    {
        return implode(',', array_map(fn (string $value): string => $this->q($value), $values));
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
