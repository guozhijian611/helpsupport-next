<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberRecoveryGoalLog;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 康复目标记录逻辑层
 */
class SaMemberRecoveryGoalLogLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberRecoveryGoalLog();
        $this->orderField = 'create_time';
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
        foreach (['target_date', 'completed_time'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }
        foreach (['goal_type' => 'custom', 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
