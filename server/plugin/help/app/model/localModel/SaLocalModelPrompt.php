<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\localModel;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 本地模型提示词模型
 *
 * sa_local_model_prompt 本地模型提示词表
 *
 * @property  $id 主键
 * @property  $model_id 关联模型ID，空表示通用提示词
 * @property  $chat_mode 聊天模式 doctor/companion/patient/ai_doctor
 * @property  $locale 语言
 * @property  $title 提示词标题
 * @property  $system_prompt 系统提示词
 * @property  $first_message 默认开场白
 * @property  $safety_prompt 安全边界提示
 * @property  $status 状态 1启用 2禁用
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaLocalModelPrompt extends BaseModel
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
    protected $table = 'sa_local_model_prompt';

    /**
     * 提示词标题 搜索
     */
    public function searchTitleAttr($query, $value)
    {
        $query->where('title', 'like', '%'.$value.'%');
    }

    /**
     * 聊天模式 搜索
     */
    public function searchChatModeAttr($query, $value)
    {
        $query->where('chat_mode', $value);
    }

    /**
     * 语言 搜索
     */
    public function searchLocaleAttr($query, $value)
    {
        $query->where('locale', $value);
    }

    /**
     * 状态 搜索
     */
    public function searchStatusAttr($query, $value)
    {
        $query->where('status', $value);
    }

}
