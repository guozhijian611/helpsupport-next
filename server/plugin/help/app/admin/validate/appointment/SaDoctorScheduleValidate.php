<?php

namespace plugin\help\app\admin\validate\appointment;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生排班验证器
 */
class SaDoctorScheduleValidate extends BaseValidate
{
    protected $rule = [
        'doctor_id' => 'require|integer',
        'schedule_date' => 'require|dateFormat:Y-m-d',
        'time_slot' => 'require|max:50',
        'meet_type' => 'require|in:link,address,phone',
        'price' => 'float|egt:0',
        'currency' => 'require|max:8',
        'capacity' => 'require|integer|egt:1',
        'booked_count' => 'integer|egt:0',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'doctor_id.require' => '医生会员ID必须填写',
        'doctor_id.integer' => '医生会员ID必须为整数',
        'schedule_date.require' => '排班日期必须填写',
        'schedule_date.dateFormat' => '排班日期格式必须为YYYY-MM-DD',
        'time_slot.require' => '时间段必须填写',
        'time_slot.max' => '时间段不能超过50个字符',
        'meet_type.require' => '接诊方式必须填写',
        'meet_type.in' => '接诊方式参数错误',
        'price.float' => '预约价格必须为数字',
        'price.egt' => '预约价格不能小于0',
        'currency.require' => '币种必须填写',
        'currency.max' => '币种不能超过8个字符',
        'capacity.require' => '容量必须填写',
        'capacity.integer' => '容量必须为整数',
        'capacity.egt' => '容量不能小于1',
        'booked_count.integer' => '已预约人数必须为整数',
        'booked_count.egt' => '已预约人数不能小于0',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['doctor_id', 'schedule_date', 'time_slot', 'meet_type', 'price', 'currency', 'capacity', 'booked_count', 'status'],
        'update' => ['doctor_id', 'schedule_date', 'time_slot', 'meet_type', 'price', 'currency', 'capacity', 'booked_count', 'status'],
    ];
}
