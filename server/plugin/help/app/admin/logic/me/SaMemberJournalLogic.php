<?php

namespace plugin\help\app\admin\logic\me;

use plugin\help\app\model\me\SaMemberJournal;
use plugin\saiadmin\basic\think\BaseLogic;

/**
 * 会员日记逻辑层
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
        return parent::add($this->normalizeFields($data));
    }

    public function edit($id, array $data): mixed
    {
        return parent::edit($id, $this->normalizeFields($data));
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('entry_time', $data) && $data['entry_time'] === '') {
            $data['entry_time'] = null;
        }
        if (!array_key_exists('media', $data) || $data['media'] === '') {
            $data['media'] = null;
        } elseif (is_array($data['media']) || is_object($data['media'])) {
            $data['media'] = json_encode($data['media'], JSON_UNESCAPED_UNICODE);
        }
        foreach (['mood_score' => 0, 'is_private' => 1, 'ai_access' => 2, 'status' => 1] as $field => $default) {
            if (!array_key_exists($field, $data) || $data[$field] === '') {
                $data[$field] = $default;
            }
        }

        return $data;
    }
}
