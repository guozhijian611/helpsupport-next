<?php

namespace plugin\help\app\model\doctor;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生评估量表模型
 *
 * sa_doctor_assessment_scale HelpSupport 医生评估量表表
 */
class SaDoctorAssessmentScale extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_assessment_scale';

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchTitleAttr($query, $value): void
    {
        $query->where('title', 'like', '%' . $value . '%');
    }

    public function searchStageAttr($query, $value): void
    {
        $query->where('stage', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (string) $value);
    }
}
