<?php

namespace plugin\help\app\admin\validate\me;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 康复目标记录验证器
 */
class SaMemberRecoveryGoalLogValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'goal_text' => 'require|max:500',
        'goal_type' => 'require|in:custom,weekly,monthly',
        'target_date' => 'dateFormat:Y-m-d',
        'status' => 'require|in:1,2,3',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'goal_text.require' => '恢复目标必须填写',
        'goal_type.require' => '目标类型必须填写',
        'goal_type.in' => '目标类型参数错误',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'goal_text', 'goal_type', 'status'],
        'update' => ['member_id', 'goal_text', 'goal_type', 'status'],
    ];
}
