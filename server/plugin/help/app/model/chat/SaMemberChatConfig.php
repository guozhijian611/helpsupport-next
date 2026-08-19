<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\chat;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * AI聊天配置模型
 *
 * sa_member_chat_config 会员AI聊天预置配置表
 *
 * @property  $id 主键
 * @property  $member_id 会员ID
 * @property  $chat_mode 模式 doctor/companion/patient/ai_doctor
 * @property  $prompt_text 用户模式描述和前置提示
 * @property  $online_config_id 会员最近选择的在线 AI 配置ID
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaMemberChatConfig extends BaseModel
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
    protected $table = 'sa_member_chat_config';

    /**
     * 会员ID 搜索
     */
    public function searchMemberIdAttr($query, $value)
    {
        $query->where('member_id', $value);
    }

    /**
     * 模式 搜索
     */
    public function searchChatModeAttr($query, $value)
    {
        $query->where('chat_mode', $value);
    }

}
