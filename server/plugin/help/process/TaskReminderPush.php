<?php

declare(strict_types=1);

namespace plugin\help\process;

use plugin\help\app\service\HelpPushService;
use Throwable;

/**
 * 每日任务提醒：扫描当天待办任务，按会员去重后写入消息中心并尝试 FCM 推送。
 *
 * 由后台「工具 / 定时任务」调度，默认每天 08:00 执行。
 */
class TaskReminderPush
{
    public function run(mixed $args): string
    {
        try {
            return (new HelpPushService())->dispatchDailyTaskReminders();
        } catch (Throwable $throwable) {
            return 'failed: ' . mb_substr($throwable->getMessage(), 0, 180);
        }
    }
}
