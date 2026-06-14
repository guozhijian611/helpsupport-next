<?php

namespace plugin\help\app\admin\validate\doctor;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生任务模板验证器
 */
class SaDoctorTaskTemplateValidate extends BaseValidate
{
    protected $rule = [
        'doctor_id' => 'integer',
        'folder_id' => 'max:64',
        'stage' => 'max:30',
        'title' => 'require|max:160',
        'task_type' => 'require|max:30',
        'priority' => 'require|max:20',
        'start_time' => 'require|max:5',
        'end_time' => 'require|max:5',
        'frequency' => 'require|max:20',
        'reward_score' => 'integer',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'doctor_id.integer' => '医生会员ID必须为整数',
        'folder_id.max' => '文件夹ID不能超过64个字符',
        'stage.max' => '所属阶段不能超过30个字符',
        'title.require' => '模板名称必须填写',
        'title.max' => '模板名称不能超过160个字符',
        'task_type.require' => '任务类型必须填写',
        'task_type.max' => '任务类型不能超过30个字符',
        'priority.require' => '优先级必须填写',
        'priority.max' => '优先级不能超过20个字符',
        'start_time.require' => '开始时间必须填写',
        'start_time.max' => '开始时间不能超过5个字符',
        'end_time.require' => '结束时间必须填写',
        'end_time.max' => '结束时间不能超过5个字符',
        'frequency.require' => '执行频率必须填写',
        'frequency.max' => '执行频率不能超过20个字符',
        'reward_score.integer' => '奖励积分必须为整数',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => [
            'doctor_id',
            'folder_id',
            'stage',
            'title',
            'task_type',
            'priority',
            'start_time',
            'end_time',
            'frequency',
            'reward_score',
            'sort',
            'status',
        ],
        'update' => [
            'doctor_id',
            'folder_id',
            'stage',
            'title',
            'task_type',
            'priority',
            'start_time',
            'end_time',
            'frequency',
            'reward_score',
            'sort',
            'status',
        ],
    ];
}
