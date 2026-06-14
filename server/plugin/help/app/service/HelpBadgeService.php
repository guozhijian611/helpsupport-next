<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use think\facade\Db;

/**
 * HelpSupport 徽章触发服务。
 */
class HelpBadgeService
{
    public function awardByTrigger(int $memberId, string $triggerType, int $triggerValue, string $sourceType, int $sourceId): void
    {
        if ($memberId <= 0 || $triggerValue <= 0) {
            return;
        }

        $rules = Db::table('sa_member_badge_rule')
            ->where('trigger_type', $triggerType)
            ->where('trigger_value', '<=', $triggerValue)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('trigger_value', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
        $now = date('Y-m-d H:i:s');
        foreach ($rules as $rule) {
            $code = (string) ($rule['code'] ?? '');
            if ($code === '' || Db::table('sa_member_badge')
                ->where('member_id', $memberId)
                ->where('badge_code', $code)
                ->whereNull('delete_time')
                ->find()) {
                continue;
            }

            $badgeId = (int) Db::table('sa_member_badge')->insertGetId([
                'member_id' => $memberId,
                'rule_id' => (int) $rule['id'],
                'badge_code' => $code,
                'badge_name' => (string) $rule['name'],
                'source_type' => $sourceType,
                'source_id' => $sourceId,
                'award_time' => $now,
                'status' => 1,
                'created_by' => $memberId,
                'updated_by' => $memberId,
                'create_time' => $now,
                'update_time' => $now,
            ]);

            $pointsReward = max(0, (int) ($rule['points_reward'] ?? 0));
            if ($pointsReward > 0) {
                $this->addPointLog($memberId, $pointsReward, 'badge', $badgeId, '获得荣誉徽章', (string) $rule['name']);
            }
        }
    }

    public function awardAppointmentDone(int $memberId, int $appointmentId): void
    {
        $doneCount = (int) Db::table('sa_doctor_appointment')
            ->where('member_id', $memberId)
            ->where('status', 2)
            ->whereNull('delete_time')
            ->count();

        $this->awardByTrigger($memberId, 'appointment_done', $doneCount, 'appointment', $appointmentId);
    }

    private function addPointLog(int $memberId, int $points, string $sourceType, int $sourceId, string $title, string $remark = ''): void
    {
        if ($memberId <= 0 || $points === 0) {
            return;
        }

        (new HelpPointService())->addLog([
            'member_id' => $memberId,
            'points' => $points,
            'change_type' => $points > 0 ? 'income' : 'expense',
            'source_type' => $sourceType,
            'source_id' => $sourceId,
            'title' => $title,
            'remark' => $remark,
        ], $memberId);
    }
}
