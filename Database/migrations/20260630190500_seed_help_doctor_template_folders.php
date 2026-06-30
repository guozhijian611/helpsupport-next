<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpDoctorTemplateFolders extends AbstractMigration
{
    private const FOLDER_TABLE = 'sa_doctor_task_template_folder';
    private const TASK_TABLE = 'sa_doctor_task_template';
    private const FOLDER_REMARK = '系统预设任务模板文件夹，迁移 SeedHelpDoctorTemplateFolders 创建';
    private const TASK_REMARK = '系统预设任务模板，迁移 SeedHelpDoctorPresets 创建';

    public function up(): void
    {
        if ($this->hasTable(self::FOLDER_TABLE)) {
            foreach ($this->folders() as $folder) {
                $this->execute(
                    "INSERT INTO `" . self::FOLDER_TABLE . "` (`id`, `doctor_id`, `name`, `color`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                    SELECT
                        " . $this->quote($folder['id']) . ",
                        0,
                        " . $this->quote($folder['name']) . ",
                        " . $this->quote($folder['color']) . ",
                        " . (int) $folder['sort'] . ",
                        1,
                        " . $this->quote(self::FOLDER_REMARK) . ",
                        1,
                        1,
                        NOW(),
                        NOW(),
                        NULL
                    WHERE NOT EXISTS (
                        SELECT 1 FROM `" . self::FOLDER_TABLE . "` WHERE `id` = " . $this->quote($folder['id']) . "
                    )"
                );
            }
        }

        if ($this->hasTable(self::TASK_TABLE)) {
            foreach ($this->taskFolderMap() as $taskId => $folderId) {
                $this->execute(
                    "UPDATE `" . self::TASK_TABLE . "`
                    SET `folder_id` = " . $this->quote($folderId) . ",
                        `update_time` = NOW()
                    WHERE `id` = " . $this->quote($taskId) . "
                      AND `doctor_id` = 0
                      AND (`folder_id` = '' OR `folder_id` IS NULL)
                      AND `remark` = " . $this->quote(self::TASK_REMARK) . "
                      AND `delete_time` IS NULL"
                );
            }
        }
    }

    public function down(): void
    {
        if ($this->hasTable(self::TASK_TABLE)) {
            foreach ($this->taskFolderMap() as $taskId => $folderId) {
                $this->execute(
                    "UPDATE `" . self::TASK_TABLE . "`
                    SET `folder_id` = '',
                        `update_time` = NOW()
                    WHERE `id` = " . $this->quote($taskId) . "
                      AND `doctor_id` = 0
                      AND `folder_id` = " . $this->quote($folderId) . "
                      AND `remark` = " . $this->quote(self::TASK_REMARK) . "
                      AND `delete_time` IS NULL"
                );
            }
        }

        if ($this->hasTable(self::FOLDER_TABLE)) {
            foreach ($this->folders() as $folder) {
                $this->execute(
                    "DELETE FROM `" . self::FOLDER_TABLE . "`
                    WHERE `id` = " . $this->quote($folder['id']) . "
                      AND `doctor_id` = 0
                      AND `remark` = " . $this->quote(self::FOLDER_REMARK) . "
                      AND `delete_time` IS NULL"
                );
            }
        }
    }

    /**
     * @return array<int, array{id: string, name: string, color: string, sort: int}>
     */
    private function folders(): array
    {
        return [
            ['id' => 'sys_folder_intake', 'name' => '初始评估', 'color' => '#FF9585', 'sort' => 10],
            ['id' => 'sys_folder_treatment', 'name' => '治疗记录', 'color' => '#5A81DA', 'sort' => 20],
            ['id' => 'sys_folder_sleep', 'name' => '睡眠恢复', 'color' => '#986FF5', 'sort' => 30],
            ['id' => 'sys_folder_rehab', 'name' => '康复训练', 'color' => '#FFAE4D', 'sort' => 40],
            ['id' => 'sys_folder_review', 'name' => '复盘随访', 'color' => '#A4C3CC', 'sort' => 50],
        ];
    }

    /**
     * @return array<string, string>
     */
    private function taskFolderMap(): array
    {
        return [
            'sys_task_breathing_checkin' => 'sys_folder_intake',
            'sys_task_medication_record' => 'sys_folder_treatment',
            'sys_task_sleep_diary' => 'sys_folder_sleep',
            'sys_task_rehab_training' => 'sys_folder_rehab',
            'sys_task_weekly_review' => 'sys_folder_review',
        ];
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
