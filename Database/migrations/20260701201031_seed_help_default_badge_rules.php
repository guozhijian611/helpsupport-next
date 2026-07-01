<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpDefaultBadgeRules extends AbstractMigration
{
    private const TABLE = 'sa_member_badge_rule';
    private const BADGE_TABLE = 'sa_member_badge';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach ($this->rules() as $rule) {
            $this->insertRuleIfMissing($rule);
        }

        $this->syncBadgeRuleIds();
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $codes = $this->quotedRuleCodes();
        if ($this->hasTable(self::BADGE_TABLE)) {
            $this->execute(
                'UPDATE `' . self::BADGE_TABLE . '`
                    SET `rule_id` = 0, `update_time` = NOW()
                  WHERE `badge_code` IN (' . implode(',', $codes) . ')
                    AND `delete_time` IS NULL'
            );
        }

        $this->execute(
            'DELETE FROM `' . self::TABLE . '`
              WHERE `code` IN (' . implode(',', $codes) . ')
                AND `created_by` = 1
                AND `delete_time` IS NULL'
        );
    }

    private function rules(): array
    {
        return [
            [
                'name' => '起步行动者',
                'code' => 'first_task_done',
                'description' => '首次完成康复任务后自动获得。',
                'trigger_type' => 'task_count',
                'trigger_value' => 1,
                'points_reward' => 10,
                'sort' => 10,
            ],
            [
                'name' => '韧性新手妈妈',
                'code' => 'demo_newmom_resilience',
                'description' => '累计完成 5 个康复任务后自动获得。',
                'trigger_type' => 'task_count',
                'trigger_value' => 5,
                'points_reward' => 20,
                'sort' => 20,
            ],
            [
                'name' => '稳定记录者',
                'code' => 'steady_recorder',
                'description' => '累计完成 7 个康复任务后自动获得。',
                'trigger_type' => 'task_count',
                'trigger_value' => 7,
                'points_reward' => 30,
                'sort' => 30,
            ],
            [
                'name' => '康复践行者',
                'code' => 'recovery_champion',
                'description' => '累计完成 30 个康复任务后自动获得。',
                'trigger_type' => 'task_count',
                'trigger_value' => 30,
                'points_reward' => 80,
                'sort' => 40,
            ],
            [
                'name' => '夜班恢复坚持者',
                'code' => 'demo_shift_keeper',
                'description' => '连续打卡 3 天后自动获得。',
                'trigger_type' => 'checkin_streak',
                'trigger_value' => 3,
                'points_reward' => 20,
                'sort' => 50,
            ],
            [
                'name' => '七日节律坚持者',
                'code' => 'demo_sleep_streak_7',
                'description' => '连续打卡 7 天后自动获得。',
                'trigger_type' => 'checkin_streak',
                'trigger_value' => 7,
                'points_reward' => 50,
                'sort' => 60,
            ],
            [
                'name' => '睡眠守护者',
                'code' => 'sleep_guardian',
                'description' => '连续打卡 14 天后自动获得。',
                'trigger_type' => 'checkin_streak',
                'trigger_value' => 14,
                'points_reward' => 80,
                'sort' => 70,
            ],
            [
                'name' => '初次记录者',
                'code' => 'first_journal',
                'description' => '首次记录会员日记后自动获得。',
                'trigger_type' => 'journal_count',
                'trigger_value' => 1,
                'points_reward' => 10,
                'sort' => 80,
            ],
            [
                'name' => '复盘星标用户',
                'code' => 'demo_reflection_star',
                'description' => '累计记录 7 篇会员日记后自动获得。',
                'trigger_type' => 'journal_count',
                'trigger_value' => 7,
                'points_reward' => 50,
                'sort' => 90,
            ],
            [
                'name' => '学习探索者',
                'code' => 'material_explorer',
                'description' => '累计学习 3 个素材后自动获得。',
                'trigger_type' => 'material_learn',
                'trigger_value' => 3,
                'points_reward' => 20,
                'sort' => 100,
            ],
            [
                'name' => '首次预约完成',
                'code' => 'first_appointment_done',
                'description' => '完成首次医生预约后自动获得。',
                'trigger_type' => 'appointment_done',
                'trigger_value' => 1,
                'points_reward' => 30,
                'sort' => 110,
            ],
            [
                'name' => '特别鼓励徽章',
                'code' => 'manual_care_award',
                'description' => '由后台管理员根据实际康复表现手动发放。',
                'trigger_type' => 'manual',
                'trigger_value' => 1,
                'points_reward' => 0,
                'sort' => 120,
            ],
        ];
    }

    private function insertRuleIfMissing(array $rule): void
    {
        $name = $this->q((string) $rule['name']);
        $code = $this->q((string) $rule['code']);
        $description = $this->q((string) $rule['description']);
        $triggerType = $this->q((string) $rule['trigger_type']);
        $triggerValue = (int) $rule['trigger_value'];
        $pointsReward = (int) $rule['points_reward'];
        $sort = (int) $rule['sort'];

        $this->execute(
            'INSERT INTO `' . self::TABLE . '`
                (`name`, `code`, `description`, `icon`, `trigger_type`, `trigger_value`, `points_reward`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $name . ', ' . $code . ', ' . $description . ", '', " . $triggerType . ', ' . $triggerValue . ', ' . $pointsReward . ', ' . $sort . ', 1, 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                SELECT 1 FROM `' . self::TABLE . '`
                 WHERE `code` = ' . $code . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function syncBadgeRuleIds(): void
    {
        if (!$this->hasTable(self::BADGE_TABLE)) {
            return;
        }

        $this->execute(
            'UPDATE `' . self::BADGE_TABLE . '` AS `b`
              INNER JOIN `' . self::TABLE . '` AS `r`
                      ON `r`.`code` = `b`.`badge_code`
                     AND `r`.`delete_time` IS NULL
                 SET `b`.`rule_id` = `r`.`id`,
                     `b`.`badge_name` = `r`.`name`,
                     `b`.`update_time` = NOW()
               WHERE `b`.`delete_time` IS NULL
                 AND (`b`.`rule_id` = 0 OR `b`.`rule_id` IS NULL)'
        );
    }

    private function quotedRuleCodes(): array
    {
        return array_map(
            fn (array $rule): string => $this->q((string) $rule['code']),
            $this->rules()
        );
    }

    private function q(string $value): string
    {
        return "'" . str_replace("'", "''", $value) . "'";
    }
}
