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
        'chat_mode' => 'require|in:doctor,companion,patient',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'member_id' => '会员ID必须填写',
        'chat_mode' => '模式 doctor/companion/patient必须填写',
        'chat_mode.in' => '模式必须是 doctor、companion 或 patient',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'member_id',
            'chat_mode',
        ],
        'update' => [
            'member_id',
            'chat_mode',
        ],
    ];

}
