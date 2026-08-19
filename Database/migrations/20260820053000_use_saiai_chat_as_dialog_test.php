<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 对话测试改回 SAIAI 试聊台，停用误挂的对话分组 CRUD。
 */
final class UseSaiaiChatAsDialogTest extends AbstractMigration
{
    private const REMARK = 'phinx:20260820053000_use_saiai_chat_as_dialog_test';
    private const LAB_CODE = 'help/aiModel/lab';
    private const CHAT_CODE = 'AiChat';
    private const GROUP_CODE = 'saiai/chat/group';

    public function up(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` lab
                     ON lab.`code` = ' . $this->q(self::LAB_CODE) . '
                    AND lab.`delete_time` IS NULL
             SET page.`parent_id` = lab.`id`,
                 page.`name` = ' . $this->q('对话测试') . ',
                 page.`path` = ' . $this->q('/helpsupport/ai-model/chat/group') . ',
                 page.`component` = ' . $this->q('/plugin/saiai/index') . ',
                 page.`sort` = 20,
                 page.`status` = 1,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q(self::CHAT_CODE) . '
               AND page.`delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu`
             SET `status` = 2,
                 `path` = ' . $this->q('/helpsupport/ai-model/chat/group-manage') . ',
                 `remark` = CASE
                     WHEN `remark` IS NULL OR `remark` = ' . $this->q('') . ' THEN ' . $this->q(self::REMARK) . '
                     ELSE `remark`
                 END,
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               AND `delete_time` IS NULL'
        );
        $this->grantChatMenu();
        $this->clearMenuCaches();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` lab
                     ON lab.`code` = ' . $this->q(self::LAB_CODE) . '
                    AND lab.`delete_time` IS NULL
             SET page.`parent_id` = lab.`id`,
                 page.`name` = ' . $this->q('对话测试') . ',
                 page.`path` = ' . $this->q('/helpsupport/ai-model/chat/group') . ',
                 page.`component` = ' . $this->q('/plugin/saiai/chat/group/index') . ',
                 page.`sort` = 20,
                 page.`status` = 1,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q(self::GROUP_CODE) . '
               AND page.`delete_time` IS NULL'
        );
        $this->execute(
            'UPDATE `sa_system_menu` page
             INNER JOIN `sa_system_menu` saiai
                     ON saiai.`code` = ' . $this->q('Saiai') . '
             SET page.`parent_id` = saiai.`id`,
                 page.`name` = ' . $this->q('AI对话') . ',
                 page.`path` = ' . $this->q('aichat') . ',
                 page.`component` = ' . $this->q('/plugin/saiai/index') . ',
                 page.`sort` = 100,
                 page.`status` = 2,
                 page.`updated_by` = 1,
                 page.`update_time` = NOW()
             WHERE page.`code` = ' . $this->q(self::CHAT_CODE) . '
               AND page.`delete_time` IS NULL'
        );
        $this->clearMenuCaches();
    }

    private function grantChatMenu(): void
    {
        if (!$this->hasTable('sa_system_role_menu')) {
            return;
        }
        $this->execute(
            'INSERT INTO `sa_system_role_menu` (`role_id`, `menu_id`)
             SELECT DISTINCT rm.`role_id`, chat.`id`
             FROM `sa_system_role_menu` rm
             INNER JOIN `sa_system_menu` source ON source.`id` = rm.`menu_id` AND source.`delete_time` IS NULL
             INNER JOIN `sa_system_menu` chat ON chat.`code` = ' . $this->q(self::CHAT_CODE) . ' AND chat.`delete_time` IS NULL
             LEFT JOIN `sa_system_role_menu` existing ON existing.`role_id` = rm.`role_id` AND existing.`menu_id` = chat.`id`
             WHERE source.`code` IN (' . $this->q(self::LAB_CODE) . ', ' . $this->q(self::GROUP_CODE) . ', ' . $this->q('help/aiModel') . ')
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
