<?php

namespace plugin\help\app\model\material;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 素材评论模型
 *
 * @property int $id
 * @property int $material_id
 * @property int $member_id
 * @property int $parent_id
 * @property string $content
 * @property int $status
 */
class SaMaterialComment extends BaseModel
{
    protected $pk = 'id';

    protected $table = 'sa_material_comment';
}
