<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\localModel;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 本地模型目录模型
 *
 * sa_local_model_catalog 本地模型目录表
 *
 * @property  $id 主键
 * @property  $name 模型显示名称
 * @property  $cover_url 封面图地址
 * @property  $code 模型编码
 * @property  $provider 模型来源
 * @property  $model_family 模型家族
 * @property  $capability 能力 llm/asr/tts
 * @property  $quantization 量化类型
 * @property  $file_size 文件大小字节
 * @property  $download_url 模型下载地址
 * @property  $sha256 SHA256校验值
 * @property  $intro 默认介绍
 * @property  $intro_i18n 多语言介绍
 * @property  $license 许可证说明
 * @property  $min_memory_mb 推荐最小内存MB
 * @property  $context_size 默认上下文长度
 * @property  $default_temperature 默认温度
 * @property  $default_top_p 默认top_p
 * @property  $sort 排序
 * @property  $status 状态 1启用 2禁用
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaLocalModelCatalog extends BaseModel
{
    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    /**
     * 数据库表名称
     * @var string
     */
    protected $table = 'sa_local_model_catalog';

    /**
     * 模型显示名称 搜索
     */
    public function searchNameAttr($query, $value)
    {
        $query->where('name', 'like', '%'.$value.'%');
    }

    /**
     * 模型编码 搜索
     */
    public function searchCodeAttr($query, $value)
    {
        $query->where('code', 'like', '%'.$value.'%');
    }

    /**
     * 能力类型 搜索
     */
    public function searchCapabilityAttr($query, $value)
    {
        $query->where('capability', $value);
    }

    /**
     * 状态 搜索
     */
    public function searchStatusAttr($query, $value)
    {
        $query->where('status', $value);
    }

}
