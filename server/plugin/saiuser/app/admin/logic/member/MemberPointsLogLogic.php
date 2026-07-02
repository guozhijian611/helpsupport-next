<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\saiuser\app\admin\logic\member;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\model\member\MemberPointsLog;

/**
 * 积分日志逻辑层
 */
class MemberPointsLogLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new MemberPointsLog();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function destroy($ids): bool
    {
        throw new ApiException('积分日志不支持删除');
    }

}
