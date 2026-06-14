<?php

namespace plugin\help\app\model\push;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员推送偏好模型
 *
 * sa_member_push_preference 会员推送偏好表
 */
class SaMemberPushPreference extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_push_preference';
}
