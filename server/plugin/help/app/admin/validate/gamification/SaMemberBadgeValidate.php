<?php

namespace plugin\help\app\admin\validate\gamification;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员徽章记录验证器
 */
class SaMemberBadgeValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'rule_id' => 'integer',
        'badge_code' => 'max:80',
        'badge_name' => 'max:100',
        'source_type' => 'max:40',
        'source_id' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'rule_id', 'badge_code', 'badge_name', 'source_type', 'source_id', 'status'],
        'update' => ['member_id', 'rule_id', 'badge_code', 'badge_name', 'source_type', 'source_id', 'status'],
    ];
}
