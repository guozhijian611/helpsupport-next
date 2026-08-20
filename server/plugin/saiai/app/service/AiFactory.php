<?php
// +----------------------------------------------------------------------
// | saiadmin [ saiadmin快速开发框架 ]
// +----------------------------------------------------------------------
// | Author: sai <1430792918@qq.com>
// +----------------------------------------------------------------------
namespace plugin\saiai\app\service;

use plugin\saiadmin\exception\ApiException;
use Symfony\Component\HttpClient\HttpClient;
use Symfony\AI\Platform\Bridge\Generic\Factory as GenericPlatformFactory;
use Symfony\AI\Platform\Bridge\Gemini\Factory as GeminiPlatformFactory;
use Symfony\AI\Platform\Bridge\OpenAi\Factory as OpenAIPlatformFactory;
use Symfony\AI\Platform\Bridge\DeepSeek\Factory as DeepPlatformFactory;
use Symfony\AI\Agent\Agent;
use Symfony\AI\Agent\Toolbox\AgentProcessor;
use Symfony\AI\Agent\Toolbox\Toolbox;
use Symfony\AI\Platform\Message\Content\ImageUrl;
use Symfony\AI\Platform\Message\Message;
use Symfony\AI\Platform\Message\MessageBag;
use Symfony\AI\Platform\Message\UserMessage;
use Symfony\AI\Platform\Result\TextResult;
use plugin\saiai\app\tool\DocTool;
use plugin\saiai\app\tool\DbTool;
use plugin\saiai\app\model\config\AiConfig;

class AiFactory
{
    private const REQUEST_TIMEOUT = 3600;
    private const IMAGE_REQUEST_TIMEOUT = 120;

    public const DEFAULT_CHAT_TYPE = 'openai';
    public const DEFAULT_CHAT_MODEL = 'gpt-5.5';
    public const DEFAULT_IMAGE_MODEL = 'gpt-image-2';

    private const DEEPSEEK_MODELS = [
        'deepseek-chat',
        'deepseek-reasoner',
    ];

    public static function createAgent(string $type, ?string $model = null, bool $enableTools = true): Agent
    {
        return self::createAgentFromResolved(self::resolveConfig($type, $model), $enableTools);
    }

    public static function createAgentByConfigId(int $configId, bool $enableTools = true): Agent
    {
        return self::createAgentFromResolved(self::resolveConfigById($configId), $enableTools);
    }

    protected static function createAgentFromResolved(array $resolved, bool $enableTools = true): Agent
    {
        $apiUrl = $resolved['apiUrl'];
        $apiKey = $resolved['apiKey'];
        $resolvedModel = $resolved['model'];
        $platformType = $resolved['platformType'];
        $requestTimeout = max(1, (int) env('SAIAI_REQUEST_TIMEOUT', self::REQUEST_TIMEOUT));
        $httpClient = HttpClient::create([
            'timeout' => $requestTimeout,
            'max_duration' => $requestTimeout + 60,
        ]);

        switch ($platformType) {
            case 'generic':
                $platform = GenericPlatformFactory::createPlatform($apiUrl, $apiKey, $httpClient);
                break;
            case 'openai':
                $platform = OpenAIPlatformFactory::createPlatform($apiKey, $httpClient);
                break;
            case 'deepseek':
                $platform = DeepPlatformFactory::createPlatform($apiKey, $httpClient);
                break;
            case 'gemini':
                $platform = GeminiPlatformFactory::createPlatform($apiKey, $httpClient);
                break;
            default:
                throw new ApiException('不支持的模型平台：' . $platformType);
        }

        if (!$enableTools) {
            return new Agent($platform, $resolvedModel);
        }

        $toolbox = new Toolbox([
            new DocTool(),
            new DbTool(),
        ]);
        $agentProcessor = new AgentProcessor($toolbox);

        return new Agent($platform, $resolvedModel, [$agentProcessor], [$agentProcessor]);
    }

    public static function chatOnce(string $message, array $history = [], ?string $model = null, array $imageUrls = [], mixed $session = false): array
    {
        return self::chatOnceWithResolved(
            self::resolveConfig(self::DEFAULT_CHAT_TYPE, $model),
            $message,
            $history,
            $imageUrls,
            $session
        );
    }

    public static function chatOnceByConfigId(string $message, array $history = [], int $configId = 0, array $imageUrls = [], mixed $session = false): array
    {
        if ($configId <= 0) {
            return self::chatOnce($message, $history, null, $imageUrls, $session);
        }

        $resolved = self::resolveConfigById($configId);
        return self::chatOnceWithResolved($resolved, $message, $history, $imageUrls, $session);
    }

    public static function chatStream(string $message, array $history = [], ?string $model = null, array $imageUrls = [], mixed $session = false): \Generator
    {
        $resolved = self::resolveConfig(self::DEFAULT_CHAT_TYPE, $model);
        yield from self::chatStreamWithResolved($resolved, $message, $history, $imageUrls, $session);
    }

    public static function chatStreamByConfigId(string $message, array $history = [], int $configId = 0, array $imageUrls = [], mixed $session = false): \Generator
    {
        if ($configId <= 0) {
            yield from self::chatStream($message, $history, null, $imageUrls, $session);
            return;
        }

        yield from self::chatStreamWithResolved(self::resolveConfigById($configId), $message, $history, $imageUrls, $session);
    }

    public static function supportsChatSessionByConfigId(int $configId): bool
    {
        if ($configId <= 0) {
            return false;
        }

        try {
            return self::shouldPassChatSession(self::resolveConfigById($configId));
        } catch (\Throwable) {
            return false;
        }
    }

    protected static function chatStreamWithResolved(array $resolved, string $message, array $history = [], array $imageUrls = [], mixed $session = false): \Generator
    {
        if (self::shouldPassChatSession($resolved) && $session !== false) {
            yield from self::chatCompletionsStream($resolved, $message, $history, $imageUrls, $session);
            return;
        }

        $resolvedModel = (string) $resolved['model'];
        $agent = self::createAgentFromResolved($resolved, false);
        $messages = self::buildChatMessages($message, $history, $imageUrls);

        try {
            $response = $agent->call($messages, [
                'temperature' => 0.7,
                'stream' => true,
            ]);
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 对话服务调用失败'));
        }

        $hasContent = false;
        foreach ($response->getContent() as $content) {
            $text = self::normalizeTextResult($content);
            if ($text !== '') {
                $hasContent = true;
                yield [
                    'type' => 'content',
                    'content' => $text,
                    'model' => $resolvedModel,
                    'platform_type' => (string) $resolved['platformType'],
                ];
            }
        }

        if (!$hasContent) {
            $fallback = self::chatOnceWithResolved($resolved, $message, $history, $imageUrls, $session);
            $fallbackContent = (string) ($fallback['content'] ?? '');
            if ($fallbackContent !== '') {
                yield [
                    'type' => 'content',
                    'content' => $fallbackContent,
                    'model' => (string) ($fallback['model'] ?? $resolvedModel),
                    'platform_type' => (string) $resolved['platformType'],
                    'session' => $fallback['session'] ?? null,
                ];
            }
        }

        yield [
            'type' => 'done',
            'model' => $resolvedModel,
            'platform_type' => (string) $resolved['platformType'],
        ];
    }

    protected static function chatOnceWithResolved(array $resolved, string $message, array $history = [], array $imageUrls = [], mixed $session = false): array
    {
        if (self::shouldPassChatSession($resolved) && $session !== false) {
            return self::chatCompletionsOnce($resolved, $message, $history, $imageUrls, $session);
        }

        $resolvedModel = (string) $resolved['model'];
        $agent = self::createAgentFromResolved($resolved, false);
        $messages = self::buildChatMessages($message, $history, $imageUrls);

        try {
            $response = $agent->call($messages, [
                'temperature' => 0.7,
            ]);
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 对话服务调用失败'));
        }

        return [
            'content' => self::normalizeTextResult($response->getContent()),
            'model' => $resolvedModel,
            'type' => (string) $resolved['platformType'],
            'session' => null,
        ];
    }

    public static function generateImage(string $prompt, ?string $model = null, string $size = '1024x1024'): array
    {
        $resolved = self::resolveConfig(self::DEFAULT_CHAT_TYPE, $model ?: self::DEFAULT_IMAGE_MODEL);
        return self::generateImageWithResolved($resolved, $prompt, $size);
    }

    public static function generateImageByConfigId(string $prompt, int $configId = 0, string $size = '1024x1024'): array
    {
        if ($configId <= 0) {
            return self::generateImage($prompt, self::DEFAULT_IMAGE_MODEL, $size);
        }

        return self::generateImageWithResolved(self::resolveConfigById($configId), $prompt, $size);
    }

    protected static function generateImageWithResolved(array $resolved, string $prompt, string $size = '1024x1024'): array
    {
        $apiUrl = self::buildImageGenerationUrl($resolved['apiUrl'], $resolved['platformType']);
        $httpClient = HttpClient::create([
            'timeout' => self::IMAGE_REQUEST_TIMEOUT,
            'max_duration' => self::IMAGE_REQUEST_TIMEOUT + 10,
        ]);

        try {
            $response = $httpClient->request('POST', $apiUrl, [
                'auth_bearer' => $resolved['apiKey'],
                'json' => [
                    'model' => $resolved['model'],
                    'prompt' => $prompt,
                    'n' => 1,
                    'size' => $size,
                ],
            ]);

            $data = $response->toArray(false);
            if ($response->getStatusCode() >= 400) {
                throw new ApiException(self::formatProviderError($data, 'AI 生图服务调用失败'));
            }
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 生图服务调用失败'));
        }

        $images = [];
        foreach (($data['data'] ?? []) as $item) {
            if (!empty($item['url'])) {
                $images[] = (string) $item['url'];
                continue;
            }

            if (!empty($item['b64_json'])) {
                $images[] = 'data:image/png;base64,' . $item['b64_json'];
            }
        }

        if ($images === []) {
            throw new ApiException('AI 生图服务未返回图片');
        }

        return [
            'images' => $images,
            'model' => $resolved['model'],
            'size' => $size,
            'revised_prompt' => (string) ($data['data'][0]['revised_prompt'] ?? ''),
        ];
    }

    public static function resolveConfig(string $type, ?string $model = null): array
    {
        $model = trim((string) $model);
        $config = $model !== ''
            ? AiConfig::where('model', $model)->where('status', 1)->findOrEmpty()
            : AiConfig::where('id', 0)->findOrEmpty();

        if ($config->isEmpty()) {
            $config = AiConfig::where('type', $type)->where('status', 1)->findOrEmpty();
        }
        if ($config->isEmpty()) {
            $config = AiConfig::where('is_default', 1)->where('status', 1)->findOrEmpty();
        }

        if ($config->isEmpty()) {
            if ($type === self::DEFAULT_CHAT_TYPE && env('OPENAI_API_KEY', '') !== '') {
                $apiUrl = self::normalizeApiUrl((string) env('OPENAI_BASE_URL', ''), $type);
                $apiKey = (string) env('OPENAI_API_KEY', '');
                $resolvedModel = $model !== '' ? $model : self::DEFAULT_CHAT_MODEL;
                self::validateConfig(self::DEFAULT_CHAT_TYPE, $resolvedModel, $apiUrl, $apiKey);

                return [
                    'apiUrl' => $apiUrl,
                    'apiKey' => $apiKey,
                    'model' => $resolvedModel,
                    'platformType' => self::DEFAULT_CHAT_TYPE,
                ];
            }

            throw new ApiException('未找到可用的 AI 配置，请先在后台启用模型配置');
        }

        return self::resolveConfigFromModel($config, $model);
    }

    public static function resolveConfigById(int $configId, bool $requireEnabled = true): array
    {
        if ($configId <= 0) {
            return self::resolveConfig(self::DEFAULT_CHAT_TYPE);
        }

        $query = AiConfig::where('id', $configId);
        if ($requireEnabled) {
            $query->where('status', 1);
        }
        $config = $query->findOrEmpty();
        if ($config->isEmpty()) {
            throw new ApiException($requireEnabled
                ? '所选 AI 模型配置不存在或未启用，请在后台重新选择模型策略'
                : '所选 AI 模型配置不存在');
        }

        return self::resolveConfigFromModel($config);
    }

    protected static function resolveConfigFromModel(AiConfig $config, ?string $model = null): array
    {
        $model = trim((string) $model);
        $platformType = trim((string) $config->type);
        $apiUrl = self::normalizeApiUrl((string) $config->ai_url, $platformType);
        $apiKey = trim((string) $config->ai_key) ?: (string) env('OPENAI_API_KEY', '');
        $resolvedModel = $model !== '' ? $model : trim((string) $config->model);

        self::validateConfig($platformType, $resolvedModel, $apiUrl, $apiKey);

        return [
            'apiUrl' => $apiUrl,
            'apiKey' => $apiKey,
            'model' => $resolvedModel,
            'platformType' => $platformType,
            'configId' => (int) $config->id,
            'configName' => (string) $config->name,
            'options' => self::decodeOptions($config->options ?? null),
        ];
    }

    protected static function validateConfig(string $platformType, string $model, string $apiUrl, string $apiKey): void
    {
        if ($apiKey === '') {
            throw new ApiException('当前 AI 配置缺少 API Key');
        }

        if ($model === '') {
            throw new ApiException('当前 AI 配置缺少模型名称');
        }

        switch ($platformType) {
            case 'generic':
                if ($apiUrl === '') {
                    throw new ApiException('Generic 平台必须配置 AI 接口基础地址');
                }
                break;
            case 'deepseek':
                if (!in_array($model, self::DEEPSEEK_MODELS, true)) {
                    throw new ApiException(sprintf(
                        'DeepSeek 平台仅支持模型：%s，当前配置为：%s',
                        implode('、', self::DEEPSEEK_MODELS),
                        $model
                    ));
                }
                break;
            case 'openai':
            case 'gemini':
            case 'asr':
            case 'tts':
            case 'realtime':
                break;
            default:
                throw new ApiException('不支持的模型平台：' . $platformType);
        }
    }

    protected static function normalizeApiUrl(string $apiUrl, string $platformType): string
    {
        $apiUrl = rtrim(trim($apiUrl), '/');
        if (!in_array($platformType, ['generic', 'asr', 'tts'], true) || $apiUrl === '') {
            return $apiUrl;
        }

        foreach ([
            '/v1/chat/completions',
            '/chat/completions',
            '/v1/embeddings',
            '/embeddings',
            '/v1/audio/transcriptions',
            '/audio/transcriptions',
            '/v1/audio/speech',
            '/audio/speech',
            '/v1',
        ] as $suffix) {
            if (str_ends_with(strtolower($apiUrl), $suffix)) {
                return substr($apiUrl, 0, -strlen($suffix));
            }
        }

        return $apiUrl;
    }

    protected static function normalizeTextResult(mixed $content): string
    {
        if (is_string($content)) {
            return $content;
        }

        if ($content instanceof \Traversable) {
            $text = '';
            foreach ($content as $item) {
                $text .= self::normalizeTextResult($item);
            }

            return $text;
        }

        if ($content instanceof TextResult) {
            return $content->getContent();
        }

        if (is_object($content) && method_exists($content, 'getDeltas')) {
            $text = '';
            foreach ($content->getDeltas() as $delta) {
                $text .= self::normalizeTextResult($delta);
            }

            return $text;
        }

        if (is_object($content) && method_exists($content, 'getText')) {
            return (string) $content->getText();
        }

        if ($content instanceof \Stringable) {
            return (string) $content;
        }

        if (is_object($content) && method_exists($content, 'getContent')) {
            $value = $content->getContent();
            return is_string($value) ? $value : self::normalizeTextResult($value);
        }

        return '';
    }

    protected static function buildChatMessages(string $message, array $history = [], array $imageUrls = []): MessageBag
    {
        $messages = [
            Message::forSystem('你是一个中文 AI 助手，请用简洁、清晰、可执行的方式回答用户。'),
        ];

        foreach ($history as $item) {
            $role = (string) ($item['role'] ?? '');
            $content = trim((string) ($item['content'] ?? ''));
            $historyImages = is_array($item['image_urls'] ?? null) ? $item['image_urls'] : [];
            if ($content === '' && $historyImages === []) {
                continue;
            }

            if ($role === 'assistant') {
                if ($content !== '') {
                    $messages[] = Message::ofAssistant($content);
                }
                continue;
            }

            $messages[] = self::userMessage($content, $historyImages);
        }

        $messages[] = self::userMessage($message, $imageUrls);

        return new MessageBag(...$messages);
    }

    /**
     * @param list<mixed> $imageUrls
     */
    protected static function userMessage(string $content, array $imageUrls = []): UserMessage
    {
        $parts = [];
        foreach ($imageUrls as $url) {
            $url = trim((string) $url);
            if (preg_match('/^https?:\/\//i', $url) === 1) {
                $parts[] = new ImageUrl($url);
            }
        }
        if ($content !== '') {
            $parts[] = $content;
        }
        if ($parts === []) {
            $parts[] = '';
        }

        return Message::ofUser(...$parts);
    }

    /**
     * Generic 自定义模型默认带 session；官方 OpenAI / DashScope / Gemini / DeepSeek 地址默认不带。
     * 可在 saiai_config.options 里用 pass_session=true/false 覆盖。
     */
    protected static function shouldPassChatSession(array $resolved): bool
    {
        $options = is_array($resolved['options'] ?? null) ? $resolved['options'] : [];
        if (array_key_exists('pass_session', $options)) {
            $value = $options['pass_session'];
            if (is_bool($value)) {
                return $value;
            }
            if (is_int($value) || is_float($value)) {
                return (int) $value === 1;
            }

            return filter_var($value, FILTER_VALIDATE_BOOLEAN);
        }
        if (($resolved['platformType'] ?? '') !== 'generic') {
            return false;
        }

        $url = strtolower((string) ($resolved['apiUrl'] ?? ''));
        if ($url === '') {
            return false;
        }
        foreach ([
            'api.openai.com',
            'openai.com',
            'dashscope.aliyuncs.com',
            'googleapis.com',
            'generativelanguage.googleapis.com',
            'api.deepseek.com',
            'deepseek.com',
        ] as $known) {
            if (str_contains($url, $known)) {
                return false;
            }
        }

        return true;
    }

    protected static function chatCompletionsOnce(array $resolved, string $message, array $history, array $imageUrls, mixed $session): array
    {
        try {
            return self::chatCompletionsOnceAttempt($resolved, $message, $history, $imageUrls, $session);
        } catch (ApiException $e) {
            if ($session !== null && self::isInvalidModelSessionError($e)) {
                return self::chatCompletionsOnceAttempt($resolved, $message, $history, $imageUrls, null);
            }
            throw $e;
        }
    }

    protected static function chatCompletionsOnceAttempt(array $resolved, string $message, array $history, array $imageUrls, mixed $session): array
    {
        $httpClient = self::chatHttpClient();
        $payload = self::chatCompletionsPayload($resolved, $message, $history, $imageUrls, $session, false);

        try {
            $response = $httpClient->request('POST', self::chatCompletionsUrl($resolved), self::chatHttpOptions($resolved, $payload));
            $data = $response->toArray(false);
            if ($response->getStatusCode() >= 400) {
                throw new ApiException(self::formatProviderError(is_array($data) ? $data : [], 'AI 对话服务调用失败'));
            }
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 对话服务调用失败'));
        }

        $content = self::extractChatCompletionsContent(is_array($data) ? $data : []);
        if ($content === '') {
            throw new ApiException('AI 未返回有效内容');
        }

        return [
            'content' => $content,
            'model' => (string) $resolved['model'],
            'type' => (string) $resolved['platformType'],
            'session' => self::extractChatSession(is_array($data) ? $data : []),
        ];
    }

    protected static function chatCompletionsStream(array $resolved, string $message, array $history, array $imageUrls, mixed $session): \Generator
    {
        try {
            yield from self::chatCompletionsStreamAttempt($resolved, $message, $history, $imageUrls, $session);
        } catch (ApiException $e) {
            if ($session !== null && self::isInvalidModelSessionError($e)) {
                yield from self::chatCompletionsStreamAttempt($resolved, $message, $history, $imageUrls, null);
                return;
            }
            throw $e;
        }
    }

    protected static function chatCompletionsStreamAttempt(array $resolved, string $message, array $history, array $imageUrls, mixed $session): \Generator
    {
        $httpClient = self::chatHttpClient();
        $payload = self::chatCompletionsPayload($resolved, $message, $history, $imageUrls, $session, true);
        $options = self::chatHttpOptions($resolved, $payload);
        $options['headers']['Accept'] = 'text/event-stream';

        try {
            $response = $httpClient->request('POST', self::chatCompletionsUrl($resolved), $options);
            $status = $response->getStatusCode();
            $contentType = strtolower((string) ($response->getHeaders(false)['content-type'][0] ?? ''));
            if ($status >= 400) {
                $data = json_decode($response->getContent(false), true);
                throw new ApiException(self::formatProviderError(is_array($data) ? $data : [], 'AI 对话服务调用失败'));
            }
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 对话服务调用失败'));
        }

        $resolvedModel = (string) $resolved['model'];
        $platformType = (string) $resolved['platformType'];
        $sessionId = is_string($session) && trim($session) !== '' ? trim($session) : null;
        $hasContent = false;

        if (!str_contains($contentType, 'text/event-stream')) {
            $data = $response->toArray(false);
            $content = self::extractChatCompletionsContent(is_array($data) ? $data : []);
            $sessionId = self::extractChatSession(is_array($data) ? $data : []) ?? $sessionId;
            if ($content === '') {
                throw new ApiException('AI 未返回有效内容');
            }
            yield [
                'type' => 'content',
                'content' => $content,
                'model' => $resolvedModel,
                'platform_type' => $platformType,
                'session' => $sessionId,
            ];
            yield [
                'type' => 'done',
                'model' => $resolvedModel,
                'platform_type' => $platformType,
                'session' => $sessionId,
            ];
            return;
        }

        $buffer = '';
        try {
            foreach ($httpClient->stream($response) as $chunk) {
                $buffer .= $chunk->getContent();
                while (($pos = strpos($buffer, "\n")) !== false) {
                    $line = rtrim(substr($buffer, 0, $pos), "\r");
                    $buffer = substr($buffer, $pos + 1);
                    if (!str_starts_with($line, 'data:')) {
                        continue;
                    }
                    $raw = trim(substr($line, 5));
                    if ($raw === '' || $raw === '[DONE]') {
                        continue;
                    }
                    $data = json_decode($raw, true);
                    if (!is_array($data)) {
                        continue;
                    }
                    if (isset($data['error'])) {
                        throw new ApiException(self::formatProviderError($data, 'AI 对话服务调用失败'));
                    }
                    $sessionId = self::extractChatSession($data) ?? $sessionId;
                    $delta = self::extractChatCompletionsDelta($data);
                    if ($delta === '') {
                        continue;
                    }
                    $hasContent = true;
                    yield [
                        'type' => 'content',
                        'content' => $delta,
                        'model' => $resolvedModel,
                        'platform_type' => $platformType,
                        'session' => $sessionId,
                    ];
                }
            }
        } catch (ApiException $e) {
            throw $e;
        } catch (\Throwable $e) {
            throw new ApiException(self::formatThrowableError($e, 'AI 对话服务调用失败'));
        }

        if (!$hasContent) {
            $fallback = self::chatCompletionsOnce($resolved, $message, $history, $imageUrls, $sessionId);
            $fallbackContent = (string) ($fallback['content'] ?? '');
            $sessionId = $fallback['session'] ?? $sessionId;
            if ($fallbackContent !== '') {
                yield [
                    'type' => 'content',
                    'content' => $fallbackContent,
                    'model' => $resolvedModel,
                    'platform_type' => $platformType,
                    'session' => $sessionId,
                ];
            }
        }

        yield [
            'type' => 'done',
            'model' => $resolvedModel,
            'platform_type' => $platformType,
            'session' => $sessionId,
        ];
    }

    /**
     * @param list<mixed> $imageUrls
     * @return array<string, mixed>
     */
    protected static function chatCompletionsPayload(array $resolved, string $message, array $history, array $imageUrls, mixed $session, bool $stream): array
    {
        $messages = [];
        foreach ($history as $item) {
            $role = (string) ($item['role'] ?? 'user');
            if (!in_array($role, ['system', 'user', 'assistant'], true)) {
                $role = 'user';
            }
            $content = trim((string) ($item['content'] ?? ''));
            $historyImages = is_array($item['image_urls'] ?? null) ? $item['image_urls'] : [];
            if ($content === '' && $historyImages === []) {
                continue;
            }
            if ($role === 'assistant' || $role === 'system') {
                $messages[] = ['role' => $role, 'content' => $content];
                continue;
            }
            $messages[] = self::openAiUserPayload($content, $historyImages);
        }
        $messages[] = self::openAiUserPayload($message, $imageUrls);

        $payload = [
            'model' => (string) $resolved['model'],
            'messages' => $messages,
            'temperature' => 0.7,
            'session' => is_string($session) && trim($session) !== '' ? trim($session) : null,
        ];
        if ($stream) {
            $payload['stream'] = true;
        }

        return $payload;
    }

    /**
     * @param list<mixed> $imageUrls
     * @return array{role:string,content:mixed}
     */
    protected static function openAiUserPayload(string $content, array $imageUrls = []): array
    {
        $parts = [];
        foreach ($imageUrls as $url) {
            $url = trim((string) $url);
            if (preg_match('/^https?:\/\//i', $url) === 1) {
                $parts[] = [
                    'type' => 'image_url',
                    'image_url' => ['url' => $url],
                ];
            }
        }
        if ($parts === []) {
            return ['role' => 'user', 'content' => $content];
        }
        if ($content !== '') {
            $parts[] = ['type' => 'text', 'text' => $content];
        }

        return ['role' => 'user', 'content' => $parts];
    }

    /**
     * @return array<string, mixed>
     */
    protected static function chatHttpOptions(array $resolved, array $payload): array
    {
        $options = [
            'headers' => [
                'Content-Type' => 'application/json',
            ],
            'json' => $payload,
        ];
        $apiKey = trim((string) ($resolved['apiKey'] ?? ''));
        if ($apiKey !== '') {
            $options['auth_bearer'] = $apiKey;
        }

        return $options;
    }

    protected static function chatHttpClient(): \Symfony\Contracts\HttpClient\HttpClientInterface
    {
        $requestTimeout = max(1, (int) env('SAIAI_REQUEST_TIMEOUT', self::REQUEST_TIMEOUT));

        return HttpClient::create([
            'timeout' => $requestTimeout,
            'max_duration' => $requestTimeout + 60,
        ]);
    }

    protected static function chatCompletionsUrl(array $resolved): string
    {
        $apiUrl = rtrim((string) ($resolved['apiUrl'] ?? ''), '/');
        if ($apiUrl === '') {
            throw new ApiException('Generic 平台必须配置 AI 接口基础地址');
        }
        if (str_ends_with(strtolower($apiUrl), '/chat/completions')) {
            return $apiUrl;
        }

        return $apiUrl . '/v1/chat/completions';
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function extractChatSession(array $data): ?string
    {
        foreach (['session', 'session_id'] as $key) {
            $value = $data[$key] ?? null;
            if (is_int($value) || is_float($value)) {
                $value = (string) $value;
            }
            if (!is_string($value)) {
                continue;
            }
            $value = trim($value);
            if ($value !== '') {
                return $value;
            }
        }

        return null;
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function extractChatCompletionsContent(array $data): string
    {
        $content = $data['choices'][0]['message']['content'] ?? $data['content'] ?? '';
        if (is_array($content)) {
            $text = '';
            foreach ($content as $part) {
                if (is_string($part)) {
                    $text .= $part;
                    continue;
                }
                if (is_array($part)) {
                    $text .= (string) ($part['text'] ?? $part['content'] ?? '');
                }
            }
            return trim($text);
        }

        return trim((string) $content);
    }

    /**
     * @param array<string, mixed> $data
     */
    protected static function extractChatCompletionsDelta(array $data): string
    {
        $delta = $data['choices'][0]['delta']['content']
            ?? $data['choices'][0]['delta']['text']
            ?? $data['choices'][0]['text']
            ?? '';

        return is_string($delta) ? $delta : '';
    }

    protected static function isInvalidModelSessionError(ApiException $e): bool
    {
        $message = strtolower($e->getMessage());

        return str_contains($message, 'invalid session')
            || str_contains($message, 'session not found')
            || str_contains($message, 'session expired')
            || str_contains($message, 'unknown session');
    }

    protected static function buildImageGenerationUrl(string $apiUrl, string $platformType): string
    {
        $apiUrl = rtrim($apiUrl, '/');
        if ($platformType === 'openai' && $apiUrl === '') {
            return 'https://api.openai.com/v1/images/generations';
        }

        if ($apiUrl === '') {
            throw new ApiException('AI 图片配置缺少接口基础地址');
        }

        if (str_ends_with(strtolower($apiUrl), '/images/generations')) {
            return $apiUrl;
        }

        return $apiUrl . '/v1/images/generations';
    }

    /**
     * @return array<string, mixed>
     */
    protected static function decodeOptions(mixed $options): array
    {
        if (is_array($options)) {
            return $options;
        }
        $raw = trim((string) $options);
        if ($raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true);

        return is_array($decoded) ? $decoded : [];
    }

    protected static function formatProviderError(array $data, string $fallback): string
    {
        $message = $data['error']['message'] ?? $data['message'] ?? '';
        $message = trim((string) $message);

        return $message !== '' ? $message : $fallback;
    }

    protected static function formatThrowableError(\Throwable $e, string $fallback): string
    {
        $message = trim($e->getMessage());
        if ($message === '') {
            return $fallback;
        }

        $lowerMessage = strtolower($message);
        if (str_contains($lowerMessage, 'model_not_found') || str_contains($lowerMessage, 'no available channel for model')) {
            $model = '';
            if (preg_match('/model\s+([^\s"\']+)/i', $message, $matches)) {
                $model = trim($matches[1]);
            }

            return $model !== ''
                ? "当前 AI 网关没有可用的 {$model} 模型通道，请检查 saiai 后台模型配置或上游网关分组通道"
                : '当前 AI 网关没有可用的模型通道，请检查 saiai 后台模型配置或上游网关分组通道';
        }

        return $message;
    }
}
