<?php

namespace plugin\help\app\admin\validate\plan;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 治疗计划验证器
 */
class SaTreatmentPlanValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'doctor_id' => 'integer',
        'title' => 'require|max:160',
        'source_type' => 'require|in:manual,ai,template',
        'status' => 'require|in:1,2,3',
    ];

    protected $message = [
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'doctor_id.integer' => '医生会员ID必须为整数',
        'title.require' => '计划标题必须填写',
        'title.max' => '计划标题不能超过160个字符',
        'source_type.require' => '计划来源必须填写',
        'source_type.in' => '计划来源参数错误',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['member_id', 'doctor_id', 'title', 'source_type', 'status'],
        'update' => ['member_id', 'doctor_id', 'title', 'source_type', 'status'],
    ];
}
