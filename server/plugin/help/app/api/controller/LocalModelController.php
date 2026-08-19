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
    #[Apidoc\Query('capability', type: 'string', require: false, desc: '能力类型 llm/asr/tts')]
    #[Apidoc\Returned('list', type: 'array', desc: '可下载模型列表')]
    public function catalog(Request $request): Response
    {
        return ok($this->service->localModelCatalog($request->get()));
    }

    #[Apidoc\Title('模型提示词')]
    #[Apidoc\Url('/app/help/local-model/prompts')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('model_id', type: 'int', require: false, desc: '模型ID，空值返回通用提示词')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
    #[Apidoc\Query('locale', type: 'string', require: false, default: 'en-US', desc: '语言')]
    #[Apidoc\Returned('list', type: 'array', desc: '提示词列表')]
    public function prompts(Request $request): Response
    {
        return ok($this->service->localModelPrompts($request->get()));
    }

    #[Apidoc\Title('上报模型下载日志')]
    #[Apidoc\Url('/app/help/local-model/download-log')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('model_id', type: 'int', require: false, desc: '模型目录ID，与model_code至少传一个')]
    #[Apidoc\Param('model_code', type: 'string', require: false, desc: '模型编码，与model_id至少传一个')]
    #[Apidoc\Param('platform', type: 'string', require: false, desc: '客户端平台 ios/android')]
    #[Apidoc\Param('app_version', type: 'string', require: false, desc: 'App版本')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '客户端语言')]
    #[Apidoc\Param('download_status', type: 'string', require: true, desc: '下载状态 started/success/failed/canceled')]
    #[Apidoc\Param('downloaded_size', type: 'int', require: false, desc: '已下载大小')]
    #[Apidoc\Param('duration_seconds', type: 'int', require: false, desc: '下载耗时秒')]
    #[Apidoc\Param('sha256', type: 'string', require: false, desc: '客户端下载后校验 SHA256')]
    #[Apidoc\Param('error_code', type: 'string', require: false, desc: '错误码')]
    #[Apidoc\Param('error_message', type: 'string', require: false, desc: '错误摘要，不上传敏感内容')]
    #[Apidoc\Returned('id', type: 'int', desc: '日志ID')]
    public function saveDownloadLog(Request $request): Response
    {
        return ok($this->service->saveLocalModelDownloadLog($this->memberId, $request->post()));
    }
}
