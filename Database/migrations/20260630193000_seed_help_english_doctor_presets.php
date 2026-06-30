<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpEnglishDoctorPresets extends AbstractMigration
{
    private const FOLDER_TABLE = 'sa_doctor_task_template_folder';
    private const TASK_TABLE = 'sa_doctor_task_template';
    private const SCALE_TABLE = 'sa_doctor_assessment_scale';
    private const FOLDER_ID = 'sys_folder_english_presets';
    private const FOLDER_REMARK = 'System English preset folder created by SeedHelpEnglishDoctorPresets';
    private const TASK_REMARK = 'System English task template created by SeedHelpEnglishDoctorPresets';
    private const SCALE_REMARK = 'System English assessment scale created by SeedHelpEnglishDoctorPresets';

    public function up(): void
    {
        if ($this->hasTable(self::FOLDER_TABLE)) {
            $this->execute(
                "INSERT INTO `" . self::FOLDER_TABLE . "` (`id`, `doctor_id`, `name`, `color`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT
                    " . $this->quote(self::FOLDER_ID) . ",
                    0,
                    'English Presets',
                    '#5A81DA',
                    60,
                    1,
                    " . $this->quote(self::FOLDER_REMARK) . ",
                    1,
                    1,
                    NOW(),
                    NOW(),
                    NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `" . self::FOLDER_TABLE . "` WHERE `id` = " . $this->quote(self::FOLDER_ID) . "
                )"
            );
        }

        if ($this->hasTable(self::TASK_TABLE)) {
            foreach ($this->taskTemplates() as $template) {
                $this->execute(
                    "INSERT INTO `" . self::TASK_TABLE . "` (`id`, `doctor_id`, `folder_id`, `stage`, `title`, `description`, `task_type`, `priority`, `start_time`, `end_time`, `frequency`, `reward_score`, `color`, `reminder_rule`, `attachments`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                    SELECT
                        " . $this->quote($template['id']) . ",
                        0,
                        " . $this->quote(self::FOLDER_ID) . ",
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

        if ($this->hasTable(self::FOLDER_TABLE)) {
            $this->execute(
                "DELETE FROM `" . self::FOLDER_TABLE . "`
                WHERE `id` = " . $this->quote(self::FOLDER_ID) . "
                  AND `doctor_id` = 0
                  AND `remark` = " . $this->quote(self::FOLDER_REMARK) . "
                  AND `delete_time` IS NULL"
            );
        }
    }

    /**
     * @return array<int, array<string, string|int>>
     */
    private function taskTemplates(): array
    {
        return [
            [
                'id' => 'sys_task_en_morning_mood_checkin',
                'stage' => 'intake',
                'title' => 'Morning mood check-in',
                'description' => 'Spend five minutes recording mood, stress level, sleep quality, and one thing that may need support today.',
                'task_type' => 'checkin',
                'priority' => 'normal',
                'start_time' => '08:20',
                'end_time' => '08:30',
                'frequency' => 'daily',
                'reward_score' => 5,
                'color' => '#FF9585',
                'sort' => 110,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [10],
                    'message' => 'Please complete your morning mood check-in.',
                ]),
            ],
            [
                'id' => 'sys_task_en_medication_followup',
                'stage' => 'treatment',
                'title' => 'Medication follow-up note',
                'description' => 'Confirm medication taken as prescribed and record side effects, missed doses, or questions for the next visit.',
                'task_type' => 'daily',
                'priority' => 'high',
                'start_time' => '20:10',
                'end_time' => '20:25',
                'frequency' => 'daily',
                'reward_score' => 8,
                'color' => '#5A81DA',
                'sort' => 120,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [15],
                    'message' => 'Please record your medication follow-up note.',
                ]),
            ],
            [
                'id' => 'sys_task_en_sleep_quality_log',
                'stage' => 'recovery',
                'title' => 'Sleep quality log',
                'description' => 'Record bedtime, wake time, interruptions, and overall sleep quality to support sleep rhythm review.',
                'task_type' => 'daily',
                'priority' => 'normal',
                'start_time' => '21:20',
                'end_time' => '21:35',
                'frequency' => 'daily',
                'reward_score' => 6,
                'color' => '#986FF5',
                'sort' => 130,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [20],
                    'message' => 'Please complete your sleep quality log.',
                ]),
            ],
            [
                'id' => 'sys_task_en_light_activity',
                'stage' => 'recovery',
                'title' => 'Light activity practice',
                'description' => 'Complete a gentle activity session and note fatigue, pain, confidence, and completion level afterward.',
                'task_type' => 'daily',
                'priority' => 'normal',
                'start_time' => '17:20',
                'end_time' => '17:40',
                'frequency' => 'daily',
                'reward_score' => 10,
                'color' => '#FFAE4D',
                'sort' => 140,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [30],
                    'message' => 'Please complete your light activity practice.',
                ]),
            ],
            [
                'id' => 'sys_task_en_weekly_progress_review',
                'stage' => 'maintenance',
                'title' => 'Weekly progress review',
                'description' => 'Review weekly symptoms, task completion, medication concerns, and questions to discuss with the care team.',
                'task_type' => 'checkin',
                'priority' => 'normal',
                'start_time' => '19:10',
                'end_time' => '19:35',
                'frequency' => 'weekly',
                'reward_score' => 12,
                'color' => '#A4C3CC',
                'sort' => 150,
                'reminder_rule' => $this->json([
                    'enabled' => true,
                    'before_minutes' => [60],
                    'message' => 'Please complete your weekly progress review.',
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
                'sys_scale_en_mood_stress',
                'Mood and stress self-check',
                'intake',
                'A brief self-check for mood, stress load, and coping capacity during the past week.',
                [
                    'I felt tense, anxious, or unable to relax during the past week.',
                    'I had less interest or motivation for normal daily activities.',
                    'I became irritated or emotionally overwhelmed more easily than usual.',
                    'I felt that current problems were difficult to manage.',
                    'I used a helpful coping strategy or asked for support when needed.',
                ],
                [
                    ['label' => 'Stable', 'min_score' => 0, 'max_score' => 4, 'suggestion' => 'Keep the current routine and continue regular check-ins.'],
                    ['label' => 'Mild stress', 'min_score' => 5, 'max_score' => 8, 'suggestion' => 'Add relaxation practice and discuss stress triggers at the next visit.'],
                    ['label' => 'Elevated stress', 'min_score' => 9, 'max_score' => 15, 'suggestion' => 'Consider a closer clinical review and a more frequent follow-up plan.'],
                ]
            ),
            $this->scale(
                'sys_scale_en_sleep_quality',
                'Sleep quality self-check',
                'recovery',
                'A short review of sleep onset, night waking, energy recovery, and daytime impact.',
                [
                    'It took me a long time to fall asleep during the past week.',
                    'I woke up during the night or too early in the morning.',
                    'I still felt tired after getting up.',
                    'Sleep problems affected my mood, work, or daily activities.',
                    'I kept a steady bedtime routine most nights.',
                ],
                [
                    ['label' => 'Good sleep', 'min_score' => 0, 'max_score' => 4, 'suggestion' => 'Keep the current sleep routine and evening wind-down plan.'],
                    ['label' => 'Disrupted sleep', 'min_score' => 5, 'max_score' => 8, 'suggestion' => 'Use a sleep log to identify triggers and reduce stimulation before bed.'],
                    ['label' => 'Poor sleep', 'min_score' => 9, 'max_score' => 15, 'suggestion' => 'Review possible sleep disorder, medication, pain, or stress contributors with the clinician.'],
                ]
            ),
            $this->scale(
                'sys_scale_en_symptom_impact',
                'Symptom impact scale',
                'treatment',
                'A quick scale for how symptoms or pain affect activity, sleep, worry, and daily function.',
                [
                    'Symptoms or pain occurred frequently during the past week.',
                    'Symptoms or pain limited my usual daily activities.',
                    'Symptoms or pain affected my sleep.',
                    'Changes in symptoms made me worried.',
                    'I recorded symptom changes as planned.',
                ],
                [
                    ['label' => 'Low impact', 'min_score' => 0, 'max_score' => 4, 'suggestion' => 'Continue observation and keep the current record routine.'],
                    ['label' => 'Moderate impact', 'min_score' => 5, 'max_score' => 8, 'suggestion' => 'Record triggers and relief methods, then review them at follow-up.'],
                    ['label' => 'High impact', 'min_score' => 9, 'max_score' => 15, 'suggestion' => 'Ask the clinician to review the plan and any warning signs soon.'],
                ]
            ),
            $this->scale(
                'sys_scale_en_treatment_adherence',
                'Treatment adherence self-check',
                'maintenance',
                'A practical check of medication, activity, follow-up, and self-management completion.',
                [
                    'I completed the tasks arranged by my clinician on time.',
                    'I recorded medication or practice notes as requested.',
                    'I clearly understood the next step in my care plan.',
                    'I asked for help or feedback when I met difficulties.',
                    'I missed medication, practice, or records during the past week.',
                ],
                [
                    ['label' => 'Good adherence', 'min_score' => 0, 'max_score' => 4, 'suggestion' => 'Continue the current plan and consider a slightly higher self-management goal.'],
                    ['label' => 'Variable adherence', 'min_score' => 5, 'max_score' => 8, 'suggestion' => 'Simplify the task plan and make reminder times and feedback channels clear.'],
                    ['label' => 'Low adherence', 'min_score' => 9, 'max_score' => 15, 'suggestion' => 'Review task difficulty, support resources, and follow-up frequency with the clinician.'],
                ]
            ),
            $this->scale(
                'sys_scale_en_daily_function',
                'Daily function and support scale',
                'maintenance',
                'A brief assessment of daily function, social support, confidence, and recovery participation.',
                [
                    'Health concerns affected my family, work, or study schedule.',
                    'I joined fewer normal social or interest activities.',
                    'I felt I did not have enough reliable support.',
                    'I felt less confident about my recovery progress.',
                    'I planned at least one helpful activity for recovery.',
                ],
                [
                    ['label' => 'Stable function', 'min_score' => 0, 'max_score' => 4, 'suggestion' => 'Keep current support and recovery activities.'],
                    ['label' => 'Limited function', 'min_score' => 5, 'max_score' => 8, 'suggestion' => 'Identify the main barrier and set a smaller recovery target.'],
                    ['label' => 'Support gap', 'min_score' => 9, 'max_score' => 15, 'suggestion' => 'Consider family support, mental health support, or care resource referral.'],
                ]
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
        array $rules
    ): array {
        $questions = [];
        foreach ($questionTitles as $index => $questionTitle) {
            $questions[] = [
                'id' => sprintf('q%d', $index + 1),
                'title' => $questionTitle,
                'options' => [
                    ['id' => 'o0', 'label' => 'Not at all', 'score' => 0],
                    ['id' => 'o1', 'label' => 'Sometimes', 'score' => 1],
                    ['id' => 'o2', 'label' => 'Often', 'score' => 2],
                    ['id' => 'o3', 'label' => 'Nearly every day', 'score' => 3],
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
