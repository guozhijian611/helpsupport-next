<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class BackfillHelpProfileRecordLogs extends AbstractMigration
{
    private const PROFILE_TABLE = 'sa_help_member_profile';
    private const RECOVERY_GOAL_TABLE = 'sa_member_recovery_goal_log';
    private const TRIGGER_TABLE = 'sa_member_trigger_log';
    private const RECOVERY_GOAL_REMARK = '由个人资料康复目标历史回填';
    private const TRIGGER_REMARK = '由个人资料重点触发历史回填';

    public function up(): void
    {
        if (!$this->canBackfill()) {
            return;
        }

        $profiles = $this->fetchAll(
            'SELECT `member_id`, `recovery_goal`, `trigger_tags`
               FROM `' . self::PROFILE_TABLE . '`
              WHERE `delete_time` IS NULL
                AND (
                    (`recovery_goal` IS NOT NULL AND TRIM(`recovery_goal`) <> \'\')
                    OR (`trigger_tags` IS NOT NULL AND TRIM(`trigger_tags`) <> \'\' AND TRIM(`trigger_tags`) <> \'[]\')
                )'
        );

        foreach ($profiles as $profile) {
            $memberId = (int) $profile['member_id'];
            if ($memberId <= 0) {
                continue;
            }

            $this->backfillRecoveryGoal($memberId, (string) ($profile['recovery_goal'] ?? ''));
            $this->backfillTriggerTags($memberId, $profile['trigger_tags'] ?? null);
        }
    }

    public function down(): void
    {
        if ($this->hasTable(self::RECOVERY_GOAL_TABLE)) {
            $this->execute(
                'DELETE FROM `' . self::RECOVERY_GOAL_TABLE . '`
                  WHERE `remark` = ' . $this->quote(self::RECOVERY_GOAL_REMARK)
            );
        }

        if ($this->hasTable(self::TRIGGER_TABLE)) {
            $this->execute(
                'DELETE FROM `' . self::TRIGGER_TABLE . '`
                  WHERE `remark` = ' . $this->quote(self::TRIGGER_REMARK)
            );
        }
    }

    private function canBackfill(): bool
    {
        return $this->hasTable(self::PROFILE_TABLE)
            && $this->hasTable(self::RECOVERY_GOAL_TABLE)
            && $this->hasTable(self::TRIGGER_TABLE)
            && $this->table(self::PROFILE_TABLE)->hasColumn('member_id')
            && $this->table(self::PROFILE_TABLE)->hasColumn('recovery_goal')
            && $this->table(self::PROFILE_TABLE)->hasColumn('trigger_tags');
    }

    private function backfillRecoveryGoal(int $memberId, string $goalText): void
    {
        $goalText = trim($goalText);
        if ($goalText === '') {
            return;
        }

        if ($this->exists(
            self::RECOVERY_GOAL_TABLE,
            'member_id = ' . $memberId
                . ' AND goal_text = ' . $this->quote($goalText)
                . ' AND remark = ' . $this->quote(self::RECOVERY_GOAL_REMARK)
                . ' AND delete_time IS NULL'
        )) {
            return;
        }

        $this->execute(
            'INSERT INTO `' . self::RECOVERY_GOAL_TABLE . '`
                (`member_id`, `goal_text`, `goal_type`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
             VALUES
                (' . $memberId . ', ' . $this->quote(mb_substr($goalText, 0, 500)) . ', \'custom\', 1, '
                . $this->quote(self::RECOVERY_GOAL_REMARK) . ', ' . $memberId . ', ' . $memberId . ', NOW(), NOW())'
        );
    }

    private function backfillTriggerTags(int $memberId, mixed $rawTags): void
    {
        foreach ($this->triggerTags($rawTags) as $triggerName) {
            if ($this->exists(
                self::TRIGGER_TABLE,
                'member_id = ' . $memberId
                    . ' AND trigger_name = ' . $this->quote($triggerName)
                    . ' AND remark = ' . $this->quote(self::TRIGGER_REMARK)
                    . ' AND delete_time IS NULL'
            )) {
                continue;
            }

            $this->execute(
                'INSERT INTO `' . self::TRIGGER_TABLE . '`
                    (`member_id`, `trigger_name`, `trigger_type`, `intensity`, `occurred_at`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
                 VALUES
                    (' . $memberId . ', ' . $this->quote(mb_substr($triggerName, 0, 120)) . ', \'custom\', 0, NOW(), 1, '
                    . $this->quote(self::TRIGGER_REMARK) . ', ' . $memberId . ', ' . $memberId . ', NOW(), NOW())'
            );
        }
    }

    /**
     * @return list<string>
     */
    private function triggerTags(mixed $rawTags): array
    {
        if (!is_string($rawTags) || trim($rawTags) === '') {
            return [];
        }

        $decoded = json_decode($rawTags, true);
        $items = json_last_error() === JSON_ERROR_NONE && is_array($decoded)
            ? $decoded
            : explode(',', $rawTags);

        $tags = [];
        foreach ($items as $item) {
            $text = trim((string) $item, " \t\n\r\0\x0B\"'");
            if ($text === '' || in_array($text, $tags, true)) {
                continue;
            }
            $tags[] = $text;
        }

        return $tags;
    }

    private function exists(string $table, string $where): bool
    {
        $rows = $this->fetchAll('SELECT `id` FROM `' . $table . '` WHERE ' . $where . ' LIMIT 1');

        return $rows !== [];
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
