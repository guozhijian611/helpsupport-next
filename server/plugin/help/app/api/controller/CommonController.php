<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiadmin\basic\OpenController;
use support\Request;
use support\Response;

#[Apidoc\Group('公共配置')]
#[Apidoc\Title('HelpSupport公共配置')]
class CommonController extends OpenController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('App运行配置')]
    #[Apidoc\Url('/app/help/common/app-config')]
    #[Apidoc\Method('GET')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Returned('app', type: 'object', desc: 'App基础配置')]
    #[Apidoc\Returned('oauth', type: 'object', desc: '第三方登录客户端配置，不包含服务端私钥')]
    #[Apidoc\Returned('push', type: 'object', desc: '推送公开配置')]
    #[Apidoc\Returned('member_platforms', type: 'array', desc: '已初始化的第三方会员平台')]
    public function appConfig(Request $request): Response
    {
        return ok($this->service->appConfig());
    }

    #[Apidoc\Title('App引导页')]
    #[Apidoc\Url('/app/help/common/onboarding')]
    #[Apidoc\Method('GET')]
    #[Apidoc\NotHeaders]
    #[Apidoc\Query('scene', type: 'string', require: false, default: 'first_launch', desc: '引导场景')]
    #[Apidoc\Query('version', type: 'string', require: false, default: '', desc: '配置版本，空值读取通用配置')]
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '语言')]
    #[Apidoc\Returned('list', type: 'array', desc: '引导页列表')]
    public function onboarding(Request $request): Response
    {
        $scene = (string) $request->get('scene', 'first_launch');
        $version = (string) $request->get('version', '');
        $locale = (string) $request->get('locale', 'en-US');

        return ok($this->service->onboarding($scene, $version, $locale));
    }
}
