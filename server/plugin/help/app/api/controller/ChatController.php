<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiuser\basic\BaseController;
use support\Request;
use support\Response;

#[Apidoc\Group('AI聊天')]
#[Apidoc\Title('HelpSupport AI聊天')]
class ChatController extends BaseController
{
    public function __construct(private readonly HelpApiService $service = new HelpApiService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('聊天模式概览')]
    #[Apidoc\Url('/app/help/chat/overview')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('modes', type: 'array', desc: '三种聊天模式及最近会话')]
    #[Apidoc\Returned('recent_sessions', type: 'array', desc: '最近会话')]
    public function overview(Request $request): Response
    {
        return ok($this->service->chatOverview($this->memberId));
    }

    #[Apidoc\Title('聊天配置')]
    #[Apidoc\Url('/app/help/chat/config')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Returned('list', type: 'array', desc: '会员自定义聊天提示词配置')]
    public function configs(Request $request): Response
    {
        return ok($this->service->chatConfigs($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存聊天配置')]
    #[Apidoc\Url('/app/help/chat/config')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('chat_mode', type: 'string', require: true, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Param('prompt_text', type: 'string', require: true, desc: '用户自定义提示词')]
    #[Apidoc\Returned('id', type: 'int', desc: '配置ID')]
    #[Apidoc\Returned('chat_mode', type: 'string', desc: '聊天模式')]
    public function saveConfig(Request $request): Response
    {
        return ok($this->service->saveChatConfig($this->memberId, $request->post()));
    }

    #[Apidoc\Title('聊天会话列表')]
    #[Apidoc\Url('/app/help/chat/sessions')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Query('keyword', type: 'string', require: false, desc: '关键词')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 20, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '会话列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function sessions(Request $request): Response
    {
        return ok($this->service->chatSessions($this->memberId, $request->get()));
    }

    #[Apidoc\Title('创建或更新聊天会话')]
    #[Apidoc\Url('/app/help/chat/session')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: false, desc: '会话ID，传入时更新')]
    #[Apidoc\Param('chat_mode', type: 'string', require: true, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Param('session_name', type: 'string', require: false, desc: '会话名称')]
    #[Apidoc\Param('is_pinned', type: 'int', require: false, default: 2, desc: '是否置顶 1是 2否')]
    #[Apidoc\Returned('id', type: 'int', desc: '会话ID')]
    #[Apidoc\Returned('session_name', type: 'string', desc: '会话名称')]
    public function saveSession(Request $request): Response
    {
        return ok($this->service->saveChatSession($this->memberId, $request->post()));
    }

    #[Apidoc\Title('删除聊天会话')]
    #[Apidoc\Url('/app/help/chat/session/delete')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('id', type: 'int', require: true, desc: '会话ID')]
    #[Apidoc\Returned('deleted', type: 'boolean', desc: '是否删除')]
    public function deleteSession(Request $request): Response
    {
        return ok($this->service->deleteChatSession($this->memberId, (int) $request->post('id', 0)));
    }

    #[Apidoc\Title('聊天记录列表')]
    #[Apidoc\Url('/app/help/chat/records')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('session_id', type: 'int', require: false, desc: '会话ID')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient')]
    #[Apidoc\Query('page', type: 'int', require: false, default: 1, desc: '页码')]
    #[Apidoc\Query('page_size', type: 'int', require: false, default: 50, desc: '每页数量')]
    #[Apidoc\Returned('list', type: 'array', desc: '聊天记录列表')]
    #[Apidoc\Returned('total', type: 'int', desc: '总数')]
    public function records(Request $request): Response
    {
        return ok($this->service->chatRecords($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存用户聊天消息')]
    #[Apidoc\Url('/app/help/chat/record')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('session_id', type: 'int', require: true, desc: '会话ID')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '消息内容')]
    #[Apidoc\Param('content_type', type: 'string', require: false, default: 'text', desc: '内容类型 text/image/file/voice')]
    #[Apidoc\Returned('id', type: 'int', desc: '消息ID')]
    #[Apidoc\Returned('message_time', type: 'datetime', desc: '消息时间')]
    public function saveRecord(Request $request): Response
    {
        return ok($this->service->saveUserChatRecord($this->memberId, $request->post()));
    }

    #[Apidoc\Title('发送在线AI消息')]
    #[Apidoc\Url('/app/help/chat/send')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('session_id', type: 'int', require: false, desc: '会话ID，不传时按 chat_mode 创建新会话')]
    #[Apidoc\Param('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient，创建新会话时必填')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '用户消息内容')]
    #[Apidoc\Param('config_id', type: 'int', require: false, default: 0, desc: '可选 SaiAI 模型配置ID')]
    #[Apidoc\Returned('session', type: 'object', desc: '会话信息')]
    #[Apidoc\Returned('user_record', type: 'object', desc: '用户消息')]
    #[Apidoc\Returned('assistant_record', type: 'object', desc: 'AI 回复消息')]
    public function send(Request $request): Response
    {
        return ok($this->service->sendChatMessage($this->memberId, $request->post()));
    }
}
