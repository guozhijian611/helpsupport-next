<?php

namespace plugin\help\app\admin\validate\appointment;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生预约验证器
 */
class SaDoctorAppointmentValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'doctor_id' => 'require|integer',
        'schedule_id' => 'integer|egt:0',
        'appoint_date' => 'require|dateFormat:Y-m-d',
        'appoint_time_slot' => 'require|max:50',
        'payment_method' => 'in:cash,points',
        'points_cost' => 'integer|egt:0',
        'points_log_id' => 'integer|egt:0',
        'points_refund_log_id' => 'integer|egt:0',
        'status' => 'require|in:0,1,2,3,4',
    ];

    protected $message = [
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'doctor_id.require' => '医生会员ID必须填写',
        'doctor_id.integer' => '医生会员ID必须为整数',
        'schedule_id.integer' => '排班ID必须为整数',
        'schedule_id.egt' => '排班ID不能小于0',
        'appoint_date.require' => '预约日期必须填写',
        'appoint_date.dateFormat' => '预约日期格式必须为YYYY-MM-DD',
        'appoint_time_slot.require' => '预约时间段必须填写',
        'appoint_time_slot.max' => '预约时间段不能超过50个字符',
        'payment_method.in' => '支付方式参数错误',
        'points_cost.integer' => '预约消耗积分必须为整数',
        'points_cost.egt' => '预约消耗积分不能小于0',
        'points_log_id.integer' => '积分扣减流水ID必须为整数',
        'points_log_id.egt' => '积分扣减流水ID不能小于0',
        'points_refund_log_id.integer' => '积分退回流水ID必须为整数',
        'points_refund_log_id.egt' => '积分退回流水ID不能小于0',
        'status.require' => '预约状态必须填写',
        'status.in' => '预约状态参数错误',
    ];

    protected $scene = [
        'save' => ['member_id', 'doctor_id', 'schedule_id', 'appoint_date', 'appoint_time_slot', 'payment_method', 'points_cost', 'points_log_id', 'points_refund_log_id'],
        'update' => ['member_id', 'doctor_id', 'schedule_id', 'appoint_date', 'appoint_time_slot', 'payment_method', 'points_cost', 'points_log_id', 'points_refund_log_id'],
    ];
}
