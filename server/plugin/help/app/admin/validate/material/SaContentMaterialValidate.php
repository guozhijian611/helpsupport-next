<?php

namespace plugin\help\app\admin\validate\material;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 内容素材验证器
 */
class SaContentMaterialValidate extends BaseValidate
{
    protected $rule = [
        'member_id' => 'integer',
        'category_id' => 'integer',
        'media_type' => 'require|in:article,video,audio,pdf,epub,link,txt,mp4,mov,mp3',
        'material_type' => 'require|in:education,entertainment,private',
        'title' => 'require|max:160',
        'artist' => 'max:120',
        'album' => 'max:120',
        'lyric_url' => 'max:500',
        'duration_seconds' => 'integer',
        'is_public' => 'require|in:1,2',
        'is_recommended' => 'require|in:1,2',
        'audit_status' => 'require|in:1,2,3',
        'sort' => 'integer',
        'status' => 'require|in:1,2',
    ];

    protected $message = [
        'member_id.integer' => '作者会员ID必须为整数',
        'category_id.integer' => '分类ID必须为整数',
        'media_type.require' => '素材类型必须填写',
        'media_type.in' => '素材类型参数错误',
        'material_type.require' => '内容大类必须填写',
        'material_type.in' => '内容大类参数错误',
        'title.require' => '素材标题必须填写',
        'title.max' => '素材标题不能超过160个字符',
        'artist.max' => '歌手/作者不能超过120个字符',
        'album.max' => '专辑名称不能超过120个字符',
        'lyric_url.max' => '歌词文件地址不能超过500个字符',
        'duration_seconds.integer' => '音视频时长必须为整数',
        'is_public.require' => '公开状态必须填写',
        'is_public.in' => '公开状态参数错误',
        'is_recommended.require' => '推荐状态必须填写',
        'is_recommended.in' => '推荐状态参数错误',
        'audit_status.require' => '审核状态必须填写',
        'audit_status.in' => '审核状态参数错误',
        'sort.integer' => '排序必须为整数',
        'status.require' => '状态必须填写',
        'status.in' => '状态参数错误',
    ];

    protected $scene = [
        'save' => [
            'member_id',
            'category_id',
            'media_type',
            'material_type',
            'title',
            'artist',
            'album',
            'lyric_url',
            'duration_seconds',
            'is_public',
            'is_recommended',
            'audit_status',
            'sort',
            'status',
        ],
        'update' => [
            'member_id',
            'category_id',
            'media_type',
            'material_type',
            'title',
            'artist',
            'album',
            'lyric_url',
            'duration_seconds',
            'is_public',
            'is_recommended',
            'audit_status',
            'sort',
            'status',
        ],
    ];
}
