<?php

namespace plugin\help\app\admin\logic\plan;

use plugin\help\app\model\plan\SaTreatmentPlan;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 治疗计划逻辑层
 */
class SaTreatmentPlanLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaTreatmentPlan();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeNullableFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeNullableFields($data));
    }

    private function normalizeNullableFields(array $data): array
    {
        foreach (['start_date', 'end_date'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        return $data;
    }
}
