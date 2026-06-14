<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use Firebase\JWT\JWT;
use GuzzleHttp\Client;
use think\facade\Db;
use Throwable;

/**
 * HelpSupport 服务端通知服务。
 *
 * 负责生成消息中心记录，并在 Firebase 配置启用时尝试发送 FCM。
 */
class HelpPushService
{
    private const DEFAULT_LOCALE = 'en-US';
    private const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function notifyMember(int $memberId, string $templateCode, array $variables = [], array $options = []): array
    {
        if ($memberId <= 0 || $templateCode === '') {
            return [];
        }

        $template = $this->template($templateCode, $this->memberLocale($memberId));
        if (!$template) {
            return [];
        }

        $payload = $this->decodeJson($template['payload'] ?? null);
        $payload = array_merge($payload, $options['payload'] ?? []);
        $route = (string) ($options['route'] ?? $template['route'] ?? '');
        $bizType = (string) ($options['biz_type'] ?? $template['scene'] ?? $templateCode);
        $bizId = (int) ($options['biz_id'] ?? 0);

        $messageId = $this->createMessage($memberId, [
            'message_type' => (int) $template['message_type'],
            'title' => $this->render((string) $template['title'], $variables),
            'content' => $this->render((string) $template['content'], $variables),
            'biz_type' => $bizType,
            'biz_id' => $bizId,
            'route' => $route !== '' ? $route : null,
            'ext' => [
                'template_code' => $templateCode,
                'scene' => (string) $template['scene'],
                'payload' => $payload,
            ],
        ]);

        $message = Db::table('sa_member_message')->where('id', $messageId)->find() ?: [];
        if (!$this->canPush($memberId, (string) $template['scene'])) {
            return $message;
        }

        $devices = $this->activeDevices($memberId);
        if ($devices === []) {
            return $message;
        }

        $results = [];
        foreach ($devices as $device) {
            try {
                $results[] = $this->sendFcm(
                    (string) $device['fcm_token'],
                    (string) $message['title'],
                    (string) $message['content'],
                    $this->fcmData($message, $templateCode, (string) $template['scene'], $payload)
                );
            } catch (Throwable $throwable) {
                $results[] = [
                    'success' => false,
                    'error' => $this->publicError($throwable->getMessage()),
                ];
            }
        }

        $successCount = count(array_filter($results, static fn (array $row) => $row['success'] === true));
        Db::table('sa_member_message')->where('id', $messageId)->update([
            'is_pushed' => $successCount > 0 ? 1 : 2,
            'push_status' => $successCount > 0 ? 1 : 2,
            'push_time' => date('Y-m-d H:i:s'),
            'ext' => json_encode(array_merge($this->decodeJson($message['ext'] ?? null), [
                'push_results' => $results,
            ]), JSON_UNESCAPED_UNICODE),
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        return Db::table('sa_member_message')->where('id', $messageId)->find() ?: [];
    }

    private function template(string $templateCode, string $locale): array
    {
        $template = Db::table('sa_push_template')
            ->where('template_code', $templateCode)
            ->where('locale', $locale)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('is_default', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->find();
        if ($template) {
            return $template;
        }

        return Db::table('sa_push_template')
            ->where('template_code', $templateCode)
            ->where('locale', self::DEFAULT_LOCALE)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('is_default', 'asc')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->find() ?: [];
    }

    private function createMessage(int $memberId, array $data): int
    {
        $now = date('Y-m-d H:i:s');

        return (int) Db::table('sa_member_message')->insertGetId([
            'member_id' => $memberId,
            'message_type' => $data['message_type'],
            'title' => $data['title'],
            'content' => $data['content'],
            'is_pushed' => 2,
            'push_status' => 0,
            'is_read' => 2,
            'biz_type' => $data['biz_type'],
            'biz_id' => $data['biz_id'],
            'route' => $data['route'],
            'ext' => json_encode($data['ext'], JSON_UNESCAPED_UNICODE),
            'status' => 1,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);
    }

    private function canPush(int $memberId, string $scene): bool
    {
        $config = $this->firebaseConfig();
        if (($config['enabled'] ?? '2') !== '1') {
            return false;
        }

        $preference = Db::table('sa_member_push_preference')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find() ?: [];
        if ((int) ($preference['is_push_enabled'] ?? 1) !== 1) {
            return false;
        }
        if ($this->inQuietHours($preference)) {
            return false;
        }

        $field = match ($scene) {
            'task_reminder' => 'is_task_reminder_enabled',
            'community_reply', 'community_follow' => 'is_community_enabled',
            'appointment_update' => 'is_appointment_enabled',
            'doctor_audit_result', 'system_notice' => 'is_audit_notice_enabled',
            default => '',
        };

        return $field === '' || (int) ($preference[$field] ?? 1) === 1;
    }

    private function activeDevices(int $memberId): array
    {
        return Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('is_active', 1)
            ->where('fcm_token', '<>', '')
            ->whereNull('delete_time')
            ->order('last_active_time', 'desc')
            ->select()
            ->toArray();
    }

    private function sendFcm(string $token, string $title, string $body, array $data): array
    {
        $config = $this->firebaseConfig();
        $projectId = trim((string) ($config['project_id'] ?? ''));
        if ($token === '' || $projectId === '') {
            return ['success' => false, 'error' => 'missing_fcm_token_or_project_id'];
        }

        $accessToken = $this->accessToken($config);
        if ($accessToken === '') {
            return ['success' => false, 'error' => 'missing_firebase_access_token'];
        }

        $client = new Client(['timeout' => 10]);
        $response = $client->post('https://fcm.googleapis.com/v1/projects/' . rawurlencode($projectId) . '/messages:send', [
            'http_errors' => false,
            'headers' => [
                'Authorization' => 'Bearer ' . $accessToken,
                'Content-Type' => 'application/json',
            ],
            'json' => [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $data,
                ],
            ],
        ]);

        $statusCode = $response->getStatusCode();
        return [
            'success' => $statusCode >= 200 && $statusCode < 300,
            'status_code' => $statusCode,
        ];
    }

    private function accessToken(array $config): string
    {
        $serviceAccount = json_decode((string) ($config['service_account_json'] ?? ''), true);
        if (!is_array($serviceAccount)) {
            return '';
        }

        $clientEmail = (string) ($serviceAccount['client_email'] ?? '');
        $privateKey = (string) ($serviceAccount['private_key'] ?? '');
        if ($clientEmail === '' || $privateKey === '') {
            return '';
        }

        $now = time();
        $assertion = JWT::encode([
            'iss' => $clientEmail,
            'scope' => self::FCM_SCOPE,
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ], $privateKey, 'RS256');

        $client = new Client(['timeout' => 10]);
        $response = $client->post('https://oauth2.googleapis.com/token', [
            'http_errors' => false,
            'form_params' => [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $assertion,
            ],
        ]);
        $body = json_decode((string) $response->getBody(), true);

        return is_array($body) ? (string) ($body['access_token'] ?? '') : '';
    }

    private function firebaseConfig(): array
    {
        $rows = Db::table('sa_system_config_group')
            ->alias('g')
            ->leftJoin('sa_system_config c', 'c.group_id = g.id AND c.delete_time IS NULL')
            ->where('g.code', 'help_firebase_push')
            ->whereNull('g.delete_time')
            ->field('c.key, c.value')
            ->select()
            ->toArray();

        $config = [];
        foreach ($rows as $row) {
            if (!empty($row['key'])) {
                $config[$row['key']] = (string) ($row['value'] ?? '');
            }
        }

        return $config;
    }

    private function memberLocale(int $memberId): string
    {
        $locale = (string) Db::table('sa_help_member_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->value('locale');

        return $locale !== '' ? $locale : self::DEFAULT_LOCALE;
    }

    private function render(string $text, array $variables): string
    {
        foreach ($variables as $key => $value) {
            if (is_scalar($value) || $value === null) {
                $text = str_replace('{' . $key . '}', (string) $value, $text);
            }
        }

        return $text;
    }

    private function fcmData(array $message, string $templateCode, string $scene, array $payload): array
    {
        $data = array_merge($payload, [
            'message_id' => (string) $message['id'],
            'template_code' => $templateCode,
            'scene' => $scene,
            'biz_type' => (string) ($message['biz_type'] ?? ''),
            'biz_id' => (string) ($message['biz_id'] ?? 0),
            'route' => (string) ($message['route'] ?? ''),
        ]);

        foreach ($data as $key => $value) {
            if (!is_scalar($value) && $value !== null) {
                $data[$key] = json_encode($value, JSON_UNESCAPED_UNICODE);
            } else {
                $data[$key] = (string) $value;
            }
        }

        return $data;
    }

    private function inQuietHours(array $preference): bool
    {
        $start = (string) ($preference['quiet_start_time'] ?? '');
        $end = (string) ($preference['quiet_end_time'] ?? '');
        if ($start === '' || $end === '') {
            return false;
        }

        $now = date('H:i:s');
        if ($start <= $end) {
            return $now >= $start && $now <= $end;
        }

        return $now >= $start || $now <= $end;
    }

    private function decodeJson(mixed $value): array
    {
        if ($value === null || $value === '') {
            return [];
        }
        if (is_array($value)) {
            return $value;
        }
        if (!is_string($value)) {
            return [];
        }

        $decoded = json_decode($value, true);
        return is_array($decoded) ? $decoded : [];
    }

    private function publicError(string $message): string
    {
        $message = trim($message);
        if ($message === '') {
            return 'fcm_send_failed';
        }

        return mb_substr($message, 0, 120);
    }
}
