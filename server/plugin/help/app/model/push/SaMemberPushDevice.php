<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\push;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 推送设备模型
 *
 * sa_member_push_device 会员推送设备表
 *
 * @property  $id 主键
 * @property  $member_id 会员ID
 * @property  $device_id 设备标识
 * @property  $platform 平台 ios/android
 * @property  $fcm_token FCM Token
 * @property  $apns_token APNs Token
 * @property  $app_version App版本
 * @property  $locale 当前语言
 * @property  $timezone 当前时区
 * @property  $is_active 是否有效 1是 2否
 * @property  $last_active_time 最近活跃时间
 * @property  $logout_time 退出或踢下线时间
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaMemberPushDevice extends BaseModel
{
    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    /**
     * 数据库表名称
     * @var string
     */
    protected $table = 'sa_member_push_device';

}
