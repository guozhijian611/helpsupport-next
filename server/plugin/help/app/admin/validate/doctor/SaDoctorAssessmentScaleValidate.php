<?php

namespace plugin\help\app\admin\validate\doctor;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生评估量表验证器
 */
class SaDoctorAssessmentScaleValidate extends BaseValidate
{
    protected $rule = [
        'doctor_id' => 'integer',
        'title' => 'require|max:160',
        'stage' => 'max:30',
        'description' => 'max:500',
        'total_score' => 'integer',
        'status' => 'require|in:draft,published,disabled',
    ];

    protected $message = [
        'doctor_id.integer' => '医生会员ID必须为整数',
        'title.require' => '量表名称必须填写',
        'title.max' => '量表名称不能超过160个字符',
        'stage.max' => '所属阶段不能超过30个字符',
        'description.max' => '量表简介不能超过500个字符',
        'total_score.integer' => '量表总分必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['doctor_id', 'title', 'stage', 'description', 'total_score', 'status'],
        'update' => ['doctor_id', 'title', 'stage', 'description', 'total_score', 'status'],
    ];
}
