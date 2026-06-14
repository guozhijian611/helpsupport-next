<?php

namespace plugin\help\app\admin\validate\push;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 推送模板验证器
 */
class SaPushTemplateValidate extends BaseValidate
{
    protected $rule = [
        'id' => 'require',
        'template_code' => 'require|max:80',
        'template_name' => 'require|max:120',
        'scene' => 'require|max:50',
        'locale' => 'require|max:20',
        'message_type' => 'require|in:1,2,3,4,5',
        'title' => 'require|max:160',
        'content' => 'require|max:1000',
        'route' => 'max:500',
        'is_default' => 'require|in:1,2',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'id.require' => '模板ID必须填写',
        'template_code.require' => '模板编码必须填写',
        'template_code.max' => '模板编码最多80个字符',
        'template_name.require' => '模板名称必须填写',
        'template_name.max' => '模板名称最多120个字符',
        'scene.require' => '推送场景必须填写',
        'scene.max' => '推送场景最多50个字符',
        'locale.require' => '语言必须填写',
        'locale.max' => '语言最多20个字符',
        'message_type.require' => '消息类型必须填写',
        'message_type.in' => '消息类型只能为1关注、2回复、3任务、4预约、5系统',
        'title.require' => '标题模板必须填写',
        'title.max' => '标题模板最多160个字符',
        'content.require' => '内容模板必须填写',
        'content.max' => '内容模板最多1000个字符',
        'route.max' => '跳转路由最多500个字符',
        'is_default.require' => '默认模板标识必须填写',
        'is_default.in' => '默认模板标识只能为1或2',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态只能为1或2',
    ];

    protected $scene = [
        'save' => [
            'template_code',
            'template_name',
            'scene',
            'locale',
            'message_type',
            'title',
            'content',
            'route',
            'is_default',
            'sort',
            'status',
        ],
        'update' => [
            'id',
            'template_code',
            'template_name',
            'scene',
            'locale',
            'message_type',
            'title',
            'content',
            'route',
            'is_default',
            'sort',
            'status',
        ],
    ];
}
