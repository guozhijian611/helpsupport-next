<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 把「AI 管理」收成三级：互动角色 + 模型中心 / 提示词 / 会话记录 / 模型测试。
 */
final class NestAiManagementMenuGroups extends AbstractMigration
{
    private const REMARK = 'phinx:20260820051000_nest_ai_management_menu_groups';
    private const ROOT_CODE = 'help/aiModel';

    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ($this->groups() as $group) {
            $this->ensureGroup($group);
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `sort` = 90,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/chat/persona') . '
               AND `delete_time` IS NULL'
        );

        foreach ($this->pageMoves() as $move) {
            $this->movePage($move);
        }

        $this->grantGroupMenus();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` root
                     ON root.`code` = ' . $this->q(self::ROOT_CODE) . '
                    AND root.`delete_time` IS NULL
             SET page.`parent_id` = root.`id`,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`delete_time` IS NULL
               AND page.`code` IN (' . $this->inList($this->movedPageCodes()) . ')'
        );
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
             SET `sort` = 5,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q('help/chat/persona') . '
               AND `delete_time` IS NULL'
        );

        if ($this->hasTable('sa_system_role_menu')) {
            $this->execute(
                'DELETE rm FROM `sa_system_role_menu` rm
                 INNER JOIN `sa_system_menu` menu ON menu.`id` = rm.`menu_id`
                 WHERE menu.`remark` = ' . $this->q(self::REMARK)
            );
        }
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `delete_time` = NOW(),
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `remark` = ' . $this->q(self::REMARK) . '
               AND `delete_time` IS NULL'
        );
        $this->clearMenuCaches();
    }

    /**
     * @return list<array{name:string,code:string,path:string,icon:string,sort:int}>
     */
    private function groups(): array
    {
        return [
            ['name' => '模型中心', 'code' => 'help/aiModel/hub', 'path' => '/helpsupport/ai-model/hub', 'icon' => 'ri:cpu-line', 'sort' => 80],
            ['name' => '提示词', 'code' => 'help/aiModel/prompts', 'path' => '/helpsupport/ai-model/prompts', 'icon' => 'ri:chat-quote-line', 'sort' => 70],
            ['name' => '会话记录', 'code' => 'help/aiModel/records', 'path' => '/helpsupport/ai-model/records', 'icon' => 'ri:chat-history-line', 'sort' => 60],
            ['name' => '模型测试', 'code' => 'help/aiModel/lab', 'path' => '/helpsupport/ai-model/lab', 'icon' => 'ri:flask-line', 'sort' => 50],
        ];
    }

    /**
     * @return list<array{code:string,group:string,name:?string,path:?string,sort:int}>
     */
    private function pageMoves(): array
    {
        return [
            ['code' => 'saiai/config/config', 'group' => 'help/aiModel/hub', 'name' => '在线模型', 'path' => '/helpsupport/ai-model/config/config', 'sort' => 30],
            ['code' => 'help/localModel/catalog', 'group' => 'help/aiModel/hub', 'name' => null, 'path' => '/helpsupport/localModel/catalog', 'sort' => 20],
            ['code' => 'help/localModel/prompt', 'group' => 'help/aiModel/hub', 'name' => null, 'path' => '/helpsupport/localModel/prompt', 'sort' => 10],
            ['code' => 'help/chat/config', 'group' => 'help/aiModel/prompts', 'name' => '用户改写提示词', 'path' => '/helpsupport/chat/config', 'sort' => 10],
            ['code' => 'help/chat/session', 'group' => 'help/aiModel/records', 'name' => null, 'path' => '/helpsupport/chat/session', 'sort' => 20],
            ['code' => 'help/chat/record', 'group' => 'help/aiModel/records', 'name' => null, 'path' => '/helpsupport/chat/record', 'sort' => 10],
            ['code' => 'saiai/chat/group', 'group' => 'help/aiModel/lab', 'name' => '对话测试', 'path' => '/helpsupport/ai-model/chat/group', 'sort' => 20],
            ['code' => 'saiai/realtime/test', 'group' => 'help/aiModel/lab', 'name' => '实时测试', 'path' => '/helpsupport/ai-model/realtime/test', 'sort' => 10],
        ];
    }

    /**
     * @return list<string>
     */
    private function movedPageCodes(): array
    {
        return array_map(static fn (array $move): string => $move['code'], $this->pageMoves());
    }

    /**
     * @param array{name:string,code:string,path:string,icon:string,sort:int} $group
     */
    private function ensureGroup(array $group): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`, ' . $this->q($group['name']) . ', ' . $this->q($group['code']) . ', NULL, 2, ' . $this->q($group['path']) . ', ' . $this->q('') . ', NULL, ' . $this->q($group['icon']) . ', ' . (int) $group['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` = ' . $this->q(self::ROOT_CODE) . '
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q($group['code']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q(self::ROOT_CODE) . '
                    AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`name` = ' . $this->q($group['name']) . ',
                 page.`type` = 2,
                 page.`path` = ' . $this->q($group['path']) . ',
                 page.`component` = ' . $this->q('') . ',
                 page.`icon` = ' . $this->q($group['icon']) . ',
                 page.`sort` = ' . (int) $group['sort'] . ',
                 page.`status` = 1,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q($group['code']) . '
               AND page.`delete_time` IS NULL'
        );
    }

    /**
     * @param array{code:string,group:string,name:?string,path:?string,sort:int} $move
     */
    private function movePage(array $move): void
    {
        $nameSql = $move['name'] === null ? 'page.`name`' : $this->q($move['name']);
        $pathSql = $move['path'] === null ? 'page.`path`' : $this->q($move['path']);
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q($move['group']) . '
                    AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`name` = ' . $nameSql . ',
                 page.`path` = ' . $pathSql . ',
                 page.`sort` = ' . (int) $move['sort'] . ',
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q($move['code']) . '
               AND page.`delete_time` IS NULL'
        );
    }

    private function grantGroupMenus(): void
    {
        if (!$this->hasTable('sa_system_role_menu')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT DISTINCT rm.`role_id`, target.`id`
             FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` source ON source.`id` = rm.`menu_id` AND source.`delete_time` IS NULL
             INNER JOIN `sa_system_menu` target ON target.`remark` = ' . $this->q(self::REMARK) . ' AND target.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = target.`id`
             WHERE source.`code` IN (' . $this->inList(array_merge([self::ROOT_CODE], $this->movedPageCodes())) . ')
               AND existing.`id` IS NULL'
        );
    }

    /**
     * @param list<string> $values
     */
    private function inList(array $values): string
    {
        return implode(', ', array_map(fn (string $value): string => $this->q($value), $values));
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
