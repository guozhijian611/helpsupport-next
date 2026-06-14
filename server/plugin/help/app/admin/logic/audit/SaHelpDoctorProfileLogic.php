<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: your name
// +----------------------------------------------------------------------
namespace plugin\help\app\admin\logic\audit;

use plugin\help\app\service\HelpPushService;
use plugin\help\app\service\HelpAuditLogService;
use plugin\saiadmin\basic\think\BaseLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\help\app\model\audit\SaHelpDoctorProfile;
use think\facade\Db;
use Throwable;

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

    public function add(array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data);

        return parent::add($data);
    }

    public function edit($id, array $data): mixed
    {
        $data = $this->normalizeFields($data);
        $this->assertUnique($data, (int) $id);

        return parent::edit($id, $data);
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

            (new HelpAuditLogService())->record(
                'doctor_profile',
                $id,
                'audit',
                $profile['audit_status'] ?? null,
                $auditStatus,
                $remark,
                $adminId
            );
        });

        try {
            (new HelpPushService())->notifyMember((int) $profile['member_id'], 'doctor_audit_result', [
                'audit_status_text' => $auditStatus === 1 ? 'approved' : 'rejected',
                'audit_remark' => $remark,
            ], [
                'biz_type' => 'doctor_audit',
                'biz_id' => $id,
                'route' => '/pages/me/doctor-certification',
                'payload' => [
                    'audit_status' => $auditStatus,
                    'profile_id' => $id,
                ],
            ]);
        } catch (Throwable) {
            // 审核结果已落库，通知失败不阻断后台审核动作。
        }

        return true;
    }

    private function normalizeFields(array $data): array
    {
        if (array_key_exists('member_id', $data)) {
            $data['member_id'] = (int) $data['member_id'];
        }
        if (array_key_exists('certification_images', $data)) {
            $data['certification_images'] = $this->normalizeImageList($data['certification_images']);
        }

        return $data;
    }

    private function normalizeImageList(mixed $value): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        if (is_array($value) || is_object($value)) {
            return json_encode($value, JSON_UNESCAPED_UNICODE);
        }

        $text = trim((string) $value);
        if ($text === '') {
            return null;
        }

        $decoded = json_decode($text, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            if (is_string($decoded)) {
                return json_encode([$decoded], JSON_UNESCAPED_UNICODE);
            }
            return json_encode($decoded, JSON_UNESCAPED_UNICODE);
        }

        return json_encode([$text], JSON_UNESCAPED_UNICODE);
    }

    private function assertUnique(array $data, ?int $id = null): void
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        if ($memberId <= 0) {
            return;
        }

        $query = Db::table('sa_help_doctor_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time');
        if ($id !== null && $id > 0) {
            $query->where('id', '<>', $id);
        }

        if ($query->find()) {
            throw new ApiException('该会员的医生资质资料已存在');
        }
    }
}
