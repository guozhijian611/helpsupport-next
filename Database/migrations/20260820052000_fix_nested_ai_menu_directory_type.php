<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 二级分组不能用目录 type=1，否则后台会把 /index/index 布局再套一层。
 */
final class FixNestedAiMenuDirectoryType extends AbstractMigration
{
    private const REMARK = 'phinx:20260820051000_nest_ai_management_menu_groups';

    /**
     * @var list<string>
     */
    private const GROUP_CODES = [
        'help/aiModel/hub',
        'help/aiModel/prompts',
        'help/aiModel/records',
        'help/aiModel/lab',
    ];

    public function up(): void
    {
        $this->setGroupType(2);
    }

    public function down(): void
    {
        $this->setGroupType(1);
    }

    private function setGroupType(int $type): void
    {
        if (!$this->hasTable('sa_system_menu')) {
            return;
        }

        $this->execute(
            'UPDATE `sa_system_menu`
             SET `type` = ' . $type . ',
                 `component` = ' . $this->q('') . ',
                 `updated_by` = 1,
                 `update_time` = NOW()
             WHERE `code` IN (' . $this->inList(self::GROUP_CODES) . ')
               AND `delete_time` IS NULL
               AND `remark` = ' . $this->q(self::REMARK)
        );
        $this->clearMenuCaches();
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
