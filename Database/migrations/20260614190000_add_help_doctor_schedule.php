<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpDoctorSchedule extends AbstractMigration
{
    private const SCHEDULE_TABLE = 'sa_doctor_schedule';
    private const APPOINTMENT_TABLE = 'sa_doctor_appointment';
    private const REMARK = 'phinx:20260614190000_add_help_doctor_schedule';

    public function up(): void
    {
        $this->createScheduleTable();
        $this->addAppointmentColumns();

        foreach ($this->menus() as $menu) {
            $this->insertMenu($menu);
            foreach ($menu['permissions'] as $permission) {
                $this->insertPermission($menu['code'], $permission);
            }
        }
    }

    public function down(): void
    {
        $this->execute('DELETE FROM `sa_system_menu` WHERE `remark` = ' . $this->q(self::REMARK));
        $this->removeAppointmentColumns();
        $this->execute('DROP TABLE IF EXISTS `' . self::SCHEDULE_TABLE . '`');
    }

    private function createScheduleTable(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `" . self::SCHEDULE_TABLE . "` (
                `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `doctor_id` int unsigned NOT NULL COMMENT '医生会员ID',
                `schedule_date` date NOT NULL COMMENT '排班日期',
                `time_slot` varchar(50) NOT NULL COMMENT '时间段展示文本',
                `start_time` time DEFAULT NULL COMMENT '开始时间',
                `end_time` time DEFAULT NULL COMMENT '结束时间',
                `meet_type` varchar(20) NOT NULL DEFAULT 'link' COMMENT '接诊方式:link/address/phone',
                `meet_link` varchar(500) DEFAULT NULL COMMENT '默认连线地址或接诊地点',
                `price` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '预约价格',
                `currency` varchar(8) NOT NULL DEFAULT 'USD' COMMENT '币种',
                `capacity` int unsigned NOT NULL DEFAULT 1 COMMENT '可预约人数',
                `booked_count` int unsigned NOT NULL DEFAULT 0 COMMENT '已预约人数',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1可预约,2关闭',
                `remark` varchar(255) DEFAULT NULL COMMENT '备注',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_doctor_slot` (`doctor_id`, `schedule_date`, `time_slot`),
                KEY `idx_doctor_date_status` (`doctor_id`, `schedule_date`, `status`),
                KEY `idx_date_status` (`schedule_date`, `status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生排班表'"
        );
    }

    private function addAppointmentColumns(): void
    {
        if (!$this->hasTable(self::APPOINTMENT_TABLE)) {
            return;
        }

        $table = $this->table(self::APPOINTMENT_TABLE);
        if (!$table->hasColumn('schedule_id')) {
            $table->addColumn('schedule_id', 'integer', [
                'signed' => false,
                'null' => false,
                'default' => 0,
                'comment' => '排班ID',
                'after' => 'doctor_id',
            ]);
        }
        if (!$table->hasColumn('price')) {
            $table->addColumn('price', 'decimal', [
                'precision' => 10,
                'scale' => 2,
                'null' => false,
                'default' => '0.00',
                'comment' => '预约价格',
                'after' => 'appoint_time_slot',
            ]);
        }
        if (!$table->hasColumn('currency')) {
            $table->addColumn('currency', 'string', [
                'limit' => 8,
                'null' => false,
                'default' => 'USD',
                'comment' => '币种',
                'after' => 'price',
            ]);
        }
        $table->update();
    }

    private function removeAppointmentColumns(): void
    {
        if (!$this->hasTable(self::APPOINTMENT_TABLE)) {
            return;
        }

        $table = $this->table(self::APPOINTMENT_TABLE);
        foreach (['currency', 'price', 'schedule_id'] as $column) {
            if ($table->hasColumn($column)) {
                $table->removeColumn($column);
            }
        }
        $table->update();
    }

    private function menus(): array
    {
        return [
            [
                'name' => '医生预约',
                'code' => 'help/appointment/doctorAppointment',
                'path' => 'appointment/doctorAppointment',
                'component' => '/plugin/help/appointment/doctorAppointment/index',
                'icon' => 'ri:calendar-check-line',
                'sort' => 160,
                'permissions' => array_merge($this->permissions('help:appointment:doctorAppointment'), [
                    ['name' => '确认', 'slug' => 'help:appointment:doctorAppointment:confirm', 'generate_key' => 'confirm'],
                    ['name' => '完成', 'slug' => 'help:appointment:doctorAppointment:finish', 'generate_key' => 'finish'],
                    ['name' => '取消', 'slug' => 'help:appointment:doctorAppointment:cancel', 'generate_key' => 'cancel'],
                    ['name' => '拒绝', 'slug' => 'help:appointment:doctorAppointment:reject', 'generate_key' => 'reject'],
                ]),
            ],
            [
                'name' => '医生排班',
                'code' => 'help/appointment/doctorSchedule',
                'path' => 'appointment/doctorSchedule',
                'component' => '/plugin/help/appointment/doctorSchedule/index',
                'icon' => 'ri:calendar-schedule-line',
                'sort' => 161,
                'permissions' => $this->permissions('help:appointment:doctorSchedule'),
            ],
        ];
    }

    private function permissions(string $prefix): array
    {
        return [
            ['name' => '列表', 'slug' => $prefix . ':index', 'generate_key' => 'index'],
            ['name' => '保存', 'slug' => $prefix . ':save', 'generate_key' => 'save'],
            ['name' => '更新', 'slug' => $prefix . ':update', 'generate_key' => 'update'],
            ['name' => '读取', 'slug' => $prefix . ':read', 'generate_key' => 'read'],
            ['name' => '删除', 'slug' => $prefix . ':destroy', 'generate_key' => 'destroy'],
            ['name' => '导入', 'slug' => $prefix . ':import', 'generate_key' => 'import'],
            ['name' => '导出', 'slug' => $prefix . ':export', 'generate_key' => 'export'],
        ];
    }

    private function insertMenu(array $menu): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($menu['name']) . ', ' . $this->q($menu['code']) . ', NULL, 2, ' . $this->q($menu['path']) . ', ' . $this->q($menu['component']) . ', NULL, ' . $this->q($menu['icon']) . ', ' . (int) $menu['sort'] . ', ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, NULL, 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q('HelpSupport') . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `code` = ' . $this->q($menu['code']) . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    private function insertPermission(string $parentCode, array $permission): void
    {
        $this->execute(
            'INSERT INTO `sa_system_menu` (`parent_id`, `name`, `code`, `slug`, `type`, `path`, `component`, `method`, `icon`, `sort`, `link_url`, `is_iframe`, `is_keep_alive`, `is_hidden`, `is_fixed_tab`, `is_full_page`, `generate_id`, `generate_key`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT `id`, ' . $this->q($permission['name']) . ', ' . $this->q('') . ', ' . $this->q($permission['slug']) . ', 3, ' . $this->q('') . ', ' . $this->q('') . ', NULL, ' . $this->q('') . ', 100, ' . $this->q('') . ', 2, 2, 2, 2, 2, 0, ' . $this->q($permission['generate_key']) . ', 1, ' . $this->q(self::REMARK) . ', 1, 1, NOW(), NOW(), NULL
            FROM `sa_system_menu`
            WHERE `code` = ' . $this->q($parentCode) . '
              AND `delete_time` IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM `sa_system_menu`
                  WHERE `slug` = ' . $this->q($permission['slug']) . '
                    AND `delete_time` IS NULL
              )
            LIMIT 1'
        );
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
