<?php

declare(strict_types=1);

namespace plugin\saiai\app\service;

use plugin\saiadmin\app\logic\system\SystemConfigLogic;
use plugin\saiadmin\exception\ApiException;
use plugin\saiadmin\utils\Arr;
use plugin\saiai\app\model\config\AiConfig;

/**
 * OpenAI 兼容的 ASR / TTS 调用。
 */
final class SpeechService
{
    public const TYPE_ASR = 'asr';
    public const TYPE_TTS = 'tts';

    private const REQUEST_TIMEOUT = 120;
    private const MAX_UPLOAD_BYTES = 20 * 1024 * 1024;

    /**
     * @return list<array{id:int,name:string,model:string,type:string,status:int,ai_url:string,voice:string}>
     */
    public function listConfigs(string $type): array
    {
        $type = $this->normalizeType($type);
        $rows = AiConfig::where('type', $type)
            ->order('is_default', 'asc')
            ->order('id', 'desc')
            ->select();

        $list = [];
        foreach ($rows as $row) {
            $options = $this->decodeOptions($row->options ?? null);
            $list[] = [
                'id' => (int) $row->id,
                'name' => (string) $row->name,
                'model' => (string) $row->model,
                'type' => (string) $row->type,
                'status' => (int) $row->status,
                'ai_url' => (string) $row->ai_url,
                'voice' => trim((string) ($options['voice'] ?? '')),
            ];
        }

        return $list;
    }

    public function transcribeUploadedFile(int $configId, mixed $file): string
    {
        if (!is_object($file) || !method_exists($file, 'isValid') || !$file->isValid()) {
            throw new ApiException('请上传要转写的音频文件', 400);
        }

        $filePath = (string) $file->getRealPath();
        if ($filePath === '' || !is_file($filePath)) {
            throw new ApiException('音频文件无效', 400);
        }
        $size = (int) $file->getSize();
        if ($size <= 0 || $size > self::MAX_UPLOAD_BYTES) {
            throw new ApiException('音频文件不能超过 20MB', 400);
        }

        return $this->transcribeFile(
            $filePath,
            (string) ($file->getUploadMimeType() ?: 'audio/webm'),
            (string) ($file->getUploadName() ?: 'speech.webm'),
            $configId,
            self::TYPE_ASR,
            false
        );
    }

    public function transcribeAttachment(array $attachment, int $configId): string
    {
        $temporary = false;
        $filePath = $this->resolveAttachmentFile($attachment, $temporary);

        try {
            return $this->transcribeFile(
                $filePath,
                (string) ($attachment['mime_type'] ?? 'audio/mp4'),
                (string) ($attachment['origin_name'] ?? basename($filePath)),
                $configId
            );
        } finally {
            if ($temporary && is_file($filePath)) {
                @unlink($filePath);
            }
        }
    }

    public function transcribeFile(
        string $filePath,
        string $mimeType,
        string $filename,
        int $configId,
        ?string $expectedType = null,
        bool $requireEnabled = true
    ): string {
        $resolved = $this->resolveSpeechConfig($configId, $expectedType, $requireEnabled);
        $response = $this->request(
            'POST',
            $this->speechEndpoint($resolved, 'transcriptions'),
            ['Authorization: Bearer ' . $resolved['apiKey']],
            [
                'model' => (string) ($resolved['model'] ?? env('SAIAI_TRANSCRIPTION_MODEL', 'whisper-1')),
                'file' => new \CURLFile($filePath, $mimeType !== '' ? $mimeType : 'application/octet-stream', $filename),
                'response_format' => 'json',
            ]
        );

        $data = json_decode($response['body'], true);
        $text = is_array($data) ? trim((string) ($data['text'] ?? '')) : '';
        if ($text === '') {
            throw new ApiException('语音转写未返回有效文本', 502);
        }

        return $text;
    }

    /**
     * @return array{audio_url:string,audio_mime_type:string,model:string,voice:string}
     */
    public function synthesize(
        string $text,
        int $configId,
        string $voice = '',
        ?string $expectedType = self::TYPE_TTS,
        bool $requireEnabled = true
    ): array {
        $text = trim($text);
        if ($text === '') {
            throw new ApiException('请输入要合成的文本', 400);
        }

        $resolved = $this->resolveSpeechConfig($configId, $expectedType, $requireEnabled);
        $options = is_array($resolved['options'] ?? null) ? $resolved['options'] : [];
        $voice = trim($voice) !== ''
            ? trim($voice)
            : trim((string) ($options['voice'] ?? env('SAIAI_SPEECH_VOICE', 'alloy')));

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
            'model' => (string) $resolved['model'],
            'voice' => $voice,
        ];
    }

    /**
     * @return array{apiUrl:string,apiKey:string,model:string,platformType:string,options:array<string,mixed>}
     */
    public function resolveSpeechConfig(int $configId, ?string $expectedType = null, bool $requireEnabled = true): array
    {
        if ($configId <= 0) {
            $configId = (int) env('SAIAI_SPEECH_CONFIG_ID', 0);
        }
        $resolved = AiFactory::resolveConfigById($configId, $requireEnabled);
        if ($expectedType !== null && ($resolved['platformType'] ?? '') !== $expectedType) {
            throw new ApiException('请选择对应的 ' . strtoupper($expectedType) . ' 配置', 400);
        }

        return $resolved;
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
        $lower = strtolower($baseUrl);
        $suffix = '/audio/' . $action;
        if ($baseUrl !== '' && str_ends_with($lower, $suffix)) {
            return $baseUrl;
        }
        if ($baseUrl === '' && in_array((string) ($resolved['platformType'] ?? ''), ['openai', self::TYPE_ASR, self::TYPE_TTS], true)) {
            $baseUrl = 'https://api.openai.com/v1';
            $lower = strtolower($baseUrl);
        }
        if ($baseUrl === '') {
            throw new ApiException('当前 AI 配置缺少可用的语音接口基础地址', 400);
        }
        if (str_ends_with($lower, '/v1')) {
            return $baseUrl . $suffix;
        }

        return $baseUrl . '/v1' . $suffix;
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
        $tempPath = tempnam(sys_get_temp_dir(), 'saiai-voice-');
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
        $folder = 'saiai-speech/' . date('Ym');
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

    /**
     * @return array<string, mixed>
     */
    private function decodeOptions(mixed $options): array
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

    private function normalizeType(string $type): string
    {
        $type = strtolower(trim($type));
        if (!in_array($type, [self::TYPE_ASR, self::TYPE_TTS], true)) {
            throw new ApiException('语音测试类型只能是 asr 或 tts', 400);
        }

        return $type;
    }
}
