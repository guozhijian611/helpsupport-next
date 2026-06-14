<?php

namespace plugin\help\app\admin\validate\plan;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 每日任务验证器
 */
class SaDailyTaskValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'plan_id' => 'integer',
        'stage_id' => 'integer',
        'task_date' => 'require',
        'title' => 'require|max:160',
        'task_type' => 'require|in:daily,assessment,material,checkin',
        'source' => 'require|in:chat,timeline,manual,template',
        'points_reward' => 'integer',
        'status' => 'require|in:0,1,2,3',
    ];

    protected $message = [
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'plan_id.integer' => '计划ID必须为整数',
        'stage_id.integer' => '阶段ID必须为整数',
        'task_date.require' => '任务日期必须填写',
        'title.require' => '任务标题必须填写',
        'title.max' => '任务标题不能超过160个字符',
        'task_type.require' => '任务类型必须填写',
        'task_type.in' => '任务类型参数错误',
        'source.require' => '任务来源必须填写',
        'source.in' => '任务来源参数错误',
        'points_reward.integer' => '奖励积分必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['member_id', 'plan_id', 'stage_id', 'task_date', 'title', 'task_type', 'source', 'points_reward', 'status'],
        'update' => ['member_id', 'plan_id', 'stage_id', 'task_date', 'title', 'task_type', 'source', 'points_reward', 'status'],
    ];
}
