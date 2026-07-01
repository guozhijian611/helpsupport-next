<?php

namespace plugin\saiai\app\realtime\adapter;

use plugin\saiai\app\realtime\RealtimeProtocol;
use plugin\saiai\app\realtime\RealtimeSessionState;
use plugin\saiai\app\service\AliyunRealtimeConfig;

class AliyunQwenRealtimeAdapter implements RealtimeProviderAdapterInterface
{
    public function name(): string
    {
        return 'aliyun_qwen';
    }

    public function upstreamUrl(array $config): string
    {
        return (string) ($config['apiUrl'] ?? AliyunRealtimeConfig::DEFAULT_URL);
    }

    public function upstreamHeaders(array $config): array
    {
        return [
            'Authorization' => 'Bearer ' . (string) ($config['apiKey'] ?? ''),
        ];
    }

    public function defaultSession(array $options = []): array
    {
        return $this->toProtocolSession(AliyunRealtimeConfig::defaultSession($options));
    }

    public function toProviderEvents(array $event, RealtimeSessionState $state): array
    {
        $eventId = (string) ($event['event_id'] ?? RealtimeSessionState::newId('evt'));
        return match ($event['type']) {
            'session.update' => [[
                'type' => 'session.update',
                'event_id' => $eventId,
                'session' => $this->toProviderSession($state->session, $state),
            ]],
            'input_audio_buffer.append' => $this->audioAppendEvent($event, $state, $eventId),
            'input_audio_buffer.commit' => [[
                'type' => 'input_audio_buffer.commit',
                'event_id' => $eventId,
            ]],
            'input_text.append' => [[
                'type' => 'conversation.item.create',
                'event_id' => $eventId,
                'item' => [
                    'type' => 'message',
                    'role' => 'user',
                    'content' => [
                        [
                            'type' => 'input_text',
                            'text' => (string) ($event['text'] ?? ''),
                        ],
                    ],
                ],
            ]],
            'input_image.append' => $this->imageAppendEvent($event, $state, $eventId),
            'response.create' => [[
                'type' => 'response.create',
                'event_id' => $eventId,
            ]],
            'response.cancel' => [[
                'type' => 'response.cancel',
                'event_id' => $eventId,
            ]],
            default => [],
        };
    }

    public function fromProviderEvent(array $event, RealtimeSessionState $state): array
    {
        $type = (string) ($event['type'] ?? '');
        $eventId = isset($event['event_id']) ? (string) $event['event_id'] : null;

        if ($type === 'session.created') {
            return [[
                'type' => 'session.created',
                'event_id' => $eventId,
                'session' => $this->toProtocolSession((array) ($event['session'] ?? $state->session)),
            ]];
        }

        if ($type === 'session.updated') {
            $state->session = $this->toProtocolSession((array) ($event['session'] ?? $state->session));
            return [[
                'type' => 'session.updated',
                'event_id' => $eventId,
                'session' => $state->session,
            ]];
        }

        if ($type === 'response.created') {
            $state->responding = true;
            $state->responseId = (string) ($event['response']['id'] ?? RealtimeSessionState::newId('resp'));
            return [[
                'type' => 'response.started',
                'event_id' => $eventId,
                'response_id' => $state->responseId,
            ]];
        }

        if (in_array($type, ['response.text.delta', 'response.output_text.delta', 'response.audio_transcript.delta', 'response.output_audio_transcript.delta'], true)) {
            $delta = (string) ($event['delta'] ?? $event['text'] ?? '');
            return $delta === '' ? [] : [[
                'type' => 'response.text.delta',
                'event_id' => $eventId,
                'response_id' => $state->responseId,
                'delta' => $delta,
            ]];
        }

        if (in_array($type, ['response.audio.delta', 'response.output_audio.delta'], true)) {
            $delta = (string) ($event['delta'] ?? '');
            return $delta === '' ? [] : [[
                'type' => 'response.audio.delta',
                'event_id' => $eventId,
                'response_id' => $state->responseId,
                'delta' => $delta,
            ]];
        }

        if ($type === 'response.done') {
            $state->responding = false;
            $responseId = $state->responseId;
            $state->responseId = null;
            $state->audioChunks = 0;
            $state->imageFrames = 0;
            return [[
                'type' => 'response.done',
                'event_id' => $eventId,
                'response_id' => $responseId,
                'status' => (string) ($event['response']['status'] ?? 'completed'),
            ]];
        }

        if ($type === 'error') {
            $error = (array) ($event['error'] ?? []);
            return [[
                'type' => 'error',
                'event_id' => $eventId,
                'error' => [
                    'code' => (string) ($error['code'] ?? 'provider_error'),
                    'message' => (string) ($error['message'] ?? '上游实时模型返回错误'),
                    'fatal' => false,
                ],
            ]];
        }

        return [];
    }

    private function audioAppendEvent(array $event, RealtimeSessionState $state, string $eventId): array
    {
        $audio = (string) ($event['audio'] ?? '');
        if (!RealtimeProtocol::isBase64($audio)) {
            throw new \InvalidArgumentException('audio 必须是 base64 PCM16', 4005);
        }

        $state->audioChunks++;
        return [[
            'type' => 'input_audio_buffer.append',
            'event_id' => $eventId,
            'audio' => $audio,
        ]];
    }

    private function imageAppendEvent(array $event, RealtimeSessionState $state, string $eventId): array
    {
        if ($state->audioChunks <= 0) {
            return [];
        }

        $image = (string) ($event['image'] ?? '');
        if ($image === '') {
            throw new \InvalidArgumentException('image 不能为空', 4006);
        }

        $state->imageFrames++;
        return [[
            'type' => 'input_image_buffer.append',
            'event_id' => $eventId,
            'image' => $this->stripDataUrl($image),
        ]];
    }

    private function toProviderSession(array $session, RealtimeSessionState $state): array
    {
        $provider = AliyunRealtimeConfig::defaultSession((array) ($state->config['options'] ?? []));
        foreach (['modalities', 'instructions', 'voice', 'turn_detection', 'temperature'] as $key) {
            if (array_key_exists($key, $session)) {
                $provider[$key] = $session[$key];
            }
        }
        $provider['input_audio_format'] = 'pcm';
        $provider['output_audio_format'] = 'pcm';

        if (($provider['turn_detection']['type'] ?? '') === 'manual') {
            $provider['turn_detection'] = null;
        }

        unset($provider['tools']);
        return $provider;
    }

    private function toProtocolSession(array $session): array
    {
        return RealtimeProtocol::normalizeSession([
            'modalities' => $session['modalities'] ?? ['text', 'audio'],
            'instructions' => $session['instructions'] ?? '',
            'input_audio_format' => $this->normalizeProviderAudioFormat((string) ($session['input_audio_format'] ?? 'pcm16')),
            'output_audio_format' => $this->normalizeProviderAudioFormat((string) ($session['output_audio_format'] ?? 'pcm16')),
            'voice' => $session['voice'] ?? AliyunRealtimeConfig::DEFAULT_VOICE,
            'turn_detection' => $session['turn_detection'] ?? ['type' => 'server_vad'],
            'temperature' => $session['temperature'] ?? 0.9,
            'tools' => $session['tools'] ?? [],
        ], [
            'modalities' => ['text', 'audio'],
            'instructions' => '',
            'input_audio_format' => 'pcm16',
            'output_audio_format' => 'pcm16',
            'voice' => AliyunRealtimeConfig::DEFAULT_VOICE,
            'turn_detection' => ['type' => 'server_vad'],
            'temperature' => 0.9,
            'tools' => [],
        ]);
    }

    private function normalizeProviderAudioFormat(string $format): string
    {
        $format = strtolower(trim($format));
        if (in_array($format, ['pcm', 'pcm16', 'pcm24'], true)) {
            return 'pcm16';
        }

        return $format;
    }

    private function stripDataUrl(string $value): string
    {
        if (str_starts_with($value, 'data:') && str_contains($value, ',')) {
            return substr($value, strpos($value, ',') + 1);
        }

        return $value;
    }
}
