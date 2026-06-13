<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\config;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * App引导页配置模型
 *
 * sa_app_onboarding_page App引导页配置表
 *
 * @property  $id 主键
 * @property  $scene 场景
 * @property  $version 配置版本
 * @property  $locale 语言
 * @property  $title 标题
 * @property  $description 说明
 * @property  $image 图片URL或附件路径
 * @property  $button_text 按钮文案
 * @property  $action_type 动作类型 next/skip/route/external_url
 * @property  $action_value 动作值
 * @property  $sort 排序
 * @property  $status 状态 1启用 2禁用
 * @property  $start_time 生效开始时间
 * @property  $end_time 生效结束时间
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaAppOnboardingPage extends BaseModel
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
    protected $table = 'sa_app_onboarding_page';

    /**
     * 标题 搜索
     */
    public function searchTitleAttr($query, $value)
    {
        $query->where('title', 'like', '%'.$value.'%');
    }

}
