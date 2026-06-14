<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\push;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\push\SaMemberPushDevice;
use think\facade\Db;

/**
 * 推送设备逻辑层
 */
class SaMemberPushDeviceLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaMemberPushDevice();
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data, (int) $id);

        return parent::edit($id, $data);
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('member_id', $data)) {
            $data['member_id'] = (int) $data['member_id'];
        }
        foreach (['device_id', 'platform'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = trim((string) $data[$field]);
            }
        }
        foreach (['last_active_time', 'logout_time'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        return $data;
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $deviceId = trim((string) ($data['device_id'] ?? ''));
        $platform = trim((string) ($data['platform'] ?? ''));
        if ($memberId <= 0 || $deviceId === '' || $platform === '') {
            return;
        }

        $query = Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('device_id', $deviceId)
            ->where('platform', $platform)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该会员设备平台的推送设备已存在');
        }
    }
}
