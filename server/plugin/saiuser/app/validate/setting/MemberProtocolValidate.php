<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\validate\setting;

use think\Validate;

/**
 * 使用协议验证器
 */
class MemberProtocolValidate extends Validate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'protocol_type' => 'require',
        'locale' => 'max:20',
        'title' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'protocol_type' => '协议类型必须填写',
        'locale.max' => '语言最多20个字符',
        'title' => '协议标题必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'protocol_type',
            'locale',
            'title',
        ],
        'update' => [
            'protocol_type',
            'locale',
            'title',
        ],
    ];

}
