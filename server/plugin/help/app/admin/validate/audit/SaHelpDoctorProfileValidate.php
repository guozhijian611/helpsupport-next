<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\validate\audit;

use plugin\saiadmin\basic\BaseValidate;

/**
 * 医生资质审核验证器
 */
class SaHelpDoctorProfileValidate extends BaseValidate
{
    /**
     * 定义验证规则
     */
    protected $rule =   [
        'member_id' => 'require',
        'real_name' => 'require',
        'title' => 'require',
        'hospital' => 'require',
        'department' => 'require',
        'specialty' => 'require',
        'license_no' => 'require',
        'audit_status' => 'require',
        'audit_remark' => 'require',
        'status' => 'require',
    ];

    /**
     * 定义错误信息
     */
    protected $message  =   [
        'member_id' => '医生会员ID必须填写',
        'real_name' => '真实姓名必须填写',
        'title' => '职称必须填写',
        'hospital' => '医院/机构必须填写',
        'department' => '科室必须填写',
        'specialty' => '专业方向必须填写',
        'license_no' => '执业证书编号必须填写',
        'audit_status' => '审核状态 0待审核 1已通过 2已拒绝必须填写',
        'audit_remark' => '审核备注必须填写',
        'status' => '状态 1正常 2禁用必须填写',
    ];

    /**
     * 定义场景
     */
    protected $scene = [
        'save' => [
            'member_id',
            'real_name',
            'title',
            'hospital',
            'department',
            'specialty',
            'license_no',
            'audit_status',
            'audit_remark',
            'status',
        ],
        'update' => [
            'member_id',
            'real_name',
            'title',
            'hospital',
            'department',
            'specialty',
            'license_no',
            'audit_status',
            'audit_remark',
            'status',
        ],
    ];

}
