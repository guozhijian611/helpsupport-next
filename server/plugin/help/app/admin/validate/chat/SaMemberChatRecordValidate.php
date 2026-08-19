<?php

namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员聊天记录验证器
 */
class SaMemberChatRecordValidate extends BaseValidate
{
    protected $rule = [
        'session_id' => 'require|integer',
        'member_id' => 'require|integer',
        'chat_mode' => 'require|in:doctor,companion,patient,ai_doctor',
        'role' => 'require|in:user,assistant,system',
        'content' => 'require',
        'content_type' => 'require|in:text,image,file,voice',
        'token_count' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'session_id.require' => '会话ID必须填写',
        'member_id.require' => '会员ID必须填写',
        'chat_mode.require' => '会话模式必须填写',
        'role.require' => '消息角色必须填写',
        'content.require' => '消息内容必须填写',
        'content_type.require' => '内容类型必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['session_id', 'member_id', 'chat_mode', 'role', 'content', 'content_type', 'token_count', 'status'],
        'update' => ['session_id', 'member_id', 'chat_mode', 'role', 'content', 'content_type', 'token_count', 'status'],
    ];
}
