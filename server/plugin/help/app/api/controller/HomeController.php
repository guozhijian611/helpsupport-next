<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('首页')]
#[Apidoc\Title('HelpSupport首页')]
class HomeController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('首页摘要')]
    #[Apidoc\Url('/app/help/home/summary')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('profile', type: 'object', desc: '会员扩展资料')]
    #[Apidoc\Returned('unread_message_count', type: 'int', desc: '未读消息数')]
    #[Apidoc\Returned('today_tasks', type: 'array', desc: '今日任务列表')]
    #[Apidoc\Returned('upcoming_appointments', type: 'array', desc: '最近预约列表')]
    public function summary(Request $request): Response
    {
        return ok($this->service->homeSummary($this->memberId));
    }
}
