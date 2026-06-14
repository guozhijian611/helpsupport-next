<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\chat;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\help\app\model\chat\SaMemberChatConfig;

/**
 * AI聊天配置逻辑层
 */
class SaMemberChatConfigLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaMemberChatConfig();
    }

}
