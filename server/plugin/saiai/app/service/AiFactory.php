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
use Symfony\AI\Platform\Message\Message;
use Symfony\AI\Platform\Message\MessageBag;
use Symfony\AI\Platform\Result\TextResult;
use plugin\saiai\app\tool\DocTool;
use plugin\saiai\app\tool\DbTool;
use plugin\saiai\app\model\config\AiConfig;

class AiFactory
{
    private const REQUEST_TIMEOUT = 60;
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
        $httpClient = HttpClient::create([
            'timeout' => self::REQUEST_TIMEOUT,
            'max_duration' => self::REQUEST_TIMEOUT + 5,
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

    public static function chatOnce(string $message, array $history = [], ?string $model = null): array
    {
        return self::chatOnceWithResolved(
            self::resolveConfig(self::DEFAULT_CHAT_TYPE, $model),
            $message,
            $history
        );
    }

    public static function chatOnceByConfigId(string $message, array $history = [], int $configId = 0): array
    {
        if ($configId <= 0) {
            return self::chatOnce($message, $history);
        }

        $resolved = self::resolveConfigById($configId);
        return self::chatOnceWithResolved($resolved, $message, $history);
    }

    public static function chatStream(string $message, array $history = [], ?string $model = null): \Generator
    {
        $resolved = self::resolveConfig(self::DEFAULT_CHAT_TYPE, $model);
        yield from self::chatStreamWithResolved($resolved, $message, $history);
    }

    public static function chatStreamByConfigId(string $message, array $history = [], int $configId = 0): \Generator
    {
        if ($configId <= 0) {
            yield from self::chatStream($message, $history);
            return;
        }

        yield from self::chatStreamWithResolved(self::resolveConfigById($configId), $message, $history);
    }

    protected static function chatStreamWithResolved(array $resolved, string $message, array $history = []): \Generator
    {
        $resolvedModel = (string) $resolved['model'];
        $agent = self::createAgentFromResolved($resolved, false);
        $messages = self::buildChatMessages($message, $history);

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
            $fallback = self::chatOnceWithResolved($resolved, $message, $history);
            $fallbackContent = (string) ($fallback['content'] ?? '');
            if ($fallbackContent !== '') {
                yield [
                    'type' => 'content',
                    'content' => $fallbackContent,
                    'model' => (string) ($fallback['model'] ?? $resolvedModel),
                    'platform_type' => (string) $resolved['platformType'],
                ];
            }
        }

        yield [
            'type' => 'done',
            'model' => $resolvedModel,
            'platform_type' => (string) $resolved['platformType'],
        ];
    }

    protected static function chatOnceWithResolved(array $resolved, string $message, array $history = []): array
    {
        $resolvedModel = (string) $resolved['model'];
        $agent = self::createAgentFromResolved($resolved, false);
        $messages = self::buildChatMessages($message, $history);

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

    public static function resolveConfigById(int $configId): array
    {
        if ($configId <= 0) {
            return self::resolveConfig(self::DEFAULT_CHAT_TYPE);
        }

        $config = AiConfig::where('id', $configId)->where('status', 1)->findOrEmpty();
        if ($config->isEmpty()) {
            throw new ApiException('所选 AI 模型配置不存在或未启用，请在后台重新选择模型策略');
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
                break;
            default:
                throw new ApiException('不支持的模型平台：' . $platformType);
        }
    }

    protected static function normalizeApiUrl(string $apiUrl, string $platformType): string
    {
        $apiUrl = rtrim(trim($apiUrl), '/');
        if ($platformType !== 'generic' || $apiUrl === '') {
            return $apiUrl;
        }

        foreach ([
            '/v1/chat/completions',
            '/chat/completions',
            '/v1/embeddings',
            '/embeddings',
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

    protected static function buildChatMessages(string $message, array $history = []): MessageBag
    {
        $messages = [
            Message::forSystem('你是一个中文 AI 助手，请用简洁、清晰、可执行的方式回答用户。'),
        ];

        foreach ($history as $item) {
            $role = (string) ($item['role'] ?? '');
            $content = trim((string) ($item['content'] ?? ''));
            if ($content === '') {
                continue;
            }

            if ($role === 'assistant') {
                $messages[] = Message::ofAssistant($content);
                continue;
            }

            $messages[] = Message::ofUser($content);
        }

        $messages[] = Message::ofUser($message);

        return new MessageBag(...$messages);
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
