<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\audit;

use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\audit\SaHelpDoctorProfile;
use think\facade\Db;

/**
 * 医生资质审核逻辑层
 */
class SaHelpDoctorProfileLogic extends BaseLogic
{
    /**
     * 构造函数
     */
    public function __construct()
    {
        $this->model = new SaHelpDoctorProfile();
        $this->orderField = 'id';
        $this->orderType = 'DESC';
    }

    public function audit(int $id, int $auditStatus, string $remark, int $adminId): bool
    {
        if ($id <= 0) {
            throw new ApiException('请选择要审核的医生资料');
        }
        if (!in_array($auditStatus, [1, 2], true)) {
            throw new ApiException('审核状态参数错误');
        }
        if ($auditStatus === 2 && $remark === '') {
            throw new ApiException('拒绝原因必须填写');
        }

        $profile = Db::table('sa_help_doctor_profile')
            ->where('id', $id)
            ->whereNull('delete_time')
            ->find();
        if (!$profile) {
            throw new ApiException('医生资料不存在');
        }

        $now = date('Y-m-d H:i:s');
        Db::transaction(function () use ($id, $auditStatus, $remark, $adminId, $profile, $now) {
            Db::table('sa_help_doctor_profile')->where('id', $id)->update([
                'audit_status' => $auditStatus,
                'audit_remark' => $remark,
                'audit_by' => $adminId > 0 ? $adminId : null,
                'audit_time' => $now,
                'approved_time' => $auditStatus === 1 ? $now : null,
                'updated_by' => $adminId > 0 ? $adminId : null,
                'update_time' => $now,
            ]);

            if ($auditStatus === 1) {
                Db::table('sa_help_member_profile')
                    ->where('member_id', (int) $profile['member_id'])
                    ->whereNull('delete_time')
                    ->update([
                        'member_role' => 'doctor',
                        'status' => 1,
                        'updated_by' => $adminId > 0 ? $adminId : null,
                        'update_time' => $now,
                    ]);
            }
        });

        return true;
    }
}
