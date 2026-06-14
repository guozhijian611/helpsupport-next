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
    private const INVALID_FCM_ERROR_CODES = ['UNREGISTERED', 'INVALID_ARGUMENT', 'SENDER_ID_MISMATCH'];

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

        return $this->pushMessageToDevices($message, $devices, $templateCode, (string) $template['scene'], $payload);
    }

    public function pushMessage(int $messageId): array
    {
        if ($messageId <= 0) {
            return [];
        }

        $message = Db::table('sa_member_message')
            ->where('id', $messageId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find() ?: [];
        if ($message === []) {
            return [];
        }

        $memberId = (int) ($message['member_id'] ?? 0);
        $ext = $this->decodeJson($message['ext'] ?? null);
        $payload = $this->decodeJson($ext['payload'] ?? null);
        $scene = (string) ($ext['scene'] ?? $payload['scene'] ?? $message['biz_type'] ?? 'system_notice');
        $scene = $scene !== '' ? $scene : 'system_notice';
        $templateCode = (string) ($ext['template_code'] ?? $scene);
        $templateCode = $templateCode !== '' ? $templateCode : 'system_notice';

        if (!$this->canPush($memberId, $scene)) {
            return $this->markMessagePushFailed($message, [[
                'success' => false,
                'error' => 'push_disabled_or_suppressed',
            ]]);
        }

        $devices = $this->activeDevices($memberId);
        if ($devices === []) {
            return $this->markMessagePushFailed($message, [[
                'success' => false,
                'error' => 'no_active_push_device',
            ]]);
        }

        return $this->pushMessageToDevices($message, $devices, $templateCode, $scene, $payload);
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

    private function pushMessageToDevices(array $message, array $devices, string $templateCode, string $scene, array $payload): array
    {
        $memberId = (int) ($message['member_id'] ?? 0);
        $messageId = (int) ($message['id'] ?? 0);
        $results = [];
        $invalidDeviceIds = [];
        foreach ($devices as $device) {
            $result = [
                'device_id' => (int) ($device['id'] ?? 0),
                'platform' => (string) ($device['platform'] ?? ''),
                'success' => false,
            ];
            try {
                $result = array_merge($result, $this->sendFcm(
                    (string) $device['fcm_token'],
                    (string) ($message['title'] ?? ''),
                    (string) ($message['content'] ?? ''),
                    $this->fcmData($message, $templateCode, $scene, $payload)
                ));
            } catch (Throwable $throwable) {
                $result = array_merge($result, [
                    'error' => $this->publicError($throwable->getMessage()),
                ]);
            }

            if ($this->shouldDeactivateDevice($result)) {
                $invalidDeviceIds[] = (int) ($device['id'] ?? 0);
            }
            $results[] = $result;
        }

        $this->deactivateInvalidDevices($memberId, $invalidDeviceIds);

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

    private function markMessagePushFailed(array $message, array $results): array
    {
        $messageId = (int) ($message['id'] ?? 0);
        if ($messageId <= 0) {
            return [];
        }

        Db::table('sa_member_message')->where('id', $messageId)->update([
            'is_pushed' => 2,
            'push_status' => 2,
            'push_time' => date('Y-m-d H:i:s'),
            'ext' => json_encode(array_merge($this->decodeJson($message['ext'] ?? null), [
                'push_results' => $results,
            ]), JSON_UNESCAPED_UNICODE),
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        return Db::table('sa_member_message')->where('id', $messageId)->find() ?: [];
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
        $body = json_decode((string) $response->getBody(), true);
        $error = is_array($body) && isset($body['error']) && is_array($body['error']) ? $body['error'] : [];

        $result = [
            'success' => $statusCode >= 200 && $statusCode < 300,
            'status_code' => $statusCode,
        ];

        if ($result['success'] === false) {
            $result['error_status'] = (string) ($error['status'] ?? '');
            $result['fcm_error_code'] = $this->fcmErrorCode($error['details'] ?? []);
            $result['error'] = $this->publicError((string) ($error['message'] ?? 'fcm_send_failed'));
        }

        return $result;
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

    private function shouldDeactivateDevice(array $result): bool
    {
        if (($result['success'] ?? false) === true) {
            return false;
        }

        $fcmErrorCode = (string) ($result['fcm_error_code'] ?? '');
        if ($fcmErrorCode !== '' && in_array($fcmErrorCode, self::INVALID_FCM_ERROR_CODES, true)) {
            return true;
        }

        return (string) ($result['error_status'] ?? '') === 'NOT_FOUND';
    }

    private function deactivateInvalidDevices(int $memberId, array $deviceIds): void
    {
        $deviceIds = array_values(array_unique(array_filter(array_map('intval', $deviceIds))));
        if ($deviceIds === []) {
            return;
        }

        $now = date('Y-m-d H:i:s');
        Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->whereIn('id', $deviceIds)
            ->where('is_active', 1)
            ->whereNull('delete_time')
            ->update([
                'is_active' => 2,
                'logout_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
    }

    private function fcmErrorCode(mixed $details): string
    {
        if (!is_array($details)) {
            return '';
        }

        foreach ($details as $detail) {
            if (!is_array($detail)) {
                continue;
            }
            if ((string) ($detail['@type'] ?? '') === 'type.googleapis.com/google.firebase.fcm.v1.FcmError') {
                return (string) ($detail['errorCode'] ?? '');
            }
        }

        return '';
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
