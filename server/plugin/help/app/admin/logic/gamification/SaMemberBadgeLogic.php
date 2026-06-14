<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberBadge;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员徽章记录逻辑层
 */
class SaMemberBadgeLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberBadge();
        $this->orderField = 'award_time';
        $this->orderType = 'DESC';
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
        if (array_key_exists('award_time', $data) && $data['award_time'] === '') {
            $data['award_time'] = null;
        }
        foreach (['rule_id' => 0, 'source_id' => 0, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
