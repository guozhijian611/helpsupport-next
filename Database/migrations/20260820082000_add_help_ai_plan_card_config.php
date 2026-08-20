<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

/**
 * 为 AI 时间线卡片增加后台可配策略：出卡数量、字段、提醒、积分范围。
 */
final class AddHelpAiPlanCardConfig extends AbstractMigration
{
    private const REMARK = 'phinx:20260820082000_add_help_ai_plan_card_config';
    private const CONFIG_GROUP = 'help_ai_plan_card';

    public function up(): void
    {
        $this->seedPlanCardConfig();
    }

    public function down(): void
    {
        if (!$this->hasTable('sa_system_config') || !$this->hasTable('sa_system_config_group')) {
            return;
        }

        $this->execute(
            'DELETE FROM `sa_system_config`
             WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND `group_id` IN (
                   SELECT `id` FROM `sa_system_config_group`
                   WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
               )'
        );
        $this->execute(
            'DELETE FROM `sa_system_config_group`
             WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
               AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_config`
                   WHERE `sa_system_config`.`group_id` = `sa_system_config_group`.`id`
               )'
        );
    }

    private function seedPlanCardConfig(): void
    {
        if (!$this->hasTable('sa_system_config_group') || !$this->hasTable('sa_system_config')) {
            return;
        }

        $this->execute(
            'INSERT INTO `sa_system_config_group` (`name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q('AI 时间线卡片') . ', ' . $this->q(self::CONFIG_GROUP) . ', ' . $this->q(self::REMARK . ':聊天回复生成治疗计划卡片的运行策略。') . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   AND `delete_time` IS NULL
             )'
        );

        $enabledOptions = [
            ['label' => '启用', 'value' => '1'],
            ['label' => '禁用', 'value' => '2'],
        ];
        $dateModeOptions = [
            ['label' => '当天', 'value' => 'today'],
            ['label' => '明天', 'value' => 'tomorrow'],
            ['label' => '由模型决定', 'value' => 'model'],
        ];
        $taskTypeOptions = [
            ['label' => '每日任务', 'value' => 'daily'],
            ['label' => '打卡', 'value' => 'checkin'],
            ['label' => '评估量表', 'value' => 'assessment'],
            ['label' => '学习素材', 'value' => 'material'],
        ];
        $fieldOptions = [
            ['label' => '标题', 'value' => 'title'],
            ['label' => '描述', 'value' => 'description'],
            ['label' => '任务类型', 'value' => 'task_type'],
            ['label' => '任务日期', 'value' => 'task_date'],
            ['label' => '开始时间', 'value' => 'start_time'],
            ['label' => '结束时间', 'value' => 'end_time'],
            ['label' => '提醒规则', 'value' => 'reminders'],
            ['label' => '奖励积分', 'value' => 'points_reward'],
            ['label' => '需要反馈', 'value' => 'requires_feedback'],
            ['label' => '反馈提示', 'value' => 'feedback_prompt'],
        ];
        $reminderOptions = [
            ['label' => '提前 5 分钟', 'value' => 'T-5m'],
            ['label' => '提前 10 分钟', 'value' => 'T-10m'],
            ['label' => '提前 15 分钟', 'value' => 'T-15m'],
            ['label' => '提前 30 分钟', 'value' => 'T-30m'],
            ['label' => '提前 60 分钟', 'value' => 'T-60m'],
            ['label' => '准时提醒', 'value' => 'on-time'],
        ];

        $items = [
            ['enabled', '出卡总开关', '1', 'radio', 220, '关闭后不再要求模型输出时间线卡片，即使模型仍返回代码块也不会写入计划。', $enabledOptions],
            ['force_emit', '强制每轮出卡', '2', 'radio', 210, '启用后，提示词要求本轮必须输出任务卡片；若模型未返回，则补一张兜底卡片。', $enabledOptions],
            ['min_tasks', '最少任务数', '0', 'number', 200, '单轮最少卡片数。强制出卡时至少按 1 处理。范围 0-5。', null],
            ['max_tasks', '最多任务数', '2', 'number', 190, '单轮最多卡片数，范围 1-5。', null],
            ['auto_assign', '自动加入计划', '2', 'radio', 180, '启用后用户无需点“加入计划”，卡片会直接写入每日任务。', $enabledOptions],
            ['enabled_fields', '允许输出字段', 'title,description,task_type,points_reward,requires_feedback,feedback_prompt', 'checkbox', 170, '标题始终保留。未勾选的字段不会写入提示词，落库时用默认值补齐。', $fieldOptions],
            ['title_max_length', '标题最长字数', '30', 'number', 160, '范围 10-80。', null],
            ['description_max_length', '描述最长字数', '500', 'number', 150, '范围 20-1000。', null],
            ['allowed_task_types', '允许的任务类型', 'daily,checkin', 'checkbox', 140, '模型只能返回这些类型。', $taskTypeOptions],
            ['default_task_type', '默认任务类型', 'daily', 'select', 130, '模型未返回类型时使用。', $taskTypeOptions],
            ['default_date_mode', '默认任务日期', 'today', 'select', 120, '模型未返回日期，或未开放日期字段时使用。', $dateModeOptions],
            ['default_start_time', '默认开始时间', '', 'input', 110, '格式 HH:MM，可留空。开放时间字段且模型未返回时使用。', null],
            ['default_duration_minutes', '默认持续分钟', '30', 'number', 100, '有开始时间但没有结束时间时自动推算。范围 0-180，0 表示不自动补结束时间。', null],
            ['reminder_enabled', '启用提醒规则', '1', 'radio', 90, '关闭后即使模型返回提醒也不会写入任务。', $enabledOptions],
            ['allowed_reminders', '允许的提醒', 'T-5m,T-10m,T-15m,T-30m,T-60m,on-time', 'checkbox', 80, '模型返回的提醒会按此列表过滤。', $reminderOptions],
            ['default_reminders', '默认提醒', 'T-30m,on-time', 'checkbox', 70, '模型未返回提醒，或未开放提醒字段时使用。', $reminderOptions],
            ['reminder_required', '必须带提醒', '2', 'radio', 60, '启用后，没有提醒的卡片会自动补上默认提醒。', $enabledOptions],
            ['points_min', '积分下限', '5', 'number', 50, '范围 0-100，不能大于上限。', null],
            ['points_max', '积分上限', '30', 'number', 40, '范围 1-200，不能小于下限。', null],
            ['points_default', '默认积分', '10', 'number', 30, '模型未返回积分时使用，必须落在上下限之间。', null],
            ['default_requires_feedback', '默认需要反馈', '2', 'radio', 20, '模型未返回是否反馈时使用。', $enabledOptions],
            ['feedback_prompt_max_length', '反馈提示最长字数', '255', 'number', 18, '范围 0-255。', null],
            ['default_feedback_prompt', '默认反馈提示', '', 'input', 16, '需要反馈且模型未给提示语时使用。', null],
            ['fallback_title', '兜底卡片标题', '今日复盘', 'input', 14, '强制出卡但模型没返回任务时使用。', null],
            ['fallback_description', '兜底卡片说明', '根据本次对话，完成本日复盘并写下感受。', 'textarea', 12, '强制出卡的兜底说明。', null],
            ['prompt_policy', '补充出卡政策', '', 'textarea', 10, '追加到系统提示词，不要填写密钥或个人信息。', null],
        ];

        foreach ($items as $item) {
            [$key, $name, $value, $inputType, $sort, $remark, $options] = $item;
            $selectData = $options === null
                ? 'NULL'
                : $this->q(json_encode($options, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]');
            $this->execute(
                'INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', ' . $selectData . ', ' . (int) $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
                 FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q(self::CONFIG_GROUP) . '
                   AND `delete_time` IS NULL
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_config`
                       WHERE `group_id` = `sa_system_config_group`.`id`
                         AND `key` = ' . $this->q($key) . '
                         AND `delete_time` IS NULL
                   )
                 LIMIT 1'
            );
        }
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
