<?php

namespace plugin\help\app\model\plan;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 治疗计划模型
 *
 * sa_treatment_plan HelpSupport 治疗计划表
 */
class SaTreatmentPlan extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_treatment_plan';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchSourceTypeAttr($query, $value): void
    {
        $query->where('source_type', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
