<?php

namespace plugin\help\app\admin\validate\me;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 触发因素记录验证器
 */
class SaMemberTriggerLogValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'trigger_name' => 'require|max:120',
        'trigger_type' => 'require|in:emotion,place,person,custom',
        'intensity' => 'integer',
        'occurred_at' => 'require|dateFormat:Y-m-d H:i:s',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'trigger_name.require' => '触发因素名称必须填写',
        'trigger_type.require' => '触发类型必须填写',
        'trigger_type.in' => '触发类型参数错误',
        'occurred_at.require' => '发生时间必须填写',
        'occurred_at.dateFormat' => '发生时间格式必须为YYYY-MM-DD HH:mm:ss',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'trigger_name', 'trigger_type', 'intensity', 'occurred_at', 'status'],
        'update' => ['member_id', 'trigger_name', 'trigger_type', 'intensity', 'occurred_at', 'status'],
    ];
}
