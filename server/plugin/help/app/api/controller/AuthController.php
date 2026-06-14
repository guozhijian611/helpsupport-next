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
    #[Apidoc\Param('username', type: 'string', require: true, desc: '会员用户名')]
    #[Apidoc\Param('password', type: 'string', require: true, desc: '会员密码')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    public function accountLogin(Request $request): Response
    {
        return ok($this->service->accountLogin($request->post()));
    }

    #[Apidoc\Title('发送注册邮箱验证码')]
    #[Apidoc\Url('/app/help/auth/register-email-code')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '注册邮箱')]
    #[Apidoc\Returned('sent', type: 'boolean', desc: '是否发送成功')]
    #[Apidoc\Returned('email', type: 'string', desc: '脱敏邮箱')]
    #[Apidoc\Returned('expires_in', type: 'int', desc: '验证码有效期秒数')]
    #[Apidoc\Returned('resend_after', type: 'int', desc: '再次发送等待秒数')]
    public function sendRegisterEmail(Request $request): Response
    {
        return ok($this->service->sendRegisterEmail($request->post()));
    }

    #[Apidoc\Title('邮箱账号注册')]
    #[Apidoc\Url('/app/help/auth/account-register')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('username', type: 'string', require: true, desc: '会员用户名')]
    #[Apidoc\Param('email', type: 'string', require: true, desc: '注册邮箱')]
    #[Apidoc\Param('password', type: 'string', require: true, desc: '登录密码')]
    #[Apidoc\Param('email_code', type: 'string', require: true, desc: '邮箱验证码')]
    #[Apidoc\Param('nickname', type: 'string', require: false, desc: '会员昵称')]
    #[Apidoc\Param('member_role', type: 'string', require: false, default: 'patient', desc: '业务身份 patient/doctor')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '语言')]
    #[Apidoc\Param('timezone', type: 'string', require: false, desc: '时区')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    public function accountRegister(Request $request): Response
    {
        return ok($this->service->accountRegister($request->post()));
    }

    #[Apidoc\Title('Google登录')]
    #[Apidoc\Url('/app/help/auth/google')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id_token', type: 'string', require: true, desc: 'Google Sign-In 返回的 ID Token')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
    public function google(Request $request): Response
    {
        return ok($this->service->googleLogin($request->post()));
    }

    #[Apidoc\Title('Apple登录')]
    #[Apidoc\Url('/app/help/auth/apple')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('identity_token', type: 'string', require: true, desc: 'Sign in with Apple 返回的 identityToken')]
    #[Apidoc\Param('full_name', type: 'string', require: false, desc: 'Apple 首次授权返回的姓名')]
    #[Apidoc\Returned('token', type: 'object', desc: 'Bearer access_token 与 refresh_token')]
    #[Apidoc\Returned('member', type: 'object', desc: '会员基础资料')]
    #[Apidoc\Returned('profile', type: 'object', desc: 'HelpSupport会员扩展资料')]
    #[Apidoc\Returned('doctor_profile', type: 'object', desc: '医生认证资料')]
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
    public function refresh(Request $request): Response
    {
        return ok($this->service->refreshToken());
    }
}
