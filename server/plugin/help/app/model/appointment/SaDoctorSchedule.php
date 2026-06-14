<?php

namespace plugin\help\app\model\appointment;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生排班模型
 *
 * sa_doctor_schedule HelpSupport 医生排班表
 */
class SaDoctorSchedule extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_schedule';

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchScheduleDateAttr($query, $value): void
    {
        $query->where('schedule_date', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }

    public function searchMeetTypeAttr($query, $value): void
    {
        $query->where('meet_type', (string) $value);
    }
}
