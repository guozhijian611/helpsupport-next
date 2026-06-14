<?php

namespace plugin\help\app\model\doctor;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生患者绑定关系模型
 *
 * sa_doctor_patient HelpSupport 医生患者绑定关系表
 */
class SaDoctorPatient extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_patient';

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }

    public function searchBindSourceAttr($query, $value): void
    {
        $query->where('bind_source', (string) $value);
    }
}
