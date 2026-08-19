<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiai\app\service\SpeechService;

/**
 * 普通聊天语音转写与语音合成。
 *
 * 复用 SAIAI 的 OpenAI 兼容语音通道，不与实时音视频链路共享连接。
 */
final class ChatSpeechService
{
    public function transcribe(array $attachment, int $configId): string
    {
        return (new SpeechService())->transcribeAttachment($attachment, $configId);
    }

    /**
     * @return array{audio_url:string,audio_mime_type:string,duration_seconds:int}
     */
    public function synthesize(string $text, int $configId, string $voice = ''): array
    {
        $result = (new SpeechService())->synthesize($text, $configId, $voice, null);

        return [
            'audio_url' => (string) $result['audio_url'],
            'audio_mime_type' => (string) $result['audio_mime_type'],
            'duration_seconds' => max(0, (int) ($result['duration_seconds'] ?? 0)),
        ];
    }
}
