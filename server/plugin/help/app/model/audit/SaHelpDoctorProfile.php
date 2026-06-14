<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\model\audit;

use plugin\saiadmin\basic\think\BaseModel;

/**
 * 医生资质审核模型
 *
 * sa_help_doctor_profile HelpSupport医生资质资料表
 *
 * @property  $id 主键
 * @property  $member_id 医生会员ID
 * @property  $real_name 真实姓名
 * @property  $title 职称
 * @property  $hospital 医院/机构
 * @property  $department 科室
 * @property  $specialty 专业方向
 * @property  $license_no 执业证书编号
 * @property  $certification_images 证书图片数组
 * @property  $audit_status 审核状态 0待审核 1已通过 2已拒绝
 * @property  $audit_remark 审核备注
 * @property  $audit_by 审核人
 * @property  $audit_time 审核时间
 * @property  $approved_time 通过时间
 * @property  $status 状态 1正常 2禁用
 * @property  $created_by 创建者
 * @property  $updated_by 更新者
 * @property  $create_time 创建时间
 * @property  $update_time 修改时间
 */
class SaHelpDoctorProfile extends BaseModel
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
    protected $table = 'sa_help_doctor_profile';

    /**
     * 真实姓名 搜索
     */
    public function searchRealNameAttr($query, $value)
    {
        $query->where('real_name', 'like', '%'.$value.'%');
    }

    /**
     * 职称 搜索
     */
    public function searchTitleAttr($query, $value)
    {
        $query->where('title', 'like', '%'.$value.'%');
    }

    /**
     * 审核状态 搜索
     */
    public function searchAuditStatusAttr($query, $value)
    {
        $query->where('audit_status', (int) $value);
    }

    /**
     * 状态 搜索
     */
    public function searchStatusAttr($query, $value)
    {
        $query->where('status', (int) $value);
    }
}
