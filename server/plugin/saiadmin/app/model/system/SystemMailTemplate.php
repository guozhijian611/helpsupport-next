<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: sai <1430792918@qq.com>
// +----------------------------------------------------------------------
namespace plugin\saiadmin\app\model\system;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 邮件模板模型
 *
 * sa_system_mail_template 邮件发信模板
 *
 * @property  $id 编号
 * @property  $name 模板名称
 * @property  $code 模板标识
 * @property  $subject 邮件主题
 * @property  $content 邮件内容
 * @property  $variables 变量说明
 * @property  $sort 排序
 * @property  $status 状态
 * @property  $remark 备注
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 * @property  $delete_time 删除时间
 */
class SystemMailTemplate extends BaseModel
{
    /**
     * 数据表主键
     * @var string
     */
    protected $pk = 'id';

    protected $table = 'sa_system_mail_template';

    /**
     * 模板名称搜索
     */
    public function searchNameAttr($query, $value): void
    {
        $query->where('name', 'like', '%' . $value . '%');
    }

    /**
     * 模板标识搜索
     */
    public function searchCodeAttr($query, $value): void
    {
        $query->where('code', 'like', '%' . $value . '%');
    }

    /**
     * 邮件主题搜索
     */
    public function searchSubjectAttr($query, $value): void
    {
        $query->where('subject', 'like', '%' . $value . '%');
    }

    /**
     * 状态搜索
     */
    public function searchStatusAttr($query, $value): void
    {
        $query->where('status', $value);
    }
}
