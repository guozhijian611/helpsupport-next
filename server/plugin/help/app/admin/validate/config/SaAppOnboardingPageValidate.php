<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\config;

use plugin\saiadmin\basic\BaseValidate;

/**
 * App引导页配置验证器
 */
class SaAppOnboardingPageValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'scene' => 'require',
        'locale' => 'require',
        'title' => 'require',
        'description' => 'require',
        'image' => 'require',
        'button_text' => 'require',
        'action_type' => 'require',
        'sort' => 'require',
        'status' => 'require',
        'slide_ids' => 'require|array',
        'source_scene' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'scene' => '场景必须填写',
        'locale' => '语言必须填写',
        'title' => '标题必须填写',
        'description' => '说明必须填写',
        'image' => '图片URL或附件路径必须填写',
        'button_text' => '按钮文案必须填写',
        'action_type' => '动作类型必须填写',
        'sort' => '排序必须填写',
        'status' => '状态必须填写',
        'slide_ids.require' => '请提供播放顺序',
        'slide_ids.array' => '播放顺序格式错误',
        'source_scene.require' => '源场景必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'scene',
            'locale',
            'title',
            'description',
            'image',
            'button_text',
            'action_type',
            'sort',
            'status',
        ],
        'update' => [
            'scene',
            'locale',
            'title',
            'description',
            'image',
            'button_text',
            'action_type',
            'sort',
            'status',
        ],
        'reorder' => [
            'scene',
            'slide_ids',
        ],
        'copyFlow' => [
            'source_scene',
            'scene',
        ],
    ];

}
