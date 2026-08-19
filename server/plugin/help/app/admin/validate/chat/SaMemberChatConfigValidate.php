<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

/**
 * AI聊天配置验证器
 */
class SaMemberChatConfigValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'member_id' => 'require',
        'chat_mode' => 'require|in:doctor,companion,patient,ai_doctor',
        'online_config_id' => 'integer|egt:0',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'member_id' => '会员ID必须填写',
        'chat_mode' => '模式 doctor/companion/patient/ai_doctor必须填写',
        'chat_mode.in' => '模式必须是 doctor、companion、patient 或 ai_doctor',
        'online_config_id.integer' => '在线模型配置ID格式错误',
        'online_config_id.egt' => '在线模型配置ID格式错误',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'member_id',
            'chat_mode',
            'online_config_id',
        ],
        'update' => [
            'member_id',
            'chat_mode',
            'online_config_id',
        ],
    ];

}
