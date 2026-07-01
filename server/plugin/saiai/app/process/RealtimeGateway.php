<?php

namespace plugin\saiai\app\process;

use plugin\saiai\app\realtime\adapter\RealtimeAdapterFactory;
use plugin\saiai\app\realtime\adapter\RealtimeProviderAdapterInterface;
use plugin\saiai\app\realtime\RealtimeProtocol;
use plugin\saiai\app\realtime\RealtimeSessionState;
use plugin\saiai\app\service\AliyunRealtimeConfig;
use support\Log;
use Tinywan\Jwt\JwtToken;
use Workerman\Connection\AsyncTcpConnection;
use Workerman\Connection\TcpConnection;
use Workerman\Protocols\Http\Request as WsRequest;
use Workerman\Timer;

class RealtimeGateway
{
    private array $upstreams = [];
    private array $states = [];
    private array $adapters = [];

    public function onWebSocketConnect(TcpConnection $connection, string|WsRequest $request): void
    {
        $connection->realtimeRequest = $request;
        Timer::add(0.001, function () use ($connection): void {
            $this->handleConnected($connection);
        }, [], false);
    }

    public function onMessage(TcpConnection $connection, mixed $data): void
    {
        $state = $this->states[$connection->id] ?? null;
        $adapter = $this->adapters[$connection->id] ?? null;
        if (!$state instanceof RealtimeSessionState || !$adapter instanceof RealtimeProviderAdapterInterface) {
            $connection->send(RealtimeProtocol::error('session_not_ready', '实时会话尚未就绪', null, null, true));
            return;
        }

        try {
            $event = RealtimeProtocol::decodeEvent($data);

            if ($event['type'] === 'ping') {
                $connection->send(RealtimeProtocol::event('pong', $state, [
                    'time' => time(),
                    'client_event_id' => $event['event_id'],
                ]));
                return;
            }

            if (!$state->upstreamReady || !isset($this->upstreams[$connection->id])) {
                $connection->send(RealtimeProtocol::error('upstream_not_ready', '上游实时模型尚未连接完成', $state, $event['event_id']));
                return;
            }

            if ($event['type'] === 'session.update') {
                $state->session = RealtimeProtocol::normalizeSession((array) ($event['session'] ?? []), $state->session);
            }

            if ($event['type'] === 'input_audio_buffer.commit') {
                $state->turnIndex++;
            }

            foreach ($adapter->toProviderEvents($event, $state) as $providerEvent) {
                $this->upstreams[$connection->id]->send($this->encodeProviderEvent($providerEvent));
            }
        } catch (\Throwable $e) {
            $connection->send(RealtimeProtocol::error(
                $this->errorCode($e),
                $e->getMessage() ?: '实时事件处理失败',
                $state,
                is_array($data) ? (string) ($data['event_id'] ?? '') : null
            ));
        }
    }

    public function onClose(TcpConnection $connection): void
    {
        if (isset($this->upstreams[$connection->id])) {
            $this->upstreams[$connection->id]->close();
            unset($this->upstreams[$connection->id]);
        }
        unset($this->states[$connection->id], $this->adapters[$connection->id]);
    }

    private function handleConnected(TcpConnection $connection): void
    {
        $request = $connection->realtimeRequest;
        $query = $this->parseQuery($request);

        try {
            $this->assertRealtimePath($request);
            $this->assertAccessToken($request, $query);

            [$config, $adapter] = $this->resolveAdapter($query);
            $state = new RealtimeSessionState(
                $adapter->name(),
                (string) ($config['model'] ?? ($query['model'] ?? '')),
                $adapter->defaultSession((array) ($config['options'] ?? [])),
                $config
            );

            $this->states[$connection->id] = $state;
            $this->adapters[$connection->id] = $adapter;
            $this->connectUpstream($connection, $adapter, $config, $state);
        } catch (\Throwable $e) {
            Log::warning('[saiai.realtime] connect failed: ' . $this->maskSensitive($e->getMessage()));
            $connection->send(RealtimeProtocol::error(
                $this->errorCode($e),
                $e->getMessage() ?: '实时会话连接失败',
                null,
                null,
                true
            ));
            $connection->close();
        }
    }

    private function connectUpstream(
        TcpConnection $client,
        RealtimeProviderAdapterInterface $adapter,
        array $config,
        RealtimeSessionState $state
    ): void {
        $apiUrl = $adapter->upstreamUrl($config);
        $target = $this->buildWorkermanWsUrl($apiUrl);
        $upstream = new AsyncTcpConnection($target);
        $upstream->transport = str_starts_with($apiUrl, 'wss://') ? 'ssl' : 'tcp';
        $upstream->headers = $adapter->upstreamHeaders($config);

        $upstream->onConnect = function () use ($client, $state): void {
            $state->upstreamReady = true;
            if ($client->getStatus() === TcpConnection::STATUS_ESTABLISHED) {
                $client->send(RealtimeProtocol::event('session.created', $state, [
                    'session' => $state->session,
                    'status' => 'ready',
                ]));
            }
        };

        $upstream->onMessage = function (AsyncTcpConnection $connection, mixed $data) use ($client, $adapter, $state): void {
            if ($client->getStatus() !== TcpConnection::STATUS_ESTABLISHED) {
                return;
            }

            $providerEvent = json_decode((string) $data, true);
            if (!is_array($providerEvent)) {
                $client->send(RealtimeProtocol::error('provider_protocol_error', '上游返回了非 JSON 事件', $state));
                return;
            }

            try {
                foreach ($adapter->fromProviderEvent($providerEvent, $state) as $event) {
                    $this->sendServerEvent($client, $state, $event);
                }
            } catch (\Throwable $e) {
                Log::error('[saiai.realtime] provider event convert failed: ' . $this->maskSensitive($e->getMessage()));
                $client->send(RealtimeProtocol::error('provider_protocol_error', $e->getMessage() ?: '上游事件转换失败', $state));
            }
        };

        $upstream->onError = function (AsyncTcpConnection $connection, int $code, string $message) use ($client, $state): void {
            Log::error('[saiai.realtime] upstream error code=' . $code . ' message=' . $this->maskSensitive($message));
            if ($client->getStatus() === TcpConnection::STATUS_ESTABLISHED) {
                $client->send(RealtimeProtocol::error('provider_connection_error', $message, $state, null, true, [
                    'provider_code' => $code,
                ]));
            }
        };

        $upstream->onClose = function () use ($client, $state): void {
            $state->upstreamReady = false;
            if ($client->getStatus() === TcpConnection::STATUS_ESTABLISHED) {
                $client->send(RealtimeProtocol::error('provider_connection_closed', '上游实时连接已关闭', $state, null, true));
            }
        };

        $this->upstreams[$client->id] = $upstream;
        $upstream->connect();
    }

    private function resolveAdapter(array $query): array
    {
        $provider = trim((string) ($query['provider'] ?? ''));
        $model = trim((string) ($query['model'] ?? ''));

        if ($provider !== '' && !in_array(strtolower($provider), ['aliyun', 'aliyun_qwen', 'qwen', 'qwen_omni'], true)) {
            $adapter = RealtimeAdapterFactory::make($provider);
            return [[
                'provider' => $adapter->name(),
                'model' => $model,
                'options' => [],
            ], $adapter];
        }

        $configId = isset($query['config_id']) ? (int) $query['config_id'] : null;
        $config = AliyunRealtimeConfig::resolve($configId ?: null);
        if ($model !== '') {
            $config = AliyunRealtimeConfig::withModel($config, $model);
        }
        $adapter = RealtimeAdapterFactory::make($provider ?: ($config['provider'] ?? AliyunRealtimeConfig::DEFAULT_PROVIDER));
        $config['provider'] = $adapter->name();

        return [$config, $adapter];
    }

    private function sendServerEvent(TcpConnection $client, RealtimeSessionState $state, array $event): void
    {
        $type = (string) ($event['type'] ?? '');
        if (!in_array($type, RealtimeProtocol::SERVER_EVENTS, true)) {
            return;
        }

        $eventId = isset($event['event_id']) ? (string) $event['event_id'] : null;
        unset($event['type'], $event['event_id']);
        $client->send(RealtimeProtocol::event($type, $state, $event, $eventId));
    }

    private function encodeProviderEvent(array $event): string
    {
        return json_encode($event, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    private function buildWorkermanWsUrl(string $apiUrl): string
    {
        if (str_starts_with($apiUrl, 'wss://')) {
            return 'ws://' . substr($apiUrl, 6);
        }

        return $apiUrl;
    }

    private function assertRealtimePath(string|WsRequest $request): void
    {
        $path = $this->parsePath($request);
        if ($path !== '/' && $path !== '/v1/realtime') {
            throw new \RuntimeException('不支持的实时 WebSocket 路径：' . $path, 4007);
        }
    }

    private function assertAccessToken(string|WsRequest $request, array $query): void
    {
        $token = $this->extractBearerToken($request, $query);
        if ($token === '') {
            throw new \RuntimeException('缺少实时连接凭证', 4010);
        }

        $payload = JwtToken::verify(1, $token);
        $extend = (array) ($payload['extend'] ?? []);
        if (!in_array((string) ($extend['plat'] ?? ''), ['saiadmin', 'saiuser'], true)) {
            throw new \RuntimeException('登录凭证平台不匹配', 4011);
        }
    }

    private function extractBearerToken(string|WsRequest $request, array $query): string
    {
        $token = trim((string) ($query['token'] ?? $query['access_token'] ?? ''));
        if ($token !== '') {
            return $token;
        }

        if ($request instanceof WsRequest) {
            $authorization = (string) $request->header('authorization', '');
            if (preg_match('/^Bearer\s+(.+)$/i', $authorization, $matches)) {
                return trim($matches[1]);
            }
        }

        return '';
    }

    private function parseQuery(string|WsRequest $request): array
    {
        if ($request instanceof WsRequest) {
            return $request->get();
        }

        $firstLine = strtok($request, "\r\n") ?: '';
        if (!preg_match('#\s([^\s]+)\s#', $firstLine, $matches)) {
            return [];
        }

        parse_str((string) parse_url($matches[1], PHP_URL_QUERY), $query);
        return is_array($query) ? $query : [];
    }

    private function parsePath(string|WsRequest $request): string
    {
        if ($request instanceof WsRequest) {
            $path = (string) parse_url($request->uri(), PHP_URL_PATH);
            return $path ?: '/';
        }

        $firstLine = strtok($request, "\r\n") ?: '';
        if (!preg_match('#\s([^\s]+)\s#', $firstLine, $matches)) {
            return '/';
        }

        $path = (string) parse_url($matches[1], PHP_URL_PATH);
        return $path ?: '/';
    }

    private function errorCode(\Throwable $e): string
    {
        return match ((int) $e->getCode()) {
            4001 => 'invalid_json',
            4002 => 'unsupported_event',
            4003, 4004 => 'invalid_session',
            4005 => 'invalid_audio',
            4006 => 'invalid_image',
            4007 => 'invalid_path',
            4010, 4011 => 'authentication_error',
            default => $e instanceof \InvalidArgumentException ? 'invalid_request' : 'internal_error',
        };
    }

    private function maskSensitive(string $message): string
    {
        $message = preg_replace('/Bearer\s+[A-Za-z0-9._\-]+/i', 'Bearer ***', $message) ?? $message;
        return preg_replace('/(token|secret|api[_-]?key)=([^&\s]+)/i', '$1=***', $message) ?? $message;
    }
}
