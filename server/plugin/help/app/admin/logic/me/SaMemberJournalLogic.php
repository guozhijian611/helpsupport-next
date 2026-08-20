<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberJournal;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员日记摘要逻辑层
 */
class SaMemberJournalLogic extends BaseLogic
{
    public function __construct()
    {
        $this->model = new SaMemberJournal();
        $this->orderField = 'entry_date';
        $this->orderType = 'DESC';
    }

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);
        if ((int) $data['local_id'] <= 0) {
            $data['local_id'] = (int) round(microtime(true) * 1000000);
        }

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        if ((int) $data['local_id'] <= 0) {
            $data['local_id'] = (int) $id;
        }

        return parent::edit($id, $data);
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('entry_time', $data) && $data['entry_time'] === '') {
            $data['entry_time'] = null;
        }

        $data['title'] = '';
        $data['content'] = '';
        $data['media'] = null;
        $data['summary'] = mb_substr(trim((string) ($data['summary'] ?? '')), 0, 255);
        $data['word_count'] = max(0, (int) ($data['word_count'] ?? 0));
        $data['local_id'] = max(0, (int) ($data['local_id'] ?? 0));

        foreach (['mood_score' => 0, 'is_private' => 1, 'ai_access' => 2, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
