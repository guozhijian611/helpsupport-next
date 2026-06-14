<?php

namespace plugin\help\app\admin\validate\plan;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 治疗阶段验证器
 */
class SaTreatmentStageValidate extends BaseValidate
{
    protected $rule = [
        'plan_id' => 'require|integer',
        'member_id' => 'require|integer',
        'stage_name' => 'require|max:80',
        'start_date' => 'require',
        'end_date' => 'require',
        'sort' => 'integer',
        'status' => 'require|in:0,1,2',
    ];

    protected $message = [
        'plan_id.require' => '所属计划ID必须填写',
        'plan_id.integer' => '所属计划ID必须为整数',
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'stage_name.require' => '阶段名称必须填写',
        'stage_name.max' => '阶段名称不能超过80个字符',
        'start_date.require' => '阶段开始日期必须填写',
        'end_date.require' => '阶段结束日期必须填写',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['plan_id', 'member_id', 'stage_name', 'start_date', 'end_date', 'sort', 'status'],
        'update' => ['plan_id', 'member_id', 'stage_name', 'start_date', 'end_date', 'sort', 'status'],
    ];
}
