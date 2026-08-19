<?php

namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

class SaAiPersonaPromptValidate extends BaseValidate
{
    protected $rule = [
        'persona_id' => 'require|integer|gt:0',
        'runtime_mode' => 'require|in:online,local',
        'locale' => 'require',
        'system_prompt' => 'require',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'persona_id.require' => '角色必须选择',
        'runtime_mode.require' => '运行模式必须填写',
        'locale.require' => '语言必须填写',
        'system_prompt.require' => '系统提示词必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['persona_id', 'runtime_mode', 'locale', 'system_prompt', 'status'],
        'update' => ['persona_id', 'runtime_mode', 'locale', 'system_prompt', 'status'],
    ];
}
