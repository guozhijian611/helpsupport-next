<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberDiagnosticLog;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员客户端诊断日志逻辑层
 */
class SaMemberDiagnosticLogLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberDiagnosticLog();
        $this->orderField = 'd.create_time';
        $this->orderType = 'DESC';
    }

    public function search(array $searchWhere = []): mixed
    {
        $query = $this->baseQuery(false);

        $memberId = (int) ($searchWhere['member_id'] ?? 0);
        if ($memberId > 0) {
            $query->where('d.member_id', $memberId);
        }

        $memberKeyword = trim((string) ($searchWhere['member_keyword'] ?? ''));
        if ($memberKeyword !== '') {
            $like = '%' . $memberKeyword . '%';
            $query->where(function ($subQuery) use ($like) {
                $subQuery->where('m.username', 'like', $like)
                    ->whereOr('m.nickname', 'like', $like)
                    ->whereOr('m.mobile', 'like', $like)
                    ->whereOr('m.email', 'like', $like);
            });
        }

        $deviceId = trim((string) ($searchWhere['device_id'] ?? ''));
        if ($deviceId !== '') {
            $query->where('d.device_id', 'like', '%' . $deviceId . '%');
        }

        $platform = trim((string) ($searchWhere['platform'] ?? ''));
        if ($platform !== '') {
            $query->where('d.platform', $platform);
        }

        $source = trim((string) ($searchWhere['source'] ?? ''));
        if ($source !== '') {
            $query->where('d.source', $source);
        }

        $status = $searchWhere['status'] ?? '';
        if ($status !== '' && $status !== null) {
            $query->where('d.status', (int) $status);
        }

        return $query;
    }

    public function getList($query): mixed
    {
        $request = request();
        $saiType = $request ? $request->input('saiType', 'list') : 'list';
        $page = max(1, (int) ($request ? $request->input('page', 1) : 1));
        $limit = max(1, (int) ($request ? $request->input('limit', 10) : 10));
        $orderField = $this->normalizeOrderField((string) ($request ? $request->input('orderField', '') : ''));
        $orderType = strtoupper((string) ($request ? $request->input('orderType', $this->orderType) : $this->orderType));
        if (!in_array($orderType, ['ASC', 'DESC'], true)) {
            $orderType = $this->orderType;
        }

        $query->order($orderField, $orderType);

        if ($saiType === 'all') {
            return $this->decorateRows($query->select()->toArray(), false);
        }

        $data = $query->paginate($limit, false, ['page' => $page])->toArray();
        $data['data'] = $this->decorateRows($data['data'] ?? [], false);

        return $data;
    }

    public function read($id): mixed
    {
        $row = $this->baseQuery(true)
            ->where('d.id', (int) $id)
            ->find();

        if (!$row) {
            return [];
        }

        return $this->decorateRow(is_array($row) ? $row : $row->toArray(), true);
    }

    private function baseQuery(bool $withEntries): mixed
    {
        $fields = [
            'd.id',
            'd.member_id',
            'd.device_id',
            'd.platform',
            'd.app_version',
            'd.locale',
            'd.timezone',
            'd.source',
            'd.entry_count',
            'd.first_log_time',
            'd.last_log_time',
            'd.log_summary',
            'd.status',
            'd.remark',
            'd.create_time',
            'm.username AS member_username',
            'm.nickname AS member_nickname',
            'm.mobile AS member_mobile',
            'm.email AS member_email',
        ];

        if ($withEntries) {
            $fields[] = 'd.log_entries';
        }

        return $this->model->alias('d')
            ->leftJoin('sa_member m', 'm.id = d.member_id AND m.delete_time IS NULL')
            ->field(implode(',', $fields));
    }

    private function decorateRows(array $rows, bool $withEntries): array
    {
        foreach ($rows as $index => $row) {
            $rows[$index] = $this->decorateRow($row, $withEntries);
        }

        return $rows;
    }

    private function decorateRow(array $row, bool $withEntries): array
    {
        $row['member_display'] = $this->buildMemberDisplay($row);

        if ($withEntries) {
            $row['log_entries'] = $this->formatJson($row['log_entries'] ?? '');
        }

        return $row;
    }

    private function buildMemberDisplay(array $row): string
    {
        $nickname = trim((string) ($row['member_nickname'] ?? ''));
        $username = trim((string) ($row['member_username'] ?? ''));
        $mobile = trim((string) ($row['member_mobile'] ?? ''));
        $email = trim((string) ($row['member_email'] ?? ''));

        $parts = array_values(array_filter([$nickname, $username, $mobile, $email], static fn (string $value): bool => $value !== ''));
        if ($parts === []) {
            return '会员 #' . (int) ($row['member_id'] ?? 0);
        }

        return implode(' / ', array_slice(array_unique($parts), 0, 3));
    }

    private function formatJson(mixed $value): string
    {
        if ($value === null || $value === '') {
            return '';
        }

        if (is_array($value) || is_object($value)) {
            return (string) json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        }

        $decoded = json_decode((string) $value, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            return (string) json_encode($decoded, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        }

        return (string) $value;
    }

    private function normalizeOrderField(string $orderField): string
    {
        $orderField = trim($orderField);
        if ($orderField === '') {
            return $this->orderField;
        }

        return [
            'id' => 'd.id',
            'member_id' => 'd.member_id',
            'device_id' => 'd.device_id',
            'platform' => 'd.platform',
            'app_version' => 'd.app_version',
            'source' => 'd.source',
            'entry_count' => 'd.entry_count',
            'first_log_time' => 'd.first_log_time',
            'last_log_time' => 'd.last_log_time',
            'status' => 'd.status',
            'create_time' => 'd.create_time',
        ][$orderField] ?? $this->orderField;
    }
}
