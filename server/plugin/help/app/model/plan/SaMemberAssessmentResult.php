<?php

namespace plugin\help\app\model\plan;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员评估结果模型
 *
 * sa_member_assessment_result HelpSupport 会员量表提交结果表
 */
class SaMemberAssessmentResult extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_assessment_result';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchAssessmentIdAttr($query, $value): void
    {
        $query->where('assessment_id', 'like', '%' . $value . '%');
    }

    public function searchAssessmentTitleAttr($query, $value): void
    {
        $query->where('assessment_title', 'like', '%' . $value . '%');
    }

    public function searchResultLevelAttr($query, $value): void
    {
        $query->where('result_level', (string) $value);
    }
}
