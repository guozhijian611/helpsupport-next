<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\localModel;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 本地模型提示词验证器
 */
class SaLocalModelPromptValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'chat_mode' => 'require',
        'locale' => 'require',
        'title' => 'require',
        'first_message' => 'require',
        'status' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'chat_mode' => '聊天模式 doctor/companion/patient必须填写',
        'locale' => '语言必须填写',
        'title' => '提示词标题必须填写',
        'first_message' => '默认开场白必须填写',
        'status' => '状态 1启用 2禁用必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'chat_mode',
            'locale',
            'title',
            'first_message',
            'status',
        ],
        'update' => [
            'chat_mode',
            'locale',
            'title',
            'first_message',
            'status',
        ],
    ];

}
