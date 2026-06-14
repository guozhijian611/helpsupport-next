<?php

namespace plugin\help\app\admin\validate\plan;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员评估结果验证器
 */
class SaMemberAssessmentResultValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'doctor_id' => 'integer',
        'task_id' => 'integer',
        'assessment_title' => 'require|max:160',
        'question_count' => 'integer',
        'total_score' => 'integer',
        'achieved_score' => 'integer',
    ];

    protected $message = [
        'member_id.require' => '患者会员ID必须填写',
        'member_id.integer' => '患者会员ID必须为整数',
        'doctor_id.integer' => '医生会员ID必须为整数',
        'task_id.integer' => '关联任务ID必须为整数',
        'assessment_title.require' => '量表名称必须填写',
        'assessment_title.max' => '量表名称不能超过160个字符',
        'question_count.integer' => '题目数必须为整数',
        'total_score.integer' => '总分必须为整数',
        'achieved_score.integer' => '实得分必须为整数',
    ];

    protected $scene = [
        'save' => ['member_id', 'doctor_id', 'task_id', 'assessment_title', 'question_count', 'total_score', 'achieved_score'],
        'update' => ['member_id', 'doctor_id', 'task_id', 'assessment_title', 'question_count', 'total_score', 'achieved_score'],
    ];
}
