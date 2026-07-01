<?php

namespace plugin\saiai\app\realtime;

class RealtimeProtocol
{
    public const CLIENT_EVENTS = [
        'session.update',
        'input_audio_buffer.append',
        'input_audio_buffer.commit',
        'input_text.append',
        'input_image.append',
        'response.create',
        'response.cancel',
        'ping',
    ];

    public const SERVER_EVENTS = [
        'session.created',
        'session.updated',
        'input_audio_buffer.speech_started',
        'input_audio_buffer.speech_stopped',
        'input_audio_buffer.committed',
        'conversation.item.created',
        'conversation.item.input_audio_transcription.delta',
        'conversation.item.input_audio_transcription.completed',
        'conversation.item.input_audio_transcription.failed',
        'response.started',
        'response.text.delta',
        'response.audio.delta',
        'response.done',
        'error',
        'pong',
    ];

    public static function decodeEvent(mixed $raw): array
    {
        if (!is_string($raw) || trim($raw) === '') {
            throw new \InvalidArgumentException('事件内容不能为空', 4001);
        }

        $event = json_decode($raw, true);
        if (!is_array($event)) {
            throw new \InvalidArgumentException('事件必须是 JSON object', 4001);
        }

        $type = (string) ($event['type'] ?? '');
        if (!in_array($type, self::CLIENT_EVENTS, true)) {
            throw new \InvalidArgumentException('不支持的客户端事件：' . ($type ?: '<empty>'), 4002);
        }

        $event['event_id'] = (string) ($event['event_id'] ?? RealtimeSessionState::newId('evt'));
        return $event;
    }

    public static function normalizeSession(array $session, array $defaults): array
    {
        $next = $defaults;
        foreach (['modalities', 'instructions', 'input_audio_format', 'output_audio_format', 'voice', 'turn_detection', 'temperature', 'tools'] as $key) {
            if (array_key_exists($key, $session)) {
                $next[$key] = $session[$key];
            }
        }

        $next['modalities'] = self::normalizeModalities($next['modalities'] ?? ['text', 'audio']);
        $next['input_audio_format'] = self::normalizeAudioFormat((string) ($next['input_audio_format'] ?? 'pcm16'));
        $next['output_audio_format'] = self::normalizeAudioFormat((string) ($next['output_audio_format'] ?? 'pcm16'));
        $next['instructions'] = (string) ($next['instructions'] ?? '');
        $next['voice'] = isset($next['voice']) ? (string) $next['voice'] : '';
        $next['temperature'] = self::normalizeTemperature($next['temperature'] ?? 0.8);
        $next['tools'] = is_array($next['tools'] ?? null) ? array_values($next['tools']) : [];
        $next['turn_detection'] = self::normalizeTurnDetection($next['turn_detection'] ?? ['type' => 'server_vad']);

        return $next;
    }

    public static function normalizeProviderSession(array $session): array
    {
        if (in_array($session['input_audio_format'] ?? '', ['pcm', 'pcm24'], true)) {
            $session['input_audio_format'] = 'pcm16';
        }
        if (in_array($session['output_audio_format'] ?? '', ['pcm', 'pcm24'], true)) {
            $session['output_audio_format'] = 'pcm16';
        }
        if (!array_key_exists('tools', $session)) {
            $session['tools'] = [];
        }
        return self::normalizeSession($session, $session);
    }

    public static function event(string $type, RealtimeSessionState $state, array $data = [], ?string $eventId = null): string
    {
        $payload = array_merge([
            'type' => $type,
            'event_id' => $eventId ?: RealtimeSessionState::newId('srv'),
            'session_id' => $state->sessionId,
            'provider' => $state->provider,
            'model' => $state->model,
        ], $data);

        return json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    public static function error(
        string $code,
        string $message,
        ?RealtimeSessionState $state = null,
        ?string $eventId = null,
        bool $fatal = false,
        array $extra = []
    ): string {
        $payload = array_merge([
            'type' => 'error',
            'event_id' => $eventId ?: RealtimeSessionState::newId('err'),
            'error' => [
                'code' => $code,
                'message' => $message,
                'fatal' => $fatal,
            ],
        ], $extra);

        if ($state) {
            $payload['session_id'] = $state->sessionId;
            $payload['provider'] = $state->provider;
            $payload['model'] = $state->model;
        }

        return json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    public static function isBase64(string $value): bool
    {
        if ($value === '') {
            return false;
        }

        return base64_decode($value, true) !== false;
    }

    private static function normalizeModalities(mixed $modalities): array
    {
        if (!is_array($modalities)) {
            return ['text', 'audio'];
        }

        $allowed = ['text', 'audio'];
        $result = array_values(array_intersect($allowed, array_map('strval', $modalities)));
        return $result ?: ['text'];
    }

    private static function normalizeAudioFormat(string $format): string
    {
        $format = strtolower(trim($format));
        if ($format === 'pcm') {
            return 'pcm16';
        }

        if ($format !== 'pcm16') {
            throw new \InvalidArgumentException('音频格式仅支持 pcm16', 4003);
        }

        return 'pcm16';
    }

    private static function normalizeTemperature(mixed $temperature): float
    {
        $value = is_numeric($temperature) ? (float) $temperature : 0.8;
        return max(0.0, min(2.0, $value));
    }

    private static function normalizeTurnDetection(mixed $turnDetection): mixed
    {
        if ($turnDetection === null) {
            return ['type' => 'manual'];
        }

        if (is_string($turnDetection)) {
            $turnDetection = ['type' => $turnDetection];
        }

        if (!is_array($turnDetection)) {
            return ['type' => 'server_vad'];
        }

        $type = (string) ($turnDetection['type'] ?? 'server_vad');
        if (!in_array($type, ['server_vad', 'semantic_vad', 'manual'], true)) {
            throw new \InvalidArgumentException('不支持的 VAD 模式：' . $type, 4004);
        }

        if ($type === 'manual') {
            return ['type' => 'manual'];
        }

        $normalized = ['type' => $type];
        if (isset($turnDetection['threshold']) && is_numeric($turnDetection['threshold'])) {
            $normalized['threshold'] = max(-1.0, min(1.0, (float) $turnDetection['threshold']));
        }
        if (isset($turnDetection['silence_duration_ms']) && is_numeric($turnDetection['silence_duration_ms'])) {
            $normalized['silence_duration_ms'] = max(200, min(6000, (int) $turnDetection['silence_duration_ms']));
        }

        return $normalized;
    }
}
