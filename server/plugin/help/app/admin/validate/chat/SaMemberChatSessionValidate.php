<?php

namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员聊天会话验证器
 */
class SaMemberChatSessionValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'chat_mode' => 'require|in:doctor,companion,patient',
        'session_name' => 'require|max:100',
        'is_pinned' => 'in:1,2',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'chat_mode.require' => '会话模式必须填写',
        'chat_mode.in' => '会话模式参数错误',
        'session_name.require' => '会话名称必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'chat_mode', 'session_name', 'is_pinned', 'status'],
        'update' => ['member_id', 'chat_mode', 'session_name', 'is_pinned', 'status'],
    ];
}
