<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiai\app\service\AiFactory;
use plugin\saiadmin\app\logic\system\SystemConfigLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\saiadmin\utils\Arr;

/**
 * 普通聊天语音转写与语音合成。
 *
 * 复用当前会话选中的 OpenAI 兼容配置，不与实时音视频链路共享连接。
 */
final class ChatSpeechService
{
    private const REQUEST_TIMEOUT = 120;

    public function transcribe(array $attachment, int $configId): string
    {
        $resolved = $this->resolveSpeechConfig($configId);
        $temporary = false;
        $filePath = $this->resolveAttachmentFile($attachment, $temporary);

        try {
            $response = $this->request(
                'POST',
                $this->speechEndpoint($resolved, 'transcriptions'),
                ['Authorization: Bearer ' . $resolved['apiKey']],
                [
                    'model' => (string) ($resolved['model'] ?? env('SAIAI_TRANSCRIPTION_MODEL', 'whisper-1')),
                    'file' => new \CURLFile(
                        $filePath,
                        (string) ($attachment['mime_type'] ?? 'audio/mp4'),
                        (string) ($attachment['origin_name'] ?? basename($filePath))
                    ),
                    'response_format' => 'json',
                ]
            );
        } finally {
            if ($temporary && is_file($filePath)) {
                @unlink($filePath);
            }
        }

        $data = json_decode($response['body'], true);
        $text = is_array($data) ? trim((string) ($data['text'] ?? '')) : '';
        if ($text === '') {
            throw new ApiException('语音转写未返回有效文本', 502);
        }

        return $text;
    }

    /**
     * @return array{audio_url:string,audio_mime_type:string}
     */
    public function synthesize(string $text, int $configId, string $voice = ''): array
    {
        $resolved = $this->resolveSpeechConfig($configId);
        $voice = trim($voice) !== '' ? trim($voice) : (string) env('SAIAI_SPEECH_VOICE', 'alloy');
        $response = $this->request(
            'POST',
            $this->speechEndpoint($resolved, 'speech'),
            [
                'Authorization: Bearer ' . $resolved['apiKey'],
                'Content-Type: application/json',
                'Accept: audio/mpeg',
            ],
            json_encode([
                'model' => (string) ($resolved['model'] ?? env('SAIAI_SPEECH_MODEL', 'gpt-4o-mini-tts')),
                'voice' => $voice,
                'input' => mb_substr($text, 0, 4096),
                'response_format' => 'mp3',
            ], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)
        );

        $mimeType = strtolower(trim((string) ($response['content_type'] ?? '')));
        if (str_contains($mimeType, 'json')) {
            $data = json_decode($response['body'], true);
            $message = is_array($data)
                ? trim((string) ($data['error']['message'] ?? $data['message'] ?? ''))
                : '';
            throw new ApiException($message !== '' ? $message : 'AI 语音合成失败', 502);
        }

        return [
            'audio_url' => $this->saveAudio($response['body']),
            'audio_mime_type' => $mimeType !== '' ? $mimeType : 'audio/mpeg',
        ];
    }

    /**
     * @return array{body:string,content_type:string}
     */
    private function request(string $method, string $url, array $headers, array|string $payload): array
    {
        $curl = curl_init($url);
        if ($curl === false) {
            throw new ApiException('无法初始化 AI 语音请求', 500);
        }

        curl_setopt_array($curl, [
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_CONNECTTIMEOUT => 12,
            CURLOPT_TIMEOUT => self::REQUEST_TIMEOUT,
        ]);

        $body = curl_exec($curl);
        $status = (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
        $contentType = (string) curl_getinfo($curl, CURLINFO_CONTENT_TYPE);
        $error = curl_error($curl);
        curl_close($curl);

        if (!is_string($body)) {
            throw new ApiException($error !== '' ? $error : 'AI 语音服务请求失败', 502);
        }
        if ($status < 200 || $status >= 300) {
            $data = json_decode($body, true);
            $message = is_array($data)
                ? trim((string) ($data['error']['message'] ?? $data['message'] ?? ''))
                : '';
            throw new ApiException($message !== '' ? $message : "AI 语音服务返回 HTTP {$status}", 502);
        }

        return ['body' => $body, 'content_type' => $contentType];
    }

    private function speechEndpoint(array $resolved, string $action): string
    {
        $baseUrl = rtrim(trim((string) ($resolved['apiUrl'] ?? '')), '/');
        if ($baseUrl === '' && ($resolved['platformType'] ?? '') === 'openai') {
            $baseUrl = 'https://api.openai.com/v1';
        }
        if ($baseUrl === '') {
            throw new ApiException('当前 AI 配置缺少可用的语音接口基础地址', 400);
        }
        if (!str_ends_with(strtolower($baseUrl), '/v1')) {
            $baseUrl .= '/v1';
        }

        return $baseUrl . '/audio/' . $action;
    }

    private function resolveSpeechConfig(int $chatConfigId): array
    {
        if ($chatConfigId > 0) {
            return AiFactory::resolveConfigById($chatConfigId);
        }
        $speechConfigId = (int) env('SAIAI_SPEECH_CONFIG_ID', 0);
        return AiFactory::resolveConfigById($speechConfigId > 0 ? $speechConfigId : $chatConfigId);
    }

    private function resolveAttachmentFile(array $attachment, bool &$temporary): string
    {
        $storagePath = trim((string) ($attachment['storage_path'] ?? ''));
        if ($storagePath !== '') {
            $candidate = str_starts_with($storagePath, '/')
                ? $storagePath
                : base_path() . DIRECTORY_SEPARATOR . $storagePath;
            if (is_file($candidate)) {
                return $candidate;
            }
        }

        $url = trim((string) ($attachment['url'] ?? ''));
        if ($url === '') {
            throw new ApiException('语音附件地址不存在', 400);
        }
        $path = (string) (parse_url($url, PHP_URL_PATH) ?? '');
        if ($path !== '') {
            $localPath = public_path() . DIRECTORY_SEPARATOR . ltrim($path, '/');
            if (is_file($localPath)) {
                return $localPath;
            }
        }
        if (!preg_match('#^https?://#i', $url)) {
            throw new ApiException('语音附件地址无效', 400);
        }

        $response = $this->request('GET', $url, [], '');
        $tempPath = tempnam(sys_get_temp_dir(), 'help-chat-voice-');
        if ($tempPath === false || file_put_contents($tempPath, $response['body']) === false) {
            throw new ApiException('语音附件临时文件创建失败', 500);
        }
        $temporary = true;

        return $tempPath;
    }

    private function saveAudio(string $bytes): string
    {
        if ($bytes === '') {
            throw new ApiException('AI 语音合成结果为空', 502);
        }

        $config = (new SystemConfigLogic())->getGroup('upload_config');
        $root = trim((string) Arr::getConfigValue($config, 'local_root')) ?: 'public/storage/';
        $uri = trim((string) Arr::getConfigValue($config, 'local_uri')) ?: '/storage/';
        $folder = 'chat-ai/' . date('Ym');
        $directory = base_path() . DIRECTORY_SEPARATOR . trim($root, '/\\') . DIRECTORY_SEPARATOR . $folder;
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('AI 语音存储目录创建失败', 500);
        }

        $fileName = date('YmdHis') . '-' . bin2hex(random_bytes(8)) . '.mp3';
        if (file_put_contents($directory . DIRECTORY_SEPARATOR . $fileName, $bytes) === false) {
            throw new ApiException('AI 语音文件保存失败', 500);
        }

        return '/' . trim($uri, '/') . '/' . $folder . '/' . $fileName;
    }
}
