<?php

namespace plugin\help\app\model\appointment;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生预约模型
 *
 * sa_doctor_appointment HelpSupport 医生预约表
 */
class SaDoctorAppointment extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_doctor_appointment';

    public function searchMemberIdAttr($query, $value): void
    {
        $query->where('member_id', (int) $value);
    }

    public function searchDoctorIdAttr($query, $value): void
    {
        $query->where('doctor_id', (int) $value);
    }

    public function searchAppointDateAttr($query, $value): void
    {
        $query->where('appoint_date', (string) $value);
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }

    public function searchMeetTypeAttr($query, $value): void
    {
        $query->where('meet_type', (string) $value);
    }

    public function searchPaymentMethodAttr($query, $value): void
    {
        $query->where('payment_method', (string) $value);
    }
}
