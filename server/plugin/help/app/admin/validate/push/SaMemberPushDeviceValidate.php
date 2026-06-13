<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\push;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 推送设备验证器
 */
class SaMemberPushDeviceValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'member_id' => 'require',
        'device_id' => 'require',
        'platform' => 'require',
        'fcm_token' => 'require',
        'apns_token' => 'require',
        'app_version' => 'require',
        'locale' => 'require',
        'timezone' => 'require',
        'is_active' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'member_id' => '会员ID必须填写',
        'device_id' => '设备标识必须填写',
        'platform' => '平台 ios/android必须填写',
        'fcm_token' => 'FCM Token必须填写',
        'apns_token' => 'APNs Token必须填写',
        'app_version' => 'App版本必须填写',
        'locale' => '当前语言必须填写',
        'timezone' => '当前时区必须填写',
        'is_active' => '是否有效 1是 2否必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'member_id',
            'device_id',
            'platform',
            'fcm_token',
            'apns_token',
            'app_version',
            'locale',
            'timezone',
            'is_active',
        ],
        'update' => [
            'member_id',
            'device_id',
            'platform',
            'fcm_token',
            'apns_token',
            'app_version',
            'locale',
            'timezone',
            'is_active',
        ],
    ];

}
