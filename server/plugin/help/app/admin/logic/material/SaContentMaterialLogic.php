<?php

namespace plugin\help\app\admin\logic\material;

use plugin\help\app\model\material\SaContentMaterial;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 内容素材逻辑层
 */
class SaContentMaterialLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaContentMaterial();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    public function audit(int $id, int $auditStatus, string $remark, int $adminId): bool
    {
        if (!in_array($auditStatus, [1, 2, 3], true)) {
            throw new ApiException('审核状态参数错误');
        }
        if ($auditStatus === 3 && $remark === '') {
            throw new ApiException('拒绝原因必须填写');
        }

        return (bool) $this->edit($id, [
            'audit_status' => $auditStatus,
            'audit_remark' => $remark,
            'audit_by' => $adminId > 0 ? $adminId : null,
            'audit_time' => date('Y-m-d H:i:s'),
            'status' => $auditStatus === 2 ? 1 : 2,
        ]);
    }

    private function normalizeFields(array $data): array
    {
        foreach (['title_i18n', 'tags'] as $field) {
            if (array_key_exists($field, $data)) {
                $data[$field] = $this->normalizeJsonField($data[$field]);
            }
        }

        foreach ([
            'member_id' => 0,
            'category_id' => 0,
            'duration_seconds' => 0,
            'view_count' => 0,
            'like_count' => 0,
            'collect_count' => 0,
            'comment_count' => 0,
            'sort' => 100,
        ] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }

    private function normalizeJsonField(mixed $value): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        return (string) $value;
    }
}
