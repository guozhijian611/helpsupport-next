<?php

namespace plugin\help\app\admin\validate\me;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 回忆录配置验证器
 */
class SaMemberMemoirConfigValidate extends BaseValidate
{
    protected $rule = [
        'name' => 'require|max:100',
        'code' => 'require|alphaDash|max:80',
        'generation_cycle' => 'require|in:weekly,monthly,quarterly',
        'source_type' => 'require|in:journal,task,mixed',
        'min_journal_count' => 'integer',
        'start_day' => 'integer',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'name.require' => '配置名称必须填写',
        'name.max' => '配置名称不能超过100个字符',
        'code.require' => '配置编码必须填写',
        'code.alphaDash' => '配置编码只能包含字母、数字、下划线和横线',
        'code.max' => '配置编码不能超过80个字符',
        'generation_cycle.require' => '生成周期必须填写',
        'generation_cycle.in' => '生成周期参数错误',
        'source_type.require' => '来源类型必须填写',
        'source_type.in' => '来源类型参数错误',
        'min_journal_count.integer' => '最少日记数必须为整数',
        'start_day.integer' => '周期开始日必须为整数',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['name', 'code', 'generation_cycle', 'source_type', 'min_journal_count', 'start_day', 'sort', 'status'],
        'update' => ['name', 'code', 'generation_cycle', 'source_type', 'min_journal_count', 'start_day', 'sort', 'status'],
    ];
}
