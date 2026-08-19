<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\localModel;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 本地模型目录验证器
 */
class SaLocalModelCatalogValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'name' => 'require',
        'code' => 'require',
        'provider' => 'require',
        'model_family' => 'require',
        'capability' => 'require|in:llm,asr,tts',
        'quantization' => 'require',
        'file_size' => 'require',
        'download_url' => 'require',
        'sha256' => 'require',
        'intro' => 'require',
        'license' => 'require',
        'min_memory_mb' => 'require',
        'context_size' => 'require',
        'default_temperature' => 'require',
        'default_top_p' => 'require',
        'sort' => 'require',
        'status' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'name' => '模型显示名称必须填写',
        'code' => '模型编码必须填写',
        'provider' => '模型来源必须填写',
        'model_family' => '模型家族必须填写',
        'capability' => '能力类型必须填写',
        'capability.in' => '能力类型只能是 llm、asr 或 tts',
        'quantization' => '量化类型必须填写',
        'file_size' => '文件大小字节必须填写',
        'download_url' => '模型下载地址必须填写',
        'sha256' => 'SHA256校验值必须填写',
        'intro' => '默认介绍必须填写',
        'license' => '许可证说明必须填写',
        'min_memory_mb' => '推荐最小内存MB必须填写',
        'context_size' => '默认上下文长度必须填写',
        'default_temperature' => '默认温度必须填写',
        'default_top_p' => '默认top_p必须填写',
        'sort' => '排序必须填写',
        'status' => '状态 1启用 2禁用必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'name',
            'code',
            'provider',
            'model_family',
            'capability',
            'quantization',
            'file_size',
            'download_url',
            'sha256',
            'intro',
            'license',
            'min_memory_mb',
            'context_size',
            'default_temperature',
            'default_top_p',
            'sort',
            'status',
        ],
        'update' => [
            'name',
            'code',
            'provider',
            'model_family',
            'capability',
            'quantization',
            'file_size',
            'download_url',
            'sha256',
            'intro',
            'license',
            'min_memory_mb',
            'context_size',
            'default_temperature',
            'default_top_p',
            'sort',
            'status',
        ],
    ];

}
