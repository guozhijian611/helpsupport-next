<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: sai <1430792918@qq.com>
// +----------------------------------------------------------------------
namespace plugin\saiadmin\app\logic\system;

use plugin\saiadmin\app\model\system\SystemMailTemplate;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 邮件模板逻辑层
 */
class SystemMailTemplateLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SystemMailTemplate();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }
}
