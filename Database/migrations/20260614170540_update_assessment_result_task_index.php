<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class UpdateAssessmentResultTaskIndex extends AbstractMigration
{
    private const TABLE = 'sa_member_assessment_result';
    private const UNIQUE_INDEX = 'uk_member_task';
    private const NORMAL_INDEX = 'idx_member_task';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        if ($this->indexExists(self::UNIQUE_INDEX)) {
            $this->execute('ALTER TABLE `' . self::TABLE . '` DROP INDEX `' . self::UNIQUE_INDEX . '`');
        }

        if (!$this->indexExists(self::NORMAL_INDEX)) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD INDEX `' . self::NORMAL_INDEX . '` (`member_id`, `task_id`)'
            );
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        if ($this->hasDuplicateMemberTaskRows()) {
            // 已产生重复评估结果时强制恢复唯一索引会失败，并可能诱导删除业务数据。
            return;
        }

        if ($this->indexExists(self::NORMAL_INDEX)) {
            $this->execute('ALTER TABLE `' . self::TABLE . '` DROP INDEX `' . self::NORMAL_INDEX . '`');
        }

        if (!$this->indexExists(self::UNIQUE_INDEX)) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD UNIQUE INDEX `' . self::UNIQUE_INDEX . '` (`member_id`, `task_id`)'
            );
        }
    }

    private function indexExists(string $indexName): bool
    {
        $rows = $this->fetchAll(
            "SHOW INDEX FROM `" . self::TABLE . "` WHERE `Key_name` = '" . $this->escapeSql($indexName) . "'"
        );

        return $rows !== [];
    }

    private function escapeSql(string $value): string
    {
        return str_replace("'", "''", $value);
    }

    private function hasDuplicateMemberTaskRows(): bool
    {
        $row = $this->fetchRow(
            'SELECT COUNT(*) AS `count`
            FROM (
                SELECT `member_id`, `task_id`
                FROM `' . self::TABLE . '`
                GROUP BY `member_id`, `task_id`
                HAVING COUNT(*) > 1
            ) AS `duplicates`'
        );

        return (int) ($row['count'] ?? 0) > 0;
    }
}
