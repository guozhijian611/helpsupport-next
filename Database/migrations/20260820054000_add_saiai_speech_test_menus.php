<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 模型测试下增加 SAIAI 的 ASR / TTS 测试页。
 */
final class AddSaiaiSpeechTestMenus extends AbstractMigration
{
    private const REMARK = 'phinx:20260820054000_add_saiai_speech_test_menus';
    private const LAB_CODE = 'help/aiModel/lab';

    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        foreach ($this->pages() as $page) {
            $this->insertMenu($page);
        }
        foreach ($this->permissions() as $permission) {
            $this->insertPermission($permission);
        }
        $this->grantMenus();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

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
     * @return list<array{name:string,code:string,path:string,component:string,icon:string,sort:int}>
     */
    private function pages(): array
    {
        return [
            [
                'name' => 'ASR测试',
                'code' => 'saiai/speech/asr',
                'path' => '/helpsupport/ai-model/speech/asr',
                'component' => '/plugin/saiai/speech/asr/index',
                'icon' => 'ri:mic-line',
                'sort' => 16,
            ],
            [
                'name' => 'TTS测试',
                'code' => 'saiai/speech/tts',
                'path' => '/helpsupport/ai-model/speech/tts',
                'component' => '/plugin/saiai/speech/tts/index',
                'icon' => 'ri:volume-up-line',
                'sort' => 14,
            ],
        ];
    }

    /**
     * @return list<array{parent:string,name:string,slug:string}>
     */
    private function permissions(): array
    {
        return [
            ['parent' => 'saiai/speech/asr', 'name' => '打开ASR测试', 'slug' => 'saiai:speech:asr'],
            ['parent' => 'saiai/speech/tts', 'name' => '打开TTS测试', 'slug' => 'saiai:speech:tts'],
            ['parent' => 'saiai/speech/asr', 'name' => '语音测试配置', 'slug' => 'saiai:speech:test'],
        ];
    }

    /**
     * @param array{name:string,code:string,path:string,component:string,icon:string,sort:int} $page
     */
    private function insertMenu(array $page): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`, ' . $this->q($page['name']) . ', ' . $this->q($page['code']) . ', NULL, 2, ' . $this->q($page['path']) . ', ' . $this->q($page['component']) . ', NULL, ' . $this->q($page['icon']) . ', ' . (int) $page['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` = ' . $this->q(self::LAB_CODE) . '
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `code` = ' . $this->q($page['code']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` parent
                     ON parent.`code` = ' . $this->q(self::LAB_CODE) . '
                    AND parent.`delete_time` IS NULL
             SET page.`parent_id` = parent.`id`,
                 page.`name` = ' . $this->q($page['name']) . ',
                 page.`type` = 2,
                 page.`path` = ' . $this->q($page['path']) . ',
                 page.`component` = ' . $this->q($page['component']) . ',
                 page.`icon` = ' . $this->q($page['icon']) . ',
                 page.`sort` = ' . (int) $page['sort'] . ',
                 page.`status` = 1,
                 page.`is_hidden` = 2,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q($page['code']) . '
               AND page.`delete_time` IS NULL'
        );
    }

    /**
     * @param array{parent:string,name:string,slug:string} $permission
     */
    private function insertPermission(array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT parent.`id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_menu` parent
             WHERE parent.`code` = ' . $this->q($permission['parent']) . '
               AND parent.`delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_menu`
                   WHERE `slug` = ' . $this->q($permission['slug']) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function grantMenus(): void
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
             WHERE source.`code` IN (' . $this->q(self::LAB_CODE) . ', ' . $this->q('help/aiModel') . ', ' . $this->q('AiChat') . ', ' . $this->q('saiai/realtime/test') . ')
               AND existing.`id` IS NULL'
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
