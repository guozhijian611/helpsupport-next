<?php

declare(strict_types=1);

namespace plugin\help\app\event;

use support\Log;
use support\think\Db;
use Throwable;

class MemberLogin
{
    private static ?bool $hasPushDeviceTable = null;

    public function deactivatePushDevices(array $item): void
    {
        $memberId = (int) ($item['member_id'] ?? 0);
        $status = (int) ($item['status'] ?? 0);
        if ($memberId <= 0 || $status !== 1 || !self::hasPushDeviceTable()) {
            return;
        }

        $now = date('Y-m-d H:i:s');
        try {
            Db::table('sa_member_push_device')
                ->where('member_id', $memberId)
                ->where('is_active', 1)
                ->whereNull('delete_time')
                ->update([
                    'is_active' => 2,
                    'logout_time' => $now,
                    'updated_by' => $memberId,
                    'update_time' => $now,
                ]);
        } catch (Throwable $e) {
            Log::warning('HelpSupport 登录设备失效处理失败', [
                'member_id' => $memberId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    private static function hasPushDeviceTable(): bool
    {
        if (self::$hasPushDeviceTable !== null) {
            return self::$hasPushDeviceTable;
        }

        try {
            self::$hasPushDeviceTable = Db::query("SHOW TABLES LIKE 'sa_member_push_device'") !== [];
        } catch (Throwable) {
            self::$hasPushDeviceTable = false;
        }

        return self::$hasPushDeviceTable;
    }
}
