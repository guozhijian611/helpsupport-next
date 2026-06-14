<?php

namespace plugin\help\app\admin\validate\me;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 会员回忆录验证器
 */
class SaMemberMemoirValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'require|integer',
        'title' => 'require|max:160',
        'source_month' => 'require|max:7',
        'grant_level_id' => 'integer',
        'grant_level_rank' => 'integer',
        'journal_count' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.require' => '会员ID必须填写',
        'title.require' => '回忆录标题必须填写',
        'source_month.require' => '来源月份必须填写',
        'status.require' => '状态必须填写',
    ];

    protected $scene = [
        'save' => ['member_id', 'title', 'source_month', 'grant_level_id', 'grant_level_rank', 'journal_count', 'status'],
        'update' => ['member_id', 'title', 'source_month', 'grant_level_id', 'grant_level_rank', 'journal_count', 'status'],
    ];
}
