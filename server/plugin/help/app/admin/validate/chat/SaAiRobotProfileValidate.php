<?php

namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

/**
 * AI 机器人形象配置验证器
 */
class SaAiRobotProfileValidate extends BaseValidate
{
    protected $rule = [
        'chat_mode' => 'require|in:doctor,companion,patient',
        'runtime_mode' => 'require|in:online,local',
        'display_name' => 'require',
        'avatar' => 'require',
        'sort' => 'require',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'chat_mode.require' => '聊天模式必须填写',
        'chat_mode.in' => '聊天模式必须是 doctor、companion 或 patient',
        'runtime_mode.require' => '运行模式必须填写',
        'runtime_mode.in' => '运行模式必须是 online 或 local',
        'display_name.require' => '显示名称必须填写',
        'avatar.require' => '浅色头像必须上传',
        'sort.require' => '排序必须填写',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => ['chat_mode', 'runtime_mode', 'display_name', 'avatar', 'sort', 'status'],
        'update' => ['chat_mode', 'runtime_mode', 'display_name', 'avatar', 'sort', 'status'],
    ];
}
