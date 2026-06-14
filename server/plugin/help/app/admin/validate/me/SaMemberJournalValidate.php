<?php

namespace plugin\help\app\admin\validate\me;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员日记验证器
 */
class SaMemberJournalValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'entry_date' => 'require|dateFormat:Y-m-d',
        'title' => 'require|max:120',
        'mood_score' => 'integer',
        'is_private' => 'in:1,2',
        'ai_access' => 'in:1,2',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'entry_date.require' => '记录日期必须填写',
        'entry_date.dateFormat' => '记录日期格式必须为YYYY-MM-DD',
        'title.require' => '标题必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'entry_date', 'title', 'mood_score', 'is_private', 'ai_access', 'status'],
        'update' => ['member_id', 'entry_date', 'title', 'mood_score', 'is_private', 'ai_access', 'status'],
    ];
}
