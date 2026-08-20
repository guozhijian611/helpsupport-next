<?php

namespace plugin\help\app\admin\validate\chat;

use plugin\saiadmin\basic\BaseValidate;

class SaAiPersonaValidate extends BaseValidate
{
    protected $rule = [
        'code' => 'require|regex:/^[a-z][a-z0-9_]{1,47}$/',
        'title_zh' => 'require',
        'sort' => 'require|integer',
        'status' => 'require|in:1,2',
        'speech_runtime' => 'in:online,local,auto',
        'auto_play_voice' => 'in:1,2',
    ];

    protected $message = [
        'code.require' => '角色编码必须填写',
        'code.regex' => '角色编码需为小写字母开头的字母数字下划线',
        'title_zh.require' => '中文标题必须填写',
        'sort.require' => '排序必须填写',
        'status.require' => '状态必须填写',
        'speech_runtime.in' => '语音运行时只能是 online、local 或 auto',
        'auto_play_voice.in' => '回复自动播放语音只能是 1 或 2',
    ];

    protected $scene = [
        'save' => ['code', 'title_zh', 'sort', 'status', 'speech_runtime', 'auto_play_voice'],
        'update' => ['code', 'title_zh', 'sort', 'status', 'speech_runtime', 'auto_play_voice'],
    ];
}
