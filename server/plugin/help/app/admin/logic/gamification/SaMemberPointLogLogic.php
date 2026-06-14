<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberPointLog;
use plugin\saiadmin\basic\think\BaseLogic;

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
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        foreach (['source_id' => 0, 'balance_after' => 0] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
