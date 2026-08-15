<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpApiService;
use plugin\saiai\app\service\AiFactory;
use plugin\saiai\app\service\AliyunRealtimeConfig;
use plugin\saiuser\basic\BaseController;
use support\Log;
use support\Request;
use support\Response;
use Workerman\Protocols\Http\ServerSentEvents;

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
    #[Apidoc\Returned('modes', type: 'array', desc: '四种聊天模式、temp_save及最近会话')]
    #[Apidoc\Returned('recent_sessions', type: 'array', desc: '最近会话')]
    public function overview(Request $request): Response
    {
        return ok($this->service->chatOverview($this->memberId));
    }

    #[Apidoc\Title('聊天配置')]
    #[Apidoc\Url('/app/help/chat/config')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
    #[Apidoc\Returned('list', type: 'array', desc: '会员聊天提示词和临时字符串配置')]
    public function configs(Request $request): Response
    {
        return ok($this->service->chatConfigs($this->memberId, $request->get()));
    }

    #[Apidoc\Title('保存聊天配置')]
    #[Apidoc\Url('/app/help/chat/config')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('chat_mode', type: 'string', require: true, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
    #[Apidoc\Param('prompt_text', type: 'string', require: false, desc: '用户自定义提示词，与temp_save至少传一项')]
    #[Apidoc\Param('temp_save', type: 'string', require: false, desc: '临时字符串配置，在线聊天保存所选SAIAI配置ID')]
    #[Apidoc\Returned('id', type: 'int', desc: '配置ID')]
    #[Apidoc\Returned('chat_mode', type: 'string', desc: '聊天模式')]
    public function saveConfig(Request $request): Response
    {
        return ok($this->service->saveChatConfig($this->memberId, $request->post()));
    }

    #[Apidoc\Title('在线AI模型列表')]
    #[Apidoc\Url('/app/help/chat/models')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('id', type: 'int', desc: 'SAIAI配置ID')]
    #[Apidoc\Returned('name', type: 'string', desc: '后台配置名称')]
    #[Apidoc\Returned('type', type: 'string', desc: '平台类型')]
    #[Apidoc\Returned('model', type: 'string', desc: '模型名称')]
    #[Apidoc\Returned('is_default', type: 'boolean', desc: '是否默认模型')]
    public function models(Request $request): Response
    {
        return ok($this->service->onlineChatModels());
    }

    #[Apidoc\Title('AI机器人形象配置')]
    #[Apidoc\Url('/app/help/chat/robot-profiles')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('runtime_mode', type: 'string', require: false, default: 'online', desc: '运行模式 online/local')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
    #[Apidoc\Returned('list', type: 'array', desc: '按聊天模式返回机器人头像、显示名和简介')]
    public function robotProfiles(Request $request): Response
    {
        return ok($this->service->aiRobotProfiles($request->get()));
    }

    #[Apidoc\Title('移动端实时音视频配置')]
    #[Apidoc\Url('/app/help/chat/realtime-config')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Returned('ws_url', type: 'string', desc: '实时 WebSocket 地址')]
    #[Apidoc\Returned('default_model', type: 'string', desc: '默认实时模型')]
    #[Apidoc\Returned('default_session', type: 'object', desc: '默认实时会话参数')]
    #[Apidoc\Returned('config_id', type: 'int', desc: '默认 realtime 配置ID')]
    public function realtimeConfig(Request $request): Response
    {
        $config = AliyunRealtimeConfig::resolve(null);

        return ok([
            'ws_url' => $this->buildRealtimeProxyUrl($request),
            'default_model' => (string) ($config['model'] ?? AliyunRealtimeConfig::DEFAULT_MODEL),
            'default_session' => AliyunRealtimeConfig::defaultSession((array) ($config['options'] ?? [])),
            'config_id' => (int) ($config['id'] ?? 0),
        ]);
    }

    private function buildRealtimeProxyUrl(Request $request): string
    {
        $customUrl = trim((string) env('SAIAI_REALTIME_PUBLIC_URL', ''));
        if ($customUrl !== '') {
            return $customUrl;
        }

        $scheme = $this->isHttpsRequest($request) ? 'wss' : 'ws';
        $hostHeader = $this->resolveRequestHost($request) ?: '127.0.0.1';
        $hostParts = parse_url('//' . $hostHeader);
        $host = (string) ($hostParts['host'] ?? $hostHeader);
        $requestPort = isset($hostParts['port']) ? (int) $hostParts['port'] : null;
        $gatewayPort = (int) env('SAIAI_REALTIME_WS_PORT', 8791);

        $authority = $host;
        if ($scheme === 'wss') {
            if ($requestPort !== null && $requestPort !== 443 && $requestPort !== $gatewayPort) {
                $authority .= ':' . $requestPort;
            }
        } elseif ($gatewayPort !== 80) {
            $authority .= ':' . $gatewayPort;
        }

        return $scheme . '://' . $authority . '/v1/realtime';
    }

    private function isHttpsRequest(Request $request): bool
    {
        $forwardedProto = strtolower(trim(explode(',', (string) $request->header('x-forwarded-proto', ''))[0]));
        if ($forwardedProto === '') {
            $forwardedProto = strtolower(trim(explode(',', (string) $request->header('x-forwarded-protocol', ''))[0]));
        }

        return $forwardedProto === 'https'
            || strtolower((string) $request->header('x-forwarded-ssl', '')) === 'on'
            || strtolower((string) $request->header('front-end-https', '')) === 'on';
    }

    private function resolveRequestHost(Request $request): string
    {
        $forwardedHost = trim(explode(',', (string) $request->header('x-forwarded-host', ''))[0]);
        if ($forwardedHost !== '') {
            return $forwardedHost;
        }

        return (string) $request->host(true);
    }

    #[Apidoc\Title('聊天会话列表')]
    #[Apidoc\Url('/app/help/chat/sessions')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
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
    #[Apidoc\Param('chat_mode', type: 'string', require: true, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
    #[Apidoc\Param('session_name', type: 'string', require: false, desc: '会话名称')]
    #[Apidoc\Param('is_pinned', type: 'int', require: false, default: 2, desc: '是否置顶 1是 2否')]
    #[Apidoc\Param('locale', type: 'string', require: false, desc: '客户端语言，用于生成默认 AI 开场白')]
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
    #[Apidoc\Query('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor')]
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

    #[Apidoc\Title('保存实时通话AI消息')]
    #[Apidoc\Url('/app/help/chat/realtime/assistant-record')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('session_id', type: 'int', require: true, desc: '会话ID')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: 'AI消息内容')]
    #[Apidoc\Returned('id', type: 'int', desc: '消息ID')]
    #[Apidoc\Returned('message_time', type: 'datetime', desc: '消息时间')]
    public function saveRealtimeAssistantRecord(Request $request): Response
    {
        return ok($this->service->saveRealtimeAssistantChatRecord($this->memberId, $request->post()));
    }

    #[Apidoc\Title('AI派发计划任务')]
    #[Apidoc\Url('/app/help/chat/plan-task')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('record_id', type: 'int', require: true, desc: '包含计划卡片的AI消息ID')]
    #[Apidoc\Param('task_index', type: 'int', require: true, desc: '计划卡片索引，从0开始')]
    #[Apidoc\Param('task_date', type: 'string', require: false, desc: '任务日期 YYYY-MM-DD，默认今天')]
    #[Apidoc\Returned('task', type: 'object', desc: '已添加到我的计划的每日任务')]
    public function assignPlanTask(Request $request): Response
    {
        return ok($this->service->assignChatPlanTask($this->memberId, $request->post()));
    }

    #[Apidoc\Title('发送在线AI消息')]
    #[Apidoc\Url('/app/help/chat/send')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('session_id', type: 'int', require: false, desc: '会话ID，不传时按 chat_mode 创建新会话')]
    #[Apidoc\Param('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor，创建新会话时必填')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '用户消息内容')]
    #[Apidoc\Param('config_id', type: 'int', require: false, default: 0, desc: '可选 SaiAI 模型配置ID')]
    #[Apidoc\Returned('session', type: 'object', desc: '会话信息')]
    #[Apidoc\Returned('user_record', type: 'object', desc: '用户消息')]
    #[Apidoc\Returned('assistant_record', type: 'object', desc: 'AI 回复消息')]
    public function send(Request $request): Response
    {
        return ok($this->service->sendChatMessage($this->memberId, $request->post()));
    }

    #[Apidoc\Title('流式发送在线AI消息')]
    #[Apidoc\Url('/app/help/chat/send/stream')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('session_id', type: 'int', require: false, desc: '会话ID，不传时按 chat_mode 创建新会话')]
    #[Apidoc\Param('chat_mode', type: 'string', require: false, desc: '聊天模式 doctor/companion/patient/ai_doctor，创建新会话时必填')]
    #[Apidoc\Param('content', type: 'string', require: true, desc: '用户消息内容')]
    #[Apidoc\Param('config_id', type: 'int', require: false, default: 0, desc: '可选 SaiAI 模型配置ID')]
    #[Apidoc\Returned('event:start', type: 'object', desc: '返回会话与用户消息记录')]
    #[Apidoc\Returned('event:delta', type: 'object', desc: '返回 AI 回复增量文本')]
    #[Apidoc\Returned('event:done', type: 'object', desc: '返回已保存的 AI 回复消息')]
    public function sendStream(Request $request): void
    {
        $connection = $request->connection;
        $connection->send(new Response(200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no',
        ], "\r\n"));

        try {
            $context = $this->service->beginChatStream($this->memberId, $request->post());
            $this->sendSse($connection, 'start', [
                'session' => $context['session'],
                'user_record' => $context['user_record'],
            ]);

            $fullContent = '';
            $aiMeta = [
                'model' => '',
                'type' => '',
                'config_id' => (int) $context['config_id'],
            ];
            foreach (AiFactory::chatStreamByConfigId(
                (string) $context['ai_message'],
                (array) $context['history'],
                (int) $context['config_id']
            ) as $chunk) {
                $aiMeta['model'] = (string) ($chunk['model'] ?? $aiMeta['model']);
                $aiMeta['type'] = (string) ($chunk['platform_type'] ?? $aiMeta['type']);
                if (($chunk['type'] ?? '') !== 'content') {
                    continue;
                }

                $delta = (string) ($chunk['content'] ?? '');
                if ($delta === '') {
                    continue;
                }
                $fullContent .= $delta;
                $this->sendSse($connection, 'delta', [
                    'content' => $delta,
                    'model' => $aiMeta['model'],
                ]);
            }

            $result = $this->service->finishChatStream($this->memberId, $context, $fullContent, $aiMeta);
            $this->sendSse($connection, 'done', $result);
        } catch (\Throwable $e) {
            Log::error('[help.chat.stream] ' . $e->getMessage());
            $this->sendSse($connection, 'error', [
                'message' => $this->streamErrorMessage($e),
            ]);
        } finally {
            $connection->close();
        }
    }

    private function sendSse(mixed $connection, string $type, array $data = []): void
    {
        $connection->send(new ServerSentEvents([
            'event' => 'message',
            'data' => json_encode([
                'type' => $type,
                'data' => $data,
            ], JSON_UNESCAPED_UNICODE),
        ]));
    }

    private function streamErrorMessage(\Throwable $e): string
    {
        $message = trim($e->getMessage());
        return $message !== '' ? $message : 'AI 服务调用失败，请稍后重试';
    }
}
