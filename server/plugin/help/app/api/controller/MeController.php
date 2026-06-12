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
    public function profile(Request $request): Response
    {
        return ok($this->service->profile($this->memberId, $this->memberInfo));
    }

    #[Apidoc\Title('保存我的资料')]
    #[Apidoc\Url('/app/help/me/profile')]
    #[Apidoc\Method('PUT')]
    #[Apidoc\Param('member_role', type: 'string', require: false, desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('gender', type: 'int', require: false, desc: '性别 1男 2女 3保密')]
    #[Apidoc\Param('birthday', type: 'string', require: false, desc: '生日 YYYY-MM-DD')]
    #[Apidoc\Param('bio', type: 'string', require: false, desc: '个人简介')]
    #[Apidoc\Param('recovery_goal', type: 'string', require: false, desc: '康复目标')]
    #[Apidoc\Param('trigger_tags', type: 'array', require: false, desc: '重点触发因素')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('id', type: 'int', desc: '资料ID')]
    public function saveProfile(Request $request): Response
    {
        return ok($this->service->saveProfile($this->memberId, $request->all()));
    }

    #[Apidoc\Title('上报已看引导页版本')]
    #[Apidoc\Url('/app/help/common/onboarding/seen')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('version', type: 'string', require: true, desc: '已看引导页版本')]
    #[Apidoc\Returned('onboarding_version', type: 'string', desc: '已记录版本')]
    public function onboardingSeen(Request $request): Response
    {
        return ok($this->service->markOnboardingSeen($this->memberId, (string) $request->post('version', '')));
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
}
