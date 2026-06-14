<?php

namespace plugin\help\app\admin\validate\doctor;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生任务模板文件夹验证器
 */
class SaDoctorTaskTemplateFolderValidate extends BaseValidate
{
    protected $rule = [
        'doctor_id' => 'integer',
        'name' => 'require|max:80',
        'color' => 'require|max:20',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'doctor_id.integer' => '医生会员ID必须为整数',
        'name.require' => '文件夹名称必须填写',
        'name.max' => '文件夹名称不能超过80个字符',
        'color.require' => '主题颜色必须填写',
        'color.max' => '主题颜色不能超过20个字符',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['doctor_id', 'name', 'color', 'sort', 'status'],
        'update' => ['doctor_id', 'name', 'color', 'sort', 'status'],
    ];
}
