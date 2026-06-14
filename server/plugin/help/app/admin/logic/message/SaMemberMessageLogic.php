<?php

namespace plugin\help\app\admin\logic\message;

use plugin\help\app\model\message\SaMemberMessage;
use plugin\help\app\service\HelpPushService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;

/**
 * 会员消息中心逻辑层
 */
class SaMemberMessageLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberMessage();
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

    public function markRead(array|string|int $ids): bool
    {
        return $this->updateByIds($ids, [
            'is_read' => 1,
            'read_time' => date('Y-m-d H:i:s'),
        ]);
    }

    public function markPushed(array|string|int $ids): bool
    {
        return $this->updateByIds($ids, [
            'is_pushed' => 1,
            'push_status' => 1,
            'push_time' => date('Y-m-d H:i:s'),
        ]);
    }

    public function markFailed(array|string|int $ids): bool
    {
        return $this->updateByIds($ids, [
            'is_pushed' => 2,
            'push_status' => 2,
        ]);
    }

    public function push(array|string|int $ids): array
    {
        $idList = $this->parseIds($ids);
        if ($idList === []) {
            throw new ApiException('请选择要推送的消息');
        }

        $service = new HelpPushService();
        $success = 0;
        $failed = 0;
        foreach ($idList as $id) {
            $message = $service->pushMessage($id);
            if ($message === []) {
                $failed++;
                continue;
            }

            if ((int) ($message['push_status'] ?? 0) === 1) {
                $success++;
            } else {
                $failed++;
            }
        }

        return [
            'total' => count($idList),
            'success' => $success,
            'failed' => $failed,
        ];
    }

    private function updateByIds(array|string|int $ids, array $data): bool
    {
        $idList = $this->parseIds($ids);
        if ($idList === []) {
            throw new ApiException('请选择要操作的消息');
        }

        $exists = (int) $this->model->whereIn('id', $idList)->count();
        if ($exists === 0) {
            return false;
        }

        return $this->model->whereIn('id', $idList)->update($data) !== false;
    }

    private function parseIds(array|string|int $ids): array
    {
        if (is_string($ids)) {
            $ids = array_filter(array_map('trim', explode(',', $ids)), static fn ($id) => $id !== '');
        }

        if (is_int($ids)) {
            $ids = [$ids];
        }

        return array_values(array_unique(array_filter(
            array_map('intval', (array) $ids),
            static fn (int $id) => $id > 0
        )));
    }

    private function normalizeFields(array $data, bool $isCreate = false): array
    {
        foreach ([
            'is_pushed' => 2,
            'push_status' => 0,
            'is_read' => 2,
            'biz_id' => 0,
            'status' => 1,
        ] as $field => $default) {
            if ($isCreate && (!array_key_exists($field, $data) || $data[$field] === '')) {
                $data[$field] = $default;
                continue;
            }
            if (!$isCreate && array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        foreach (['push_time', 'read_time'] as $field) {
            if (array_key_exists($field, $data) && $data[$field] === '') {
                $data[$field] = null;
            }
        }

        if (array_key_exists('ext', $data)) {
            $data['ext'] = $this->normalizeJsonField($data['ext']);
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

        $decoded = json_decode((string) $value, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new ApiException('扩展JSON格式错误');
        }

        return json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
}
