<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: sai <1430792918@qq.com>
// +----------------------------------------------------------------------
namespace plugin\saiadmin\app\validate\system;

use plugin\saiadmin\app\model\system\SystemMailTemplate;
use plugin\saiadmin\basic\BaseValidate;

/**
 * 邮件模板验证器
 */
class SystemMailTemplateValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule = [
        'name' => 'require|max:100',
        'code' => 'require|alphaDash|max:100|unique:' . SystemMailTemplate::class,
        'subject' => 'require|max:255',
        'content' => 'require',
        'status' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message = [
        'name.require' => '模板名称必须填写',
        'name.max' => '模板名称最多不能超过100个字符',
        'code.require' => '模板标识必须填写',
        'code.alphaDash' => '模板标识只能由字母、数字、下划线和中划线组成',
        'code.max' => '模板标识最多不能超过100个字符',
        'code.unique' => '模板标识已存在',
        'subject.require' => '邮件主题必须填写',
        'subject.max' => '邮件主题最多不能超过255个字符',
        'content.require' => '邮件内容必须填写',
        'status.require' => '状态必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'name',
            'code',
            'subject',
            'content',
            'status',
        ],
        'update' => [
            'name',
            'code',
            'subject',
            'content',
            'status',
        ],
    ];
}
