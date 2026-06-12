<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('本地模型')]
#[Apidoc\Title('HelpSupport本地模型')]
class LocalModelController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('模型目录')]
    #[Apidoc\Url('/app/help/local-model/catalog')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('code', type: 'string', require: false, desc: '模型编码')]
    #[Apidoc\Returned('list', type: 'array', desc: '可下载模型列表')]
    public function catalog(Request $request): Response
    {
        return ok($this->service->localModelCatalog($request->get()));
    }

    #[Apidoc\Title('模型提示词')]
    #[Apidoc\Url('/app/help/local-model/prompts')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('model_id', type: 'int', require: false, desc: '模型ID，空值返回通用提示词')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '语言')]
    #[Apidoc\Returned('list', type: 'array', desc: '提示词列表')]
    public function prompts(Request $request): Response
    {
        return ok($this->service->localModelPrompts($request->get()));
    }
}
