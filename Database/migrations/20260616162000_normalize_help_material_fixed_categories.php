<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class NormalizeHelpMaterialFixedCategories extends AbstractMigration
{
    private const REMARK = 'phinx:20260616162000_normalize_help_material_fixed_categories';
    private const TARGET_NAMES = [
        'education' => ['入门', '动机与认知', '应对技能', '复发预防', '家属指南'],
        'entertainment' => ['书籍', '电影', '音乐', '游戏'],
        'private' => ['私人素材'],
    ];
    private const FALLBACK_NAME = [
        'education' => '入门',
        'entertainment' => '书籍',
        'private' => '私人素材',
    ];

    /**
     * 只收敛历史演示数据分类，不处理管理员真实创建的业务分类。
     */
    public function up(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        foreach (self::TARGET_NAMES as $type => $names) {
            $targetId = $this->categoryId($type, self::FALLBACK_NAME[$type]);
            if ($targetId <= 0) {
                continue;
            }

            $legacyRows = $this->legacyDemoCategories($type, $names);
            foreach ($legacyRows as $row) {
                $id = (int) $row['id'];
                if ($this->hasTable('sa_content_material')) {
                    $this->execute(
                        'UPDATE `sa_content_material`
                        SET `category_id` = ' . $targetId . ', `update_time` = NOW()
                        WHERE `category_id` = ' . $id . '
                          AND `delete_time` IS NULL'
                    );
                }

                $this->execute(
                    'UPDATE `sa_content_category`
                    SET `status` = 2,
                        `remark` = CONCAT(IFNULL(`remark`, ' . $this->q('') . '), ' . $this->q(';' . self::REMARK) . '),
                        `update_time` = NOW(),
                        `delete_time` = NOW()
                    WHERE `id` = ' . $id . '
                      AND `delete_time` IS NULL'
                );
            }
        }
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_content_category')) {
            return;
        }

        // 回滚时恢复被隐藏的历史演示分类可见性；已归并到目标分类的素材不再自动迁回，避免误改用户后续编辑。
        $this->execute(
            'UPDATE `sa_content_category`
            SET `status` = 1,
                `delete_time` = NULL,
                `update_time` = NOW()
            WHERE `remark` LIKE ' . $this->q('%' . self::REMARK . '%')
        );
    }

    /**
     * @param array<int, string> $targetNames
     * @return array<int, array<string, mixed>>
     */
    private function legacyDemoCategories(string $type, array $targetNames): array
    {
        $quotedNames = implode(',', array_map(fn (string $name): string => $this->q($name), $targetNames));

        return $this->fetchAll(
            'SELECT `id`, `name`
            FROM `sa_content_category`
            WHERE `type` = ' . $this->q($type) . '
              AND `remark` = ' . $this->q('demo-seed') . '
              AND `name` NOT IN (' . $quotedNames . ')
              AND `delete_time` IS NULL'
        );
    }

    private function categoryId(string $type, string $name): int
    {
        $row = $this->fetchRow(
            'SELECT `id`
            FROM `sa_content_category`
            WHERE `type` = ' . $this->q($type) . '
              AND `name` = ' . $this->q($name) . '
              AND `delete_time` IS NULL
            ORDER BY `sort` ASC, `id` ASC
            LIMIT 1'
        );

        return (int) ($row['id'] ?? 0);
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
