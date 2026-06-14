<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberPointLog;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

/**
 * 积分流水逻辑层
 */
class SaMemberPointLogLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberPointLog();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);

        return Db::transaction(function () use ($data) {
            $memberId = (int) ($data['member_id'] ?? 0);
            $member = Db::table('sa_member')
                ->where('id', $memberId)
                ->whereNull('delete_time')
                ->lock(true)
                ->find();
            if (!$member) {
                throw new ApiException('会员不存在');
            }

            $balanceAfter = (int) ($member['points_balance'] ?? 0) + (int) $data['points'];
            if ($balanceAfter < 0) {
                throw new ApiException('会员积分余额不足');
            }

            $data['balance_after'] = $balanceAfter;
            $result = parent::add($data);

            Db::table('sa_member')
                ->where('id', $memberId)
                ->update([
                    'points_balance' => $balanceAfter,
                    'update_time' => date('Y-m-d H:i:s'),
                ]);

            return $result;
        });
    }

    public function edit($id, array $data): mixed
    {
        throw new ApiException('积分流水不支持直接修改，请新增一条调整流水');
    }

    public function destroy($ids): bool
    {
        throw new ApiException('积分流水不支持删除');
    }

    private function normalizeFields(array $data): array
    {
        foreach (['source_id' => 0] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }
        $data['source_type'] = trim((string) ($data['source_type'] ?? 'manual'));
        if ($data['source_type'] === '') {
            $data['source_type'] = 'manual';
        }

        $points = (int) ($data['points'] ?? 0);
        $changeType = (string) ($data['change_type'] ?? 'income');
        if ($points === 0) {
            throw new ApiException('积分变动值不能为0');
        }

        if ($changeType === 'income') {
            $data['points'] = abs($points);
        } elseif ($changeType === 'expense') {
            $data['points'] = -abs($points);
        } else {
            $data['points'] = $points;
        }
        $data['balance_after'] = 0;

        return $data;
    }
}
