<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

class HelpPointService
{
    public function addLog(array $data, ?int $operatorId = null, bool $deduplicateSource = true): ?int
    {
        $data = $this->normalizeLogData($data);

        return Db::transaction(function () use ($data, $operatorId, $deduplicateSource) {
            $memberId = (int) $data['member_id'];
            $member = Db::table('sa_member')
                ->where('id', $memberId)
                ->whereNull('delete_time')
                ->lock(true)
                ->find();
            if (!$member) {
                throw new ApiException('会员不存在');
            }

            if ($deduplicateSource && (int) $data['source_id'] > 0 && $this->sourceLogExists($data)) {
                return null;
            }

            $balanceAfter = (int) ($member['points_balance'] ?? 0) + (int) $data['points'];
            if ($balanceAfter < 0) {
                throw new ApiException('会员积分余额不足');
            }

            $now = date('Y-m-d H:i:s');
            $operator = $operatorId ?? $memberId;
            $data['balance_after'] = $balanceAfter;
            $data['created_by'] = $operator;
            $data['updated_by'] = $operator;
            $data['create_time'] = $now;
            $data['update_time'] = $now;

            $id = (int) Db::table('sa_member_point_log')->insertGetId($data);
            $memberUpdate = [
                'points_balance' => $balanceAfter,
                'update_time' => $now,
            ];
            $levelId = $this->levelIdForPoints($balanceAfter, (int) ($member['member_level_id'] ?? 0));
            if ($levelId > 0) {
                $memberUpdate['member_level_id'] = $levelId;
            }
            Db::table('sa_member')
                ->where('id', $memberId)
                ->update($memberUpdate);

            return $id;
        });
    }

    public function balance(int $memberId): int
    {
        return (int) Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->value('points_balance');
    }

    private function normalizeLogData(array $data): array
    {
        $points = (int) ($data['points'] ?? 0);
        if ($points === 0) {
            throw new ApiException('积分变动值不能为0');
        }

        $changeType = (string) ($data['change_type'] ?? ($points < 0 ? 'expense' : 'income'));
        if (!in_array($changeType, ['income', 'expense', 'adjust'], true)) {
            throw new ApiException('变动类型参数错误');
        }

        if ($changeType === 'income') {
            $points = abs($points);
        } elseif ($changeType === 'expense') {
            $points = -abs($points);
        }

        $sourceType = trim((string) ($data['source_type'] ?? 'manual'));
        if ($sourceType === '') {
            $sourceType = 'manual';
        }

        return [
            'member_id' => (int) ($data['member_id'] ?? 0),
            'points' => $points,
            'change_type' => $changeType,
            'source_type' => $sourceType,
            'source_id' => (int) ($data['source_id'] ?? 0),
            'title' => (string) ($data['title'] ?? ''),
            'remark' => (string) ($data['remark'] ?? ''),
        ];
    }

    private function sourceLogExists(array $data): bool
    {
        return (bool) Db::table('sa_member_point_log')
            ->where('member_id', (int) $data['member_id'])
            ->where('source_type', (string) $data['source_type'])
            ->where('source_id', (int) $data['source_id'])
            ->whereNull('delete_time')
            ->find();
    }

    private function levelIdForPoints(int $points, int $currentLevelId): int
    {
        $level = Db::table('sa_member_level')
            ->where('min_points', '<=', $points)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->where(function ($query) use ($points): void {
                $query->whereNull('max_points')->whereOr('max_points', '>=', $points);
            })
            ->field('id')
            ->order('min_points', 'desc')
            ->order('sort', 'asc')
            ->order('id', 'desc')
            ->find();

        return (int) ($level['id'] ?? $currentLevelId);
    }
}
