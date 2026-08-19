<?php

namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

class SaAiPersona extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_ai_persona';

    public function searchCodeAttr($query, $value): void
    {
        $query->where('code', 'like', '%' . $value . '%');
    }

    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', (int) $value);
    }
}
