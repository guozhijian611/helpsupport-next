<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpTaskReminderCrontab extends AbstractMigration
{
    private const TABLE = 'sa_tool_crontab';
    private const TEMPLATE_TABLE = 'sa_push_template';
    private const REMARK = 'phinx:20260819070000_seed_help_task_reminder_crontab';
    private const TARGET = '\\plugin\\help\\process\\TaskReminderPush';
    private const NAME = '每日任务提醒推送';

    public function up(): void
    {
        $this->seedCrontab();
        $this->updateTemplateRoutes();
    }

    public function down(): void
    {
        if ($this->hasTable(self::TABLE)) {
            $this->execute(
                'DELETE FROM `' . self::TABLE . '`
                WHERE `remark` = ' . $this->q(self::REMARK) . '
                  AND `target` = ' . $this->q(self::TARGET)
            );
        }

        if (!$this->hasTable(self::TEMPLATE_TABLE)) {
            return;
        }

        foreach ($this->templateRouteMap() as $from => $to) {
            $this->execute(
                'UPDATE `' . self::TEMPLATE_TABLE . '`
                SET `route` = ' . $this->q($from) . ', `update_time` = NOW()
                WHERE `route` = ' . $this->q($to) . '
                  AND `delete_time` IS NULL'
            );
        }
    }

    private function seedCrontab(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        $now = date('Y-m-d H:i:s');
        $this->execute(
            'INSERT INTO `' . self::TABLE . '` (`name`, `type`, `target`, `parameter`, `task_style`, `rule`, `singleton`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT ' . $this->q(self::NAME) . ', 3, ' . $this->q(self::TARGET) . ', ' . $this->q('{}') . ', 1, ' . $this->q('0 0 8 * * *') . ', 2, 1, ' . $this->q(self::REMARK) . ', 1, 1, ' . $this->q($now) . ', ' . $this->q($now) . ', NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `' . self::TABLE . '`
                WHERE `target` = ' . $this->q(self::TARGET) . '
                  AND `delete_time` IS NULL
            )'
        );
    }

    private function updateTemplateRoutes(): void
    {
        if (!$this->hasTable(self::TEMPLATE_TABLE)) {
            return;
        }

        foreach ($this->templateRouteMap() as $from => $to) {
            $this->execute(
                'UPDATE `' . self::TEMPLATE_TABLE . '`
                SET `route` = ' . $this->q($to) . ', `update_time` = NOW()
                WHERE `route` = ' . $this->q($from) . '
                  AND `delete_time` IS NULL'
            );
        }
    }

    /**
     * @return array<string, string>
     */
    private function templateRouteMap(): array
    {
        return [
            '/pages/plan/tasks' => '/home?tab=plan',
            '/pages/community/detail' => '/community/post',
            '/pages/community/profile' => '/community/profile',
            '/pages/appointment/detail' => '/appointments/mine',
            '/pages/doctor/appointments' => '/doctor/patients',
            '/pages/me/doctor-certification' => '/register/doctor-certification',
            '/pages/message/detail' => '/me/messages',
        ];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
