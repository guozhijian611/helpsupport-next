<?php

namespace plugin\help\app\admin\logic\config;

use plugin\help\app\service\HelpAiPlanCardConfigService;
use plugin\saiadmin\app\cache\ConfigCache;
use plugin\saiadmin\exception\ApiException;
use support\Db;

/**
 * HelpSupport 登录与推送运行配置逻辑层
 */
class HelpRuntimeConfigLogic
{
    private const AI_AUDIT_PLATFORM_TYPES = [
        'generic',
        'openai',
        'deepseek',
        'gemini',
    ];

    private const RUNTIME_GROUPS = [
        'help_google_oauth' => 'Google 登录',
        'help_apple_oauth' => 'Apple 登录',
        'help_firebase_push' => 'Firebase 推送',
        'help_appointment_payment' => '预约积分',
        'help_ai_audit' => 'AI 内容审核',
        'help_ai_plan_card' => 'AI 时间线卡片',
    ];

    private const PLAN_CARD_CSV_KEYS = [
        'enabled_fields',
        'allowed_task_types',
        'allowed_reminders',
        'default_reminders',
    ];

    private const APP_DOWNLOAD_GROUPS = [
        'help_app_download' => 'App 下载配置',
    ];

    private const SECRET_KEYS = [
        'help_apple_oauth' => ['private_key'],
        'help_firebase_push' => ['service_account_json'],
    ];

    public function init($user): void
    {
        // 配置聚合页不依赖管理员上下文，仅满足 BaseController 初始化约定。
    }

    public function read(): array
    {
        return $this->readGroups(self::RUNTIME_GROUPS);
    }

    public function readAppDownload(): array
    {
        return $this->readGroups(self::APP_DOWNLOAD_GROUPS)[0] ?? [
            'id' => 0,
            'code' => 'help_app_download',
            'name' => self::APP_DOWNLOAD_GROUPS['help_app_download'],
            'remark' => '',
            'items' => [],
        ];
    }

    public function aiOptions(): array
    {
        return Db::table('saiai_config')
            ->where('status', 1)
            ->whereIn('type', self::AI_AUDIT_PLATFORM_TYPES)
            ->whereNull('delete_time')
            ->orderBy('is_default')
            ->orderBy('id')
            ->get(['id', 'name', 'type', 'model', 'is_default'])
            ->map(static fn (object $item): array => [
                'value' => (string) $item->id,
                'label' => sprintf('%s（%s / %s）', $item->name, $item->type, $item->model),
                'name' => (string) $item->name,
                'type' => (string) $item->type,
                'model' => (string) $item->model,
                'is_default' => (int) $item->is_default,
            ])
            ->all();
    }

    public function update(array $configs, int $adminId = 0): bool
    {
        return $this->updateGroups($configs, $adminId, self::RUNTIME_GROUPS);
    }

    public function updateAppDownload(array $values, int $adminId = 0): bool
    {
        return $this->updateGroups(['help_app_download' => $values], $adminId, self::APP_DOWNLOAD_GROUPS);
    }

    private function readGroups(array $allowedGroups): array
    {
        $groups = [];
        foreach (array_keys($allowedGroups) as $code) {
            $group = Db::table('sa_system_config_group')
                ->where('code', $code)
                ->whereNull('delete_time')
                ->first();
            if (!$group) {
                continue;
            }

            $items = Db::table('sa_system_config')
                ->where('group_id', $group->id)
                ->whereNull('delete_time')
                ->orderBy('sort', 'desc')
                ->orderBy('id')
                ->get()
                ->map(fn ($item) => $this->formatConfigItem($code, $item))
                ->all();

            $groups[] = [
                'id' => (int) $group->id,
                'code' => (string) $group->code,
                'name' => (string) $group->name,
                'remark' => $this->formatRemark((string) ($group->remark ?? '')),
                'items' => $items,
            ];
        }

        return $groups;
    }

    private function updateGroups(array $configs, int $adminId, array $allowedGroups): bool
    {
        if (empty($configs)) {
            throw new ApiException('配置参数不能为空');
        }

        $touchedGroups = [];
        Db::connection()->transaction(function () use ($configs, $adminId, $allowedGroups, &$touchedGroups) {
            foreach ($configs as $groupCode => $values) {
                if (!array_key_exists($groupCode, $allowedGroups)) {
                    throw new ApiException('配置组参数错误');
                }
                if (!is_array($values)) {
                    throw new ApiException('配置项参数错误');
                }

                $group = Db::table('sa_system_config_group')
                    ->where('code', $groupCode)
                    ->whereNull('delete_time')
                    ->first();
                if (!$group) {
                    throw new ApiException($allowedGroups[$groupCode] . '配置组不存在');
                }

                $items = Db::table('sa_system_config')
                    ->where('group_id', $group->id)
                    ->whereNull('delete_time')
                    ->get()
                    ->keyBy('key');

                foreach ($values as $key => $value) {
                    if (!$items->has($key)) {
                        continue;
                    }
                    if ($this->isSecretKey($groupCode, (string) $key) && $this->isBlank($value)) {
                        continue;
                    }
                    $value = $this->normalizeValue($groupCode, (string) $key, $value);
                    if (!$this->isCsvKey($groupCode, (string) $key)) {
                        $this->assertAllowedOption($items[$key], $value);
                    }

                    Db::table('sa_system_config')
                        ->where('id', $items[$key]->id)
                        ->update([
                            'value' => $value,
                            'updated_by' => $adminId,
                            'update_time' => date('Y-m-d H:i:s'),
                        ]);
                    $touchedGroups[$groupCode] = true;
                }

                if ($groupCode === 'help_ai_audit') {
                    $this->assertAiAuditReady((int) $group->id);
                }
                if ($groupCode === 'help_ai_plan_card') {
                    $this->assertPlanCardReady((int) $group->id);
                }
            }
        });

        foreach (array_keys($touchedGroups) as $groupCode) {
            ConfigCache::clearConfig($groupCode);
        }

        return true;
    }

    private function formatConfigItem(string $groupCode, object $item): array
    {
        $isSecret = $this->isSecretKey($groupCode, (string) $item->key);
        $value = (string) ($item->value ?? '');

        return [
            'id' => (int) $item->id,
            'key' => (string) $item->key,
            'name' => (string) $item->name,
            'value' => $isSecret ? '' : $value,
            'input_type' => (string) ($item->input_type ?? 'input'),
            'sort' => (int) ($item->sort ?? 0),
            'remark' => $this->formatRemark((string) ($item->remark ?? '')),
            'is_secret' => $isSecret,
            'has_value' => $isSecret && $value !== '',
            'options' => $this->optionsFor($item),
        ];
    }

    private function optionsFor(object $item): array
    {
        $selectData = json_decode((string) ($item->config_select_data ?? ''), true);
        if (is_array($selectData)) {
            return $selectData;
        }
        if (($item->key ?? '') === 'enabled') {
            return [
                ['label' => '启用', 'value' => '1'],
                ['label' => '禁用', 'value' => '2'],
            ];
        }

        return [];
    }

    private function assertAllowedOption(object $item, string $value): void
    {
        $options = $this->optionsFor($item);
        if ($options === []) {
            return;
        }

        $allowedValues = array_map(
            static fn (array $option) => (string) ($option['value'] ?? ''),
            $options
        );
        if (!in_array($value, $allowedValues, true)) {
            throw new ApiException((string) ($item->name ?? '配置项') . '参数错误');
        }
    }

    private function isSecretKey(string $groupCode, string $key): bool
    {
        return in_array($key, self::SECRET_KEYS[$groupCode] ?? [], true);
    }

    private function isBlank(mixed $value): bool
    {
        return $value === null || trim((string) $value) === '';
    }

    private function stringValue(mixed $value): string
    {
        if (is_bool($value)) {
            return $value ? '1' : '2';
        }
        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '';
        }

        return trim((string) $value);
    }

    private function normalizeValue(string $groupCode, string $key, mixed $value): string
    {
        $value = $this->stringValue($value);
        if ($key === 'points_cost') {
            $points = (int) $value;
            if ($points <= 0) {
                throw new ApiException('每次预约积分必须大于0');
            }

            return (string) $points;
        }

        if ($groupCode === 'help_ai_audit') {
            if ($key === 'ai_config_id') {
                $configId = (int) $value;
                if ($configId < 0) {
                    throw new ApiException('AI审核模型参数错误');
                }
                if ($configId > 0 && !$this->isAvailableAiAuditConfig($configId)) {
                    throw new ApiException('所选AI模型不存在、未启用或不支持文本审核');
                }
                return (string) $configId;
            }
            if (in_array($key, ['auto_pass_confidence', 'auto_reject_confidence'], true)) {
                if (!is_numeric($value)) {
                    throw new ApiException('自动审核阈值必须是数字');
                }
                $threshold = (float) $value;
                $min = $key === 'auto_pass_confidence' ? 0.50 : 0.80;
                if ($threshold < $min || $threshold > 1.00) {
                    throw new ApiException('自动审核阈值超出允许范围');
                }
                return rtrim(rtrim(number_format($threshold, 4, '.', ''), '0'), '.');
            }
            if ($key === 'max_attempts') {
                $attempts = (int) $value;
                if ($attempts < 1 || $attempts > 5) {
                    throw new ApiException('最大尝试次数必须在1到5之间');
                }
                return (string) $attempts;
            }
            if ($key === 'retry_delay_seconds') {
                $seconds = (int) $value;
                if ($seconds < 1 || $seconds > 300) {
                    throw new ApiException('重试间隔必须在1到300秒之间');
                }
                return (string) $seconds;
            }
            if ($key === 'prompt_policy') {
                return mb_substr($value, 0, 3000);
            }
        }

        if ($groupCode === 'help_ai_plan_card') {
            return $this->normalizePlanCardValue($key, $value);
        }

        return $value;
    }

    private function assertAiAuditReady(int $groupId): void
    {
        $values = Db::table('sa_system_config')
            ->where('group_id', $groupId)
            ->whereNull('delete_time')
            ->pluck('value', 'key')
            ->all();
        if ((int) ($values['enabled'] ?? 2) !== 1) {
            return;
        }
        $configId = (int) ($values['ai_config_id'] ?? 0);
        if ($configId <= 0) {
            throw new ApiException('启用AI内容审核前必须选择审核模型');
        }
        if (!$this->isAvailableAiAuditConfig($configId)) {
            throw new ApiException('所选AI模型不存在、未启用或不支持文本审核');
        }
    }

    private function isAvailableAiAuditConfig(int $configId): bool
    {
        return Db::table('saiai_config')
            ->where('id', $configId)
            ->where('status', 1)
            ->whereIn('type', self::AI_AUDIT_PLATFORM_TYPES)
            ->whereNull('delete_time')
            ->exists();
    }

    private function formatRemark(string $remark): string
    {
        $parts = explode(':', $remark, 3);
        return count($parts) === 3 && str_starts_with($remark, 'phinx:')
            ? $parts[2]
            : $remark;
    }

    private function isCsvKey(string $groupCode, string $key): bool
    {
        return $groupCode === 'help_ai_plan_card' && in_array($key, self::PLAN_CARD_CSV_KEYS, true);
    }

    private function normalizePlanCardValue(string $key, string $value): string
    {
        if ($this->isCsvKey('help_ai_plan_card', $key)) {
            $allowed = match ($key) {
                'enabled_fields' => HelpAiPlanCardConfigService::ALL_FIELDS,
                'allowed_task_types' => HelpAiPlanCardConfigService::TASK_TYPES,
                'allowed_reminders', 'default_reminders' => HelpAiPlanCardConfigService::REMINDERS,
                default => [],
            };
            $items = [];
            foreach (preg_split('/\s*,\s*/', $value) ?: [] as $item) {
                $item = trim((string) $item);
                if ($item !== '' && in_array($item, $allowed, true) && !in_array($item, $items, true)) {
                    $items[] = $item;
                }
            }
            if ($key === 'enabled_fields' && !in_array('title', $items, true)) {
                array_unshift($items, 'title');
            }
            if ($key === 'allowed_task_types' && $items === []) {
                throw new ApiException('至少选择一种任务类型');
            }
            return implode(',', $items);
        }

        if (in_array($key, ['min_tasks', 'max_tasks', 'title_max_length', 'description_max_length', 'default_duration_minutes', 'points_min', 'points_max', 'points_default', 'feedback_prompt_max_length'], true)) {
            if ($value !== '' && !is_numeric($value)) {
                throw new ApiException('数字配置必须是整数');
            }
            $number = (int) $value;
            [$min, $max, $label] = match ($key) {
                'min_tasks' => [0, 5, '最少任务数'],
                'max_tasks' => [1, 5, '最多任务数'],
                'title_max_length' => [10, 80, '标题最长字数'],
                'description_max_length' => [20, 1000, '描述最长字数'],
                'default_duration_minutes' => [0, 180, '默认持续分钟'],
                'points_min' => [0, 100, '积分下限'],
                'points_max' => [1, 200, '积分上限'],
                'points_default' => [0, 200, '默认积分'],
                default => [0, 255, '反馈提示最长字数'],
            };
            if ($number < $min || $number > $max) {
                throw new ApiException($label . '超出允许范围');
            }
            return (string) $number;
        }

        if ($key === 'default_start_time') {
            if ($value === '') {
                return '';
            }
            if (preg_match('/^([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/', $value, $matches) !== 1) {
                throw new ApiException('默认开始时间格式必须是 HH:MM');
            }
            return sprintf('%02d:%02d', (int) $matches[1], (int) $matches[2]);
        }

        if ($key === 'default_date_mode' && !in_array($value, HelpAiPlanCardConfigService::DATE_MODES, true)) {
            throw new ApiException('默认任务日期参数错误');
        }
        if ($key === 'default_task_type' && !in_array($value, HelpAiPlanCardConfigService::TASK_TYPES, true)) {
            throw new ApiException('默认任务类型参数错误');
        }
        if (in_array($key, ['fallback_title', 'default_feedback_prompt'], true)) {
            return mb_substr($value, 0, 80);
        }
        if (in_array($key, ['fallback_description', 'prompt_policy'], true)) {
            return mb_substr($value, 0, $key === 'prompt_policy' ? 3000 : 500);
        }

        return $value;
    }

    private function assertPlanCardReady(int $groupId): void
    {
        $values = Db::table('sa_system_config')
            ->where('group_id', $groupId)
            ->whereNull('delete_time')
            ->pluck('value', 'key')
            ->all();

        $minTasks = (int) ($values['min_tasks'] ?? 0);
        $maxTasks = (int) ($values['max_tasks'] ?? 2);
        if ($minTasks > $maxTasks) {
            throw new ApiException('最少任务数不能大于最多任务数');
        }
        $pointsMin = (int) ($values['points_min'] ?? 5);
        $pointsMax = (int) ($values['points_max'] ?? 30);
        $pointsDefault = (int) ($values['points_default'] ?? 10);
        if ($pointsMin > $pointsMax) {
            throw new ApiException('积分下限不能大于积分上限');
        }
        if ($pointsDefault < $pointsMin || $pointsDefault > $pointsMax) {
            throw new ApiException('默认积分必须落在积分上下限之间');
        }

        $allowedTypes = array_filter(preg_split('/\s*,\s*/', (string) ($values['allowed_task_types'] ?? '')) ?: []);
        $defaultType = trim((string) ($values['default_task_type'] ?? 'daily'));
        if ($allowedTypes !== [] && !in_array($defaultType, $allowedTypes, true)) {
            throw new ApiException('默认任务类型必须包含在允许的任务类型中');
        }

        $allowedReminders = array_filter(preg_split('/\s*,\s*/', (string) ($values['allowed_reminders'] ?? '')) ?: []);
        $defaultReminders = array_filter(preg_split('/\s*,\s*/', (string) ($values['default_reminders'] ?? '')) ?: []);
        foreach ($defaultReminders as $reminder) {
            if ($allowedReminders !== [] && !in_array($reminder, $allowedReminders, true)) {
                throw new ApiException('默认提醒必须包含在允许的提醒列表中');
            }
        }

        if ((int) ($values['force_emit'] ?? 2) === 1 && trim((string) ($values['fallback_title'] ?? '')) === '') {
            throw new ApiException('启用强制出卡时必须填写兜底卡片标题');
        }
    }
}
