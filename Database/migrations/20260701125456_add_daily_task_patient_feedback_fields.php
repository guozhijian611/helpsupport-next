<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddDailyTaskPatientFeedbackFields extends AbstractMigration
{
    private const TABLE = 'sa_daily_task';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        if (!$this->hasColumn('requires_feedback')) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD COLUMN `requires_feedback` tinyint(1) NOT NULL DEFAULT 0 COMMENT \'是否需要患者反馈\' AFTER `completion_note`'
            );
        }
        if (!$this->hasColumn('feedback_prompt')) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD COLUMN `feedback_prompt` varchar(255) DEFAULT NULL COMMENT \'患者反馈填写提示\' AFTER `requires_feedback`'
            );
        }
        if (!$this->hasColumn('feedback_content')) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD COLUMN `feedback_content` text COMMENT \'患者反馈内容\' AFTER `feedback_prompt`'
            );
        }
        if (!$this->hasColumn('feedback_time')) {
            $this->execute(
                'ALTER TABLE `' . self::TABLE . '`
                ADD COLUMN `feedback_time` datetime DEFAULT NULL COMMENT \'患者反馈时间\' AFTER `feedback_content`'
            );
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach (['feedback_time', 'feedback_content', 'feedback_prompt', 'requires_feedback'] as $column) {
            if ($this->hasColumn($column)) {
                $this->execute('ALTER TABLE `' . self::TABLE . '` DROP COLUMN `' . $column . '`');
            }
        }
    }

    private function hasColumn(string $column): bool
    {
        $rows = $this->fetchAll(
            'SHOW COLUMNS FROM `' . self::TABLE . '` LIKE ' . $this->getAdapter()->getConnection()->quote($column)
        );

        return $rows !== [];
    }
}
