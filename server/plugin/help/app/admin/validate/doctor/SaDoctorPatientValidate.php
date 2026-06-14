<?php

namespace plugin\help\app\admin\validate\doctor;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生患者绑定关系验证器
 */
class SaDoctorPatientValidate extends BaseValidate
{
    protected $rule = [
        'doctor_id' => 'require|integer',
        'member_id' => 'require|integer',
        'status' => 'require|in:1,2',
        'bind_source' => 'require|in:manual,system,appointment',
    ];

    protected $message = [
        'doctor_id.require' => '医生会员ID必须填写',
        'doctor_id.integer' => '医生会员ID必须为整数',
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
        'bind_source.require' => '绑定来源必须填写',
        'bind_source.in' => '绑定来源参数错误',
    ];

    protected $scene = [
        'save' => ['doctor_id', 'member_id', 'status', 'bind_source'],
        'update' => ['doctor_id', 'member_id', 'status', 'bind_source'],
    ];
}
