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
