<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 将 HelpSupport 的 8 个业务分组提升为顶级目录，并把「机器人形象」归入「AI与模型」。
 *
 * 不清理会员、素材或其他业务/测试数据；只调整菜单层级。
 */
final class PromoteHelpSupportMenuGroups extends AbstractMigration
{
    private const ROOT_CODE = 'HelpSupport';
    private const ROBOT_PROFILE_CODE = 'help/chat/robotProfile';
    private const REMARK = 'phinx:20260818145444_promote_help_support_menu_groups';

    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ($this->menuGroups() as $group) {
            $this->ensureTopLevelGroup($group);
        }

        foreach ($this->menuFamilies() as $groupCode => $prefixes) {
            $this->moveMenuFamily($groupCode, $prefixes);
        }

        $this->hideEmptyHelpSupportRoot();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->restoreHelpSupportRoot();
        $this->restoreNestedGroups();
        $this->restoreRobotProfileToTopLevel();
        $this->clearMenuCaches();
    }

    /**
     * @return list<array{name: string, code: string, path: string, icon: string, sort: int, nested_path: string, nested_sort: int}>
     */
    private function menuGroups(): array
    {
        return [
            ['name' => '运营配置', 'code' => 'help/config', 'path' => '/helpsupport/config', 'icon' => 'ri:settings-4-line', 'sort' => 80, 'nested_path' => 'config', 'nested_sort' => 100],
            ['name' => '社区管理', 'code' => 'help/community', 'path' => '/helpsupport/community', 'icon' => 'ri:community-line', 'sort' => 81, 'nested_path' => 'community', 'nested_sort' => 110],
            ['name' => '素材内容', 'code' => 'help/material', 'path' => '/helpsupport/material', 'icon' => 'ri:book-open-line', 'sort' => 82, 'nested_path' => 'material', 'nested_sort' => 120],
            ['name' => 'AI与模型', 'code' => 'help/aiModel', 'path' => '/helpsupport/ai-model', 'icon' => 'ri:brain-line', 'sort' => 84, 'nested_path' => 'ai-model', 'nested_sort' => 130],
            ['name' => '治疗计划', 'code' => 'help/plan', 'path' => '/helpsupport/plan', 'icon' => 'ri:calendar-check-line', 'sort' => 85, 'nested_path' => 'plan', 'nested_sort' => 140],
            ['name' => '医生服务', 'code' => 'help/doctor', 'path' => '/helpsupport/doctor', 'icon' => 'ri:user-heart-line', 'sort' => 86, 'nested_path' => 'doctor', 'nested_sort' => 150],
            ['name' => '消息推送', 'code' => 'help/push', 'path' => '/helpsupport/push', 'icon' => 'ri:notification-3-line', 'sort' => 87, 'nested_path' => 'push', 'nested_sort' => 160],
            ['name' => '用户成长与风控', 'code' => 'help/growth', 'path' => '/helpsupport/growth', 'icon' => 'ri:shield-star-line', 'sort' => 88, 'nested_path' => 'growth', 'nested_sort' => 170],
        ];
    }

    /**
     * @return array<string, list<string>>
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
     * @param array{name: string, code: string, path: string, icon: string, sort: int, nested_path: string, nested_sort: int} $group
     */
    private function ensureTopLevelGroup(array $group): void
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
     * @param list<string> $prefixes
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

    private function hideEmptyHelpSupportRoot(): void
    {
        $this->execute(
            'UPDATE `sa_system_menu` root
             LEFT JOIN `sa_system_menu` child
                    ON child.`parent_id` = root.`id`
                   AND child.`delete_time` IS NULL
             SET root.`status` = 2,
                 root.`updated_by` = 1,
                 root.`update_time` = NOW(),
                 root.`delete_time` = COALESCE(root.`delete_time`, NOW()),
                 root.`remark` = CASE
                     WHEN root.`remark` IS NULL OR root.`remark` = ' . $this->q('') . ' THEN ' . $this->q(self::REMARK) . '
                     ELSE root.`remark`
                 END
             WHERE root.`code` = ' . $this->q(self::ROOT_CODE) . '
               AND root.`delete_time` IS NULL
               AND child.`id` IS NULL'
        );
    }

    private function restoreHelpSupportRoot(): void
    {
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `parent_id` = 0,
                 `status` = 1,
                 `delete_time` = NULL,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q(self::ROOT_CODE)
        );
    }

    private function restoreNestedGroups(): void
    {
        foreach ($this->menuGroups() as $group) {
            $this->execute(
                'UPDATE `sa_system_menu` group_menu
                 INNER JOIN `sa_system_menu` root
                         ON root.`code` = ' . $this->q(self::ROOT_CODE) . '
                 SET group_menu.`parent_id` = root.`id`,
                     group_menu.`type` = 2,
                     group_menu.`path` = ' . $this->q($group['nested_path']) . ',
                     group_menu.`sort` = ' . (int) $group['nested_sort'] . ',
                     group_menu.`updated_by` = 1,
                     group_menu.`update_time` = NOW()
                 WHERE group_menu.`code` = ' . $this->q($group['code']) . '
                   AND group_menu.`delete_time` IS NULL'
            );
        }
    }

    private function restoreRobotProfileToTopLevel(): void
    {
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `parent_id` = 0,
                 `sort` = 83,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q(self::ROBOT_PROFILE_CODE) . '
               AND `delete_time` IS NULL'
        );
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
