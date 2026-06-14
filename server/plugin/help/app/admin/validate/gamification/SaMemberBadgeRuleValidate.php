<?php

namespace plugin\help\app\admin\validate\gamification;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 荣誉徽章规则验证器
 */
class SaMemberBadgeRuleValidate extends BaseValidate
{
    protected $rule = [
        'name' => 'require|max:100',
        'code' => 'require|alphaDash|max:80',
        'trigger_type' => 'require|in:task_count,checkin_streak,journal_count,material_learn,appointment_done,manual',
        'trigger_value' => 'integer',
        'points_reward' => 'integer',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'name.require' => '徽章名称必须填写',
        'name.max' => '徽章名称不能超过100个字符',
        'code.require' => '徽章编码必须填写',
        'code.alphaDash' => '徽章编码只能包含字母、数字、下划线和横线',
        'code.max' => '徽章编码不能超过80个字符',
        'trigger_type.require' => '触发类型必须填写',
        'trigger_type.in' => '触发类型参数错误',
        'trigger_value.integer' => '触发阈值必须为整数',
        'points_reward.integer' => '奖励积分必须为整数',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['name', 'code', 'trigger_type', 'trigger_value', 'points_reward', 'sort', 'status'],
        'update' => ['name', 'code', 'trigger_type', 'trigger_value', 'points_reward', 'sort', 'status'],
    ];
}
