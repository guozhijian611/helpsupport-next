<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpDoctorPresets extends AbstractMigration
{
    private const TASK_TABLE = 'sa_doctor_task_template';
    private const SCALE_TABLE = 'sa_doctor_assessment_scale';
    private const TASK_REMARK = '系统预设任务模板，迁移 SeedHelpDoctorPresets 创建';
    private const SCALE_REMARK = '系统预设评估量表，迁移 SeedHelpDoctorPresets 创建';

    public function up(): void
    {
        if ($this->hasTable(self::TASK_TABLE)) {
            foreach ($this->taskTemplates() as $template) {
                $this->execute(
                    "INSERT INTO `" . self::TASK_TABLE . "` (`id`, `doctor_id`, `folder_id`, `stage`, `title`, `description`, `task_type`, `priority`, `start_time`, `end_time`, `frequency`, `reward_score`, `color`, `reminder_rule`, `attachments`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                    SELECT
                        " . $this->quote($template['id']) . ",
                        0,
                        '',
                        " . $this->quote($template['stage']) . ",
                        " . $this->quote($template['title']) . ",
                        " . $this->quote($template['description']) . ",
                        " . $this->quote($template['task_type']) . ",
                        " . $this->quote($template['priority']) . ",
                        " . $this->quote($template['start_time']) . ",
                        " . $this->quote($template['end_time']) . ",
                        " . $this->quote($template['frequency']) . ",
                        " . (int) $template['reward_score'] . ",
                        " . $this->quote($template['color']) . ",
                        " . $this->quote($template['reminder_rule']) . ",
                        " . $this->quote('[]') . ",
                        " . (int) $template['sort'] . ",
                        1,
                        " . $this->quote(self::TASK_REMARK) . ",
                        1,
                        1,
                        NOW(),
                        NOW(),
                        NULL
                    WHERE NOT EXISTS (
                        SELECT 1 FROM `" . self::TASK_TABLE . "` WHERE `id` = " . $this->quote($template['id']) . "
                    )"
                );
            }
        }

        if ($this->hasTable(self::SCALE_TABLE)) {
            foreach ($this->assessmentScales() as $scale) {
                $this->execute(
                    "INSERT INTO `" . self::SCALE_TABLE . "` (`id`, `doctor_id`, `title`, `stage`, `description`, `total_score`, `questions`, `scoring_rule`, `status`, `published_at`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                    SELECT
                        " . $this->quote($scale['id']) . ",
                        0,
                        " . $this->quote($scale['title']) . ",
                        " . $this->quote($scale['stage']) . ",
                        " . $this->quote($scale['description']) . ",
                        " . (int) $scale['total_score'] . ",
                        " . $this->quote($scale['questions']) . ",
                        " . $this->quote($scale['scoring_rule']) . ",
                        'published',
                        NOW(),
                        " . $this->quote(self::SCALE_REMARK) . ",
                        1,
                        1,
                        NOW(),
                        NOW(),
                        NULL
                    WHERE NOT EXISTS (
                        SELECT 1 FROM `" . self::SCALE_TABLE . "` WHERE `id` = " . $this->quote($scale['id']) . "
                    )"
                );
            }
        }
    }

    public function down(): void
    {
        if ($this->hasTable(self::TASK_TABLE)) {
            foreach ($this->taskTemplates() as $template) {
                $this->execute(
                    "DELETE FROM `" . self::TASK_TABLE . "`
                    WHERE `id` = " . $this->quote($template['id']) . "
                      AND `doctor_id` = 0
                      AND `remark` = " . $this->quote(self::TASK_REMARK) . "
                      AND `delete_time` IS NULL"
                );
            }
        }

        if ($this->hasTable(self::SCALE_TABLE)) {
            foreach ($this->assessmentScales() as $scale) {
                $this->execute(
                    "DELETE FROM `" . self::SCALE_TABLE . "`
                    WHERE `id` = " . $this->quote($scale['id']) . "
                      AND `doctor_id` = 0
                      AND `remark` = " . $this->quote(self::SCALE_REMARK) . "
                      AND `delete_time` IS NULL"
                );
            }
        }
    }

    /**
     * @return array<int, array<string, string|int>>
     */
    private function taskTemplates(): array
    {
        return [
            [
                'id' => 'sys_task_breathing_checkin',
                'stage' => 'intake',
                'title' => '晨间呼吸与情绪打卡',
                'description' => '患者每天早晨完成 3 分钟呼吸练习，并记录当前情绪、压力和身体感受。',
                'task_type' => 'checkin',
                'priority' => 'normal',
                'start_time' => '08:30',
                'end_time' => '08:40',
                'frequency' => 'daily',
                'reward_score' => 5,
                'color' => '#FF9585',
                'sort' => 10,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [10],
                    'message' => '请完成晨间呼吸与情绪打卡',
                ]),
            ],
            [
                'id' => 'sys_task_medication_record',
                'stage' => 'treatment',
                'title' => '用药与不适记录',
                'description' => '按医嘱记录每日用药情况、漏服情况和明显不适，便于复诊时回顾。',
                'task_type' => 'daily',
                'priority' => 'high',
                'start_time' => '20:00',
                'end_time' => '20:15',
                'frequency' => 'daily',
                'reward_score' => 8,
                'color' => '#5A81DA',
                'sort' => 20,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [15],
                    'message' => '请记录今天的用药和身体反应',
                ]),
            ],
            [
                'id' => 'sys_task_sleep_diary',
                'stage' => 'recovery',
                'title' => '睡眠日记',
                'description' => '记录入睡时间、夜醒次数、起床时间和睡眠质量，为睡眠干预提供依据。',
                'task_type' => 'daily',
                'priority' => 'normal',
                'start_time' => '21:30',
                'end_time' => '21:45',
                'frequency' => 'daily',
                'reward_score' => 6,
                'color' => '#986FF5',
                'sort' => 30,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [20],
                    'message' => '请填写今天的睡眠日记',
                ]),
            ],
            [
                'id' => 'sys_task_rehab_training',
                'stage' => 'recovery',
                'title' => '轻量康复训练',
                'description' => '根据医生建议完成 10 到 15 分钟轻量训练，训练后记录疼痛、疲劳和完成度。',
                'task_type' => 'daily',
                'priority' => 'normal',
                'start_time' => '17:30',
                'end_time' => '17:50',
                'frequency' => 'daily',
                'reward_score' => 10,
                'color' => '#FFAE4D',
                'sort' => 40,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [30],
                    'message' => '请按计划完成轻量康复训练',
                ]),
            ],
            [
                'id' => 'sys_task_weekly_review',
                'stage' => 'maintenance',
                'title' => '每周恢复复盘',
                'description' => '每周回顾症状变化、任务完成情况和需要向医生反馈的问题。',
                'task_type' => 'checkin',
                'priority' => 'normal',
                'start_time' => '19:00',
                'end_time' => '19:30',
                'frequency' => 'weekly',
                'reward_score' => 12,
                'color' => '#A4C3CC',
                'sort' => 50,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [60],
                    'message' => '请完成本周恢复复盘',
                ]),
            ],
        ];
    }

    /**
     * @return array<int, array<string, string|int>>
     */
    private function assessmentScales(): array
    {
        return [
            $this->scale(
                'sys_scale_mood_stress',
                '情绪与压力自评量表',
                'intake',
                '用于快速了解近一周情绪波动、压力负荷和自我调节状态。',
                [
                    '近一周我经常感到紧张或难以放松',
                    '近一周我对日常事情的兴趣明显下降',
                    '近一周我容易烦躁或情绪失控',
                    '近一周我觉得自己很难应对当前问题',
                    '近一周我能主动使用放松或求助方式调节状态',
                ],
                [
                    ['label' => '状态稳定', 'min_score' => 0, 'max_score' => 4, 'suggestion' => '继续保持规律作息和当前支持计划。'],
                    ['label' => '轻度压力', 'min_score' => 5, 'max_score' => 8, 'suggestion' => '建议增加放松训练，并在复诊时反馈压力来源。'],
                    ['label' => '中高压力', 'min_score' => 9, 'max_score' => 15, 'suggestion' => '建议医生进一步评估情绪风险，必要时安排更密集随访。'],
                ],
                10
            ),
            $this->scale(
                'sys_scale_sleep_quality',
                '睡眠质量自评量表',
                'recovery',
                '用于追踪睡眠节律、夜间醒来和白天精力恢复情况。',
                [
                    '近一周入睡通常需要较长时间',
                    '近一周夜间醒来或早醒影响休息',
                    '近一周醒来后仍觉得疲惫',
                    '近一周睡眠问题影响白天情绪或工作',
                    '近一周我能保持相对固定的睡前习惯',
                ],
                [
                    ['label' => '睡眠良好', 'min_score' => 0, 'max_score' => 4, 'suggestion' => '继续保持固定作息和睡前放松。'],
                    ['label' => '睡眠受扰', 'min_score' => 5, 'max_score' => 8, 'suggestion' => '建议结合睡眠日记寻找诱因，减少睡前刺激。'],
                    ['label' => '睡眠明显受损', 'min_score' => 9, 'max_score' => 15, 'suggestion' => '建议医生评估睡眠障碍、药物影响或疼痛干扰。'],
                ],
                20
            ),
            $this->scale(
                'sys_scale_symptom_pain',
                '症状与疼痛影响量表',
                'treatment',
                '用于评估主要症状或疼痛对活动、睡眠和情绪的影响程度。',
                [
                    '近一周症状或疼痛出现频率较高',
                    '近一周症状或疼痛影响日常活动',
                    '近一周症状或疼痛影响睡眠',
                    '近一周症状变化让我感到担心',
                    '近一周我能按计划记录症状变化',
                ],
                [
                    ['label' => '影响较轻', 'min_score' => 0, 'max_score' => 4, 'suggestion' => '继续观察并保持当前记录频率。'],
                    ['label' => '中度影响', 'min_score' => 5, 'max_score' => 8, 'suggestion' => '建议补充症状诱因和缓解方式，复诊时重点讨论。'],
                    ['label' => '明显影响', 'min_score' => 9, 'max_score' => 15, 'suggestion' => '建议医生尽快复核治疗方案和风险信号。'],
                ],
                30
            ),
            $this->scale(
                'sys_scale_adherence',
                '治疗依从性量表',
                'maintenance',
                '用于了解患者对用药、训练、复诊和自我管理任务的执行情况。',
                [
                    '近一周我能按时完成医生安排的任务',
                    '近一周我能按要求记录用药或训练情况',
                    '近一周我清楚知道下一步治疗计划',
                    '近一周我遇到困难时会及时反馈',
                    '近一周我有漏服、漏练或漏记的情况',
                ],
                [
                    ['label' => '依从性良好', 'min_score' => 0, 'max_score' => 4, 'suggestion' => '继续保持当前计划，可适当提高自主管理目标。'],
                    ['label' => '依从性波动', 'min_score' => 5, 'max_score' => 8, 'suggestion' => '建议简化任务安排，并明确提醒时间和反馈渠道。'],
                    ['label' => '依从性不足', 'min_score' => 9, 'max_score' => 15, 'suggestion' => '建议医生重新评估任务难度、家庭支持和随访频率。'],
                ],
                40
            ),
            $this->scale(
                'sys_scale_life_support',
                '生活功能与支持量表',
                'maintenance',
                '用于评估患者生活功能恢复、社交支持和自我效能。',
                [
                    '近一周健康问题影响我的家庭或工作安排',
                    '近一周我较少参与正常社交或兴趣活动',
                    '近一周我觉得缺少可依靠的支持',
                    '近一周我对恢复进展缺乏信心',
                    '近一周我能主动安排有助恢复的生活活动',
                ],
                [
                    ['label' => '功能稳定', 'min_score' => 0, 'max_score' => 4, 'suggestion' => '继续保持社会支持和恢复活动。'],
                    ['label' => '功能受限', 'min_score' => 5, 'max_score' => 8, 'suggestion' => '建议识别主要限制因素，并设置更小的恢复目标。'],
                    ['label' => '支持不足', 'min_score' => 9, 'max_score' => 15, 'suggestion' => '建议医生关注家庭支持、心理支持和生活资源转介。'],
                ],
                50
            ),
        ];
    }

    /**
     * @param array<int, string> $questionTitles
     * @param array<int, array{label: string, min_score: int, max_score: int, suggestion: string}> $rules
     * @return array<string, string|int>
     */
    private function scale(
        string $id,
        string $title,
        string $stage,
        string $description,
        array $questionTitles,
        array $rules,
        int $sort
    ): array {
        $questions = [];
        foreach ($questionTitles as $index => $questionTitle) {
            $questions[] = [
                'id' => sprintf('q%d', $index + 1),
                'title' => $questionTitle,
                'options' => [
                    ['id' => 'o0', 'label' => '没有或很少', 'score' => 0],
                    ['id' => 'o1', 'label' => '偶尔', 'score' => 1],
                    ['id' => 'o2', 'label' => '经常', 'score' => 2],
                    ['id' => 'o3', 'label' => '几乎每天', 'score' => 3],
                ],
            ];
        }

        return [
            'id' => $id,
            'title' => $title,
            'stage' => $stage,
            'description' => $description,
            'total_score' => 15,
            'questions' => $this->json($questions),
            'scoring_rule' => $this->json($rules),
            'sort' => $sort,
        ];
    }

    /**
     * @param mixed $value
     */
    private function json($value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
