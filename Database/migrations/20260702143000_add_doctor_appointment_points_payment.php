<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddDoctorAppointmentPointsPayment extends AbstractMigration
{
    private const APPOINTMENT_TABLE = 'sa_doctor_appointment';
    private const GROUP_TABLE = 'sa_system_config_group';
    private const CONFIG_TABLE = 'sa_system_config';
    private const GROUP_CODE = 'help_appointment_payment';
    private const REMARK = 'phinx:20260702143000_add_doctor_appointment_points_payment';

    public function up(): void
    {
        $this->addAppointmentPaymentColumns();
        $this->seedAppointmentPaymentConfig();
    }

    public function down(): void
    {
        $this->deleteAppointmentPaymentConfig();
        $this->removeAppointmentPaymentColumns();
    }

    private function addAppointmentPaymentColumns(): void
    {
        if (!$this->hasTable(self::APPOINTMENT_TABLE)) {
            return;
        }

        $table = $this->table(self::APPOINTMENT_TABLE);
        if (!$table->hasColumn('payment_method')) {
            $table->addColumn('payment_method', 'string', [
                'limit' => 20,
                'null' => false,
                'default' => 'cash',
                'comment' => '支付方式:cash/points',
                'after' => 'currency',
            ]);
        }
        if (!$table->hasColumn('points_cost')) {
            $table->addColumn('points_cost', 'integer', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '预约消耗积分',
                'after' => 'payment_method',
            ]);
        }
        if (!$table->hasColumn('points_log_id')) {
            $table->addColumn('points_log_id', 'integer', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '积分扣减流水ID',
                'after' => 'points_cost',
            ]);
        }
        if (!$table->hasColumn('points_refund_log_id')) {
            $table->addColumn('points_refund_log_id', 'integer', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '积分退回流水ID',
                'after' => 'points_log_id',
            ]);
        }
        $table->update();
    }

    private function removeAppointmentPaymentColumns(): void
    {
        if (!$this->hasTable(self::APPOINTMENT_TABLE)) {
            return;
        }

        $table = $this->table(self::APPOINTMENT_TABLE);
        foreach (['points_refund_log_id', 'points_log_id', 'points_cost', 'payment_method'] as $column) {
            if ($table->hasColumn($column)) {
                $table->removeColumn($column);
            }
        }
        $table->update();
    }

    private function seedAppointmentPaymentConfig(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->insertConfigGroup(
            self::GROUP_CODE,
            '预约积分',
            'HelpSupport 医生预约积分支付配置。开启后用户端预约医生会消耗配置积分。'
        );

        $enabledOptions = [
            ['label' => '启用', 'value' => '1'],
            ['label' => '禁用', 'value' => '2'],
        ];
        $this->insertConfigItem(
            self::GROUP_CODE,
            'points_enabled',
            '积分预约',
            '1',
            'radio',
            100,
            '1启用 2禁用；启用后用户创建医生预约时按下方积分数扣减。',
            $enabledOptions
        );
        $this->insertConfigItem(
            self::GROUP_CODE,
            'points_cost',
            '每次预约积分',
            '6000',
            'number',
            90,
            '每次免费预约真人医生需要消耗的积分，必须为正整数。'
        );
        $this->insertConfigItem(
            self::GROUP_CODE,
            'refund_on_cancel',
            '取消/拒绝退回积分',
            '1',
            'radio',
            80,
            '开启后，待确认或已确认的积分预约被取消或拒绝时自动退回积分。',
            $enabledOptions
        );
    }

    private function deleteAppointmentPaymentConfig(): void
    {
        if (!$this->hasTable(self::GROUP_TABLE) || !$this->hasTable(self::CONFIG_TABLE)) {
            return;
        }

        $this->execute(
            'DELETE FROM `' . self::CONFIG_TABLE . '`
             WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND `group_id` IN (
                   SELECT `id` FROM `' . self::GROUP_TABLE . '`
                   WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               )'
        );
        $this->execute(
            'DELETE FROM `' . self::GROUP_TABLE . '`
             WHERE `code` = ' . $this->q(self::GROUP_CODE) . '
               AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::CONFIG_TABLE . '`
                   WHERE `' . self::CONFIG_TABLE . '`.`group_id` = `' . self::GROUP_TABLE . '`.`id`
               )'
        );
    }

    private function insertConfigGroup(string $code, string $name, string $remark): void
    {
        $this->execute(
            'INSERT INTO `' . self::GROUP_TABLE . '` (`name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q($name) . ', ' . $this->q($code) . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `' . self::GROUP_TABLE . '`
                 WHERE `code` = ' . $this->q($code) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function insertConfigItem(
        string $groupCode,
        string $key,
        string $name,
        string $value,
        string $inputType,
        int $sort,
        string $remark,
        ?array $selectData = null
    ): void {
        $this->execute(
            'INSERT INTO `' . self::CONFIG_TABLE . '` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', ' . $this->configSelectDataSql($selectData) . ', ' . $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             FROM `' . self::GROUP_TABLE . '`
             WHERE `code` = ' . $this->q($groupCode) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `' . self::CONFIG_TABLE . '`
                   WHERE `group_id` = `' . self::GROUP_TABLE . '`.`id`
                     AND `key` = ' . $this->q($key) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function configSelectDataSql(?array $selectData): string
    {
        if ($selectData === null) {
            return 'NULL';
        }

        return $this->q(json_encode($selectData, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]');
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
