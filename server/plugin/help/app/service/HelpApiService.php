<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\exception\ApiException;
use think\facade\Db;

class HelpApiService
{
    private const DEFAULT_LOCALE = 'en-US';

    public function appConfig(): array
    {
        $groups = $this->configGroups([
            'help_google_oauth',
            'help_apple_oauth',
            'help_firebase_push',
        ]);
        $platforms = Db::table('sa_member_platform')
            ->whereIn('platform_code', ['GOOGLE', 'APPLE'])
            ->whereNull('delete_time')
            ->field('id, platform_name, platform_code, status')
            ->select()
            ->toArray();

        return [
            'app' => [
                'name' => 'HelpSupport',
                'api_prefix' => '/app/help',
                'default_locale' => self::DEFAULT_LOCALE,
                'supported_locales' => ['en-US', 'zh-CN'],
            ],
            'oauth' => [
                'google' => [
                    'enabled' => ($groups['help_google_oauth']['enabled'] ?? '2') === '1',
                    'web_client_id' => $groups['help_google_oauth']['web_client_id'] ?? '',
                    'ios_client_id' => $groups['help_google_oauth']['ios_client_id'] ?? '',
                    'android_client_id' => $groups['help_google_oauth']['android_client_id'] ?? '',
                ],
                'apple' => [
                    'enabled' => ($groups['help_apple_oauth']['enabled'] ?? '2') === '1',
                    'team_id' => $groups['help_apple_oauth']['team_id'] ?? '',
                    'bundle_id' => $groups['help_apple_oauth']['bundle_id'] ?? '',
                    'service_id' => $groups['help_apple_oauth']['service_id'] ?? '',
                    'key_id' => $groups['help_apple_oauth']['key_id'] ?? '',
                ],
            ],
            'push' => [
                'firebase_enabled' => ($groups['help_firebase_push']['enabled'] ?? '2') === '1',
                'firebase_project_id' => $groups['help_firebase_push']['project_id'] ?? '',
            ],
            'member_platforms' => $platforms,
        ];
    }

    public function onboarding(string $scene, string $version, string $locale): array
    {
        $locale = $locale !== '' ? $locale : self::DEFAULT_LOCALE;
        $rows = $this->queryOnboarding($scene, $version, $locale);
        if ($rows !== [] || $locale === self::DEFAULT_LOCALE) {
            return $rows;
        }

        return $this->queryOnboarding($scene, $version, self::DEFAULT_LOCALE);
    }

    public function profile(int $memberId, array $memberInfo): array
    {
        return [
            'member' => $memberInfo,
            'profile' => $this->rowByMember('sa_help_member_profile', $memberId),
            'doctor_profile' => $this->rowByMember('sa_help_doctor_profile', $memberId),
        ];
    }

    public function saveProfile(int $memberId, array $data): array
    {
        $payload = $this->only($data, [
            'member_role',
            'gender',
            'birthday',
            'bio',
            'recovery_goal',
            'trigger_tags',
            'locale',
            'timezone',
            'onboarding_version',
            'status',
        ]);

        if (isset($payload['member_role']) && !in_array($payload['member_role'], ['patient', 'doctor'], true)) {
            throw new ApiException('会员身份参数错误', 400);
        }
        if (isset($payload['gender'])) {
            $payload['gender'] = $this->intIn($payload['gender'], [1, 2, 3], '性别参数错误');
        }
        if (isset($payload['status'])) {
            $payload['status'] = $this->intIn($payload['status'], [1, 2], '状态参数错误');
        }
        if (array_key_exists('trigger_tags', $payload)) {
            $payload['trigger_tags'] = $this->jsonValue($payload['trigger_tags']);
        }

        $this->upsertByMember('sa_help_member_profile', $memberId, $payload);
        return $this->rowByMember('sa_help_member_profile', $memberId);
    }

    public function saveDoctorCertification(int $memberId, array $data): array
    {
        $payload = $this->only($data, [
            'real_name',
            'title',
            'hospital',
            'department',
            'specialty',
            'license_no',
            'certification_images',
        ]);
        if (empty($payload['real_name']) || empty($payload['license_no'])) {
            throw new ApiException('真实姓名和执业证书编号必须填写', 400);
        }
        if (array_key_exists('certification_images', $payload)) {
            $payload['certification_images'] = $this->jsonValue($payload['certification_images']);
        }

        $payload['audit_status'] = 0;
        $payload['audit_remark'] = '';
        $payload['audit_by'] = null;
        $payload['audit_time'] = null;
        $payload['approved_time'] = null;
        $payload['status'] = 1;

        Db::transaction(function () use ($memberId, $payload) {
            $this->upsertByMember('sa_help_member_profile', $memberId, [
                'member_role' => 'doctor',
                'status' => 1,
            ]);
            $this->upsertByMember('sa_help_doctor_profile', $memberId, $payload);
        });

        return $this->rowByMember('sa_help_doctor_profile', $memberId);
    }

    public function localModelCatalog(array $params): array
    {
        $query = Db::table('sa_local_model_catalog')
            ->where('status', 1)
            ->whereNull('delete_time');
        if (!empty($params['code'])) {
            $query->where('code', (string) $params['code']);
        }

        return $query
            ->field('id, name, code, provider, model_family, quantization, file_size, download_url, sha256, intro, intro_i18n, license, min_memory_mb, context_size, default_temperature, default_top_p, sort')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    public function localModelPrompts(array $params): array
    {
        $locale = (string) ($params['locale'] ?? self::DEFAULT_LOCALE);
        $query = Db::table('sa_local_model_prompt')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->whereIn('locale', [$locale, self::DEFAULT_LOCALE]);

        if (!empty($params['chat_mode'])) {
            $query->where('chat_mode', (string) $params['chat_mode']);
        }
        if (!empty($params['model_id'])) {
            $query->where(function ($query) use ($params) {
                $query->where('model_id', (int) $params['model_id'])->whereOr('model_id', null);
            });
        }

        return $query
            ->field('id, model_id, chat_mode, locale, title, system_prompt, first_message, safety_prompt')
            ->order('model_id', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    public function registerDevice(int $memberId, array $data): array
    {
        $deviceId = trim((string) ($data['device_id'] ?? ''));
        $platform = strtolower(trim((string) ($data['platform'] ?? '')));
        if ($deviceId === '') {
            throw new ApiException('设备标识必须填写', 400);
        }
        if (!in_array($platform, ['ios', 'android'], true)) {
            throw new ApiException('设备平台参数错误', 400);
        }

        $payload = $this->only($data, [
            'fcm_token',
            'apns_token',
            'app_version',
            'locale',
            'timezone',
        ]);
        $payload['device_id'] = $deviceId;
        $payload['platform'] = $platform;
        $payload['is_active'] = 1;
        $payload['last_active_time'] = date('Y-m-d H:i:s');
        $payload['logout_time'] = null;

        $exists = Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('device_id', $deviceId)
            ->where('platform', $platform)
            ->whereNull('delete_time')
            ->find();

        $now = date('Y-m-d H:i:s');
        if ($exists) {
            $payload['updated_by'] = $memberId;
            $payload['update_time'] = $now;
            Db::table('sa_member_push_device')->where('id', $exists['id'])->update($payload);
            return Db::table('sa_member_push_device')->where('id', $exists['id'])->find() ?: [];
        }

        $payload['member_id'] = $memberId;
        $payload['created_by'] = $memberId;
        $payload['updated_by'] = $memberId;
        $payload['create_time'] = $now;
        $payload['update_time'] = $now;
        $id = Db::table('sa_member_push_device')->insertGetId($payload);
        return Db::table('sa_member_push_device')->where('id', $id)->find() ?: [];
    }

    public function logoutDevice(int $memberId, array $data): bool
    {
        $deviceId = trim((string) ($data['device_id'] ?? ''));
        $platform = strtolower(trim((string) ($data['platform'] ?? '')));
        if ($deviceId === '' || $platform === '') {
            throw new ApiException('设备标识和平台必须填写', 400);
        }

        Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('device_id', $deviceId)
            ->where('platform', $platform)
            ->whereNull('delete_time')
            ->update([
                'is_active' => 2,
                'logout_time' => date('Y-m-d H:i:s'),
                'updated_by' => $memberId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);

        return true;
    }

    public function pushPreference(int $memberId): array
    {
        $row = $this->rowByMember('sa_member_push_preference', $memberId);
        if ($row !== []) {
            return $row;
        }

        return [
            'member_id' => $memberId,
            'is_push_enabled' => 1,
            'is_task_reminder_enabled' => 1,
            'is_community_enabled' => 1,
            'is_appointment_enabled' => 1,
            'is_audit_notice_enabled' => 1,
            'is_local_companion_enabled' => 1,
            'quiet_start_time' => null,
            'quiet_end_time' => null,
        ];
    }

    public function savePushPreference(int $memberId, array $data): array
    {
        $payload = $this->only($data, [
            'is_push_enabled',
            'is_task_reminder_enabled',
            'is_community_enabled',
            'is_appointment_enabled',
            'is_audit_notice_enabled',
            'is_local_companion_enabled',
            'quiet_start_time',
            'quiet_end_time',
        ]);

        foreach (array_keys($payload) as $key) {
            if (str_starts_with($key, 'is_')) {
                $payload[$key] = $this->intIn($payload[$key], [1, 2], $key . ' 参数错误');
            }
        }

        $this->upsertByMember('sa_member_push_preference', $memberId, $payload);
        return $this->rowByMember('sa_member_push_preference', $memberId);
    }

    private function rowByMember(string $table, int $memberId): array
    {
        $row = Db::table($table)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();

        return $row ?: [];
    }

    private function queryOnboarding(string $scene, string $version, string $locale): array
    {
        return Db::table('sa_app_onboarding_page')
            ->where('scene', $scene !== '' ? $scene : 'first_launch')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->where(function ($query) use ($version) {
                $query->where('version', $version)->whereOr('version', '');
            })
            ->where('locale', $locale)
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    private function upsertByMember(string $table, int $memberId, array $payload): void
    {
        $now = date('Y-m-d H:i:s');
        $exists = Db::table($table)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();

        if ($exists) {
            $payload['updated_by'] = $memberId;
            $payload['update_time'] = $now;
            Db::table($table)->where('id', $exists['id'])->update($payload);
            return;
        }

        $payload['member_id'] = $memberId;
        $payload['created_by'] = $memberId;
        $payload['updated_by'] = $memberId;
        $payload['create_time'] = $now;
        $payload['update_time'] = $now;
        Db::table($table)->insert($payload);
    }

    private function configGroups(array $codes): array
    {
        $rows = Db::table('sa_system_config_group')
            ->alias('g')
            ->leftJoin('sa_system_config c', 'c.group_id = g.id AND c.delete_time IS NULL')
            ->whereIn('g.code', $codes)
            ->whereNull('g.delete_time')
            ->field('g.code AS group_code, c.key, c.value')
            ->select()
            ->toArray();

        $groups = [];
        foreach ($rows as $row) {
            if (empty($row['key'])) {
                continue;
            }
            $groups[$row['group_code']][$row['key']] = (string) ($row['value'] ?? '');
        }

        return $groups;
    }

    private function only(array $data, array $keys): array
    {
        $result = [];
        foreach ($keys as $key) {
            if (array_key_exists($key, $data)) {
                $result[$key] = $data[$key];
            }
        }

        return $result;
    }

    private function intIn(mixed $value, array $allowed, string $message): int
    {
        $value = (int) $value;
        if (!in_array($value, $allowed, true)) {
            throw new ApiException($message, 400);
        }

        return $value;
    }

    private function jsonValue(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (is_string($value)) {
            json_decode($value, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new ApiException('JSON 参数格式错误', 400);
            }
            return $value;
        }

        return json_encode($value, JSON_UNESCAPED_UNICODE);
    }
}
