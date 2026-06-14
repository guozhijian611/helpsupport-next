<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberBadgeRule;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 荣誉徽章规则逻辑层
 */
class SaMemberBadgeRuleLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberBadgeRule();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        foreach (['trigger_value' => 1, 'points_reward' => 0, 'sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
