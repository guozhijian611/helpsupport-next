<?php

namespace plugin\help\app\admin\logic\gamification;

use plugin\help\app\model\gamification\SaMemberBadgeRule;
use plugin\saiadmin\basic\think\BaseLogic;
use think\facade\Db;

/**
 * 荣誉徽章规则逻辑层
 */
class SaMemberBadgeRuleLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberBadgeRule();
        $this->orderField = 'sort';
        $this->orderType = 'ASC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        foreach (['trigger_value' => 1, 'points_reward' => 0, 'sort' => 100, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }
        if (!array_key_exists('code', $data) || trim((string) $data['code']) === '') {
            $data['code'] = $this->generateCode($data);
        }

        return $data;
    }

    private function generateCode(array $data): string
    {
        $triggerType = preg_replace('/[^a-z0-9_]+/', '_', strtolower((string) ($data['trigger_type'] ?? 'manual')));
        $triggerType = trim((string) $triggerType, '_') ?: 'manual';
        $triggerValue = max(1, (int) ($data['trigger_value'] ?? 1));
        $nameHash = substr(md5((string) ($data['name'] ?? '') . '|' . $triggerType . '|' . $triggerValue), 0, 6);
        $baseCode = substr($triggerType . '_' . $triggerValue . '_' . $nameHash, 0, 70);
        $code = $baseCode;
        $suffix = 1;

        while ($this->codeExists($code)) {
            $code = substr($baseCode, 0, 70) . '_' . $suffix;
            $suffix++;
        }

        return $code;
    }

    private function codeExists(string $code): bool
    {
        return (bool) Db::table('sa_member_badge_rule')
            ->where('code', $code)
            ->whereNull('delete_time')
            ->find();
    }
}
