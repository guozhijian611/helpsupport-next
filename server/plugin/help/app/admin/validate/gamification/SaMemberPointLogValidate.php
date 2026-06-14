<?php

namespace plugin\help\app\admin\validate\gamification;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 积分流水验证器
 */
class SaMemberPointLogValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'points' => 'require|integer',
        'change_type' => 'require|in:income,expense,adjust',
        'source_type' => 'require|max:40',
        'source_id' => 'integer',
        'title' => 'require|max:160',
        'balance_after' => 'integer',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'member_id.integer' => '会员ID必须为整数',
        'points.require' => '积分变动值必须填写',
        'points.integer' => '积分变动值必须为整数',
        'change_type.require' => '变动类型必须填写',
        'change_type.in' => '变动类型参数错误',
        'source_type.require' => '来源类型必须填写',
        'source_type.max' => '来源类型不能超过40个字符',
        'source_id.integer' => '来源ID必须为整数',
        'title.require' => '积分标题必须填写',
        'title.max' => '积分标题不能超过160个字符',
        'balance_after.integer' => '变动后余额必须为整数',
    ];

    protected $scene = [
        'save' => ['member_id', 'points', 'change_type', 'source_type', 'source_id', 'title'],
        'update' => ['member_id', 'points', 'change_type', 'source_type', 'source_id', 'title'],
    ];
}
