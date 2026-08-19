<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

class SaAiPersonaPrompt extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_ai_persona_prompt';

    public function searchPersonaIdAttr($query, $value): void
    {
        $query->where('persona_id', (int) $value);
    }

    public function searchRuntimeModeAttr($query, $value): void
    {
        $query->where('runtime_mode', (string) $value);
    }

    public function searchLocaleAttr($query, $value): void
    {
        $query->where('locale', (string) $value);
    }
}
