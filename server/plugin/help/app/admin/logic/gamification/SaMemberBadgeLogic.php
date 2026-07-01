<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberBadge;
use plugin\saiadmin\exception\ApiException;
use plugin\saiadmin\basic\think\BaseLogic;
use think\facade\Db;

/**
 * 会员徽章记录逻辑层
 */
class SaMemberBadgeLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberBadge();
        $this->orderField = 'b.award_time';
        $this->orderType = 'DESC';
    }

    public function search(array $searchWhere = []): mixed
    {
        $query = $this->badgeQuery();
        if (!empty($searchWhere['member_id'])) {
            $query->where('b.member_id', (int) $searchWhere['member_id']);
        }
        if (!empty($searchWhere['badge_code'])) {
            $query->where('b.badge_code', 'like', '%' . $searchWhere['badge_code'] . '%');
        }
        if (!empty($searchWhere['badge_name'])) {
            $query->where('b.badge_name', 'like', '%' . $searchWhere['badge_name'] . '%');
        }
        if (!empty($searchWhere['source_type'])) {
            $query->where('b.source_type', (string) $searchWhere['source_type']);
        }
        if (array_key_exists('status', $searchWhere) && $searchWhere['status'] !== '' && $searchWhere['status'] !== null) {
            $query->where('b.status', (int) $searchWhere['status']);
        }

        return $query;
    }

    public function read($id): mixed
    {
        $row = $this->badgeQuery()->where('b.id', (int) $id)->find();
        if (!$row) {
            throw new ApiException('数据不存在');
        }

        return $row;
    }

    public function add(array $data): mixed
    {
        return parent::add($this->prepareAwardData($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->prepareAwardData($data));
    }

    public function prepareAwardData(array $data): array
    {
        $data = array_intersect_key($data, array_flip([
            'id',
            'member_id',
            'rule_id',
            'badge_code',
            'badge_name',
            'source_type',
            'source_id',
            'award_time',
            'status',
        ]));
        if (array_key_exists('award_time', $data) && $data['award_time'] === '') {
            $data['award_time'] = null;
        }
        if (!array_key_exists('award_time', $data) || $data['award_time'] === null) {
            $data['award_time'] = date('Y-m-d H:i:s');
        }
        foreach (['rule_id' => 0, 'source_id' => 0, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }
        if (!array_key_exists('source_type', $data) || trim((string) $data['source_type']) === '') {
            $data['source_type'] = 'manual';
        }

        $ruleId = (int) ($data['rule_id'] ?? 0);
        if ($ruleId > 0) {
            $rule = Db::table('sa_member_badge_rule')
                ->where('id', $ruleId)
                ->whereNull('delete_time')
                ->find();
            if (!$rule) {
                throw new ApiException('徽章规则不存在');
            }
            $data['badge_code'] = (string) ($rule['code'] ?? '');
            $data['badge_name'] = (string) ($rule['name'] ?? '');
        }

        if (trim((string) ($data['badge_code'] ?? '')) === '') {
            throw new ApiException('徽章编码必须填写，或先选择有效的规则ID');
        }
        if (trim((string) ($data['badge_name'] ?? '')) === '') {
            throw new ApiException('徽章名称必须填写，或先选择有效的规则ID');
        }

        return $data;
    }

    private function badgeQuery(): mixed
    {
        return Db::table('sa_member_badge')
            ->alias('b')
            ->leftJoin('sa_member_badge_rule r', 'r.id = b.rule_id AND r.delete_time IS NULL')
            ->field('b.*, r.icon AS badge_icon, r.description AS rule_description, r.trigger_type AS rule_trigger_type, r.trigger_value AS rule_trigger_value, r.points_reward AS rule_points_reward')
            ->whereNull('b.delete_time');
    }
}
