<?php

namespace plugin\help\app\admin\logic\config;

use plugin\saiadmin\app\cache\ConfigCache;
use plugin\saiadmin\exception\ApiException;
use support\Db;

/**
 * HelpSupport 登录与推送运行配置逻辑层
 */
class HelpRuntimeConfigLogic
{
    private const GROUPS = [
        'help_google_oauth' => 'Google 登录',
        'help_apple_oauth' => 'Apple 登录',
        'help_firebase_push' => 'Firebase 推送',
    ];

    private const SECRET_KEYS = [
        'help_apple_oauth' => ['private_key'],
        'help_firebase_push' => ['service_account_json'],
    ];

    public function read(): array
    {
        $groups = [];
        foreach (array_keys(self::GROUPS) as $code) {
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

    public function update(array $configs, int $adminId = 0): bool
    {
        if (empty($configs)) {
            throw new ApiException('配置参数不能为空');
        }

        $touchedGroups = [];
        Db::connection()->transaction(function () use ($configs, $adminId, &$touchedGroups) {
            foreach ($configs as $groupCode => $values) {
                if (!array_key_exists($groupCode, self::GROUPS)) {
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
                    throw new ApiException(self::GROUPS[$groupCode] . '配置组不存在');
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
                    $value = $this->stringValue($value);
                    $this->assertAllowedOption($items[$key], $value);

                    Db::table('sa_system_config')
                        ->where('id', $items[$key]->id)
                        ->update([
                            'value' => $value,
                            'updated_by' => $adminId,
                            'update_time' => date('Y-m-d H:i:s'),
                        ]);
                    $touchedGroups[$groupCode] = true;
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

    private function formatRemark(string $remark): string
    {
        $parts = explode(':', $remark, 3);
        return count($parts) === 3 && str_starts_with($remark, 'phinx:')
            ? $parts[2]
            : $remark;
    }
}
