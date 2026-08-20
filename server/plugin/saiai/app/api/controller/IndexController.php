<?php

namespace plugin\saiai\app\api\controller;

use plugin\saiai\app\api\logic\ChatGroupLogic;
use plugin\saiai\app\api\logic\ChatLogic;
use plugin\saiai\app\api\logic\IndexLogic;
use plugin\saiai\app\model\chat\AiChat;
use plugin\saiai\app\service\AiFactory;
use plugin\saiadmin\basic\BaseController;
use support\Cache;
use support\Log;
use support\Request;
use support\Response;
use Symfony\AI\Platform\Message\Message;
use Symfony\AI\Platform\Message\MessageBag;
use Workerman\Protocols\Http\ServerSentEvents;

class IndexController extends BaseController
{
    private const DIALOG_SESSION_TTL = 86400 * 7;

    public function __construct()
    {
        $this->logic = new IndexLogic();
        parent::__construct();
    }

    public function index(Request $request): void
    {
        $connection = $request->connection;

        $connection->send(new Response(200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no',
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Credentials' => 'true',
        ], "\r\n"));

        $this->sendSse($connection, 'start', null);

        $userMessage = trim((string) $request->input('message', '你好，介绍一下自己'));
        $type = (string) $request->input('type', 'deepseek');
        $model = $request->input('model');
        $configId = (int) $request->input('config_id', 0);
        $debug = $this->isDebugRequest($request);
        $groupId = (int) $request->input('group_id', 0);
        $userId = $this->adminId;
        $startedAt = microtime(true);

        if ($groupId <= 0) {
            $groupLogic = new ChatGroupLogic();
            $title = mb_substr($userMessage, 0, 10);
            $group = $groupLogic->createGroup($userId, $title);
            $groupId = (int) $group->id;
            $this->sendSse($connection, 'session_id', $groupId);
        }

        $chatLogic = new ChatLogic();
        $chatLogic->saveChat($userId, 'user', $userMessage, $type, (string) $groupId);

        $history = $this->chatHistoryForGroup($groupId);
        $sessionArg = $configId > 0 ? $this->loadDialogSession($groupId, $configId) : false;
        $reuseModelSession = is_string($sessionArg) && $sessionArg !== '';
        if ($reuseModelSession) {
            $history = [];
        }

        if ($debug) {
            try {
                $inspect = $configId > 0
                    ? AiFactory::inspectChatRequest($configId, $userMessage, $history, [], $sessionArg)
                    : [
                        'transport' => 'symfony_agent',
                        'platform_type' => $type,
                        'model' => (string) $model,
                        'pass_session' => false,
                        'session_in' => null,
                        'payload' => [
                            'messages' => [
                                ['role' => 'system', 'content' => '你是一个友好的AI助手，请用中文回答用户的问题。'],
                                ['role' => 'user', 'content' => $userMessage],
                            ],
                            'temperature' => 0.7,
                            'stream' => true,
                        ],
                    ];
            } catch (\Throwable $e) {
                $inspect = [
                    'error' => $e->getMessage(),
                    'config_id' => $configId,
                    'platform_type' => $type,
                    'model' => (string) $model,
                ];
            }
            $this->sendSse($connection, 'debug', [
                'phase' => 'request',
                'group_id' => $groupId,
                'debug' => $debug,
                ...$inspect,
            ]);
        }

        $fullContent = '';
        $chunkCount = 0;
        $sessionOut = is_string($sessionArg) ? $sessionArg : null;
        $streamError = '';

        try {
            $generator = $configId > 0
                ? $this->chatByConfig($userMessage, $history, $configId, $sessionArg)
                : $this->chat($userMessage, $type, is_string($model) ? $model : null);

            foreach ($generator as $chunk) {
                $data = json_decode($chunk, true);
                if (!is_array($data)) {
                    continue;
                }
                $eventType = (string) ($data['type'] ?? '');
                if ($eventType === 'content') {
                    $fullContent .= (string) ($data['data'] ?? '');
                    $chunkCount++;
                }
                if (!empty($data['session'])) {
                    $sessionOut = (string) $data['session'];
                }
                if ($eventType === 'error') {
                    $streamError = is_string($data['data'] ?? null) ? (string) $data['data'] : 'AI 服务调用失败';
                }
                $this->sendRawSse($connection, $chunk);
            }
        } catch (\Throwable $e) {
            $streamError = $this->formatChatError($e);
            Log::error(sprintf(
                '[saiai.chat] config_id=%s type=%s model=%s error=%s',
                $configId,
                $type,
                is_string($model) ? $model : '',
                $e->getMessage()
            ));
            $this->sendSse($connection, 'error', $streamError);
        }

        if ($sessionOut !== null && $sessionOut !== '' && $configId > 0) {
            $this->saveDialogSession($groupId, $configId, $sessionOut);
        }

        if ($fullContent !== '') {
            $chatLogic->saveChat($userId, 'assistant', $fullContent, $type, (string) $groupId);
        }

        if ($debug) {
            $this->sendSse($connection, 'debug', [
                'phase' => 'response',
                'group_id' => $groupId,
                'session_out' => $sessionOut,
                'elapsed_ms' => (int) round((microtime(true) - $startedAt) * 1000),
                'chunk_count' => $chunkCount,
                'content_length' => mb_strlen($fullContent),
                'error' => $streamError !== '' ? $streamError : null,
            ]);
        }

        $connection->close();
    }

    public function modelList(Request $request): Response
    {
        $list = $this->logic->modelList();
        return $this->success($list);
    }

    public function defaultModel(Request $request): Response
    {
        $data = $this->logic->getDefaultModel();
        return $this->success($data);
    }

    /**
     * @param list<array<string, mixed>> $history
     */
    protected function chatByConfig(string $userMessage, array $history, int $configId, mixed $session): \Generator
    {
        foreach (AiFactory::chatStreamByConfigId($userMessage, $history, $configId, [], $session) as $chunk) {
            $type = (string) ($chunk['type'] ?? '');
            if ($type === 'content') {
                yield $this->output('content', (string) ($chunk['content'] ?? ''), [
                    'session' => $chunk['session'] ?? null,
                    'model' => $chunk['model'] ?? '',
                ]);
                continue;
            }
            if ($type === 'done') {
                yield $this->output('done', '', [
                    'session' => $chunk['session'] ?? null,
                    'model' => $chunk['model'] ?? '',
                ]);
                continue;
            }
        }
    }

    protected function chat(string $userMessage, string $type, ?string $model = null): \Generator
    {
        try {
            $agent = AiFactory::createAgent($type, $model, false);

            $messages = new MessageBag(
                Message::forSystem('你是一个友好的AI助手，请用中文回答用户的问题。'),
                Message::ofUser($userMessage)
            );

            $response = $agent->call($messages, [
                'temperature' => 0.7,
                'stream' => true,
            ]);

            foreach ($response->getContent() as $content) {
                $text = $this->normalizeStreamContent($content);
                if ($text !== '') {
                    yield $this->output('content', $text);
                }
            }

            yield $this->output('done', '');
        } catch (\Throwable $e) {
            Log::error(sprintf(
                '[saiai.chat] type=%s model=%s error=%s',
                $type,
                $model ?: '',
                $e->getMessage()
            ));

            yield $this->output('error', $this->formatChatError($e));
        }
    }

    /**
     * @return list<array{role:string,content:string}>
     */
    private function chatHistoryForGroup(int $groupId, int $limit = 20): array
    {
        if ($groupId <= 0) {
            return [];
        }

        $records = AiChat::where('group_id', $groupId)
            ->whereIn('role', ['user', 'assistant'])
            ->order('id', 'desc')
            ->limit($limit + 1)
            ->select()
            ->toArray();
        $records = array_reverse($records);
        if ($records !== [] && ($records[count($records) - 1]['role'] ?? '') === 'user') {
            array_pop($records);
        }

        $history = [];
        foreach ($records as $record) {
            $content = trim((string) ($record['content'] ?? ''));
            if ($content === '') {
                continue;
            }
            $history[] = [
                'role' => (string) ($record['role'] ?? 'user'),
                'content' => $content,
            ];
        }

        return $history;
    }

    private function loadDialogSession(int $groupId, int $configId): mixed
    {
        if ($groupId <= 0 || $configId <= 0 || !AiFactory::supportsChatSessionByConfigId($configId)) {
            return false;
        }
        $stored = Cache::get($this->dialogSessionKey($groupId, $configId));
        $value = is_string($stored) ? trim($stored) : '';

        return $value !== '' ? $value : null;
    }

    private function saveDialogSession(int $groupId, int $configId, string $session): void
    {
        if ($groupId <= 0 || $configId <= 0 || $session === '') {
            return;
        }
        Cache::set($this->dialogSessionKey($groupId, $configId), $session, self::DIALOG_SESSION_TTL);
    }

    private function dialogSessionKey(int $groupId, int $configId): string
    {
        return 'saiai:dialog_test:session:' . $groupId . ':' . $configId;
    }

    private function isDebugRequest(Request $request): bool
    {
        $value = $request->input('debug', false);
        if (is_bool($value)) {
            return $value;
        }
        if (is_int($value) || is_float($value)) {
            return (int) $value === 1;
        }

        return filter_var($value, FILTER_VALIDATE_BOOLEAN);
    }

    private function sendSse(mixed $connection, string $type, mixed $data): void
    {
        $this->sendRawSse($connection, $this->output($type, $data));
    }

    private function sendRawSse(mixed $connection, string $chunk): void
    {
        $connection->send(new ServerSentEvents([
            'event' => 'message',
            'data' => $chunk,
        ]));
    }

    /**
     * @param array<string, mixed> $extra
     */
    protected function output(string $type, mixed $data, array $extra = []): string
    {
        return json_encode(array_filter([
            'type' => $type,
            'data' => $data,
            ...$extra,
        ], static fn (mixed $value): bool => $value !== null), JSON_UNESCAPED_UNICODE);
    }

    protected function normalizeStreamContent(mixed $content): string
    {
        if (is_string($content)) {
            return $content;
        }

        if ($content instanceof \Stringable) {
            return (string) $content;
        }

        if (is_object($content) && method_exists($content, 'getText')) {
            return (string) $content->getText();
        }

        return '';
    }

    protected function formatChatError(\Throwable $e): string
    {
        $message = trim($e->getMessage());
        if ($message === '') {
            return 'AI 服务调用失败，请检查模型配置或稍后重试';
        }

        $lowerMessage = strtolower($message);
        if (str_contains($lowerMessage, '404') && str_contains($lowerMessage, 'page not found')) {
            return 'AI 接口地址配置不正确，请检查 ai_url 是否只填写基础地址';
        }

        if (str_contains($lowerMessage, 'no provider found for model')) {
            return '当前模型名称与所选平台不匹配，请检查后台模型配置';
        }

        return $message;
    }
}
