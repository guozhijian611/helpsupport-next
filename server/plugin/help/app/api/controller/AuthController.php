<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpAuthService;
use plugin\saiadmin\basic\OpenController;
use support\Request;
use support\Response;

#[Apidoc\Group('会员认证')]
#[Apidoc\Title('HelpSupport会员认证')]
class AuthController extends OpenController
{
    public function __construct(private readonly HelpAuthService $service = new HelpAuthService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('账号密码登录')]
    #[Apidoc\Url('/app/help/auth/account-login')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('username', type: 'string', require: true, desc: '账号、邮箱或手机号')]
    #[Apidoc\Param('password', type: 'string', require: true, desc: '会员密码')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    #[Apidoc\Returned('member.member_level', type: 'object', desc: '当前会员等级，来源 sa_member_level')]
    #[Apidoc\Returned('member.member_levels', type: 'array', desc: 'App 可展示的有效会员等级配置列表')]
    #[Apidoc\Returned('member.member_level_progress', type: 'object', desc: '当前积分、下一等级和剩余积分进度')]
    public function accountLogin(Request $request): Response
    {
        return ok($this->service->accountLogin($request->post()));
    }

    #[Apidoc\Title('发送注册邮箱验证码')]
    #[Apidoc\Url('/app/help/auth/register-email-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '注册邮箱')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏邮箱')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendRegisterEmail(Request $request): Response
    {
        return ok($this->service->sendRegisterEmail($request->post()));
    }

    #[Apidoc\Title('发送注册手机验证码')]
    #[Apidoc\Url('/app/help/auth/register-phone-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('mobile', type: 'string', require: true, desc: '注册手机号')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏手机号')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendRegisterPhone(Request $request): Response
    {
        return ok($this->service->sendRegisterPhone($request->post()));
    }

    #[Apidoc\Title('发送找回密码邮箱验证码')]
    #[Apidoc\Url('/app/help/auth/forgot-email-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '找回密码邮箱')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏邮箱')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendForgotEmail(Request $request): Response
    {
        return ok($this->service->sendForgotEmail($request->post()));
    }

    #[Apidoc\Title('发送找回密码手机验证码')]
    #[Apidoc\Url('/app/help/auth/forgot-phone-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('mobile', type: 'string', require: true, desc: '找回密码手机号')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('target', type: 'string', desc: '脱敏手机号')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendForgotPhone(Request $request): Response
    {
        return ok($this->service->sendForgotPhone($request->post()));
    }

    #[Apidoc\Title('邮箱账号注册')]
    #[Apidoc\Url('/app/help/auth/account-register')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('register_type', type: 'string', require: false, default: 'email', desc: '注册方式 email/phone，不传时按字段推断')]
    #[Apidoc\Param('username', type: 'string', require: false, desc: '可选账号名，不传时自动生成')]
    #[Apidoc\Param('email', type: 'string', require: false, desc: '注册邮箱')]
    #[Apidoc\Param('mobile', type: 'string', require: false, desc: '注册手机号')]
    #[Apidoc\Param('password', type: 'string', require: true, desc: '登录密码')]
    #[Apidoc\Param('email_code', type: 'string', require: false, desc: '邮箱验证码')]
    #[Apidoc\Param('mobile_code', type: 'string', require: false, desc: '手机验证码')]
    #[Apidoc\Param('nickname', type: 'string', require: false, desc: '会员昵称')]
    #[Apidoc\Param('member_role', type: 'string', require: false, default: 'patient', desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    #[Apidoc\Returned('member.member_level', type: 'object', desc: '当前会员等级，来源 sa_member_level')]
    #[Apidoc\Returned('member.member_levels', type: 'array', desc: 'App 可展示的有效会员等级配置列表')]
    #[Apidoc\Returned('member.member_level_progress', type: 'object', desc: '当前积分、下一等级和剩余积分进度')]
    public function accountRegister(Request $request): Response
    {
        return ok($this->service->accountRegister($request->post()));
    }

    #[Apidoc\Title('找回密码')]
    #[Apidoc\Url('/app/help/auth/password-reset')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('reset_type', type: 'string', require: false, default: 'email', desc: '找回方式 email/phone，不传时按字段推断')]
    #[Apidoc\Param('email', type: 'string', require: false, desc: '找回邮箱')]
    #[Apidoc\Param('mobile', type: 'string', require: false, desc: '找回手机号')]
    #[Apidoc\Param('email_code', type: 'string', require: false, desc: '邮箱验证码')]
    #[Apidoc\Param('mobile_code', type: 'string', require: false, desc: '手机验证码')]
    #[Apidoc\Param('password', type: 'string', require: true, desc: '新密码')]
    #[Apidoc\Returned('reset', type: 'boolean', desc: '是否重置成功')]
    public function passwordReset(Request $request): Response
    {
        return ok($this->service->passwordReset($request->post()));
    }

    #[Apidoc\Title('Google登录')]
    #[Apidoc\Url('/app/help/auth/google')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('id_token', type: 'string', require: true, desc: 'Google Sign-In 返回的 ID Token')]
    #[Apidoc\Param('member_role', type: 'string', require: false, default: 'patient', desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    #[Apidoc\Returned('member.member_level', type: 'object', desc: '当前会员等级，来源 sa_member_level')]
    #[Apidoc\Returned('member.member_levels', type: 'array', desc: 'App 可展示的有效会员等级配置列表')]
    #[Apidoc\Returned('member.member_level_progress', type: 'object', desc: '当前积分、下一等级和剩余积分进度')]
    public function google(Request $request): Response
    {
        return ok($this->service->googleLogin($request->post()));
    }

    #[Apidoc\Title('Apple登录')]
    #[Apidoc\Url('/app/help/auth/apple')]
    #[Apidoc\Method('POST')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Param('identity_token', type: 'string', require: true, desc: 'Sign in with Apple 返回的 identityToken')]
    #[Apidoc\Param('full_name', type: 'string', require: false, desc: 'Apple 首次授权返回的姓名')]
    #[Apidoc\Param('member_role', type: 'string', require: false, default: 'patient', desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    #[Apidoc\Returned('member.member_level', type: 'object', desc: '当前会员等级，来源 sa_member_level')]
    #[Apidoc\Returned('member.member_levels', type: 'array', desc: 'App 可展示的有效会员等级配置列表')]
    #[Apidoc\Returned('member.member_level_progress', type: 'object', desc: '当前积分、下一等级和剩余积分进度')]
    public function apple(Request $request): Response
    {
        return ok($this->service->appleLogin($request->post()));
    }

    #[Apidoc\Title('刷新会员Token')]
    #[Apidoc\Url('/app/help/auth/refresh')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Returned('token', type: 'object', desc: '新的 Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    #[Apidoc\Returned('current_role', type: 'string', desc: '当前生效身份 patient/doctor')]
    #[Apidoc\Returned('role_flags', type: 'object', desc: '身份标记 profile_role/is_patient/is_doctor/doctor_profile_submitted/doctor_approved')]
    #[Apidoc\Returned('member.member_level', type: 'object', desc: '当前会员等级，来源 sa_member_level')]
    #[Apidoc\Returned('member.member_levels', type: 'array', desc: 'App 可展示的有效会员等级配置列表')]
    #[Apidoc\Returned('member.member_level_progress', type: 'object', desc: '当前积分、下一等级和剩余积分进度')]
    public function refresh(Request $request): Response
    {
        return ok($this->service->refreshToken());
    }
}
