<?php

namespace plugin\help\app\model\plan;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 治疗计划阶段模型
 *
 * sa_treatment_stage HelpSupport 治疗计划阶段表
 */
class SaTreatmentStage extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_treatment_stage';

    public function searchPlanIdAttr($query, $value): void
    {
        $query->where('plan_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchStageKeyAttr($query, $value): void
    {
        $query->where('stage_key', 'like', '%' . $value . '%');
    }

    public function searchStageNameAttr($query, $value): void
    {
        $query->where('stage_name', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
