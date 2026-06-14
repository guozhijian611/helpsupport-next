<?php

namespace plugin\help\app\model\message;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 会员消息中心模型
 *
 * sa_member_message HelpSupport 会员消息中心表
 */
class SaMemberMessage extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_member_message';
}
