<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('我的')]
#[Apidoc\Title('HelpSupport我的资料')]
class MeController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('读取我的资料')]
    #[Apidoc\Url('/app/help/me/profile')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('member', type: 'object', desc: '父框架会员资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生资质资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    public function profile(Request $request): Response
    {
        return ok($this->service->profile($this->memberId, $this->memberInfo));
    }

    #[Apidoc\Title('保存我的资料')]
    #[Apidoc\Url('/app/help/me/profile/save')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('nickname', type: 'string', require: false, desc: '昵称/显示名称')]
    #[Apidoc\Param('member_role', type: 'string', require: false, desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('gender', type: 'int', require: false, desc: '性别 1男 2女 3保密')]
    #[Apidoc\Param('birthday', type: 'string', require: false, desc: '生日 YYYY-MM-DD')]
    #[Apidoc\Param('bio', type: 'string', require: false, desc: '个人简介')]
    #[Apidoc\Param('recovery_goal', type: 'string', require: false, desc: '康复目标')]
    #[Apidoc\Param('trigger_tags', type: 'array', require: false, desc: '重点触发因素')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('member', type: 'object', desc: '父框架会员资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生资质资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    public function saveProfile(Request $request): Response
    {
        return ok($this->service->saveProfile($this->memberId, $request->all()));
    }

    #[Apidoc\Title('上传或更换头像')]
    #[Apidoc\Url('/app/help/me/profile/avatar')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('file', type: 'file', require: true, desc: '头像图片文件')]
    #[Apidoc\Returned('member', type: 'object', desc: '父框架会员资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生资质资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    public function updateAvatar(Request $request): Response
    {
        return ok($this->service->updateProfileAvatar($this->memberId, $request));
    }

    #[Apidoc\Title('账号安全概览')]
    #[Apidoc\Url('/app/help/me/security')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('member', type: 'object', desc: '当前会员安全资料，含 email/mobile/has_password')]
    #[Apidoc\Returned('linked_accounts', type: 'array', desc: '已绑定账号列表，含 EMAIL/MOBILE/GOOGLE/APPLE')]
    #[Apidoc\Returned('devices', type: 'array', desc: '当前登录设备列表')]
    #[Apidoc\Returned('recent_logins', type: 'array', desc: '最近登录记录')]
    #[Apidoc\Returned('sso_enabled', type: 'boolean', desc: '是否启用单点登录')]
    #[Apidoc\Returned('active_device_count', type: 'int', desc: '当前活跃设备数量')]
    public function security(Request $request): Response
    {
        return ok($this->service->securityOverview($this->memberId));
    }

    #[Apidoc\Title('修改账号密码')]
    #[Apidoc\Url('/app/help/me/security/password')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('old_password', type: 'string', require: false, desc: '当前密码，已有密码账号修改时必填')]
    #[Apidoc\Param('new_password', type: 'string', require: true, desc: '新密码，至少 6 位')]
    #[Apidoc\Returned('changed', type: 'boolean', desc: '是否修改成功')]
    #[Apidoc\Returned('has_password', type: 'boolean', desc: '修改后是否已设置密码')]
    public function changePassword(Request $request): Response
    {
        return ok($this->service->changeSecurityPassword($this->memberId, $request->post()));
    }

    #[Apidoc\Title('发送绑定或更换邮箱验证码')]
    #[Apidoc\Url('/app/help/me/security/email-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '待绑定邮箱')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏邮箱')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendEmailCode(Request $request): Response
    {
        return ok($this->service->sendSecurityEmailCode($this->memberId, $request->post()));
    }

    #[Apidoc\Title('绑定或更换邮箱')]
    #[Apidoc\Url('/app/help/me/security/email')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '待绑定邮箱')]
    #[Apidoc\Param('email_code', type: 'string', require: true, desc: '邮箱验证码')]
    #[Apidoc\Returned('email', type: 'string', desc: '当前绑定邮箱')]
    #[Apidoc\Returned('email_bound', type: 'boolean', desc: '是否已绑定邮箱')]
    public function bindEmail(Request $request): Response
    {
        return ok($this->service->bindSecurityEmail($this->memberId, $request->post()));
    }

    #[Apidoc\Title('发送绑定手机号验证码')]
    #[Apidoc\Url('/app/help/me/security/mobile-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('mobile', type: 'string', require: true, desc: '待绑定手机号')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏手机号')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendMobileCode(Request $request): Response
    {
        return ok($this->service->sendSecurityMobileCode($this->memberId, $request->post()));
    }

    #[Apidoc\Title('绑定或更换手机号')]
    #[Apidoc\Url('/app/help/me/security/mobile')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('mobile', type: 'string', require: true, desc: '待绑定手机号')]
    #[Apidoc\Param('mobile_code', type: 'string', require: true, desc: '短信验证码')]
    #[Apidoc\Returned('mobile', type: 'string', desc: '当前绑定手机号')]
    #[Apidoc\Returned('mobile_bound', type: 'boolean', desc: '是否已绑定手机号')]
    public function bindMobile(Request $request): Response
    {
        return ok($this->service->bindSecurityMobile($this->memberId, $request->post()));
    }

    #[Apidoc\Title('下线其他设备')]
    #[Apidoc\Url('/app/help/me/security/logout-other-devices')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('current_device_id', type: 'string', require: false, desc: '当前设备标识，传入后保留当前设备')]
    #[Apidoc\Param('platform', type: 'string', require: false, desc: '当前设备平台 ios/android')]
    #[Apidoc\Returned('logged_out_devices', type: 'int', desc: '本次下线的设备数')]
    public function logoutOtherDevices(Request $request): Response
    {
        return ok($this->service->logoutOtherDevices($this->memberId, $request->post()));
    }

    #[Apidoc\Title('上传诊断日志')]
    #[Apidoc\Url('/app/help/me/diagnostic-log/upload')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('device_id', type: 'string', require: false, desc: '当前设备标识')]
    #[Apidoc\Param('platform', type: 'string', require: false, desc: '客户端平台 ios/android')]
    #[Apidoc\Param('app_version', type: 'string', require: false, desc: 'App 版本')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '客户端语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '客户端时区')]
    #[Apidoc\Param('source', type: 'string', require: false, default: 'manual', desc: '上传来源 manual/auto')]
    #[Apidoc\Param('first_log_at', type: 'string', require: false, desc: '首条日志时间 ISO8601')]
    #[Apidoc\Param('last_log_at', type: 'string', require: false, desc: '末条日志时间 ISO8601')]
    #[Apidoc\Param('entries', type: 'array', require: true, desc: '诊断日志条目列表')]
    #[Apidoc\Returned('id', type: 'int', desc: '上传记录 ID')]
    #[Apidoc\Returned('entry_count', type: 'int', desc: '本次保存的日志条数')]
    #[Apidoc\Returned('uploaded_at', type: 'string', desc: '服务端保存时间')]
    public function uploadDiagnosticLog(Request $request): Response
    {
        return ok($this->service->saveDiagnosticLogUpload($this->memberId, $request->post()));
    }

    #[Apidoc\Title('上报已看引导页版本')]
    #[Apidoc\Url('/app/help/common/onboarding/seen')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('version', type: 'string', require: false, default: '', desc: '已看引导页版本，空值表示默认版本')]
    #[Apidoc\Returned('onboarding_version', type: 'string', desc: '已记录版本')]
    public function onboardingSeen(Request $request): Response
    {
        return ok($this->service->markOnboardingSeen($this->memberId, (string) $request->post('version', '')));
    }

    #[Apidoc\Title('上传医生资质图片')]
    #[Apidoc\Url('/app/help/me/doctor-certification/upload-image')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('file', type: 'file', require: true, desc: '医生资质图片文件')]
    #[Apidoc\Returned('url', type: 'string', desc: '图片URL')]
    #[Apidoc\Returned('origin_name', type: 'string', desc: '原始文件名')]
    #[Apidoc\Returned('mime_type', type: 'string', desc: '文件 MIME 类型')]
    #[Apidoc\Returned('size_byte', type: 'int', desc: '文件大小')]
    public function uploadDoctorCertificationImage(Request $request): Response
    {
        return ok($this->service->uploadDoctorCertificationImage($request));
    }

    #[Apidoc\Title('提交医生资质')]
    #[Apidoc\Url('/app/help/me/doctor-certification')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('real_name', type: 'string', require: true, desc: '真实姓名')]
    #[Apidoc\Param('title', type: 'string', require: false, desc: '职称')]
    #[Apidoc\Param('hospital', type: 'string', require: false, desc: '医院/机构')]
    #[Apidoc\Param('department', type: 'string', require: false, desc: '科室')]
    #[Apidoc\Param('specialty', type: 'string', require: false, desc: '专业方向')]
    #[Apidoc\Param('license_no', type: 'string', require: true, desc: '执业证书编号')]
    #[Apidoc\Param('certification_images', type: 'array', require: false, desc: '证书图片')]
    #[Apidoc\Returned('audit_status', type: 'int', desc: '审核状态 0待审核 1通过 2拒绝')]
    public function doctorCertification(Request $request): Response
    {
        return ok($this->service->saveDoctorCertification($this->memberId, $request->all()));
    }

    #[Apidoc\Title('我的日记列表')]
    #[Apidoc\Url('/app/help/me/journals')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '日记列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function journals(Request $request): Response
    {
        return ok($this->service->journals($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存我的日记')]
    #[Apidoc\Url('/app/help/me/journal')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '日记ID，空为新增')]
    #[Apidoc\Param('entry_date', type: 'string', require: true, desc: '记录日期 YYYY-MM-DD')]
    #[Apidoc\Param('title', type: 'string', require: true, desc: '标题')]
    #[Apidoc\Param('content', type: 'string', require: false, desc: '内容')]
    #[Apidoc\Param('media', type: 'array', require: false, desc: '媒体列表')]
    #[Apidoc\Returned('id', type: 'int', desc: '日记ID')]
    #[Apidoc\Returned('entry_date', type: 'string', desc: '记录日期')]
    #[Apidoc\Returned('title', type: 'string', desc: '标题')]
    public function saveJournal(Request $request): Response
    {
        return ok($this->service->saveJournal($this->memberId, $request->post()));
    }

    #[Apidoc\Title('删除我的日记')]
    #[Apidoc\Url('/app/help/me/journal/delete')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '日记ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '日记ID')]
    #[Apidoc\Returned('deleted', type: 'boolean', desc: '是否删除成功')]
    public function deleteJournal(Request $request): Response
    {
        return ok($this->service->deleteJournal($this->memberId, (int) $request->post('id')));
    }

    #[Apidoc\Title('我的回忆录列表')]
    #[Apidoc\Url('/app/help/me/memoirs')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('source_month', type: 'string', require: false, desc: '来源月份 YYYY-MM')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '回忆录列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function memoirs(Request $request): Response
    {
        return ok($this->service->memoirs($this->memberId, $request->get()));
    }

    #[Apidoc\Title('我的回忆录详情')]
    #[Apidoc\Url('/app/help/me/memoir')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('id', type: 'int', require: true, desc: '回忆录ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '回忆录ID')]
    #[Apidoc\Returned('title', type: 'string', desc: '回忆录标题')]
    public function memoirDetail(Request $request): Response
    {
        return ok($this->service->memoirDetail($this->memberId, (int) $request->get('id')));
    }

    #[Apidoc\Title('回忆录生成配置')]
    #[Apidoc\Url('/app/help/me/memoir-configs')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('code', type: 'string', require: false, desc: '配置编码')]
    #[Apidoc\Query('generation_cycle', type: 'string', require: false, desc: '生成周期 weekly/monthly/quarterly')]
    #[Apidoc\Query('source_type', type: 'string', require: false, desc: '来源类型 journal/task/mixed')]
    #[Apidoc\Returned('list', type: 'array', desc: '启用的回忆录生成配置')]
    public function memoirConfigs(Request $request): Response
    {
        return ok($this->service->memoirConfigs($request->get()));
    }

    #[Apidoc\Title('我的荣誉徽章')]
    #[Apidoc\Url('/app/help/me/badges')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('status', type: 'int', require: false, default: 1, desc: '状态 1有效 2撤销')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '徽章列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function badges(Request $request): Response
    {
        return ok($this->service->memberBadges($this->memberId, $request->get()));
    }

    #[Apidoc\Title('我的积分流水')]
    #[Apidoc\Url('/app/help/me/points')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('change_type', type: 'string', require: false, desc: '变动类型 income/expense/adjust')]
    #[Apidoc\Query('source_type', type: 'string', require: false, desc: '来源类型')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('balance', type: 'int', desc: '当前积分余额')]
    #[Apidoc\Returned('list', type: 'array', desc: '积分流水')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function points(Request $request): Response
    {
        return ok($this->service->memberPointLogs($this->memberId, $request->get()));
    }

    #[Apidoc\Title('康复目标记录列表')]
    #[Apidoc\Url('/app/help/me/recovery-goals')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('status', type: 'int', require: false, desc: '状态 1进行中 2已完成 3已放弃')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '康复目标记录')]
    public function recoveryGoals(Request $request): Response
    {
        return ok($this->service->recoveryGoals($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存康复目标记录')]
    #[Apidoc\Url('/app/help/me/recovery-goal')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '记录ID，空为新增')]
    #[Apidoc\Param('goal_text', type: 'string', require: true, desc: '恢复目标')]
    #[Apidoc\Param('goal_type', type: 'string', require: false, default: 'custom', desc: '目标类型 custom/weekly/monthly')]
    #[Apidoc\Param('target_date', type: 'string', require: false, desc: '目标日期 YYYY-MM-DD')]
    #[Apidoc\Param('status', type: 'int', require: false, default: 1, desc: '状态 1进行中 2已完成 3已放弃')]
    #[Apidoc\Returned('id', type: 'int', desc: '记录ID')]
    public function saveRecoveryGoal(Request $request): Response
    {
        return ok($this->service->saveRecoveryGoal($this->memberId, $request->post()));
    }

    #[Apidoc\Title('删除康复目标记录')]
    #[Apidoc\Url('/app/help/me/recovery-goal/delete')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '记录ID')]
    #[Apidoc\Returned('deleted', type: 'boolean', desc: '是否删除成功')]
    public function deleteRecoveryGoal(Request $request): Response
    {
        return ok($this->service->deleteRecoveryGoal($this->memberId, (int) $request->post('id')));
    }

    #[Apidoc\Title('触发因素记录列表')]
    #[Apidoc\Url('/app/help/me/triggers')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('trigger_type', type: 'string', require: false, desc: '触发类型 emotion/place/person/custom')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '触发因素记录')]
    public function triggerLogs(Request $request): Response
    {
        return ok($this->service->triggerLogs($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存触发因素记录')]
    #[Apidoc\Url('/app/help/me/trigger')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '记录ID，空为新增')]
    #[Apidoc\Param('trigger_name', type: 'string', require: true, desc: '触发因素名称')]
    #[Apidoc\Param('trigger_type', type: 'string', require: false, default: 'custom', desc: '触发类型 emotion/place/person/custom')]
    #[Apidoc\Param('intensity', type: 'int', require: false, default: 0, desc: '强度 0-10')]
    #[Apidoc\Param('occurred_at', type: 'string', require: false, desc: '发生时间，空为当前时间')]
    #[Apidoc\Param('response_action', type: 'string', require: false, desc: '应对动作')]
    #[Apidoc\Param('note', type: 'string', require: false, desc: '记录说明')]
    #[Apidoc\Returned('id', type: 'int', desc: '记录ID')]
    public function saveTriggerLog(Request $request): Response
    {
        return ok($this->service->saveTriggerLog($this->memberId, $request->post()));
    }

    #[Apidoc\Title('删除触发因素记录')]
    #[Apidoc\Url('/app/help/me/trigger/delete')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '记录ID')]
    #[Apidoc\Returned('deleted', type: 'boolean', desc: '是否删除成功')]
    public function deleteTriggerLog(Request $request): Response
    {
        return ok($this->service->deleteTriggerLog($this->memberId, (int) $request->post('id')));
    }

    #[Apidoc\Title('我的消息列表')]
    #[Apidoc\Url('/app/help/me/messages')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('is_read', type: 'int', require: false, desc: '是否已读 1是 2否')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '消息列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    #[Apidoc\Returned('page', type: 'int', desc: '当前页码')]
    #[Apidoc\Returned('page_size', type: 'int', desc: '每页数量')]
    public function messages(Request $request): Response
    {
        return ok($this->service->messages($this->memberId, $request->get()));
    }

    #[Apidoc\Title('标记消息已读')]
    #[Apidoc\Url('/app/help/me/message/read')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('message_id', type: 'int', require: false, desc: '消息ID，空则按条件批量标记')]
    #[Apidoc\Param('all', type: 'int', require: false, desc: '是否全部标记 1是')]
    #[Apidoc\Returned('affected', type: 'int', desc: '标记已读的消息数量')]
    public function readMessage(Request $request): Response
    {
        return ok($this->service->readMessage($this->memberId, $request->all()));
    }
}
