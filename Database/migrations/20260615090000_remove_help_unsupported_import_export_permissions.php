<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class RemoveHelpUnsupportedImportExportPermissions extends AbstractMigration
{
    private const REMARK = 'phinx:20260615090000_remove_help_unsupported_import_export_permissions';
    private const OPERATOR_ROLE_CODE = 'helpsupport_operator';

    public function up(): void
    {
        $slugs = $this->permissionSlugs();
        if ($slugs === []) {
            return;
        }

        $this->execute(
            'DELETE rm FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` m ON m.`id` = rm.`menu_id`
             WHERE m.`slug` IN (' . $this->quotedList($slugs) . ')'
        );

        $this->execute(
            'DELETE FROM `sa_system_menu`
             WHERE `slug` IN (' . $this->quotedList($slugs) . ')
               AND `delete_time` IS NULL'
        );

        $this->clearAuthCaches();
    }

    public function down(): void
    {
        foreach ($this->permissionTargets() as $target) {
            $this->insertPermission($target['parent_code'], [
                'name' => '导入',
                'slug' => $target['prefix'] . ':import',
                'generate_key' => 'import',
            ]);
            $this->insertPermission($target['parent_code'], [
                'name' => '导出',
                'slug' => $target['prefix'] . ':export',
                'generate_key' => 'export',
            ]);
        }

        $this->grantOperatorRoleMenus();
        $this->clearAuthCaches();
    }

    private function permissionTargets(): array
    {
        return [
            ['parent_code' => 'help/config/page', 'prefix' => 'help:config:page'],
            ['parent_code' => 'help/audit/profile', 'prefix' => 'help:audit:profile'],
            ['parent_code' => 'help/community/post', 'prefix' => 'help:community:post'],
            ['parent_code' => 'help/chat/config', 'prefix' => 'help:chat:config'],
            ['parent_code' => 'help/localModel/catalog', 'prefix' => 'help:localModel:catalog'],
            ['parent_code' => 'help/localModel/prompt', 'prefix' => 'help:localModel:prompt'],
            ['parent_code' => 'help/push/device', 'prefix' => 'help:push:device'],
            ['parent_code' => 'help/plan/treatmentPlan', 'prefix' => 'help:plan:treatmentPlan'],
            ['parent_code' => 'help/plan/treatmentStage', 'prefix' => 'help:plan:treatmentStage'],
            ['parent_code' => 'help/plan/dailyTask', 'prefix' => 'help:plan:dailyTask'],
            ['parent_code' => 'help/plan/assessmentResult', 'prefix' => 'help:plan:assessmentResult'],
            ['parent_code' => 'help/doctor/patient', 'prefix' => 'help:doctor:patient'],
            ['parent_code' => 'help/doctor/taskTemplateFolder', 'prefix' => 'help:doctor:taskTemplateFolder'],
            ['parent_code' => 'help/doctor/taskTemplate', 'prefix' => 'help:doctor:taskTemplate'],
            ['parent_code' => 'help/doctor/assessmentScale', 'prefix' => 'help:doctor:assessmentScale'],
            ['parent_code' => 'help/push/preference', 'prefix' => 'help:push:preference'],
            ['parent_code' => 'help/message/memberMessage', 'prefix' => 'help:message:memberMessage'],
            ['parent_code' => 'help/push/template', 'prefix' => 'help:push:template'],
            ['parent_code' => 'help/appointment/doctorAppointment', 'prefix' => 'help:appointment:doctorAppointment'],
            ['parent_code' => 'help/appointment/doctorSchedule', 'prefix' => 'help:appointment:doctorSchedule'],
            ['parent_code' => 'help/material/category', 'prefix' => 'help:material:category'],
            ['parent_code' => 'help/material/content', 'prefix' => 'help:material:content'],
            ['parent_code' => 'help/gamification/badgeRule', 'prefix' => 'help:gamification:badgeRule'],
            ['parent_code' => 'help/gamification/pointLog', 'prefix' => 'help:gamification:pointLog'],
            ['parent_code' => 'help/me/memoirConfig', 'prefix' => 'help:me:memoirConfig'],
            ['parent_code' => 'help/risk/sensitiveWordRule', 'prefix' => 'help:risk:sensitiveWordRule'],
            ['parent_code' => 'help/community/tag', 'prefix' => 'help:community:tag'],
            ['parent_code' => 'help/chat/session', 'prefix' => 'help:chat:session'],
            ['parent_code' => 'help/chat/record', 'prefix' => 'help:chat:record'],
            ['parent_code' => 'help/me/journal', 'prefix' => 'help:me:journal'],
            ['parent_code' => 'help/me/memoir', 'prefix' => 'help:me:memoir'],
            ['parent_code' => 'help/me/recoveryGoal', 'prefix' => 'help:me:recoveryGoal'],
            ['parent_code' => 'help/me/triggerLog', 'prefix' => 'help:me:triggerLog'],
            ['parent_code' => 'help/gamification/badge', 'prefix' => 'help:gamification:badge'],
        ];
    }

    private function permissionSlugs(): array
    {
        $slugs = [];
        foreach ($this->permissionTargets() as $target) {
            $slugs[] = $target['prefix'] . ':import';
            $slugs[] = $target['prefix'] . ':export';
        }

        return $slugs;
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
        $slugs = $this->permissionSlugs();
        if ($slugs === []) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT r.`id`, m.`id`
             FROM `sa_system_role` r
             INNER JOIN `sa_system_menu` m ON m.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` rm ON rm.`role_id` = r.`id` AND rm.`menu_id` = m.`id`
             WHERE r.`code` = ' . $this->q(self::OPERATOR_ROLE_CODE) . '
               AND r.`delete_time` IS NULL
               AND m.`slug` IN (' . $this->quotedList($slugs) . ')
               AND rm.`id` IS NULL'
        );
    }

    private function clearAuthCaches(): void
    {
        if (class_exists(\plugin\saiadmin\app\cache\UserMenuCache::class)) {
            \plugin\saiadmin\app\cache\UserMenuCache::clearMenuCache();
        }
        if (class_exists(\plugin\saiadmin\app\cache\UserAuthCache::class)) {
            \plugin\saiadmin\app\cache\UserAuthCache::clear();
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
