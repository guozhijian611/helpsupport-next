<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\app\cache\ConfigCache;

/**
 * AI 时间线卡片运行策略。
 */
class HelpAiPlanCardConfigService
{
    public const GROUP_CODE = 'help_ai_plan_card';

    public const FIELD_TITLE = 'title';
    public const FIELD_DESCRIPTION = 'description';
    public const FIELD_TASK_TYPE = 'task_type';
    public const FIELD_TASK_DATE = 'task_date';
    public const FIELD_START_TIME = 'start_time';
    public const FIELD_END_TIME = 'end_time';
    public const FIELD_REMINDERS = 'reminders';
    public const FIELD_POINTS = 'points_reward';
    public const FIELD_REQUIRES_FEEDBACK = 'requires_feedback';
    public const FIELD_FEEDBACK_PROMPT = 'feedback_prompt';

    public const ALL_FIELDS = [
        self::FIELD_TITLE,
        self::FIELD_DESCRIPTION,
        self::FIELD_TASK_TYPE,
        self::FIELD_TASK_DATE,
        self::FIELD_START_TIME,
        self::FIELD_END_TIME,
        self::FIELD_REMINDERS,
        self::FIELD_POINTS,
        self::FIELD_REQUIRES_FEEDBACK,
        self::FIELD_FEEDBACK_PROMPT,
    ];

    public const TASK_TYPES = ['daily', 'checkin', 'assessment', 'material'];
    public const REMINDERS = ['T-5m', 'T-10m', 'T-15m', 'T-30m', 'T-60m', 'on-time'];
    public const DATE_MODES = ['today', 'tomorrow', 'model'];

    /**
     * @return array<string, mixed>
     */
    public function all(): array
    {
        $config = ConfigCache::getConfig(self::GROUP_CODE, true);
        $enabledFields = $this->csvIn($config['enabled_fields'] ?? '', self::ALL_FIELDS, [
            self::FIELD_TITLE,
            self::FIELD_DESCRIPTION,
            self::FIELD_TASK_TYPE,
            self::FIELD_POINTS,
            self::FIELD_REQUIRES_FEEDBACK,
            self::FIELD_FEEDBACK_PROMPT,
        ]);
        if (!in_array(self::FIELD_TITLE, $enabledFields, true)) {
            array_unshift($enabledFields, self::FIELD_TITLE);
        }

        $allowedTaskTypes = $this->csvIn($config['allowed_task_types'] ?? '', self::TASK_TYPES, ['daily', 'checkin']);
        if ($allowedTaskTypes === []) {
            $allowedTaskTypes = ['daily'];
        }
        $defaultTaskType = trim((string) ($config['default_task_type'] ?? 'daily'));
        if (!in_array($defaultTaskType, $allowedTaskTypes, true)) {
            $defaultTaskType = $allowedTaskTypes[0];
        }

        $allowedReminders = $this->csvIn($config['allowed_reminders'] ?? '', self::REMINDERS, self::REMINDERS);
        $rawDefaultReminders = trim((string) ($config['default_reminders'] ?? 'T-30m,on-time'));
        $defaultReminders = $this->csvIn(
            $rawDefaultReminders,
            $allowedReminders,
            $rawDefaultReminders === '' ? [] : ['T-30m', 'on-time']
        );
        $pointsMin = $this->intIn($config['points_min'] ?? 5, 0, 100, 5);
        $pointsMax = $this->intIn($config['points_max'] ?? 30, 1, 200, 30);
        if ($pointsMin > $pointsMax) {
            [$pointsMin, $pointsMax] = [$pointsMax, $pointsMin];
        }
        $pointsDefault = $this->intIn($config['points_default'] ?? 10, $pointsMin, $pointsMax, min(10, $pointsMax));

        $minTasks = $this->intIn($config['min_tasks'] ?? 0, 0, 5, 0);
        $maxTasks = $this->intIn($config['max_tasks'] ?? 2, 1, 5, 2);
        if ($minTasks > $maxTasks) {
            $minTasks = $maxTasks;
        }
        $forceEmit = (int) ($config['force_emit'] ?? 2) === 1;
        if ($forceEmit && $minTasks < 1) {
            $minTasks = 1;
        }

        $dateMode = trim((string) ($config['default_date_mode'] ?? 'today'));
        if (!in_array($dateMode, self::DATE_MODES, true)) {
            $dateMode = 'today';
        }

        return [
            'enabled' => (int) ($config['enabled'] ?? 1) === 1,
            'force_emit' => $forceEmit,
            'min_tasks' => $minTasks,
            'max_tasks' => $maxTasks,
            'auto_assign' => (int) ($config['auto_assign'] ?? 2) === 1,
            'enabled_fields' => $enabledFields,
            'title_max_length' => $this->intIn($config['title_max_length'] ?? 30, 10, 80, 30),
            'description_max_length' => $this->intIn($config['description_max_length'] ?? 500, 20, 1000, 500),
            'allowed_task_types' => $allowedTaskTypes,
            'default_task_type' => $defaultTaskType,
            'default_date_mode' => $dateMode,
            'default_start_time' => $this->normalizeClock((string) ($config['default_start_time'] ?? '')),
            'default_duration_minutes' => $this->intIn($config['default_duration_minutes'] ?? 30, 0, 180, 30),
            'reminder_enabled' => (int) ($config['reminder_enabled'] ?? 1) === 1,
            'allowed_reminders' => $allowedReminders,
            'default_reminders' => $defaultReminders,
            'reminder_required' => (int) ($config['reminder_required'] ?? 2) === 1,
            'points_min' => $pointsMin,
            'points_max' => $pointsMax,
            'points_default' => $pointsDefault,
            'default_requires_feedback' => (int) ($config['default_requires_feedback'] ?? 2) === 1,
            'feedback_prompt_max_length' => $this->intIn($config['feedback_prompt_max_length'] ?? 255, 0, 255, 255),
            'default_feedback_prompt' => mb_substr(trim((string) ($config['default_feedback_prompt'] ?? '')), 0, 255),
            'fallback_title' => mb_substr(trim((string) ($config['fallback_title'] ?? '今日复盘')), 0, 80),
            'fallback_description' => mb_substr(trim((string) ($config['fallback_description'] ?? '')), 0, 500),
            'prompt_policy' => mb_substr(trim((string) ($config['prompt_policy'] ?? '')), 0, 3000),
        ];
    }

    public function promptAppendix(): string
    {
        $config = $this->all();
        if (!$config['enabled']) {
            return '';
        }

        $example = $this->exampleTask($config);
        $fieldLines = $this->fieldInstructions($config);
        $countRule = $config['force_emit']
            ? sprintf('本轮必须输出 %d 到 %d 个任务，不得省略代码块。', $config['min_tasks'], $config['max_tasks'])
            : sprintf('当你认为本轮对话适合给用户一个可执行计划任务时再出卡，一次最少 %d 个、最多 %d 个。', $config['min_tasks'], $config['max_tasks']);

        $lines = [
            '当你给用户可执行计划任务时，先用自然语言解释建议，再在回复末尾追加一个独立代码块：',
            '```helpsupport_plan_tasks',
            json_encode([$example], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            '```',
            $countRule,
            '任务字段要求：',
            ...$fieldLines,
            '不要告诉用户你已经加入计划，只能说可由用户确认加入。',
        ];
        if ($config['auto_assign']) {
            $lines[count($lines) - 1] = '卡片会自动加入用户计划，回复里只需说明建议内容，不要承诺已经写入日历。';
        }
        if ($config['prompt_policy'] !== '') {
            $lines[] = '补充政策：';
            $lines[] = $config['prompt_policy'];
        }

        return "\n\n" . implode("\n", $lines);
    }

    /**
     * @return array{content:string,plan_tasks:array<int,array<string,mixed>>}
     */
    public function extract(string $content): array
    {
        $config = $this->all();
        $tasks = [];
        $cleanContent = preg_replace_callback(
            '/```helpsupport_plan_tasks\s*(.*?)```/su',
            function (array $matches) use (&$tasks, $config): string {
                if (!$config['enabled']) {
                    return '';
                }
                $decoded = json_decode(trim((string) ($matches[1] ?? '')), true);
                if (!is_array($decoded)) {
                    return '';
                }
                foreach ($decoded as $item) {
                    if (!is_array($item)) {
                        continue;
                    }
                    $task = $this->normalizeTask($item, $config);
                    if ($task !== null) {
                        $tasks[] = $task;
                    }
                    if (count($tasks) >= (int) $config['max_tasks']) {
                        break;
                    }
                }

                return '';
            },
            $content
        );
        $cleanContent = trim((string) $cleanContent);
        if ($cleanContent === '') {
            $cleanContent = trim($content);
        }
        if ($config['enabled'] && $config['force_emit']) {
            while (count($tasks) < max(1, (int) $config['min_tasks'])) {
                $fallback = $this->fallbackTask($config, count($tasks) + 1);
                if ($fallback === null) {
                    break;
                }
                $tasks[] = $fallback;
            }
        }

        return [
            'content' => $cleanContent,
            'plan_tasks' => array_slice($tasks, 0, (int) $config['max_tasks']),
        ];
    }

    /**
     * @param array<string, mixed> $item
     * @param array<string, mixed>|null $config
     * @return array<string, mixed>|null
     */
    public function normalizeTask(array $item, ?array $config = null): ?array
    {
        $config ??= $this->all();
        $title = mb_substr(trim((string) ($item['title'] ?? '')), 0, (int) $config['title_max_length']);
        if ($title === '') {
            return null;
        }

        $fields = $config['enabled_fields'];
        $taskType = $config['default_task_type'];
        if ($this->fieldEnabled($fields, self::FIELD_TASK_TYPE)) {
            $candidate = trim((string) ($item['task_type'] ?? ''));
            if (in_array($candidate, $config['allowed_task_types'], true)) {
                $taskType = $candidate;
            }
        }

        $description = '';
        if ($this->fieldEnabled($fields, self::FIELD_DESCRIPTION)) {
            $description = mb_substr(trim((string) ($item['description'] ?? '')), 0, (int) $config['description_max_length']);
        }

        $pointsReward = (int) $config['points_default'];
        if ($this->fieldEnabled($fields, self::FIELD_POINTS) && isset($item['points_reward']) && is_numeric($item['points_reward'])) {
            $pointsReward = $this->intIn($item['points_reward'], (int) $config['points_min'], (int) $config['points_max'], (int) $config['points_default']);
        }

        $requiresFeedback = $config['default_requires_feedback'] ? 1 : 0;
        if ($this->fieldEnabled($fields, self::FIELD_REQUIRES_FEEDBACK) && array_key_exists('requires_feedback', $item)) {
            $requiresFeedback = filter_var($item['requires_feedback'], FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
        }

        $feedbackPrompt = '';
        if ($requiresFeedback === 1) {
            $feedbackPrompt = (string) $config['default_feedback_prompt'];
            if ($this->fieldEnabled($fields, self::FIELD_FEEDBACK_PROMPT)) {
                $fromModel = mb_substr(trim((string) ($item['feedback_prompt'] ?? '')), 0, (int) $config['feedback_prompt_max_length']);
                if ($fromModel !== '') {
                    $feedbackPrompt = $fromModel;
                }
            }
        }

        $schedule = $this->resolveSchedule($item, $config);

        return [
            'title' => $title,
            'description' => $description,
            'task_type' => $taskType,
            'task_date' => $schedule['task_date'],
            'start_time' => $schedule['start_time'],
            'end_time' => $schedule['end_time'],
            'reminders' => $schedule['reminders'],
            'points_reward' => $pointsReward,
            'requires_feedback' => $requiresFeedback,
            'feedback_prompt' => $feedbackPrompt,
            'daily_task_id' => max(0, (int) ($item['daily_task_id'] ?? 0)),
        ];
    }

    /**
     * @param array<string, mixed> $task
     * @return array{task_date:string,start_time:?string,end_time:?string,reminders:array<int,string>}
     */
    public function resolveSchedule(array $task, ?array $config = null, ?string $preferredDate = null): array
    {
        $config ??= $this->all();
        $fields = $config['enabled_fields'];
        $taskDate = '';
        if (is_string($preferredDate) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $preferredDate) === 1) {
            $taskDate = $preferredDate;
        }
        if ($taskDate === '' && $this->fieldEnabled($fields, self::FIELD_TASK_DATE)) {
            $candidate = trim((string) ($task['task_date'] ?? ''));
            if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $candidate) === 1) {
                $taskDate = $candidate;
            }
        }
        if ($taskDate === '') {
            $taskDate = $config['default_date_mode'] === 'tomorrow'
                ? date('Y-m-d', strtotime('+1 day'))
                : date('Y-m-d');
        }

        $startTime = null;
        if ($this->fieldEnabled($fields, self::FIELD_START_TIME)) {
            $startTime = $this->normalizeClock((string) ($task['start_time'] ?? ''));
        }
        if ($startTime === null && $config['default_start_time'] !== null) {
            $startTime = $config['default_start_time'];
        }

        $endTime = null;
        if ($this->fieldEnabled($fields, self::FIELD_END_TIME)) {
            $endTime = $this->normalizeClock((string) ($task['end_time'] ?? ''));
        }
        if ($endTime === null && $startTime !== null && (int) $config['default_duration_minutes'] > 0) {
            $endTime = $this->addMinutes($startTime, (int) $config['default_duration_minutes']);
        }

        $reminders = [];
        if ($config['reminder_enabled']) {
            if ($this->fieldEnabled($fields, self::FIELD_REMINDERS)) {
                $reminders = $this->normalizeReminders($task['reminders'] ?? [], $config['allowed_reminders']);
            }
            if ($reminders === [] && ($config['reminder_required'] || !$this->fieldEnabled($fields, self::FIELD_REMINDERS))) {
                $reminders = $config['default_reminders'];
            }
        }

        return [
            'task_date' => $taskDate,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'reminders' => $reminders,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    public function fallbackTask(?array $config = null, int $index = 1): ?array
    {
        $config ??= $this->all();
        $title = (string) $config['fallback_title'];
        if ($title === '') {
            $title = '今日复盘';
        }
        if ($index > 1) {
            $title .= ' ' . $index;
        }

        return $this->normalizeTask([
            'title' => $title,
            'description' => (string) $config['fallback_description'],
            'task_type' => $config['default_task_type'],
            'points_reward' => $config['points_default'],
            'requires_feedback' => $config['default_requires_feedback'],
            'feedback_prompt' => $config['default_feedback_prompt'],
        ], $config);
    }

    /**
     * @param array<string, mixed> $config
     * @return array<string, mixed>
     */
    private function exampleTask(array $config): array
    {
        $example = ['title' => '任务标题'];
        foreach ($config['enabled_fields'] as $field) {
            $example[$field] = match ($field) {
                self::FIELD_TITLE => '任务标题',
                self::FIELD_DESCRIPTION => '执行说明',
                self::FIELD_TASK_TYPE => $config['default_task_type'],
                self::FIELD_TASK_DATE => date('Y-m-d'),
                self::FIELD_START_TIME => $config['default_start_time'] ?? '09:00',
                self::FIELD_END_TIME => $this->addMinutes($config['default_start_time'] ?? '09:00', max(15, (int) $config['default_duration_minutes'])),
                self::FIELD_REMINDERS => $config['default_reminders'] !== [] ? $config['default_reminders'] : ['T-30m', 'on-time'],
                self::FIELD_POINTS => $config['points_default'],
                self::FIELD_REQUIRES_FEEDBACK => false,
                self::FIELD_FEEDBACK_PROMPT => '',
                default => '',
            };
        }

        return $example;
    }

    /**
     * @param array<string, mixed> $config
     * @return array<int, string>
     */
    private function fieldInstructions(array $config): array
    {
        $lines = [];
        foreach ($config['enabled_fields'] as $field) {
            $lines[] = match ($field) {
                self::FIELD_TITLE => sprintf('- title 必填，不超过 %d 个汉字。', $config['title_max_length']),
                self::FIELD_DESCRIPTION => sprintf('- description 具体可执行，不超过 %d 字。', $config['description_max_length']),
                self::FIELD_TASK_TYPE => sprintf('- task_type 只能是 %s。', implode(' / ', $config['allowed_task_types'])),
                self::FIELD_TASK_DATE => '- task_date 使用 YYYY-MM-DD。',
                self::FIELD_START_TIME => '- start_time 使用 HH:MM。',
                self::FIELD_END_TIME => '- end_time 使用 HH:MM，且不能早于 start_time。',
                self::FIELD_REMINDERS => sprintf('- reminders 只能从 %s 中选择。', implode(' / ', $config['allowed_reminders'])),
                self::FIELD_POINTS => sprintf('- points_reward 只能是 %d 到 %d 的整数。', $config['points_min'], $config['points_max']),
                self::FIELD_REQUIRES_FEEDBACK => '- requires_feedback 为布尔值。',
                self::FIELD_FEEDBACK_PROMPT => sprintf('- feedback_prompt 在需要反馈时填写，不超过 %d 字。', $config['feedback_prompt_max_length']),
                default => '',
            };
        }

        return array_values(array_filter($lines));
    }

    /**
     * @param array<int, string> $fields
     */
    private function fieldEnabled(array $fields, string $field): bool
    {
        return in_array($field, $fields, true);
    }

    /**
     * @param array<int, string> $allowed
     * @param array<int, string> $default
     * @return array<int, string>
     */
    private function csvIn(mixed $value, array $allowed, array $default): array
    {
        $items = is_array($value)
            ? $value
            : (preg_split('/\s*,\s*/', trim((string) $value)) ?: []);
        $normalized = [];
        foreach ($items as $item) {
            $item = trim((string) $item);
            if ($item !== '' && in_array($item, $allowed, true) && !in_array($item, $normalized, true)) {
                $normalized[] = $item;
            }
        }

        return $normalized !== [] ? $normalized : $default;
    }

    /**
     * @param mixed $value
     * @param array<int, string> $allowed
     * @return array<int, string>
     */
    private function normalizeReminders(mixed $value, array $allowed): array
    {
        if (is_string($value)) {
            $decoded = json_decode($value, true);
            $value = is_array($decoded) ? $decoded : preg_split('/\s*,\s*/', $value);
        }
        if (!is_array($value)) {
            return [];
        }

        $reminders = [];
        foreach ($value as $item) {
            $item = trim((string) $item);
            if ($item !== '' && in_array($item, $allowed, true) && !in_array($item, $reminders, true)) {
                $reminders[] = $item;
            }
        }

        return $reminders;
    }

    private function normalizeClock(string $value): ?string
    {
        $value = trim($value);
        if ($value === '') {
            return null;
        }
        if (preg_match('/^([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/', $value, $matches) !== 1) {
            return null;
        }

        return sprintf('%02d:%02d', (int) $matches[1], (int) $matches[2]);
    }

    private function addMinutes(string $clock, int $minutes): string
    {
        $parsed = \DateTimeImmutable::createFromFormat('H:i', $clock);
        if ($parsed === false) {
            return $clock;
        }

        return $parsed->modify('+' . max(0, $minutes) . ' minutes')->format('H:i');
    }

    private function intIn(mixed $value, int $min, int $max, int $default): int
    {
        if (!is_numeric($value)) {
            return $default;
        }

        return max($min, min($max, (int) $value));
    }
}
