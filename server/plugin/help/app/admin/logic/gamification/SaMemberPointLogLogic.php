<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberPointLog;
use plugin\help\app\service\HelpPointService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 积分流水逻辑层
 */
class SaMemberPointLogLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberPointLog();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return (new HelpPointService())->addLog($data, $this->currentAdminId(), false);
    }

    public function edit($id, array $data): mixed
    {
        throw new ApiException('积分流水不支持直接修改，请新增一条调整流水');
    }

    public function destroy($ids): bool
    {
        throw new ApiException('积分流水不支持删除');
    }

    private function currentAdminId(): ?int
    {
        if (!function_exists('getCurrentInfo')) {
            return null;
        }
        $info = getCurrentInfo();

        return isset($info['id']) ? (int) $info['id'] : null;
    }
}
