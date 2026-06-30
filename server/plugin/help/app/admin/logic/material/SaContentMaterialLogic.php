<?php

namespace plugin\help\app\admin\logic\material;

use plugin\help\app\model\material\SaContentMaterial;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

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
        return parent::add($this->normalizeFields($data, true));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    public function read($id): mixed
    {
        $model = parent::read($id);
        $data = is_array($model) ? $model : $model->toArray();
        $rows = $this->enrichRows([$data]);

        return $rows[0] ?? $data;
    }

    public function getList($query): mixed
    {
        $data = parent::getList($query);
        if (isset($data['data']) && is_array($data['data'])) {
            $data['data'] = $this->enrichRows($data['data']);
            return $data;
        }
        if (is_array($data)) {
            return $this->enrichRows($data);
        }

        return $data;
    }

    public function audit(int $id, int $auditStatus, string $remark, int $adminId): bool
    {
        if (!in_array($auditStatus, [1, 2, 3], true)) {
            throw new ApiException('审核状态参数错误');
        }
        if ($auditStatus === 3 && $remark === '') {
            throw new ApiException('拒绝原因必须填写');
        }

        $material = Db::table('sa_content_material')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$material) {
            throw new ApiException('内容素材不存在');
        }

        return Db::transaction(function () use ($id, $auditStatus, $remark, $adminId, $material) {
            $result = (bool) $this->edit($id, [
                'audit_status' => $auditStatus,
                'audit_remark' => $remark,
                'audit_by' => $adminId > 0 ? $adminId : null,
                'audit_time' => date('Y-m-d H:i:s'),
                'status' => $auditStatus === 2 ? 1 : 2,
            ]);
            if ($result) {
                (new HelpAuditLogService())->record(
                    'content_material',
                    $id,
                    'audit',
                    $material['audit_status'] ?? null,
                    $auditStatus,
                    $remark,
                    $adminId
                );
            }

            return $result;
        });
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        foreach (['title_i18n', 'summary_i18n', 'content_text_i18n', 'tags'] as $field) {
            if (array_key_exists($field, $data)) {
                $label = match ($field) {
                    'title_i18n' => '多语言标题',
                    'summary_i18n' => '多语言摘要',
                    'content_text_i18n' => '多语言正文',
                    default => '标签',
                };
                $data[$field] = $this->normalizeJsonField($data[$field], $label);
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
            if ($isCreate && (!array_key_exists($field, $data) || $data[$field] === '')) {
                $data[$field] = $default;
                continue;
            }
            if (!$isCreate && array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }

    private function normalizeJsonField(mixed $value, string $label): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        $decoded = json_decode((string) $value, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new ApiException($label . 'JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    public function enrichRows(array $rows): array
    {
        $auditorIds = [];
        foreach ($rows as $row) {
            $auditorId = (int) ($row['audit_by'] ?? 0);
            if ($auditorId > 0) {
                $auditorIds[] = $auditorId;
            }
        }

        $auditors = [];
        if ($auditorIds !== []) {
            $users = Db::table('sa_system_user')
                ->whereIn('id', array_values(array_unique($auditorIds)))
                ->field('id, username, realname')
                ->select()
                ->toArray();
            foreach ($users as $user) {
                $name = trim((string) ($user['realname'] ?? ''));
                if ($name === '') {
                    $name = trim((string) ($user['username'] ?? ''));
                }
                $auditors[(int) $user['id']] = $name !== '' ? $name : '管理员 #' . (int) $user['id'];
            }
        }

        foreach ($rows as &$row) {
            $auditorId = (int) ($row['audit_by'] ?? 0);
            $row['audit_by_name'] = $auditorId > 0 ? ($auditors[$auditorId] ?? '管理员 #' . $auditorId) : '';
            $row['audit_by_display'] = $row['audit_by_name'] !== '' ? $row['audit_by_name'] : '-';
        }
        unset($row);

        return $rows;
    }
}
