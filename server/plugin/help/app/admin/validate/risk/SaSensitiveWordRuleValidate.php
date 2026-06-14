<?php

namespace plugin\help\app\admin\validate\risk;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 敏感词风控规则验证器
 */
class SaSensitiveWordRuleValidate extends BaseValidate
{
    protected $rule = [
        'scene' => 'require|in:community,material,profile,chat,all',
        'word' => 'require|max:160',
        'match_type' => 'require|in:contains,exact,regex',
        'action' => 'require|in:review,reject,replace',
        'risk_level' => 'require|in:1,2,3',
        'hit_count' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'scene.require' => '生效场景必须填写',
        'scene.in' => '生效场景参数错误',
        'word.require' => '规则内容必须填写',
        'word.max' => '规则内容不能超过160个字符',
        'match_type.require' => '匹配方式必须填写',
        'match_type.in' => '匹配方式参数错误',
        'action.require' => '处理动作必须填写',
        'action.in' => '处理动作参数错误',
        'risk_level.require' => '风险等级必须填写',
        'risk_level.in' => '风险等级参数错误',
        'hit_count.integer' => '命中次数必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['scene', 'word', 'match_type', 'action', 'risk_level', 'hit_count', 'status'],
        'update' => ['scene', 'word', 'match_type', 'action', 'risk_level', 'hit_count', 'status'],
    ];
}
