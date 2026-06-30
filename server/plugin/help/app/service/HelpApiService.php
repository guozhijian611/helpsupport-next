<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiadmin\app\logic\system\SystemAttachmentLogic;
use plugin\saiai\app\service\AiFactory;
use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\api\logic\common\IndexLogic;
use plugin\saiuser\app\admin\logic\member\MemberLogic;
use support\Request;
use think\facade\Db;
use Throwable;

class HelpApiService
{
    private const DEFAULT_LOCALE = 'en-US';
    private const DEFAULT_PROTOCOL_LOCALE = 'zh-CN';
    private const RISK_REVIEW_REMARK = '命中风控规则，需人工审核';
    private const EMAIL_CODE_EXPIRES_IN = 600;
    private const SMS_CODE_EXPIRES_IN = 300;
    private const CODE_RESEND_AFTER = 120;
    private const MATERIAL_MEDIA_TYPES = [
        'article',
        'image',
        'video',
        'audio',
        'pdf',
        'epub',
        'link',
        'txt',
        'mp4',
        'mov',
        'mp3',
    ];
    private const MATERIAL_UPLOAD_EXTENSIONS = ['txt', 'epub', 'pdf', 'mp4', 'mov', 'mp3', 'lrc', 'jpg', 'jpeg', 'png', 'webp', 'gif'];
    private const MATERIAL_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    private const MATERIAL_CATEGORY_NAMES = [
        'education' => ['入门', '动机与认知', '应对技能', '复发预防', '家属指南'],
        'entertainment' => ['书籍', '电影', '音乐', '游戏'],
        'private' => ['私人素材'],
    ];

    public function appConfig(): array
    {
        $groups = $this->configGroups([
            'help_google_oauth',
            'help_apple_oauth',
            'help_firebase_push',
        ]);
        $siteInfo = (array) Db::table('sa_site_info')
            ->where('id', 1)
            ->whereNull('delete_time')
            ->field('site_name, site_logo, site_desc')
            ->find();
        $platforms = Db::table('sa_member_platform')
            ->whereIn('platform_code', ['GOOGLE', 'APPLE'])
            ->whereNull('delete_time')
            ->field('id, platform_name, platform_code, status')
            ->select()
            ->toArray();

        return [
            'app' => [
                'name' => $this->firstFilled($siteInfo['site_name'] ?? null, 'HelpSupport'),
                'logo' => $this->firstFilled($siteInfo['site_logo'] ?? null),
                'description' => $this->firstFilled($siteInfo['site_desc'] ?? null),
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
                    'callback_strategy' => $groups['help_google_oauth']['callback_strategy'] ?? 'id_token',
                    'binding_strategy' => $groups['help_google_oauth']['binding_strategy'] ?? 'verified_email_or_create',
                ],
                'apple' => [
                    'enabled' => ($groups['help_apple_oauth']['enabled'] ?? '2') === '1',
                    'team_id' => $groups['help_apple_oauth']['team_id'] ?? '',
                    'bundle_id' => $groups['help_apple_oauth']['bundle_id'] ?? '',
                    'service_id' => $groups['help_apple_oauth']['service_id'] ?? '',
                    'key_id' => $groups['help_apple_oauth']['key_id'] ?? '',
                    'callback_strategy' => $groups['help_apple_oauth']['callback_strategy'] ?? 'id_token',
                    'binding_strategy' => $groups['help_apple_oauth']['binding_strategy'] ?? 'verified_email_or_create',
                ],
            ],
            'push' => [
                'firebase_enabled' => ($groups['help_firebase_push']['enabled'] ?? '2') === '1',
                'firebase_project_id' => $groups['help_firebase_push']['project_id'] ?? '',
            ],
            'member_platforms' => $platforms,
        ];
    }

    private function firstFilled(?string ...$values): string
    {
        foreach ($values as $value) {
            $trimmed = trim((string) $value);
            if ($trimmed !== '') {
                return $trimmed;
            }
        }

        return '';
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

    public function protocol(int $type, string $locale = ''): array
    {
        if ($type <= 0) {
            throw new ApiException('协议类型参数错误', 400);
        }

        $fallbackLocales = $this->protocolLocaleCandidates($locale);

        $protocol = [];
        foreach ($fallbackLocales as $candidateLocale) {
            $protocol = $this->queryProtocol($type, $candidateLocale);
            if ($protocol !== []) {
                break;
            }
        }
        if ($protocol === []) {
            throw new ApiException('协议内容未配置', 404);
        }

        return $protocol;
    }

    public function profile(int $memberId, array $memberInfo): array
    {
        $member = $this->member($memberId);
        $profile = $this->rowByMember('sa_help_member_profile', $memberId);
        $doctorProfile = $this->rowByMember('sa_help_doctor_profile', $memberId);

        return [
            'member' => $member,
            'profile' => $profile,
            'doctor_profile' => $doctorProfile,
            'current_role' => $this->currentRole($profile, $doctorProfile),
            'role_flags' => $this->roleFlags($profile, $doctorProfile),
        ];
    }

    public function saveProfile(int $memberId, array $data): array
    {
        $hasNickname = array_key_exists('nickname', $data);
        $nickname = trim((string) ($data['nickname'] ?? ''));
        if ($hasNickname && $nickname === '') {
            throw new ApiException('昵称必须填写', 400);
        }

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
        if (($payload['member_role'] ?? '') === 'doctor' && !$this->hasApprovedDoctorProfile($memberId)) {
            throw new ApiException('医生资质审核通过后才能切换为医生身份', 403);
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
        foreach (['bio', 'recovery_goal'] as $field) {
            if (array_key_exists($field, $payload)) {
                $payload[$field] = (new HelpRiskService())->filterText('profile', (string) $payload[$field]);
            }
        }

        Db::transaction(function () use ($memberId, $payload, $hasNickname, $nickname) {
            if ($hasNickname) {
                Db::table('sa_member')->where('id', $memberId)->update([
                    'nickname' => mb_substr($nickname, 0, 80),
                    'update_time' => date('Y-m-d H:i:s'),
                ]);
            }
            $this->upsertByMember('sa_help_member_profile', $memberId, $payload);
        });

        return $this->profile($memberId, $this->member($memberId));
    }

    public function updateProfileAvatar(int $memberId, Request $request): array
    {
        if ($request->file() === []) {
            throw new ApiException('头像图片必须上传', 400);
        }

        $upload = (new SystemAttachmentLogic())->uploadBase('image');
        $avatar = trim((string) ($upload['url'] ?? ''));
        if ($avatar === '') {
            throw new ApiException('头像上传失败，请稍后重试', 500);
        }

        Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->update([
                'avatar' => $avatar,
                'update_time' => date('Y-m-d H:i:s'),
            ]);

        return $this->profile($memberId, $this->member($memberId));
    }

    public function securityOverview(int $memberId): array
    {
        $member = $this->memberWithPassword($memberId);
        $devices = $this->securityDevices($memberId);

        return [
            'member' => [
                'id' => (int) ($member['id'] ?? 0),
                'email' => (string) ($member['email'] ?? ''),
                'mobile' => (string) ($member['mobile'] ?? ''),
                'has_password' => trim((string) ($member['password_hash'] ?? '')) !== '',
            ],
            'linked_accounts' => $this->securityLinkedAccounts($memberId),
            'devices' => $devices,
            'recent_logins' => $this->securityRecentLogins($memberId),
            'sso_enabled' => true,
            'active_device_count' => count(array_filter(
                $devices,
                static fn(array $row): bool => (int) ($row['is_active'] ?? 2) === 1
            )),
        ];
    }

    public function changeSecurityPassword(int $memberId, array $data): array
    {
        $member = $this->memberWithPassword($memberId);
        $oldPassword = (string) ($data['old_password'] ?? '');
        $newPassword = (string) ($data['new_password'] ?? '');

        if ($newPassword === '') {
            throw new ApiException('新密码必须填写', 400);
        }
        if (strlen($newPassword) < 6) {
            throw new ApiException('密码长度不能少于 6 位', 400);
        }

        $currentHash = trim((string) ($member['password_hash'] ?? ''));
        if ($currentHash !== '') {
            if ($oldPassword === '') {
                throw new ApiException('当前密码必须填写', 400);
            }
            if (!password_verify($oldPassword, $currentHash)) {
                throw new ApiException('当前密码错误', 400);
            }
        }

        Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->update([
                'password_hash' => password_hash($newPassword, PASSWORD_DEFAULT),
                'update_time' => date('Y-m-d H:i:s'),
            ]);

        return [
            'changed' => true,
            'has_password' => true,
        ];
    }

    public function sendSecurityEmailCode(int $memberId, array $data): array
    {
        $email = $this->normalizeEmail($data['email'] ?? '');
        $this->assertEmailChangeTarget($memberId, $email);
        $this->assertEmailBindable($memberId, $email);
        $this->sendEmailCode($email);

        return [
            'sent' => true,
            'target' => $this->maskEmail($email),
            'expires_in' => self::EMAIL_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function bindSecurityEmail(int $memberId, array $data): array
    {
        $email = $this->normalizeEmail($data['email'] ?? '');
        $emailCode = trim((string) ($data['email_code'] ?? ''));
        if ($emailCode === '') {
            throw new ApiException('邮箱验证码必须填写', 400);
        }

        $this->assertEmailChangeTarget($memberId, $email);
        $this->assertEmailBindable($memberId, $email);
        $this->consumeEmailCode($email, $emailCode);

        $platformId = $this->memberPlatformId('EMAIL');
        $now = date('Y-m-d H:i:s');

        Db::transaction(function () use ($memberId, $email, $platformId, $now) {
            Db::table('sa_member')
                ->where('id', $memberId)
                ->whereNull('delete_time')
                ->update([
                    'email' => $email,
                    'update_time' => $now,
                ]);

            $rel = Db::table('sa_member_platform_rel')
                ->where('member_id', $memberId)
                ->where('platform_id', $platformId)
                ->whereNull('delete_time')
                ->find();

            if ($rel) {
                Db::table('sa_member_platform_rel')->where('id', (int) $rel['id'])->update([
                    'platform_openid' => $email,
                    'is_bind' => 1,
                    'bind_time' => $now,
                    'update_time' => $now,
                ]);
            } else {
                Db::table('sa_member_platform_rel')->insert([
                    'member_id' => $memberId,
                    'platform_id' => $platformId,
                    'platform_openid' => $email,
                    'is_bind' => 1,
                    'bind_time' => $now,
                    'create_time' => $now,
                    'update_time' => $now,
                ]);
            }
        });

        return [
            'email' => $email,
            'email_bound' => true,
        ];
    }

    public function sendSecurityMobileCode(int $memberId, array $data): array
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $this->assertMobileChangeTarget($memberId, $mobile);
        $this->assertMobileBindable($memberId, $mobile);
        $this->sendSmsCode($mobile);

        return [
            'sent' => true,
            'target' => $this->maskMobile($mobile),
            'expires_in' => self::SMS_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function bindSecurityMobile(int $memberId, array $data): array
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $mobileCode = trim((string) ($data['mobile_code'] ?? ''));
        if ($mobileCode === '') {
            throw new ApiException('短信验证码必须填写', 400);
        }

        $this->assertMobileChangeTarget($memberId, $mobile);
        $this->assertMobileBindable($memberId, $mobile);
        $this->consumeSmsCode($mobile, $mobileCode);

        $platformId = $this->memberPlatformId('MOBILE');
        $now = date('Y-m-d H:i:s');

        Db::transaction(function () use ($memberId, $mobile, $platformId, $now) {
            Db::table('sa_member')
                ->where('id', $memberId)
                ->whereNull('delete_time')
                ->update([
                    'mobile' => $mobile,
                    'update_time' => $now,
                ]);

            $rel = Db::table('sa_member_platform_rel')
                ->where('member_id', $memberId)
                ->where('platform_id', $platformId)
                ->whereNull('delete_time')
                ->find();

            if ($rel) {
                Db::table('sa_member_platform_rel')->where('id', (int) $rel['id'])->update([
                    'platform_openid' => $mobile,
                    'is_bind' => 1,
                    'bind_time' => $now,
                    'update_time' => $now,
                ]);
            } else {
                Db::table('sa_member_platform_rel')->insert([
                    'member_id' => $memberId,
                    'platform_id' => $platformId,
                    'platform_openid' => $mobile,
                    'is_bind' => 1,
                    'bind_time' => $now,
                    'create_time' => $now,
                    'update_time' => $now,
                ]);
            }
        });

        return [
            'mobile' => $mobile,
            'mobile_bound' => true,
        ];
    }

    public function logoutOtherDevices(int $memberId, array $data): array
    {
        $currentDeviceId = trim((string) ($data['current_device_id'] ?? ''));
        $platform = strtolower(trim((string) ($data['platform'] ?? '')));
        $query = Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('is_active', 1)
            ->whereNull('delete_time');

        if ($currentDeviceId !== '') {
            $query->where(function ($subQuery) use ($currentDeviceId, $platform) {
                $subQuery->where('device_id', '<>', $currentDeviceId);
                if ($platform !== '') {
                    $subQuery->whereOr(function ($orQuery) use ($currentDeviceId, $platform) {
                        $orQuery->where('device_id', $currentDeviceId)
                            ->where('platform', '<>', $platform);
                    });
                }
            });
        }

        $affected = $query->update([
            'is_active' => 2,
            'logout_time' => date('Y-m-d H:i:s'),
            'updated_by' => $memberId,
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        return [
            'logged_out_devices' => (int) $affected,
        ];
    }

    public function saveDiagnosticLogUpload(int $memberId, array $data): array
    {
        $deviceId = mb_substr(trim((string) ($data['device_id'] ?? '')), 0, 64);
        $platform = strtolower(trim((string) ($data['platform'] ?? '')));
        $appVersion = mb_substr(trim((string) ($data['app_version'] ?? '')), 0, 40);
        $locale = mb_substr(trim((string) ($data['locale'] ?? '')), 0, 20);
        $timezone = mb_substr(trim((string) ($data['timezone'] ?? '')), 0, 64);
        $source = strtolower(trim((string) ($data['source'] ?? 'manual')));
        $entries = $data['entries'] ?? [];

        if ($platform !== '' && !in_array($platform, ['ios', 'android'], true)) {
            throw new ApiException('客户端平台参数错误', 400);
        }
        if (!in_array($source, ['manual', 'auto'], true)) {
            throw new ApiException('诊断日志来源参数错误', 400);
        }
        if (!is_array($entries) || $entries === []) {
            throw new ApiException('诊断日志内容不能为空', 400);
        }

        $entries = array_slice($entries, -200);
        $normalizedEntries = [];
        foreach ($entries as $entry) {
            if (!is_array($entry)) {
                continue;
            }

            $message = mb_substr(trim((string) ($entry['message'] ?? '')), 0, 400);
            if ($message === '') {
                continue;
            }
            $level = strtolower(trim((string) ($entry['level'] ?? 'info')));
            if (!in_array($level, ['info', 'warning', 'error'], true)) {
                $level = 'info';
            }
            $category = mb_substr(trim((string) ($entry['category'] ?? 'app')), 0, 80);
            $details = mb_substr(trim((string) ($entry['details'] ?? '')), 0, 12000);
            $createdAt = trim((string) ($entry['created_at'] ?? ''));

            $normalizedEntries[] = [
                'id' => mb_substr(trim((string) ($entry['id'] ?? '')), 0, 64),
                'level' => $level,
                'category' => $category === '' ? 'app' : $category,
                'message' => $message,
                'details' => $details,
                'created_at' => $createdAt,
            ];
        }

        if ($normalizedEntries === []) {
            throw new ApiException('诊断日志内容不能为空', 400);
        }

        $logEntries = json_encode($normalizedEntries, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($logEntries === false) {
            throw new ApiException('诊断日志编码失败', 500);
        }
        if (strlen($logEntries) > 300000) {
            throw new ApiException('诊断日志内容过大，请精简后重试', 400);
        }

        $firstLogAt = trim((string) ($data['first_log_at'] ?? ''));
        $lastLogAt = trim((string) ($data['last_log_at'] ?? ''));
        $firstLogAt = $firstLogAt !== '' && strtotime($firstLogAt) !== false
            ? date('Y-m-d H:i:s', strtotime($firstLogAt))
            : null;
        $lastLogAt = $lastLogAt !== '' && strtotime($lastLogAt) !== false
            ? date('Y-m-d H:i:s', strtotime($lastLogAt))
            : null;

        $uploadedAt = date('Y-m-d H:i:s');
        $payload = [
            'device_id' => $deviceId,
            'platform' => $platform,
            'app_version' => $appVersion,
            'locale' => $locale,
            'timezone' => $timezone,
            'source' => $source,
            'entry_count' => count($normalizedEntries),
            'first_log_time' => $firstLogAt,
            'last_log_time' => $lastLogAt,
            'log_summary' => mb_substr((string) ($normalizedEntries[array_key_last($normalizedEntries)]['message'] ?? ''), 0, 255),
            'log_entries' => $logEntries,
            'status' => 1,
            'remark' => null,
        ];
        $id = $this->saveRow('sa_member_diagnostic_log', $payload, $memberId);

        return [
            'id' => $id,
            'entry_count' => count($normalizedEntries),
            'uploaded_at' => $uploadedAt,
        ];
    }

    public function markOnboardingSeen(int $memberId, string $version): array
    {
        $version = trim($version);

        $this->upsertByMember('sa_help_member_profile', $memberId, [
            'onboarding_version' => $version,
            'status' => 1,
        ]);

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

    public function uploadDoctorCertificationImage(Request $request): array
    {
        if ($request->file() === []) {
            throw new ApiException('医生资质图片必须上传', 400);
        }

        $upload = (new SystemAttachmentLogic())->uploadBase('image');
        $url = trim((string) ($upload['url'] ?? ''));
        if ($url === '') {
            throw new ApiException('医生资质图片上传失败，请稍后重试', 500);
        }

        return [
            'url' => $url,
            'origin_name' => (string) ($upload['origin_name'] ?? ''),
            'mime_type' => (string) ($upload['mime_type'] ?? ''),
            'size_byte' => (int) ($upload['size_byte'] ?? 0),
        ];
    }

    private function queryProtocol(int $type, string $locale): array
    {
        return (array) Db::table('sa_member_protocol')
            ->where('protocol_type', $type)
            ->where('locale', $locale)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('id, protocol_type, locale, title, content, update_time')
            ->order('id', 'desc')
            ->find();
    }

    /**
     * Flutter 当前语言切换只会传 en / zh，这里统一归一化为协议存储使用的 locale。
     *
     * @return array<int, string>
     */
    private function protocolLocaleCandidates(string $locale): array
    {
        $locale = trim($locale);
        $normalized = $this->normalizeProtocolLocale($locale);
        $prefix = strtolower(strtok($normalized !== '' ? $normalized : $locale, '-_') ?: '');

        $candidates = [];
        if ($locale !== '') {
            $candidates[] = $locale;
        }
        if ($normalized !== '' && $normalized !== $locale) {
            $candidates[] = $normalized;
        }

        if ($prefix === 'en') {
            $candidates[] = self::DEFAULT_LOCALE;
            $candidates[] = self::DEFAULT_PROTOCOL_LOCALE;
        } else {
            $candidates[] = self::DEFAULT_PROTOCOL_LOCALE;
            $candidates[] = self::DEFAULT_LOCALE;
        }

        return array_values(array_unique(array_filter($candidates)));
    }

    private function normalizeProtocolLocale(string $locale): string
    {
        return match (strtolower(trim($locale))) {
            'en', 'en-us', 'en_us' => self::DEFAULT_LOCALE,
            'zh', 'zh-cn', 'zh_cn' => self::DEFAULT_PROTOCOL_LOCALE,
            default => trim($locale),
        };
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
        $modelId = (int) ($params['model_id'] ?? 0);
        if ($modelId > 0) {
            $query->where(function ($query) use ($modelId) {
                $query->where('model_id', $modelId)->whereOr('model_id', null);
            });
        } else {
            $query->whereNull('model_id');
        }

        return $query
            ->field('id, model_id, chat_mode, locale, title, system_prompt, first_message, safety_prompt')
            ->order('model_id', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    public function saveLocalModelDownloadLog(int $memberId, array $data): array
    {
        $model = $this->localModelByInput($data);
        $downloadStatus = trim((string) ($data['download_status'] ?? ''));
        if (!in_array($downloadStatus, ['started', 'success', 'failed', 'canceled'], true)) {
            throw new ApiException('模型下载状态参数错误', 400);
        }

        $payload = $this->only($data, [
            'platform',
            'app_version',
            'locale',
            'downloaded_size',
            'sha256',
            'duration_seconds',
            'error_code',
            'error_message',
            'started_at',
            'finished_at',
            'ext',
            'remark',
        ]);
        $payload['model_id'] = (int) $model['id'];
        $payload['model_code'] = (string) $model['code'];
        $payload['model_name'] = (string) $model['name'];
        $payload['download_status'] = $downloadStatus;
        $payload['file_size'] = (int) ($model['file_size'] ?? 0);
        $payload['downloaded_size'] = max(0, (int) ($payload['downloaded_size'] ?? 0));
        $payload['duration_seconds'] = max(0, (int) ($payload['duration_seconds'] ?? 0));
        foreach (['platform', 'app_version', 'locale', 'sha256', 'error_code', 'error_message'] as $field) {
            $payload[$field] = trim((string) ($payload[$field] ?? ''));
        }
        if ($payload['platform'] !== '' && !in_array($payload['platform'], ['ios', 'android'], true)) {
            throw new ApiException('客户端平台参数错误', 400);
        }
        if (array_key_exists('ext', $payload)) {
            $payload['ext'] = $this->jsonValue($payload['ext']);
        }
        foreach (['started_at', 'finished_at'] as $field) {
            if (array_key_exists($field, $payload) && trim((string) $payload[$field]) === '') {
                $payload[$field] = null;
            }
        }
        if (empty($payload['started_at'])) {
            $payload['started_at'] = date('Y-m-d H:i:s');
        }
        if (in_array($downloadStatus, ['success', 'failed', 'canceled'], true) && empty($payload['finished_at'])) {
            $payload['finished_at'] = date('Y-m-d H:i:s');
        }
        $payload['status'] = 1;

        $id = $this->saveRow('sa_local_model_download_log', $payload, $memberId);
        return Db::table('sa_local_model_download_log')->where('id', $id)->find() ?: [];
    }

    public function chatOverview(int $memberId): array
    {
        $modes = [];
        foreach ($this->chatModes() as $mode) {
            $latestSession = Db::table('sa_member_chat_session')
                ->where('member_id', $memberId)
                ->where('chat_mode', $mode)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->order('is_pinned', 'asc')
                ->orderRaw('last_message_time IS NULL ASC')
                ->order('last_message_time', 'desc')
                ->order('id', 'desc')
                ->find() ?: [];

            $modes[] = [
                'chat_mode' => $mode,
                'prompt_text' => (string) Db::table('sa_member_chat_config')
                    ->where('member_id', $memberId)
                    ->where('chat_mode', $mode)
                    ->whereNull('delete_time')
                    ->value('prompt_text'),
                'session_count' => (int) Db::table('sa_member_chat_session')
                    ->where('member_id', $memberId)
                    ->where('chat_mode', $mode)
                    ->where('status', 1)
                    ->whereNull('delete_time')
                    ->count(),
                'latest_session' => $latestSession,
            ];
        }

        return [
            'modes' => $modes,
            'recent_sessions' => Db::table('sa_member_chat_session')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->order('is_pinned', 'asc')
                ->orderRaw('last_message_time IS NULL ASC')
                ->order('last_message_time', 'desc')
                ->order('id', 'desc')
                ->limit(10)
                ->select()
                ->toArray(),
        ];
    }

    public function chatConfigs(int $memberId, array $params): array
    {
        $query = Db::table('sa_member_chat_config')
            ->where('member_id', $memberId)
            ->whereNull('delete_time');
        if (!empty($params['chat_mode'])) {
            $query->where('chat_mode', $this->chatMode($params['chat_mode']));
        }

        return $query->order('id', 'asc')->select()->toArray();
    }

    public function saveChatConfig(int $memberId, array $data): array
    {
        $chatMode = $this->chatMode($data['chat_mode'] ?? '');
        $promptText = trim((string) ($data['prompt_text'] ?? ''));
        if ($promptText === '') {
            throw new ApiException('聊天提示词必须填写', 400);
        }

        $now = date('Y-m-d H:i:s');
        $exists = Db::table('sa_member_chat_config')
            ->where('member_id', $memberId)
            ->where('chat_mode', $chatMode)
            ->whereNull('delete_time')
            ->find();

        if ($exists) {
            Db::table('sa_member_chat_config')->where('id', $exists['id'])->update([
                'prompt_text' => $promptText,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            return Db::table('sa_member_chat_config')->where('id', $exists['id'])->find() ?: [];
        }

        $id = Db::table('sa_member_chat_config')->insertGetId([
            'member_id' => $memberId,
            'chat_mode' => $chatMode,
            'prompt_text' => $promptText,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return Db::table('sa_member_chat_config')->where('id', $id)->find() ?: [];
    }

    public function chatSessions(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_chat_session')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time');
            if (!empty($params['chat_mode'])) {
                $query->where('chat_mode', $this->chatMode($params['chat_mode']));
            }
            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('session_name', 'like', $keyword)
                        ->whereOr('last_message', 'like', $keyword);
                });
            }

            return $query
                ->order('is_pinned', 'asc')
                ->orderRaw('last_message_time IS NULL ASC')
                ->order('last_message_time', 'desc')
                ->order('id', 'desc');
        }, $params);
    }

    public function saveChatSession(int $memberId, array $data): array
    {
        $sessionId = (int) ($data['id'] ?? 0);
        $chatMode = $this->chatMode($data['chat_mode'] ?? '');
        $sessionName = trim((string) ($data['session_name'] ?? ''));
        $isPinned = $this->intIn($data['is_pinned'] ?? 2, [1, 2], '置顶参数错误');
        $now = date('Y-m-d H:i:s');

        if ($sessionId > 0) {
            $this->assertChatSession($memberId, $sessionId);
            $payload = [
                'chat_mode' => $chatMode,
                'is_pinned' => $isPinned,
                'updated_by' => $memberId,
                'update_time' => $now,
            ];
            if ($sessionName !== '') {
                $payload['session_name'] = $sessionName;
            }
            Db::table('sa_member_chat_session')->where('id', $sessionId)->update($payload);
            return Db::table('sa_member_chat_session')->where('id', $sessionId)->find() ?: [];
        }

        if ($sessionName === '') {
            $count = (int) Db::table('sa_member_chat_session')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->count();
            $sessionName = 'Conversation ' . ($count + 1);
        }

        $id = Db::table('sa_member_chat_session')->insertGetId([
            'member_id' => $memberId,
            'chat_mode' => $chatMode,
            'session_name' => $sessionName,
            'last_message' => '',
            'last_message_time' => null,
            'is_pinned' => $isPinned,
            'status' => 1,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return Db::table('sa_member_chat_session')->where('id', $id)->find() ?: [];
    }

    public function deleteChatSession(int $memberId, int $sessionId): array
    {
        $this->assertChatSession($memberId, $sessionId);
        $now = date('Y-m-d H:i:s');
        Db::transaction(function () use ($memberId, $sessionId, $now) {
            Db::table('sa_member_chat_session')->where('id', $sessionId)->update([
                'status' => 2,
                'delete_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            Db::table('sa_member_chat_record')
                ->where('member_id', $memberId)
                ->where('session_id', $sessionId)
                ->whereNull('delete_time')
                ->update([
                    'status' => 2,
                    'delete_time' => $now,
                    'updated_by' => $memberId,
                    'update_time' => $now,
                ]);
        });

        return ['id' => $sessionId, 'deleted' => true];
    }

    public function chatRecords(int $memberId, array $params): array
    {
        $sessionId = (int) ($params['session_id'] ?? 0);
        if ($sessionId > 0) {
            $this->assertChatSession($memberId, $sessionId);
        }

        return $this->paginate(function () use ($memberId, $params, $sessionId) {
            $query = Db::table('sa_member_chat_record')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time');
            if ($sessionId > 0) {
                $query->where('session_id', $sessionId);
            }
            if (!empty($params['chat_mode'])) {
                $query->where('chat_mode', $this->chatMode($params['chat_mode']));
            }

            return $query->order('message_time', 'asc')->order('id', 'asc');
        }, $params);
    }

    public function saveUserChatRecord(int $memberId, array $data): array
    {
        $sessionId = (int) ($data['session_id'] ?? 0);
        $content = trim((string) ($data['content'] ?? ''));
        $contentType = trim((string) ($data['content_type'] ?? 'text'));
        if ($sessionId <= 0) {
            throw new ApiException('会话ID必须填写', 400);
        }
        if ($content === '') {
            throw new ApiException('消息内容必须填写', 400);
        }
        $content = (new HelpRiskService())->filterText('chat', $content);
        if ($content === '') {
            throw new ApiException('消息内容必须填写', 400);
        }
        if (!in_array($contentType, ['text', 'image', 'file', 'voice'], true)) {
            throw new ApiException('消息类型参数错误', 400);
        }

        $session = $this->assertChatSession($memberId, $sessionId);
        $now = date('Y-m-d H:i:s');
        $summary = $this->chatSummary($content, $contentType);

        $id = Db::transaction(function () use ($memberId, $session, $sessionId, $content, $contentType, $summary, $now) {
            $recordId = Db::table('sa_member_chat_record')->insertGetId([
                'session_id' => $sessionId,
                'member_id' => $memberId,
                'chat_mode' => $session['chat_mode'],
                'role' => 'user',
                'content' => $content,
                'content_type' => $contentType,
                'token_count' => 0,
                'message_time' => $now,
                'ext' => null,
                'status' => 1,
                'created_by' => $memberId,
                'updated_by' => $memberId,
                'create_time' => $now,
                'update_time' => $now,
            ]);

            Db::table('sa_member_chat_session')->where('id', $sessionId)->update([
                'last_message' => $summary,
                'last_message_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);

            return $recordId;
        });

        return Db::table('sa_member_chat_record')->where('id', $id)->find() ?: [];
    }

    public function sendChatMessage(int $memberId, array $data): array
    {
        $sessionId = (int) ($data['session_id'] ?? 0);
        $content = trim((string) ($data['content'] ?? $data['message'] ?? ''));
        $contentType = trim((string) ($data['content_type'] ?? 'text'));
        $configId = max(0, (int) ($data['config_id'] ?? 0));

        if ($content === '') {
            throw new ApiException('消息内容必须填写', 400);
        }
        $content = (new HelpRiskService())->filterText('chat', $content);
        if ($content === '') {
            throw new ApiException('消息内容必须填写', 400);
        }
        if ($contentType !== 'text') {
            throw new ApiException('在线 AI 暂只支持文本消息', 400);
        }

        if ($sessionId > 0) {
            $session = $this->assertChatSession($memberId, $sessionId);
            $chatMode = (string) $session['chat_mode'];
            if (!empty($data['chat_mode']) && $this->chatMode($data['chat_mode']) !== $chatMode) {
                throw new ApiException('聊天模式与会话不匹配', 400);
            }
        } else {
            $chatMode = $this->chatMode($data['chat_mode'] ?? '');
            $session = [];
        }

        $history = $sessionId > 0 ? $this->chatHistory($memberId, $sessionId) : [];
        $prompt = $this->chatSystemPrompt($memberId, $chatMode);
        $aiResult = AiFactory::chatOnceByConfigId($this->chatAiMessage($prompt, $content), $history, $configId);
        $assistantContent = trim((string) ($aiResult['content'] ?? ''));
        if ($assistantContent === '') {
            throw new ApiException('AI 未返回有效内容', 502);
        }

        $now = date('Y-m-d H:i:s');
        return Db::transaction(function () use ($memberId, $session, $sessionId, $chatMode, $content, $contentType, $assistantContent, $aiResult, $configId, $now) {
            $activeSession = $session;
            if ($sessionId <= 0) {
                $count = (int) Db::table('sa_member_chat_session')
                    ->where('member_id', $memberId)
                    ->where('status', 1)
                    ->whereNull('delete_time')
                    ->count();
                $newSessionId = Db::table('sa_member_chat_session')->insertGetId([
                    'member_id' => $memberId,
                    'chat_mode' => $chatMode,
                    'session_name' => 'Conversation ' . ($count + 1),
                    'last_message' => '',
                    'last_message_time' => null,
                    'is_pinned' => 2,
                    'status' => 1,
                    'created_by' => $memberId,
                    'updated_by' => $memberId,
                    'create_time' => $now,
                    'update_time' => $now,
                ]);
                $activeSession = Db::table('sa_member_chat_session')->where('id', $newSessionId)->find() ?: [];
            }

            $activeSessionId = (int) ($activeSession['id'] ?? 0);
            $userRecord = $this->insertChatRecord(
                $memberId,
                $activeSessionId,
                $chatMode,
                'user',
                $content,
                $contentType,
                null,
                $now
            );
            $assistantRecord = $this->insertChatRecord(
                $memberId,
                $activeSessionId,
                $chatMode,
                'assistant',
                $assistantContent,
                'text',
                $this->jsonValue([
                    'ai_model' => (string) ($aiResult['model'] ?? ''),
                    'ai_type' => (string) ($aiResult['type'] ?? ''),
                    'config_id' => $configId,
                ]),
                $now
            );

            Db::table('sa_member_chat_session')->where('id', $activeSessionId)->update([
                'last_message' => $this->chatSummary($assistantContent),
                'last_message_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);

            return [
                'session' => Db::table('sa_member_chat_session')->where('id', $activeSessionId)->find() ?: [],
                'user_record' => $userRecord,
                'assistant_record' => $assistantRecord,
                'records' => [$userRecord, $assistantRecord],
            ];
        });
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

        return Db::transaction(function () use ($memberId, $payload, $exists) {
            $now = date('Y-m-d H:i:s');
            if ($exists) {
                $id = (int) $exists['id'];
                $payload['updated_by'] = $memberId;
                $payload['update_time'] = $now;
                Db::table('sa_member_push_device')->where('id', $id)->update($payload);
            } else {
                $payload['member_id'] = $memberId;
                $payload['created_by'] = $memberId;
                $payload['updated_by'] = $memberId;
                $payload['create_time'] = $now;
                $payload['update_time'] = $now;
                $id = (int) Db::table('sa_member_push_device')->insertGetId($payload);
            }

            $this->deactivateOtherPushDevices($memberId, $id, $now);
            return Db::table('sa_member_push_device')->where('id', $id)->find() ?: [];
        });
    }

    public function unregisterDevice(int $memberId, array $data): bool
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

    private function deactivateOtherPushDevices(int $memberId, int $activeDeviceId, string $now): void
    {
        if ($activeDeviceId <= 0) {
            return;
        }

        Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->where('id', '<>', $activeDeviceId)
            ->where('is_active', 1)
            ->whereNull('delete_time')
            ->update([
                'is_active' => 2,
                'logout_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
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

    public function homeSummary(int $memberId): array
    {
        $today = date('Y-m-d');

        return [
            'profile' => $this->rowByMember('sa_help_member_profile', $memberId),
            'unread_message_count' => (int) Db::table('sa_member_message')
                ->where('member_id', $memberId)
                ->where('is_read', 2)
                ->where('status', 1)
                ->whereNull('delete_time')
                ->count(),
            'today_tasks' => Db::table('sa_daily_task')
                ->where('member_id', $memberId)
                ->where('task_date', $today)
                ->whereNull('delete_time')
                ->order('start_time', 'asc')
                ->order('id', 'asc')
                ->select()
                ->toArray(),
            'upcoming_appointments' => Db::table('sa_doctor_appointment')
                ->where('member_id', $memberId)
                ->where('appoint_date', '>=', $today)
                ->whereIn('status', [0, 1])
                ->whereNull('delete_time')
                ->order('appoint_date', 'asc')
                ->order('appoint_time_slot', 'asc')
                ->limit(5)
                ->select()
                ->toArray(),
        ];
    }

    public function communityTags(int $memberId = 0): array
    {
        $rows = Db::table('sa_community_tag')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('id, tag_name, tag_name_i18n, color, sort')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        foreach ($rows as &$row) {
            $tagId = (int) ($row['id'] ?? 0);
            $row['tag_name_i18n'] = $this->decodeJsonArray($row['tag_name_i18n'] ?? null);
            $row['is_followed'] = $memberId > 0
                && $this->activeInteractionExists('sa_community_follow_tag', $memberId, 'tag_id', $tagId);
        }
        unset($row);

        return $rows;
    }

    public function communityMemberProfile(int $memberId, int $targetMemberId): array
    {
        $targetMemberId = $this->communityTargetMemberId($memberId, $targetMemberId);
        $member = $this->member($targetMemberId);
        $profile = $this->rowByMember('sa_help_member_profile', $targetMemberId);
        $doctorProfile = $this->rowByMember('sa_help_doctor_profile', $targetMemberId);

        return array_merge(
            $this->communityMemberPayload($memberId, $member, $profile, $doctorProfile),
            [
                'follow_count' => (int) Db::table('sa_community_follow_member')
                    ->where('member_id', $targetMemberId)
                    ->whereNull('delete_time')
                    ->count(),
                'follower_count' => (int) Db::table('sa_community_follow_member')
                    ->where('target_member_id', $targetMemberId)
                    ->whereNull('delete_time')
                    ->count(),
                'like_count' => (int) $this->visibleCommunityPostQuery($memberId)
                    ->where('p.member_id', $targetMemberId)
                    ->sum('p.like_count'),
                'post_count' => (int) $this->visibleCommunityPostQuery($memberId)
                    ->where('p.member_id', $targetMemberId)
                    ->count(),
            ]
        );
    }

    public function communityMemberPosts(int $memberId, array $params): array
    {
        $targetMemberId = $this->communityTargetMemberId($memberId, (int) ($params['member_id'] ?? 0));
        $this->member($targetMemberId);

        $page = $this->paginate(function () use ($memberId, $targetMemberId) {
            return $this->visibleCommunityPostQuery($memberId)
                ->where('p.member_id', $targetMemberId)
                ->field('p.*, m.nickname AS author_name, m.avatar AS author_avatar')
                ->order('p.is_top', 'asc')
                ->order('p.id', 'desc');
        }, $params);

        $page['list'] = $this->decorateCommunityPosts($page['list'], $memberId);
        return $page;
    }

    public function communityFollowingMembers(int $memberId, array $params): array
    {
        $targetMemberId = $this->communityTargetMemberId($memberId, (int) ($params['member_id'] ?? 0));
        $this->member($targetMemberId);

        $page = $this->paginate(function () use ($targetMemberId, $params) {
            $query = Db::table('sa_community_follow_member')
                ->alias('f')
                ->leftJoin('sa_member m', 'm.id = f.target_member_id AND m.delete_time IS NULL')
                ->leftJoin('sa_help_member_profile hp', 'hp.member_id = f.target_member_id AND hp.delete_time IS NULL')
                ->leftJoin('sa_help_doctor_profile dp', 'dp.member_id = f.target_member_id AND dp.delete_time IS NULL')
                ->where('f.member_id', $targetMemberId)
                ->whereNull('f.delete_time')
                ->where('m.status', 1)
                ->field(
                    'f.id AS relation_id, f.create_time AS relation_time, '
                    . 'm.id AS member_id, m.username, m.nickname, m.avatar, m.create_time AS member_create_time, '
                    . 'hp.bio, hp.recovery_goal, hp.member_role, hp.gender, hp.birthday, hp.create_time AS profile_create_time, '
                    . 'dp.audit_status AS doctor_audit_status, dp.status AS doctor_status, dp.title AS doctor_title, dp.specialty AS doctor_specialty'
                );

            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('m.nickname', 'like', $keyword)
                        ->whereOr('m.username', 'like', $keyword)
                        ->whereOr('hp.bio', 'like', $keyword)
                        ->whereOr('hp.recovery_goal', 'like', $keyword)
                        ->whereOr('dp.specialty', 'like', $keyword);
                });
            }

            return $query->order('f.id', 'desc');
        }, $params);

        $page['list'] = $this->decorateCommunityMembers($page['list'], $memberId);
        return $page;
    }

    public function communityFollowerMembers(int $memberId, array $params): array
    {
        $targetMemberId = $this->communityTargetMemberId($memberId, (int) ($params['member_id'] ?? 0));
        $this->member($targetMemberId);

        $page = $this->paginate(function () use ($targetMemberId, $params) {
            $query = Db::table('sa_community_follow_member')
                ->alias('f')
                ->leftJoin('sa_member m', 'm.id = f.member_id AND m.delete_time IS NULL')
                ->leftJoin('sa_help_member_profile hp', 'hp.member_id = f.member_id AND hp.delete_time IS NULL')
                ->leftJoin('sa_help_doctor_profile dp', 'dp.member_id = f.member_id AND dp.delete_time IS NULL')
                ->where('f.target_member_id', $targetMemberId)
                ->whereNull('f.delete_time')
                ->where('m.status', 1)
                ->field(
                    'f.id AS relation_id, f.create_time AS relation_time, '
                    . 'm.id AS member_id, m.username, m.nickname, m.avatar, m.create_time AS member_create_time, '
                    . 'hp.bio, hp.recovery_goal, hp.member_role, hp.gender, hp.birthday, hp.create_time AS profile_create_time, '
                    . 'dp.audit_status AS doctor_audit_status, dp.status AS doctor_status, dp.title AS doctor_title, dp.specialty AS doctor_specialty'
                );

            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('m.nickname', 'like', $keyword)
                        ->whereOr('m.username', 'like', $keyword)
                        ->whereOr('hp.bio', 'like', $keyword)
                        ->whereOr('hp.recovery_goal', 'like', $keyword)
                        ->whereOr('dp.specialty', 'like', $keyword);
                });
            }

            return $query->order('f.id', 'desc');
        }, $params);

        $page['list'] = $this->decorateCommunityMembers($page['list'], $memberId);
        return $page;
    }

    public function communityReviewPosts(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);
        $scope = trim((string) ($params['scope'] ?? 'pending'));
        $scope = $scope === 'reviewed' ? 'reviewed' : 'pending';

        $page = $this->paginate(function () use ($scope, $params) {
            $query = Db::table('sa_community_post')
                ->alias('p')
                ->leftJoin('sa_member m', 'm.id = p.member_id AND m.delete_time IS NULL')
                ->whereNull('p.delete_time')
                ->field('p.*, m.nickname AS author_name, m.avatar AS author_avatar');

            if ($scope === 'reviewed') {
                $query->whereIn('p.audit_status', [1, 2]);
            } else {
                $query->whereIn('p.audit_status', [0, 3]);
            }

            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('p.content', 'like', $keyword)
                        ->whereOr('m.nickname', 'like', $keyword);
                });
            }

            return $query->order('p.audit_status', 'desc')->order('p.id', 'desc');
        }, $params);

        $page['list'] = $this->decorateCommunityPosts($page['list'], $doctorId);
        return $page;
    }

    public function reviewCommunityPost(int $doctorId, array $data): array
    {
        $this->assertApprovedDoctor($doctorId);
        $postId = (int) ($data['post_id'] ?? 0);
        $auditStatus = $this->intIn($data['audit_status'] ?? 0, [1, 2], '审核状态参数错误');
        $auditRemark = trim((string) ($data['audit_remark'] ?? ''));
        if ($auditStatus === 2 && $auditRemark === '') {
            throw new ApiException('拒绝原因必须填写', 400);
        }

        $post = Db::table('sa_community_post')
            ->where('id', $postId)
            ->whereNull('delete_time')
            ->find();
        if (!$post) {
            throw new ApiException('帖子不存在', 404);
        }

        $now = date('Y-m-d H:i:s');
        Db::transaction(function () use ($postId, $auditStatus, $auditRemark, $doctorId, $post, $now) {
            Db::table('sa_community_post')->where('id', $postId)->update([
                'audit_status' => $auditStatus,
                'audit_remark' => $auditRemark,
                'audit_by' => $doctorId,
                'audit_time' => $now,
                'status' => $auditStatus === 1 ? 1 : 2,
                'updated_by' => $doctorId,
                'update_time' => $now,
            ]);
            (new HelpAuditLogService())->record(
                'community_post',
                $postId,
                'audit',
                $post['audit_status'] ?? null,
                $auditStatus,
                $auditRemark,
                $doctorId
            );
        });

        $authorMemberId = (int) ($post['member_id'] ?? 0);
        if ($authorMemberId > 0 && $authorMemberId !== $doctorId) {
            $approved = $auditStatus === 1;
            $this->notifyMemberSafely($authorMemberId, 'system_notice', [
                'title' => $approved ? '社区帖子审核已通过' : '社区帖子审核未通过',
                'content' => $approved
                    ? '你发布的社区帖子已通过审核，现在可以在社区展示。'
                    : '你发布的社区帖子未通过审核。' . ($auditRemark !== '' ? ' 原因：' . $auditRemark : ''),
            ], [
                'biz_type' => 'community_audit_result',
                'biz_id' => $postId,
                'route' => '/pages/community/detail',
                'payload' => [
                    'post_id' => $postId,
                    'audit_status' => $auditStatus,
                ],
            ]);
        }

        $updated = Db::table('sa_community_post')
            ->alias('p')
            ->leftJoin('sa_member m', 'm.id = p.member_id AND m.delete_time IS NULL')
            ->where('p.id', $postId)
            ->field('p.*, m.nickname AS author_name, m.avatar AS author_avatar')
            ->find() ?: [];

        return $this->decorateCommunityPosts([$updated], $doctorId)[0] ?? [];
    }

    public function communityPosts(int $memberId, array $params): array
    {
        $page = $this->paginate(function () use ($memberId, $params) {
            $query = $this->visibleCommunityPostQuery($memberId)
                ->field('p.*, m.nickname AS author_name, m.avatar AS author_avatar');
            $scope = trim((string) ($params['scope'] ?? 'public'));

            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where('p.content', 'like', $keyword);
            }
            if ($scope === 'following') {
                if ($memberId <= 0) {
                    $query->whereRaw('1 = 0');
                } else {
                    $query
                        ->leftJoin(
                            'sa_community_follow_member cf',
                            'cf.target_member_id = p.member_id AND cf.member_id = ' . $memberId . ' AND cf.delete_time IS NULL'
                        )
                        ->whereRaw('cf.id IS NOT NULL')
                        ->where('p.is_anonymous', '<>', 1);
                }
            }
            if ($scope === 'followed_topics') {
                if ($memberId <= 0) {
                    $query->whereRaw('1 = 0');
                } else {
                    $query->whereRaw(sprintf(
                        'EXISTS (
                            SELECT 1
                            FROM `sa_community_follow_tag` cft
                            INNER JOIN `sa_community_tag` ft
                                ON ft.`id` = cft.`tag_id`
                               AND ft.`status` = 1
                               AND ft.`delete_time` IS NULL
                            WHERE cft.`member_id` = %d
                              AND cft.`delete_time` IS NULL
                              AND JSON_CONTAINS(p.`tags`, JSON_QUOTE(ft.`tag_name`))
                        )',
                        $memberId
                    ));
                }
            }
            if ((int) ($params['mine'] ?? 2) === 1) {
                $query->where('p.member_id', $memberId);
            }

            return $query
                ->order('p.is_top', 'asc')
                ->order('p.id', 'desc');
        }, $params);

        $page['list'] = $this->decorateCommunityPosts($page['list'], $memberId);
        return $page;
    }

    public function communityPostDetail(int $memberId, int $postId): array
    {
        $post = $this->assertVisibleCommunityPost($memberId, $postId);

        Db::execute('UPDATE `sa_community_post` SET `view_count` = `view_count` + 1, `update_time` = NOW() WHERE `id` = ' . $postId);
        $post['view_count'] = ((int) ($post['view_count'] ?? 0)) + 1;

        return $this->decorateCommunityPosts([$post], $memberId)[0] ?? [];
    }

    public function uploadCommunityImage(Request $request): array
    {
        if ($request->file() === []) {
            throw new ApiException('社区图片必须上传', 400);
        }

        $upload = (new SystemAttachmentLogic())->uploadBase('image');
        $url = trim((string) ($upload['url'] ?? ''));
        if ($url === '') {
            throw new ApiException('社区图片上传失败，请稍后重试', 500);
        }

        return [
            'url' => $url,
            'origin_name' => (string) ($upload['origin_name'] ?? ''),
            'mime_type' => (string) ($upload['mime_type'] ?? ''),
            'size_byte' => (int) ($upload['size_byte'] ?? 0),
        ];
    }

    public function saveCommunityPost(int $memberId, array $data): array
    {
        $content = trim((string) ($data['content'] ?? ''));
        if ($content === '') {
            throw new ApiException('帖子内容必须填写', 400);
        }
        $riskResult = (new HelpRiskService())->filter('community', $content);
        $content = (string) $riskResult['text'];
        if ($content === '') {
            throw new ApiException('帖子内容必须填写', 400);
        }
        $reviewRequired = (bool) ($riskResult['review_required'] ?? false);

        $payload = [
            'member_id' => $memberId,
            'content' => $content,
            'images' => $this->jsonValue($data['images'] ?? null),
            'link_url' => trim((string) ($data['link_url'] ?? '')),
            'tags' => $this->jsonValue($data['tags'] ?? null),
            'is_anonymous' => $this->intIn($data['is_anonymous'] ?? 2, [1, 2], '匿名参数错误'),
            'is_doctor_post' => 2,
            'audit_status' => $reviewRequired ? 3 : 0,
            'audit_remark' => $reviewRequired ? self::RISK_REVIEW_REMARK : '',
            'status' => 1,
        ];

        $id = $this->saveRow('sa_community_post', $payload, $memberId);
        return $this->communityPostDetail($memberId, $id);
    }

    public function communityComments(int $memberId, array $params): array
    {
        $postId = (int) ($params['post_id'] ?? 0);
        $this->assertVisibleCommunityPost($memberId, $postId);
        $parentId = max(0, (int) ($params['parent_id'] ?? 0));
        $withReplies = (int) ($params['with_replies'] ?? 2) === 1;

        $page = $this->paginate(function () use ($memberId, $postId, $parentId, $withReplies) {
            $query = Db::table('sa_community_comment')
                ->alias('c')
                ->leftJoin('sa_member m', 'm.id = c.member_id AND m.delete_time IS NULL')
                ->leftJoin('sa_member rm', 'rm.id = c.reply_to_member_id AND rm.delete_time IS NULL')
                ->where('c.post_id', $postId)
                ->where('c.status', 1)
                ->whereNull('c.delete_time')
                ->where(function ($query) use ($memberId) {
                    $query->where('c.audit_status', 1)->whereOr('c.member_id', $memberId);
                })
                ->field('c.*, m.nickname AS author_name, m.avatar AS author_avatar, rm.nickname AS reply_to_member_name');

            if ($parentId > 0) {
                $query->where('c.parent_id', $parentId);
            } elseif (!$withReplies) {
                $query->where('c.parent_id', 0);
            }

            if ($withReplies) {
                $query->orderRaw('CASE WHEN c.parent_id = 0 THEN c.id ELSE c.parent_id END ASC')
                    ->order('c.parent_id', 'asc');
            }

            return $query->order('c.id', 'asc');
        }, $params);

        $page['list'] = $this->decorateCommunityComments($page['list'], $memberId);
        return $page;
    }

    public function saveCommunityComment(int $memberId, array $data): array
    {
        $postId = (int) ($data['post_id'] ?? 0);
        $this->assertVisibleCommunityPost($memberId, $postId);
        $parentId = max(0, (int) ($data['parent_id'] ?? 0));
        if ($parentId > 0) {
            $this->assertVisibleCommunityComment($memberId, $parentId);
        }

        $content = trim((string) ($data['content'] ?? ''));
        if ($content === '') {
            throw new ApiException('评论内容必须填写', 400);
        }
        $riskResult = (new HelpRiskService())->filter('community', $content);
        $content = (string) $riskResult['text'];
        if ($content === '') {
            throw new ApiException('评论内容必须填写', 400);
        }
        $reviewRequired = (bool) ($riskResult['review_required'] ?? false);

        $commentId = $this->saveRow('sa_community_comment', [
            'post_id' => $postId,
            'member_id' => $memberId,
            'parent_id' => $parentId,
            'reply_to_member_id' => (int) ($data['reply_to_member_id'] ?? 0) ?: null,
            'content' => $content,
            'attachments' => $this->jsonValue($data['attachments'] ?? null),
            'is_anonymous' => $this->intIn($data['is_anonymous'] ?? 2, [1, 2], '匿名参数错误'),
            'audit_status' => $reviewRequired ? 3 : 0,
            'audit_remark' => $reviewRequired ? self::RISK_REVIEW_REMARK : '',
            'status' => 1,
        ], $memberId);

        $comment = Db::table('sa_community_comment')
            ->alias('c')
            ->leftJoin('sa_member m', 'm.id = c.member_id AND m.delete_time IS NULL')
            ->where('c.id', $commentId)
            ->field('c.*, m.nickname AS author_name, m.avatar AS author_avatar')
            ->find() ?: [];

        return $this->decorateCommunityComments([$comment], $memberId)[0] ?? [];
    }

    public function toggleCommunityLike(int $memberId, array $data): array
    {
        $targetType = $this->intIn($data['target_type'] ?? 0, [1, 2], '点赞目标类型错误');
        $targetId = (int) ($data['target_id'] ?? 0);
        if ($targetType === 1) {
            $this->assertVisibleCommunityPost($memberId, $targetId);
        } else {
            $this->assertVisibleCommunityComment($memberId, $targetId);
        }

        $isActive = Db::transaction(function () use ($memberId, $targetType, $targetId) {
            $active = $this->toggleCommunityLikeRow($memberId, $targetType, $targetId);
            $this->syncCommunityCounter($targetType === 1 ? 'post' : 'comment', $targetId, 'like_count', $active);

            return $active;
        });

        return [
            'target_type' => $targetType,
            'target_id' => $targetId,
            'is_liked' => $isActive,
        ];
    }

    public function toggleCommunityCollect(int $memberId, int $postId): array
    {
        $this->assertVisibleCommunityPost($memberId, $postId);
        $isActive = $this->toggleInteraction('sa_community_collect', $memberId, 'post_id', $postId);
        $this->syncCommunityCounter('post', $postId, 'collect_count', $isActive);

        return ['post_id' => $postId, 'is_collected' => $isActive];
    }

    public function toggleCommunityFollowTag(int $memberId, int $tagId): array
    {
        $this->assertVisibleCommunityTag($tagId);
        $isActive = $this->toggleInteraction('sa_community_follow_tag', $memberId, 'tag_id', $tagId);

        return ['tag_id' => $tagId, 'is_followed' => $isActive];
    }

    public function toggleCommunityFollowMember(int $memberId, int $targetMemberId): array
    {
        $this->assertCommunityTargetMember($memberId, $targetMemberId);
        $isActive = $this->toggleInteraction('sa_community_follow_member', $memberId, 'target_member_id', $targetMemberId);
        if ($isActive) {
            $this->notifyCommunityFollow($memberId, $targetMemberId);
        }

        return array_merge(
            ['target_member_id' => $targetMemberId],
            $this->communityFollowState($memberId, $targetMemberId)
        );
    }

    public function reportCommunityTarget(int $memberId, array $data): array
    {
        $targetType = $this->intIn($data['target_type'] ?? 0, [1, 2, 3], '举报目标类型错误');
        $targetId = (int) ($data['target_id'] ?? 0);
        if ($targetId <= 0) {
            throw new ApiException('举报目标ID必须填写', 400);
        }
        if ($targetType === 1) {
            $this->assertVisibleCommunityPost($memberId, $targetId);
        } elseif ($targetType === 2) {
            $this->assertVisibleCommunityComment($memberId, $targetId);
        }

        $reason = trim((string) ($data['reason'] ?? ''));
        if ($reason === '') {
            throw new ApiException('举报原因必须填写', 400);
        }
        $risk = new HelpRiskService();
        $reason = $risk->filterText('community', $reason);
        $description = $risk->filterText('community', (string) ($data['description'] ?? ''));
        if ($reason === '') {
            throw new ApiException('举报原因必须填写', 400);
        }

        $id = $this->saveRow('sa_community_report', [
            'member_id' => $memberId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'reason' => $reason,
            'description' => $description,
            'handle_status' => 0,
        ], $memberId);

        return Db::table('sa_community_report')->where('id', $id)->find() ?: [];
    }

    public function reportMaterialTarget(int $memberId, array $data): array
    {
        $targetType = $this->intIn($data['target_type'] ?? 0, [1, 2], '举报目标类型错误');
        $targetId = (int) ($data['target_id'] ?? 0);
        if ($targetId <= 0) {
            throw new ApiException('举报目标ID必须填写', 400);
        }
        if ($targetType === 1) {
            $this->assertVisibleMaterial($memberId, $targetId);
        } else {
            $this->assertVisibleMaterialComment($memberId, $targetId);
        }

        $reason = trim((string) ($data['reason'] ?? ''));
        if ($reason === '') {
            throw new ApiException('举报原因必须填写', 400);
        }
        $risk = new HelpRiskService();
        $reason = $risk->filterText('material', $reason);
        $description = $risk->filterText('material', (string) ($data['description'] ?? ''));
        if ($reason === '') {
            throw new ApiException('举报原因必须填写', 400);
        }

        $id = $this->saveRow('sa_material_report', [
            'member_id' => $memberId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'reason' => $reason,
            'description' => $description,
            'handle_status' => 0,
        ], $memberId);

        return Db::table('sa_material_report')->where('id', $id)->find() ?: [];
    }

    public function materialCategories(int $memberId, array $params): array
    {
        $locale = (string) ($params['locale'] ?? '');
        $query = Db::table('sa_content_category')
            ->where('status', 1)
            ->whereNull('delete_time');

        if (!empty($params['type'])) {
            $type = (string) $params['type'];
            $query->where('type', $type);
            if ($type === 'private') {
                $query->where(function ($query) use ($memberId) {
                    $query->where('member_id', 0)->whereOr('member_id', $memberId);
                });
            } elseif (isset(self::MATERIAL_CATEGORY_NAMES[$type])) {
                $query->whereIn('name', self::MATERIAL_CATEGORY_NAMES[$type]);
                $query->where('member_id', 0);
            }
        } else {
            $query->where(function ($query) use ($memberId) {
                foreach (self::MATERIAL_CATEGORY_NAMES as $type => $names) {
                    $query->whereOr(function ($query) use ($type, $names, $memberId) {
                        $query->where('type', $type);
                        if ($type === 'private') {
                            $query->where(function ($query) use ($memberId) {
                                $query->where('member_id', 0)->whereOr('member_id', $memberId);
                            });
                            return;
                        }
                        $query->whereIn('name', $names)->where('member_id', 0);
                    });
                }
            });
        }

        $rows = $query
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();

        return array_map(fn (array $row): array => $this->localizeMaterialCategory($row, $locale), $rows);
    }

    public function savePrivateMaterialCategory(int $memberId, array $data): array
    {
        if ($memberId <= 0) {
            throw new ApiException('请先登录后再创建私人分类', 401);
        }

        $categoryId = (int) ($data['id'] ?? 0);
        $name = trim((string) ($data['name'] ?? ''));
        if ($name === '') {
            throw new ApiException('私人分类名称必须填写', 400);
        }
        $name = (new HelpRiskService())->filterText('material', $name);
        if ($name === '') {
            throw new ApiException('私人分类名称必须填写', 400);
        }

        if ($categoryId > 0) {
            $exists = Db::table('sa_content_category')
                ->where('id', $categoryId)
                ->where('member_id', $memberId)
                ->where('type', 'private')
                ->whereNull('delete_time')
                ->find();
            if (!$exists) {
                throw new ApiException('私人分类不存在或无权操作', 404);
            }
        }

        $status = (int) ($data['status'] ?? 1);
        if (!in_array($status, [1, 2], true)) {
            throw new ApiException('私人分类状态参数错误', 400);
        }

        $payload = [
            'member_id' => $memberId,
            'parent_id' => 0,
            'name' => $name,
            'name_i18n' => $this->jsonValue($data['name_i18n'] ?? null),
            'type' => 'private',
            'icon' => (string) ($data['icon'] ?? 'ri:folder-lock-line'),
            'sort' => max(0, (int) ($data['sort'] ?? 100)),
            'status' => $status,
        ];

        $id = $this->saveRow('sa_content_category', $payload, $memberId, $categoryId);

        return Db::table('sa_content_category')->where('id', $id)->find() ?: [];
    }

    public function materials(int $memberId, array $params): array
    {
        $locale = (string) ($params['locale'] ?? '');
        $page = $this->paginate(function () use ($memberId, $params) {
            $query = $this->visibleMaterialQuery($memberId)
                ->field('id, member_id, category_id, media_type, material_type, title, title_i18n, summary, summary_i18n, artist, album, cover_url, content_url, image_urls, lyric_url, duration_seconds, is_public, is_recommended, audit_status, audit_remark, view_count, like_count, collect_count, comment_count, sort, create_time');

            if (!empty($params['material_type'])) {
                $query->where('material_type', (string) $params['material_type']);
                if ((string) $params['material_type'] === 'private') {
                    $query->where('member_id', $memberId);
                }
            }
            if (!empty($params['category_id'])) {
                $query->where('category_id', (int) $params['category_id']);
            }
            if (!empty($params['media_type'])) {
                $query->where('media_type', (string) $params['media_type']);
            }
            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query
                        ->where('title', 'like', $keyword)
                        ->whereOr('summary', 'like', $keyword)
                        ->whereOr('title_i18n', 'like', $keyword)
                        ->whereOr('summary_i18n', 'like', $keyword);
                });
            }

            return $query->order('is_recommended', 'asc')->order('sort', 'asc')->order('id', 'desc');
        }, $params);

        $page['list'] = $this->localizeMaterialRows($page['list'], $locale);
        $page['list'] = $this->appendMaterialInteractionFlags($page['list'], $memberId);

        return $page;
    }

    public function materialDetail(int $memberId, int $materialId, string $locale = ''): array
    {
        $material = $this->visibleMaterialQuery($memberId)
            ->where('id', $materialId)
            ->find();
        if (!$material) {
            throw new ApiException('素材不存在或无权访问', 404);
        }

        Db::execute('UPDATE `sa_content_material` SET `view_count` = `view_count` + 1, `update_time` = NOW() WHERE `id` = ' . $materialId);

        $material['is_liked'] = $this->activeInteractionExists('sa_material_like', $memberId, 'material_id', $materialId);
        $material['is_collected'] = $this->activeInteractionExists('sa_material_collect', $memberId, 'material_id', $materialId);
        $history = Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->where('content_id', $materialId)
            ->where('content_type', 'material')
            ->whereNull('delete_time')
            ->field('progress, duration_seconds')
            ->find();
        $material['history_progress'] = (float) ($history['progress'] ?? 0);
        $material['history_duration_seconds'] = (int) ($history['duration_seconds'] ?? 0);
        $material['comments'] = Db::table('sa_material_comment')
            ->where('material_id', $materialId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->where(function ($query) use ($memberId) {
                $query->where('audit_status', 1)->whereOr('member_id', $memberId);
            })
            ->order('id', 'desc')
            ->limit(10)
            ->select()
            ->toArray();

        return $this->localizeMaterialRow($material, $locale);
    }

    public function savePrivateMaterial(int $memberId, array $data): array
    {
        $materialId = (int) ($data['id'] ?? 0);
        $mediaType = trim((string) ($data['media_type'] ?? 'article'));
        if (!in_array($mediaType, self::MATERIAL_MEDIA_TYPES, true)) {
            throw new ApiException('素材类型参数错误', 400);
        }

        $title = trim((string) ($data['title'] ?? ''));
        if ($title === '') {
            throw new ApiException('素材标题必须填写', 400);
        }

        if ($materialId > 0) {
            $exists = Db::table('sa_content_material')
                ->where('id', $materialId)
                ->where('member_id', $memberId)
                ->where('material_type', 'private')
                ->whereNull('delete_time')
                ->find();
            if (!$exists) {
                throw new ApiException('私人素材不存在或无权操作', 404);
            }
        }

        $categoryId = max(0, (int) ($data['category_id'] ?? 0));
        if ($categoryId > 0) {
            $category = Db::table('sa_content_category')
                ->where('id', $categoryId)
                ->where('type', 'private')
                ->where(function ($query) use ($memberId) {
                    $query->where('member_id', 0)->whereOr('member_id', $memberId);
                })
                ->where('status', 1)
                ->whereNull('delete_time')
                ->find();
            if (!$category) {
                throw new ApiException('私人素材分类不存在或已禁用', 404);
            }
        }

        $risk = new HelpRiskService();
        $titleRisk = $risk->filter('material', $title);
        $summaryRisk = $risk->filter('material', (string) ($data['summary'] ?? ''));
        $contentRisk = $risk->filter('material', (string) ($data['content_text'] ?? ''));
        $title = (string) $titleRisk['text'];
        $summary = (string) $summaryRisk['text'];
        $contentText = (string) $contentRisk['text'];
        if ($title === '') {
            throw new ApiException('素材标题必须填写', 400);
        }
        $reviewRequired = (bool) ($titleRisk['review_required'] ?? false)
            || (bool) ($summaryRisk['review_required'] ?? false)
            || (bool) ($contentRisk['review_required'] ?? false);

        $imageUrls = $this->normalizeImageUrls($data['image_urls'] ?? null);
        $coverUrl = (string) ($data['cover_url'] ?? '');
        $contentUrl = (string) ($data['content_url'] ?? '');
        if ($mediaType === 'image' && $imageUrls !== []) {
            $coverUrl = $coverUrl !== '' ? $coverUrl : $imageUrls[0];
            $contentUrl = $contentUrl !== '' ? $contentUrl : $imageUrls[0];
        }

        $payload = [
            'member_id' => $memberId,
            'category_id' => $categoryId,
            'media_type' => $mediaType,
            'material_type' => 'private',
            'title' => $title,
            'title_i18n' => $this->jsonValue($data['title_i18n'] ?? null),
            'summary' => $summary,
            'summary_i18n' => $this->jsonValue($data['summary_i18n'] ?? null),
            'artist' => mb_substr(trim((string) ($data['artist'] ?? '')), 0, 120),
            'album' => mb_substr(trim((string) ($data['album'] ?? '')), 0, 120),
            'cover_url' => $coverUrl,
            'content_url' => $contentUrl,
            'image_urls' => $imageUrls === [] ? null : $this->jsonValue($imageUrls),
            'lyric_url' => (string) ($data['lyric_url'] ?? ''),
            'content_text' => $contentText,
            'content_text_i18n' => $this->jsonValue($data['content_text_i18n'] ?? null),
            'tags' => $this->jsonValue($data['tags'] ?? null),
            'duration_seconds' => max(0, (int) ($data['duration_seconds'] ?? 0)),
            'is_public' => 2,
            'is_recommended' => 2,
            'audit_status' => 1,
            'audit_remark' => $reviewRequired ? self::RISK_REVIEW_REMARK : '',
            'status' => 1,
            'sort' => max(0, (int) ($data['sort'] ?? 100)),
        ];

        $id = $this->saveRow('sa_content_material', $payload, $memberId, $materialId);

        return $this->localizeMaterialRow(Db::table('sa_content_material')->where('id', $id)->find() ?: [], '');
    }

    public function deletePrivateMaterial(int $memberId, int $materialId): array
    {
        if ($memberId <= 0) {
            throw new ApiException('请先登录后再删除私人素材', 401);
        }
        if ($materialId <= 0) {
            throw new ApiException('请选择要删除的私人素材', 400);
        }

        $material = Db::table('sa_content_material')
            ->where('id', $materialId)
            ->where('member_id', $memberId)
            ->where('material_type', 'private')
            ->whereNull('delete_time')
            ->find();
        if (!$material) {
            throw new ApiException('私人素材不存在或无权操作', 404);
        }

        Db::table('sa_content_material')
            ->where('id', $materialId)
            ->where('member_id', $memberId)
            ->update([
                'status' => 2,
                'updated_by' => $memberId,
                'update_time' => date('Y-m-d H:i:s'),
                'delete_time' => date('Y-m-d H:i:s'),
            ]);

        return ['id' => $materialId];
    }

    public function deletePrivateMaterialCategory(int $memberId, int $categoryId): array
    {
        if ($memberId <= 0) {
            throw new ApiException('请先登录后再删除私人分类', 401);
        }
        if ($categoryId <= 0) {
            throw new ApiException('请选择要删除的私人分类', 400);
        }

        $category = Db::table('sa_content_category')
            ->where('id', $categoryId)
            ->where('member_id', $memberId)
            ->where('type', 'private')
            ->whereNull('delete_time')
            ->find();
        if (!$category) {
            throw new ApiException('私人分类不存在或无权操作', 404);
        }

        $usedCount = Db::table('sa_content_material')
            ->where('member_id', $memberId)
            ->where('category_id', $categoryId)
            ->where('material_type', 'private')
            ->whereNull('delete_time')
            ->count();
        if ((int) $usedCount > 0) {
            throw new ApiException('分类下还有私人素材，请先移动或删除素材', 400);
        }

        Db::table('sa_content_category')
            ->where('id', $categoryId)
            ->where('member_id', $memberId)
            ->update([
                'status' => 2,
                'updated_by' => $memberId,
                'update_time' => date('Y-m-d H:i:s'),
                'delete_time' => date('Y-m-d H:i:s'),
            ]);

        return ['id' => $categoryId];
    }

    public function uploadPrivateMaterialFile(Request $request): array
    {
        $file = current($request->file());
        if (!$file) {
            throw new ApiException('私人素材文件必须上传', 400);
        }

        $extension = strtolower((string) ($file->getUploadExtension() ?: pathinfo((string) $file->getUploadName(), PATHINFO_EXTENSION)));
        if (!in_array($extension, self::MATERIAL_UPLOAD_EXTENSIONS, true)) {
            throw new ApiException('私人素材仅支持 txt、epub、pdf、mp4、mov、mp3、lrc、jpg、jpeg、png、webp、gif 文件', 400);
        }

        $upload = (new SystemAttachmentLogic())->uploadBase(
            in_array($extension, self::MATERIAL_IMAGE_EXTENSIONS, true) ? 'image' : 'file'
        );
        $url = trim((string) ($upload['url'] ?? ''));
        if ($url === '') {
            throw new ApiException('私人素材上传失败，请稍后重试', 500);
        }

        return [
            'url' => $url,
            'origin_name' => (string) ($upload['origin_name'] ?? ''),
            'mime_type' => (string) ($upload['mime_type'] ?? ''),
            'suffix' => strtolower((string) ($upload['suffix'] ?? $extension)),
            'size_byte' => (int) ($upload['size_byte'] ?? 0),
        ];
    }

    public function saveMaterialHistory(int $memberId, array $data): array
    {
        $contentId = (int) ($data['content_id'] ?? 0);
        $contentType = trim((string) ($data['content_type'] ?? ''));
        $title = trim((string) ($data['title'] ?? ''));
        $route = trim((string) ($data['route'] ?? ''));
        if ($contentId <= 0 || $contentType === '' || $title === '' || $route === '') {
            throw new ApiException('内容ID、类型、标题和路由必须填写', 400);
        }

        $payload = $this->only($data, [
            'author_name',
            'progress',
            'duration_seconds',
        ]);
        $payload['progress'] = min(100, max(0, (float) ($payload['progress'] ?? 0)));
        $payload['duration_seconds'] = max(0, (int) ($payload['duration_seconds'] ?? 0));
        $payload['member_id'] = $memberId;
        $payload['content_id'] = $contentId;
        $payload['content_type'] = $contentType;
        $payload['title'] = $title;
        $payload['route'] = $route;
        $payload['viewed_at'] = date('Y-m-d H:i:s');

        $exists = Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->where('content_id', $contentId)
            ->where('content_type', $contentType)
            ->find();

        $historyId = (int) $this->saveRow('sa_member_content_history', $payload, $memberId, $exists['id'] ?? 0);
        $this->awardMaterialLearnBadges($memberId, $historyId);

        return Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->where('content_id', $contentId)
            ->where('content_type', $contentType)
            ->find() ?: [];
    }

    public function materialHistory(int $memberId, array $params): array
    {
        return $this->paginate(fn () => Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->order('viewed_at', 'desc')
            ->order('id', 'desc'), $params);
    }

    public function materialCollections(int $memberId, array $params): array
    {
        $locale = (string) ($params['locale'] ?? '');
        $page = $this->paginate(fn () => Db::table('sa_material_collect')
            ->alias('c')
            ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
            ->where('c.member_id', $memberId)
            ->where('m.status', 1)
            ->whereRaw(sprintf(
                "((m.`material_type` = 'private' AND m.`member_id` = %d) OR (m.`material_type` <> 'private' AND (m.`is_public` = 1 OR m.`member_id` = %d)))",
                $memberId,
                $memberId
            ))
            ->where(function ($query) use ($memberId) {
                $query->where('m.audit_status', 2)->whereOr('m.member_id', $memberId);
            })
            ->whereNull('c.delete_time')
            ->field('c.id AS collect_id, c.create_time AS collect_time, m.*')
            ->order('c.id', 'desc'), $params);
        $page['list'] = $this->localizeMaterialRows($page['list'], $locale);
        $page['list'] = $this->appendMaterialInteractionFlags($page['list'], $memberId);

        return $page;
    }

    public function materialComments(int $memberId, array $params): array
    {
        $materialId = (int) ($params['material_id'] ?? 0);
        $this->assertVisibleMaterial($memberId, $materialId);
        $parentId = max(0, (int) ($params['parent_id'] ?? 0));
        $withReplies = $parentId === 0 && (int) ($params['with_replies'] ?? 2) === 1;

        $page = $this->paginate(function () use ($memberId, $materialId, $parentId, $withReplies) {
            $query = Db::table('sa_material_comment')
                ->alias('c')
                ->leftJoin('sa_member m', 'm.id = c.member_id AND m.delete_time IS NULL')
                ->where('c.material_id', $materialId)
                ->where('c.status', 1)
                ->whereNull('c.delete_time')
                ->where(function ($query) use ($memberId) {
                    $query->where('c.audit_status', 1)->whereOr('c.member_id', $memberId);
                })
                ->field('c.*, m.nickname AS author_name, m.avatar AS author_avatar');
            if (!$withReplies) {
                $query->where('c.parent_id', $parentId);
            }

            return $query
                ->order('c.parent_id', 'asc')
                ->order('c.id', 'asc');
        }, $params);

        $page['list'] = $this->decorateMaterialComments($page['list'], $memberId);
        return $page;
    }

    public function saveMaterialComment(int $memberId, array $data): array
    {
        $materialId = (int) ($data['material_id'] ?? 0);
        $this->assertVisibleMaterial($memberId, $materialId);
        $parentId = max(0, (int) ($data['parent_id'] ?? 0));
        if ($parentId > 0) {
            $parent = $this->assertVisibleMaterialComment($memberId, $parentId);
            if ((int) ($parent['material_id'] ?? 0) !== $materialId) {
                throw new ApiException('父评论与素材不匹配', 400);
            }
        }

        $content = trim((string) ($data['content'] ?? ''));
        if ($content === '') {
            throw new ApiException('评论内容必须填写', 400);
        }
        $riskResult = (new HelpRiskService())->filter('material', $content);
        $content = (string) $riskResult['text'];
        if ($content === '') {
            throw new ApiException('评论内容必须填写', 400);
        }
        $reviewRequired = (bool) ($riskResult['review_required'] ?? false);

        $commentId = Db::transaction(function () use ($memberId, $materialId, $parentId, $content, $data, $reviewRequired) {
            $id = $this->saveRow('sa_material_comment', [
                'material_id' => $materialId,
                'member_id' => $memberId,
                'parent_id' => $parentId,
                'content' => $content,
                'attachments' => $this->jsonValue($data['attachments'] ?? null),
                'like_count' => 0,
                'audit_status' => $reviewRequired ? 3 : 1,
                'audit_remark' => $reviewRequired ? self::RISK_REVIEW_REMARK : '',
                'status' => 1,
            ], $memberId);
            if (!$reviewRequired) {
                $this->syncMaterialCounter($materialId, 'comment_count', true);
            }

            return $id;
        });

        $comment = Db::table('sa_material_comment')
            ->alias('c')
            ->leftJoin('sa_member m', 'm.id = c.member_id AND m.delete_time IS NULL')
            ->where('c.id', $commentId)
            ->field('c.*, m.nickname AS author_name, m.avatar AS author_avatar')
            ->find() ?: [];

        return $this->decorateMaterialComments([$comment], $memberId)[0] ?? [];
    }

    public function toggleMaterialCommentLike(int $memberId, int $commentId): array
    {
        $comment = $this->assertVisibleMaterialComment($memberId, $commentId);
        $isActive = $this->toggleInteraction('sa_material_comment_like', $memberId, 'comment_id', $commentId);
        $this->syncMaterialCommentCounter((int) $comment['id'], 'like_count', $isActive);

        return ['comment_id' => $commentId, 'is_liked' => $isActive];
    }

    public function toggleMaterialLike(int $memberId, int $materialId): array
    {
        $this->assertVisibleMaterial($memberId, $materialId);
        $isActive = $this->toggleInteraction('sa_material_like', $memberId, 'material_id', $materialId);
        $this->syncMaterialCounter($materialId, 'like_count', $isActive);

        return ['material_id' => $materialId, 'is_liked' => $isActive];
    }

    public function toggleMaterialCollect(int $memberId, int $materialId): array
    {
        $this->assertVisibleMaterial($memberId, $materialId);
        $isActive = $this->toggleInteraction('sa_material_collect', $memberId, 'material_id', $materialId);
        $this->syncMaterialCounter($materialId, 'collect_count', $isActive);

        return ['material_id' => $materialId, 'is_collected' => $isActive];
    }

    public function currentPlans(int $memberId): array
    {
        $plans = Db::table('sa_treatment_plan')
            ->where('member_id', $memberId)
            ->whereIn('status', [1, 2])
            ->whereNull('delete_time')
            ->order('id', 'desc')
            ->select()
            ->toArray();

        if ($plans === []) {
            return [];
        }

        $planIds = array_column($plans, 'id');
        $stages = Db::table('sa_treatment_stage')
            ->whereIn('plan_id', $planIds)
            ->whereNull('delete_time')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
        $stageMap = [];
        foreach ($stages as $stage) {
            $stageMap[$stage['plan_id']][] = $stage;
        }
        foreach ($plans as &$plan) {
            $plan['stages'] = $stageMap[$plan['id']] ?? [];
        }
        unset($plan);

        return $plans;
    }

    public function dailyTasks(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_daily_task')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');
            if (!empty($params['date'])) {
                $query->where('task_date', (string) $params['date']);
            }
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }

            return $query->order('task_date', 'desc')->order('start_time', 'asc')->order('id', 'asc');
        }, $params);
    }

    public function saveTaskStatus(int $memberId, array $data): array
    {
        $taskId = (int) ($data['task_id'] ?? 0);
        $status = $this->intIn($data['status'] ?? null, [0, 1, 2, 3], '任务状态参数错误');
        $task = Db::table('sa_daily_task')
            ->where('id', $taskId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$task) {
            throw new ApiException('任务不存在或无权操作', 404);
        }

        $payload = [
            'status' => $status,
            'completion_note' => (string) ($data['completion_note'] ?? ''),
            'completed_time' => $status === 1 ? date('Y-m-d H:i:s') : null,
        ];
        $shouldReward = (int) ($task['status'] ?? 0) !== 1 && $status === 1;
        Db::transaction(function () use ($memberId, $taskId, $payload, $task, $shouldReward) {
            $this->saveRow('sa_daily_task', $payload, $memberId, $taskId);
            if ($shouldReward) {
                $this->awardTaskCompletionRewards($memberId, $task);
            }
        });

        return Db::table('sa_daily_task')->where('id', $taskId)->find() ?: [];
    }

    public function memberBadges(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_badge')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            } else {
                $query->where('status', 1);
            }

            return $query->order('award_time', 'desc')->order('id', 'desc');
        }, $params);
    }

    public function memberPointLogs(int $memberId, array $params): array
    {
        $page = $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_point_log')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');
            if (!empty($params['change_type'])) {
                $query->where('change_type', (string) $params['change_type']);
            }
            if (!empty($params['source_type'])) {
                $query->where('source_type', (string) $params['source_type']);
            }

            return $query->order('id', 'desc');
        }, $params);
        $page['balance'] = (new HelpPointService())->balance($memberId);

        return $page;
    }

    public function assessmentResults(int $memberId, array $params): array
    {
        return $this->paginate(fn () => Db::table('sa_member_assessment_result')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->order('id', 'desc'), $params);
    }

    public function assessmentTaskDetail(int $memberId, int $taskId): array
    {
        $task = $this->assertMemberDailyTask($memberId, $taskId);
        if ((string) ($task['task_type'] ?? '') !== 'assessment'
            && (string) ($task['source'] ?? '') !== 'assessment') {
            throw new ApiException('当前任务不是评估量表任务', 400);
        }

        $scaleId = trim((string) ($task['source_id'] ?? ''));
        if ($scaleId === '') {
            throw new ApiException('当前评估任务未关联量表', 404);
        }

        $scale = Db::table('sa_doctor_assessment_scale')
            ->where('id', $scaleId)
            ->whereNull('delete_time')
            ->find();
        if (!$scale) {
            throw new ApiException('评估量表不存在或已删除', 404);
        }

        $result = Db::table('sa_member_assessment_result')
            ->where('member_id', $memberId)
            ->where('task_id', $taskId)
            ->whereNull('delete_time')
            ->find() ?: [];

        $task['attachments'] = $this->decodeJsonArray($task['attachments'] ?? null);
        $task['reminders'] = $this->decodeJsonArray($task['reminders'] ?? null);
        $scale['questions'] = $this->decodeJsonArray($scale['questions'] ?? null);
        $scale['scoring_rule'] = $this->decodeJsonArray($scale['scoring_rule'] ?? null);
        if ($result !== []) {
            $result['answers'] = $this->decodeJsonArray($result['answers'] ?? null);
            $result['assessment_snapshot'] = $this->decodeJsonArray($result['assessment_snapshot'] ?? null);
        }

        return [
            'task' => $task,
            'scale' => $scale,
            'result' => $result,
        ];
    }

    public function saveAssessmentResult(int $memberId, array $data): array
    {
        $title = trim((string) ($data['assessment_title'] ?? ''));
        if ($title === '') {
            throw new ApiException('量表名称必须填写', 400);
        }

        $payload = $this->only($data, [
            'doctor_id',
            'task_id',
            'assessment_id',
            'assessment_title',
            'task_title',
            'stage_key',
            'question_count',
            'total_score',
            'achieved_score',
            'result_level',
            'answers',
            'assessment_snapshot',
            'suggestions',
        ]);
        foreach (['answers', 'assessment_snapshot'] as $key) {
            if (array_key_exists($key, $payload)) {
                $payload[$key] = $this->jsonValue($payload[$key]);
            }
        }
        $payload['member_id'] = $memberId;
        $payload['assessment_title'] = $title;
        $payload['assessed_at'] = date('Y-m-d H:i:s');

        $existsId = 0;
        $taskId = (int) ($payload['task_id'] ?? 0);
        if ($taskId > 0) {
            $exists = Db::table('sa_member_assessment_result')
                ->where('member_id', $memberId)
                ->where('task_id', $taskId)
                ->find();
            $existsId = (int) ($exists['id'] ?? 0);
        }

        $id = $this->saveRow('sa_member_assessment_result', $payload, $memberId, $existsId);
        return Db::table('sa_member_assessment_result')->where('id', $id)->find() ?: [];
    }

    public function appointmentDoctors(array $params): array
    {
        return $this->paginate(function () use ($params) {
            $query = Db::table('sa_help_doctor_profile')
                ->alias('p')
                ->leftJoin('sa_member m', 'm.id = p.member_id AND m.delete_time IS NULL')
                ->where('p.audit_status', 1)
                ->where('p.status', 1)
                ->whereNull('p.delete_time')
                ->field('p.member_id AS doctor_id, p.real_name, p.title, p.hospital, p.department, p.specialty, p.approved_time, m.nickname, m.avatar');

            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('p.real_name', 'like', $keyword)
                        ->whereOr('p.hospital', 'like', $keyword)
                        ->whereOr('p.specialty', 'like', $keyword);
                });
            }

            return $query->order('p.approved_time', 'desc')->order('p.id', 'desc');
        }, $params);
    }

    public function appointmentSlots(array $params): array
    {
        $doctorId = (int) ($params['doctor_id'] ?? 0);
        if ($doctorId <= 0) {
            throw new ApiException('医生会员ID必须填写', 400);
        }

        $doctor = Db::table('sa_help_doctor_profile')
            ->where('member_id', $doctorId)
            ->where('audit_status', 1)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$doctor) {
            throw new ApiException('医生不存在或未通过审核', 404);
        }

        $date = trim((string) ($params['date'] ?? ''));
        $query = Db::table('sa_doctor_schedule')
            ->where('doctor_id', $doctorId)
            ->where('status', 1)
            ->whereRaw('`booked_count` < `capacity`')
            ->whereNull('delete_time');
        if ($date !== '') {
            $query->where('schedule_date', $date);
        } else {
            $query->where('schedule_date', '>=', date('Y-m-d'));
        }

        $rows = $query
            ->order('schedule_date', 'asc')
            ->order('start_time', 'asc')
            ->order('id', 'asc')
            ->limit(60)
            ->select()
            ->toArray();

        foreach ($rows as &$row) {
            $row['available_count'] = max(0, (int) ($row['capacity'] ?? 0) - (int) ($row['booked_count'] ?? 0));
        }
        unset($row);

        return $rows;
    }

    public function appointments(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_doctor_appointment')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }

            return $query->order('appoint_date', 'desc')->order('appoint_time_slot', 'desc')->order('id', 'desc');
        }, $params);
    }

    public function createAppointment(int $memberId, array $data): array
    {
        $id = Db::transaction(function () use ($memberId, $data) {
            $schedule = $this->lockAvailableSchedule($data);
            $doctorId = (int) $schedule['doctor_id'];
            if ($doctorId === $memberId) {
                throw new ApiException('不能预约自己', 400);
            }
            $this->assertNoActiveAppointmentForSchedule($memberId, (int) $schedule['id']);

            $payload = $this->only($data, ['meet_type', 'meet_link', 'remark']);
            $payload['member_id'] = $memberId;
            $payload['doctor_id'] = $doctorId;
            $payload['schedule_id'] = (int) $schedule['id'];
            $payload['appoint_date'] = (string) $schedule['schedule_date'];
            $payload['appoint_time_slot'] = (string) $schedule['time_slot'];
            $payload['meet_type'] = trim((string) ($payload['meet_type'] ?? '')) !== '' ? $payload['meet_type'] : $schedule['meet_type'];
            $payload['meet_link'] = trim((string) ($payload['meet_link'] ?? '')) !== '' ? $payload['meet_link'] : $schedule['meet_link'];
            $payload['price'] = (string) $schedule['price'];
            $payload['currency'] = (string) $schedule['currency'];
            $payload['status'] = 0;

            $appointmentId = $this->saveRow('sa_doctor_appointment', $payload, $memberId);
            Db::execute('UPDATE `sa_doctor_schedule` SET `booked_count` = `booked_count` + 1, `update_time` = NOW() WHERE `id` = ' . (int) $schedule['id']);

            return $appointmentId;
        });

        $doctorId = (int) Db::table('sa_doctor_appointment')->where('id', $id)->value('doctor_id');
        $appointment = Db::table('sa_doctor_appointment')->where('id', $id)->find() ?: [];
        $this->notifyMemberSafely($doctorId, 'appointment_update', [
            'status_text' => 'pending',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => $id,
            'route' => '/pages/doctor/appointments',
            'payload' => ['appointment_id' => $id],
        ]);

        return $appointment;
    }

    public function cancelAppointment(int $memberId, array $data): array
    {
        $appointmentId = (int) ($data['appointment_id'] ?? 0);
        $appointment = Db::table('sa_doctor_appointment')
            ->where('id', $appointmentId)
            ->where('member_id', $memberId)
            ->whereIn('status', [0, 1])
            ->whereNull('delete_time')
            ->find();
        if (!$appointment) {
            throw new ApiException('预约不存在或当前状态不可取消', 404);
        }

        Db::transaction(function () use ($memberId, $appointmentId, $appointment, $data) {
            $this->saveRow('sa_doctor_appointment', [
                'status' => 3,
                'cancel_by' => 'member',
                'cancel_reason' => (string) ($data['cancel_reason'] ?? ''),
                'canceled_at' => date('Y-m-d H:i:s'),
            ], $memberId, $appointmentId);
            $this->releaseAppointmentSchedule($appointment);
        });

        $updated = Db::table('sa_doctor_appointment')->where('id', $appointmentId)->find() ?: [];
        $this->notifyMemberSafely((int) $appointment['doctor_id'], 'appointment_update', [
            'status_text' => 'canceled',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => $appointmentId,
            'route' => '/pages/doctor/appointments',
            'payload' => ['appointment_id' => $appointmentId],
        ]);

        return $updated;
    }

    public function doctorPatients(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);

        return $this->paginate(function () use ($doctorId, $params) {
            $query = Db::table('sa_doctor_patient')
                ->alias('dp')
                ->leftJoin('sa_member m', 'm.id = dp.member_id AND m.delete_time IS NULL')
                ->leftJoin('sa_help_member_profile hp', 'hp.member_id = dp.member_id AND hp.delete_time IS NULL')
                ->where('dp.doctor_id', $doctorId)
                ->whereNull('dp.delete_time')
                ->field('dp.*, m.nickname, m.avatar, hp.gender, hp.birthday, hp.recovery_goal, hp.locale, hp.timezone');

            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('dp.status', (int) $params['status']);
            }
            if (!empty($params['keyword'])) {
                $keyword = '%' . trim((string) $params['keyword']) . '%';
                $query->where(function ($query) use ($keyword) {
                    $query->where('m.nickname', 'like', $keyword)
                        ->whereOr('hp.recovery_goal', 'like', $keyword);
                });
            }

            return $query->orderRaw('dp.bind_time IS NULL ASC')
                ->order('dp.bind_time', 'desc')
                ->order('dp.id', 'desc');
        }, $params);
    }

    public function bindDoctorPatient(int $doctorId, array $data): array
    {
        $this->assertApprovedDoctor($doctorId);
        $memberId = (int) ($data['member_id'] ?? 0);
        if ($memberId <= 0 || $memberId === $doctorId) {
            throw new ApiException('患者会员ID参数错误', 400);
        }

        return $this->upsertDoctorPatientRelation($doctorId, $memberId, (string) ($data['bind_source'] ?? 'manual'));
    }

    public function unbindDoctorPatient(int $doctorId, array $data): array
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $relation = $this->assertDoctorPatient($doctorId, $memberId);

        $now = date('Y-m-d H:i:s');
        Db::table('sa_doctor_patient')->where('id', $relation['id'])->update([
            'status' => 2,
            'unbind_time' => $now,
            'updated_by' => $doctorId,
            'update_time' => $now,
        ]);

        return Db::table('sa_doctor_patient')->where('id', $relation['id'])->find() ?: [];
    }

    public function doctorPatientPlans(int $doctorId, array $params): array
    {
        $memberId = (int) ($params['member_id'] ?? 0);
        $this->assertDoctorPatient($doctorId, $memberId);

        $query = Db::table('sa_treatment_plan')
            ->where('member_id', $memberId)
            ->where('doctor_id', $doctorId)
            ->whereNull('delete_time');
        if (isset($params['status']) && $params['status'] !== '') {
            $query->where('status', (int) $params['status']);
        }

        $plans = $query->order('id', 'desc')->select()->toArray();
        if ($plans === []) {
            return ['list' => []];
        }

        $planIds = array_column($plans, 'id');
        $stages = Db::table('sa_treatment_stage')
            ->whereIn('plan_id', $planIds)
            ->whereNull('delete_time')
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
        $stageMap = [];
        foreach ($stages as $stage) {
            $stageMap[$stage['plan_id']][] = $stage;
        }
        foreach ($plans as &$plan) {
            $plan['stages'] = $stageMap[$plan['id']] ?? [];
        }
        unset($plan);

        return ['list' => $plans];
    }

    public function saveDoctorTreatmentPlan(int $doctorId, array $data): array
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $this->assertDoctorPatient($doctorId, $memberId);

        $title = trim((string) ($data['title'] ?? ''));
        if ($title === '') {
            throw new ApiException('计划标题必须填写', 400);
        }

        $planId = (int) ($data['id'] ?? 0);
        if ($planId > 0) {
            $this->assertDoctorPlan($doctorId, $memberId, $planId);
        }

        $payload = $this->only($data, [
            'title',
            'description',
            'start_date',
            'end_date',
            'source_type',
            'status',
            'remark',
        ]);
        $payload['member_id'] = $memberId;
        $payload['doctor_id'] = $doctorId;
        $payload['title'] = $title;
        $payload['source_type'] = trim((string) ($payload['source_type'] ?? '')) !== ''
            ? (string) $payload['source_type']
            : 'manual';
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [1, 2, 3], '计划状态参数错误')
            : 1;
        foreach (['start_date', 'end_date'] as $field) {
            if (array_key_exists($field, $payload) && $payload[$field] === '') {
                $payload[$field] = null;
            }
        }

        $id = $this->saveRow('sa_treatment_plan', $payload, $doctorId, $planId);
        return Db::table('sa_treatment_plan')->where('id', $id)->find() ?: [];
    }

    public function saveDoctorTreatmentStage(int $doctorId, array $data): array
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $planId = (int) ($data['plan_id'] ?? 0);
        $this->assertDoctorPatient($doctorId, $memberId);
        $this->assertDoctorPlan($doctorId, $memberId, $planId);

        $stageName = trim((string) ($data['stage_name'] ?? ''));
        $startDate = trim((string) ($data['start_date'] ?? ''));
        $endDate = trim((string) ($data['end_date'] ?? ''));
        if ($stageName === '' || $startDate === '' || $endDate === '') {
            throw new ApiException('阶段名称、开始日期和结束日期必须填写', 400);
        }

        $stageId = (int) ($data['id'] ?? 0);
        if ($stageId > 0) {
            $stage = $this->assertDoctorStage($doctorId, $memberId, $stageId);
            if ((int) ($stage['plan_id'] ?? 0) !== $planId) {
                throw new ApiException('治疗阶段不属于所选治疗计划', 400);
            }
        }

        $sort = isset($data['sort']) && $data['sort'] !== ''
            ? (int) $data['sort']
            : ((int) Db::table('sa_treatment_stage')
                ->where('plan_id', $planId)
                ->whereNull('delete_time')
                ->max('sort')) + 10;

        $payload = $this->only($data, [
            'stage_key',
            'stage_name',
            'start_date',
            'end_date',
            'stage_target',
            'sort',
            'status',
            'remark',
        ]);
        $payload['plan_id'] = $planId;
        $payload['member_id'] = $memberId;
        $payload['stage_name'] = $stageName;
        $payload['start_date'] = $startDate;
        $payload['end_date'] = $endDate;
        $payload['sort'] = $sort > 0 ? $sort : 100;
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [0, 1, 2], '阶段状态参数错误')
            : 0;

        $id = $this->saveRow('sa_treatment_stage', $payload, $doctorId, $stageId);
        return Db::table('sa_treatment_stage')->where('id', $id)->find() ?: [];
    }

    public function doctorDailyTasks(int $doctorId, array $params): array
    {
        $memberId = (int) ($params['member_id'] ?? 0);
        $this->assertDoctorPatient($doctorId, $memberId);

        $planId = (int) ($params['plan_id'] ?? 0);
        if ($planId > 0) {
            $this->assertDoctorPlan($doctorId, $memberId, $planId);
        }
        $doctorPlanIds = $planId > 0 ? [$planId] : $this->doctorPlanIds($doctorId, $memberId);
        $doctorStageIds = $this->doctorStageIds($doctorPlanIds);

        return $this->paginate(function () use ($memberId, $params, $planId, $doctorId, $doctorPlanIds, $doctorStageIds) {
            $query = Db::table('sa_daily_task')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');
            if ($planId > 0) {
                $query->where('plan_id', $planId);
            } else {
                $query->where(function ($query) use ($doctorId, $doctorPlanIds, $doctorStageIds) {
                    $query->where('created_by', $doctorId);
                    if ($doctorPlanIds !== []) {
                        $query->whereOr('plan_id', 'in', $doctorPlanIds);
                    }
                    if ($doctorStageIds !== []) {
                        $query->whereOr('stage_id', 'in', $doctorStageIds);
                    }
                });
            }
            if (!empty($params['date'])) {
                $query->where('task_date', (string) $params['date']);
            }
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }

            return $query->order('task_date', 'desc')->order('start_time', 'asc')->order('id', 'asc');
        }, $params);
    }

    public function saveDoctorDailyTask(int $doctorId, array $data): array
    {
        $memberId = (int) ($data['member_id'] ?? 0);
        $this->assertDoctorPatient($doctorId, $memberId);

        $taskDate = trim((string) ($data['task_date'] ?? ''));
        $title = trim((string) ($data['title'] ?? ''));
        if ($taskDate === '' || $title === '') {
            throw new ApiException('任务日期和标题必须填写', 400);
        }

        $planId = (int) ($data['plan_id'] ?? 0);
        if ($planId > 0) {
            $this->assertDoctorPlan($doctorId, $memberId, $planId);
        }
        $stageId = (int) ($data['stage_id'] ?? 0);
        $stage = null;
        if ($stageId > 0) {
            $stage = $this->assertDoctorStage($doctorId, $memberId, $stageId);
            if ($planId > 0 && (int) ($stage['plan_id'] ?? 0) !== $planId) {
                throw new ApiException('任务阶段不属于所选治疗计划', 400);
            }
        }

        $taskId = (int) ($data['id'] ?? 0);
        if ($taskId > 0) {
            $this->assertDoctorDailyTask($doctorId, $memberId, $taskId);
        }

        $payload = $this->only($data, [
            'plan_id',
            'stage_id',
            'task_date',
            'start_time',
            'end_time',
            'title',
            'description',
            'task_type',
            'source',
            'source_id',
            'reminders',
            'attachments',
            'points_reward',
            'completion_note',
            'status',
            'remark',
        ]);
        foreach (['reminders', 'attachments'] as $field) {
            if (array_key_exists($field, $payload)) {
                $payload[$field] = $this->jsonValue($payload[$field]);
            }
        }
        foreach ([
            'plan_id' => 0,
            'stage_id' => 0,
            'points_reward' => 10,
        ] as $field => $default) {
            if (array_key_exists($field, $payload) && $payload[$field] === '') {
                $payload[$field] = $default;
            }
        }
        foreach (['start_time', 'end_time'] as $field) {
            if (array_key_exists($field, $payload) && $payload[$field] === '') {
                $payload[$field] = null;
            }
        }
        $payload['member_id'] = $memberId;
        if ($planId <= 0 && $stage !== null) {
            $payload['plan_id'] = (int) ($stage['plan_id'] ?? 0);
        }
        $payload['task_date'] = $taskDate;
        $payload['title'] = $title;
        $payload['task_type'] = trim((string) ($payload['task_type'] ?? '')) !== ''
            ? (string) $payload['task_type']
            : 'daily';
        $payload['source'] = trim((string) ($payload['source'] ?? '')) !== ''
            ? (string) $payload['source']
            : 'manual';
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [0, 1, 2, 3], '任务状态参数错误')
            : 0;

        $id = $this->saveRow('sa_daily_task', $payload, $doctorId, $taskId);
        return Db::table('sa_daily_task')->where('id', $id)->find() ?: [];
    }

    public function doctorTaskTemplateFolders(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);
        $query = Db::table('sa_doctor_task_template_folder')
            ->whereIn('doctor_id', [0, $doctorId])
            ->whereNull('delete_time');
        if (isset($params['status']) && $params['status'] !== '') {
            $query->where('status', (int) $params['status']);
        } else {
            $query->where('status', 1);
        }

        return $query->order('doctor_id', 'asc')->order('sort', 'asc')->order('id', 'asc')->select()->toArray();
    }

    public function saveDoctorTaskTemplateFolder(int $doctorId, array $data): array
    {
        $this->assertApprovedDoctor($doctorId);
        $name = trim((string) ($data['name'] ?? ''));
        if ($name === '') {
            throw new ApiException('文件夹名称必须填写', 400);
        }

        $id = trim((string) ($data['id'] ?? ''));
        if ($id !== '') {
          $folder = Db::table('sa_doctor_task_template_folder')
              ->where('id', $id)
              ->where('doctor_id', $doctorId)
              ->whereNull('delete_time')
              ->find();
          if (!$folder) {
              throw new ApiException('模板文件夹不存在或无权操作', 404);
          }
        } else {
            $id = bin2hex(random_bytes(16));
        }

        $payload = $this->only($data, [
            'name',
            'color',
            'sort',
            'status',
            'remark',
        ]);
        foreach ([
            'sort' => 100,
        ] as $field => $default) {
            if (array_key_exists($field, $payload) && $payload[$field] === '') {
                $payload[$field] = $default;
            }
        }
        $payload['doctor_id'] = $doctorId;
        $payload['name'] = $name;
        $payload['color'] = trim((string) ($payload['color'] ?? '')) !== ''
            ? (string) $payload['color']
            : '#5E8FE6';
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [1, 2], '文件夹状态参数错误')
            : 1;

        $now = date('Y-m-d H:i:s');
        if (Db::table('sa_doctor_task_template_folder')->where('id', $id)->whereNull('delete_time')->find()) {
            $payload['updated_by'] = $doctorId;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_task_template_folder')->where('id', $id)->update($payload);
        } else {
            $payload['id'] = $id;
            $payload['created_by'] = $doctorId;
            $payload['updated_by'] = $doctorId;
            $payload['create_time'] = $now;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_task_template_folder')->insert($payload);
        }

        return Db::table('sa_doctor_task_template_folder')->where('id', $id)->find() ?: [];
    }

    public function doctorTaskTemplates(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);
        $query = Db::table('sa_doctor_task_template')
            ->whereIn('doctor_id', [0, $doctorId])
            ->whereNull('delete_time');
        if (!empty($params['folder_id'])) {
            $query->where('folder_id', (string) $params['folder_id']);
        }
        if (!empty($params['stage'])) {
            $query->where('stage', (string) $params['stage']);
        }
        if (isset($params['status']) && $params['status'] !== '') {
            $query->where('status', (int) $params['status']);
        } else {
            $query->where('status', 1);
        }

        return $query->order('doctor_id', 'asc')->order('sort', 'asc')->order('id', 'asc')->select()->toArray();
    }

    public function saveDoctorTaskTemplate(int $doctorId, array $data): array
    {
        $this->assertApprovedDoctor($doctorId);
        $title = trim((string) ($data['title'] ?? ''));
        if ($title === '') {
            throw new ApiException('模板名称必须填写', 400);
        }

        $id = trim((string) ($data['id'] ?? ''));
        if ($id !== '') {
            $this->assertDoctorOwnedTemplate($doctorId, $id);
        } else {
            $id = bin2hex(random_bytes(16));
        }

        $payload = $this->only($data, [
            'folder_id',
            'stage',
            'title',
            'description',
            'task_type',
            'priority',
            'start_time',
            'end_time',
            'frequency',
            'reward_score',
            'color',
            'reminder_rule',
            'attachments',
            'sort',
            'status',
            'remark',
        ]);
        if (!empty($payload['folder_id'])) {
            $this->assertVisibleTemplateFolder($doctorId, (string) $payload['folder_id']);
        }
        foreach (['reminder_rule', 'attachments'] as $field) {
            if (array_key_exists($field, $payload)) {
                $payload[$field] = $this->jsonValue($payload[$field]);
            }
        }
        foreach ([
            'reward_score' => 0,
            'sort' => 100,
        ] as $field => $default) {
            if (array_key_exists($field, $payload) && $payload[$field] === '') {
                $payload[$field] = $default;
            }
        }
        $payload['doctor_id'] = $doctorId;
        $payload['title'] = $title;
        $payload['task_type'] = trim((string) ($payload['task_type'] ?? '')) !== ''
            ? (string) $payload['task_type']
            : 'daily';
        $payload['priority'] = trim((string) ($payload['priority'] ?? '')) !== ''
            ? (string) $payload['priority']
            : 'normal';
        $payload['start_time'] = trim((string) ($payload['start_time'] ?? '')) !== ''
            ? (string) $payload['start_time']
            : '09:00';
        $payload['end_time'] = trim((string) ($payload['end_time'] ?? '')) !== ''
            ? (string) $payload['end_time']
            : '09:30';
        $payload['frequency'] = trim((string) ($payload['frequency'] ?? '')) !== ''
            ? (string) $payload['frequency']
            : 'daily';
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [1, 2], '模板状态参数错误')
            : 1;

        $now = date('Y-m-d H:i:s');
        if (Db::table('sa_doctor_task_template')->where('id', $id)->whereNull('delete_time')->find()) {
            $payload['updated_by'] = $doctorId;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_task_template')->where('id', $id)->update($payload);
        } else {
            $payload['id'] = $id;
            $payload['created_by'] = $doctorId;
            $payload['updated_by'] = $doctorId;
            $payload['create_time'] = $now;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_task_template')->insert($payload);
        }

        return Db::table('sa_doctor_task_template')->where('id', $id)->find() ?: [];
    }

    public function doctorAssessmentScales(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);
        $query = Db::table('sa_doctor_assessment_scale')
            ->whereRaw(sprintf("((doctor_id = 0 AND status = 'published') OR doctor_id = %d)", $doctorId))
            ->whereNull('delete_time');
        if (!empty($params['stage'])) {
            $query->where('stage', (string) $params['stage']);
        }
        if (!empty($params['status'])) {
            $query->where('status', (string) $params['status']);
        }

        return $query->order('doctor_id', 'asc')->order('published_at', 'desc')->order('id', 'asc')->select()->toArray();
    }

    public function saveDoctorAssessmentScale(int $doctorId, array $data): array
    {
        $this->assertApprovedDoctor($doctorId);
        $title = trim((string) ($data['title'] ?? ''));
        if ($title === '') {
            throw new ApiException('量表名称必须填写', 400);
        }

        $id = trim((string) ($data['id'] ?? ''));
        if ($id !== '') {
            $this->assertDoctorOwnedAssessmentScale($doctorId, $id);
        } else {
            $id = bin2hex(random_bytes(16));
        }

        $payload = $this->only($data, [
            'title',
            'stage',
            'description',
            'total_score',
            'questions',
            'scoring_rule',
            'status',
            'published_at',
            'remark',
        ]);
        foreach (['questions', 'scoring_rule'] as $field) {
            if (array_key_exists($field, $payload)) {
                $payload[$field] = $this->jsonValue($payload[$field]);
            }
        }
        if (array_key_exists('published_at', $payload) && $payload['published_at'] === '') {
            $payload['published_at'] = null;
        }
        if (array_key_exists('total_score', $payload) && $payload['total_score'] === '') {
            $payload['total_score'] = 0;
        }
        $payload['doctor_id'] = $doctorId;
        $payload['title'] = $title;
        $payload['status'] = (string) ($payload['status'] ?? 'draft');
        if (!in_array($payload['status'], ['draft', 'published', 'disabled'], true)) {
            throw new ApiException('量表状态参数错误', 400);
        }
        if ($payload['status'] === 'published' && empty($payload['published_at'])) {
            $payload['published_at'] = date('Y-m-d H:i:s');
        }

        $now = date('Y-m-d H:i:s');
        if (Db::table('sa_doctor_assessment_scale')->where('id', $id)->whereNull('delete_time')->find()) {
            $payload['updated_by'] = $doctorId;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_assessment_scale')->where('id', $id)->update($payload);
        } else {
            $payload['id'] = $id;
            $payload['created_by'] = $doctorId;
            $payload['updated_by'] = $doctorId;
            $payload['create_time'] = $now;
            $payload['update_time'] = $now;
            Db::table('sa_doctor_assessment_scale')->insert($payload);
        }

        return Db::table('sa_doctor_assessment_scale')->where('id', $id)->find() ?: [];
    }

    public function publishDoctorAssessmentScale(int $doctorId, string $id): array
    {
        $id = trim($id);
        $this->assertApprovedDoctor($doctorId);
        $this->assertDoctorOwnedAssessmentScale($doctorId, $id);

        Db::table('sa_doctor_assessment_scale')->where('id', $id)->update([
            'status' => 'published',
            'published_at' => date('Y-m-d H:i:s'),
            'updated_by' => $doctorId,
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        return Db::table('sa_doctor_assessment_scale')->where('id', $id)->find() ?: [];
    }

    public function doctorAppointments(int $doctorId, array $params): array
    {
        $this->assertApprovedDoctor($doctorId);

        return $this->paginate(function () use ($doctorId, $params) {
            $query = Db::table('sa_doctor_appointment')
                ->where('doctor_id', $doctorId)
                ->whereNull('delete_time');
            if (isset($params['member_id']) && $params['member_id'] !== '') {
                $query->where('member_id', (int) $params['member_id']);
            }
            if (!empty($params['date'])) {
                $query->where('appoint_date', (string) $params['date']);
            }
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }

            return $query->order('appoint_date', 'desc')->order('appoint_time_slot', 'desc')->order('id', 'desc');
        }, $params);
    }

    public function confirmDoctorAppointment(int $doctorId, array $data): array
    {
        $appointment = $this->assertDoctorAppointment($doctorId, (int) ($data['appointment_id'] ?? 0), [0]);
        $meetType = trim((string) ($data['meet_type'] ?? ''));
        if ($meetType !== '' && !in_array($meetType, ['link', 'address', 'phone'], true)) {
            throw new ApiException('接诊方式参数错误', 400);
        }

        Db::transaction(function () use ($doctorId, $data, $appointment, $meetType) {
            Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->update([
                'status' => 1,
                'meet_type' => $meetType !== '' ? $meetType : null,
                'meet_link' => trim((string) ($data['meet_link'] ?? '')) ?: null,
                'confirm_remark' => (string) ($data['confirm_remark'] ?? ''),
                'confirmed_at' => date('Y-m-d H:i:s'),
                'updated_by' => $doctorId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
            $this->upsertDoctorPatientRelation($doctorId, (int) $appointment['member_id'], 'appointment');
        });

        $updated = Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->find() ?: [];
        $this->notifyMemberSafely((int) $appointment['member_id'], 'appointment_update', [
            'status_text' => 'confirmed',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => (int) $appointment['id'],
            'route' => '/pages/appointment/detail',
            'payload' => ['appointment_id' => (int) $appointment['id']],
        ]);

        return $updated;
    }

    public function finishDoctorAppointment(int $doctorId, array $data): array
    {
        $appointment = $this->assertDoctorAppointment($doctorId, (int) ($data['appointment_id'] ?? 0), [1]);
        Db::transaction(function () use ($doctorId, $appointment) {
            Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->update([
                'status' => 2,
                'finished_at' => date('Y-m-d H:i:s'),
                'updated_by' => $doctorId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
            $this->awardAppointmentDoneBadges((int) $appointment['member_id'], (int) $appointment['id']);
        });

        $updated = Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->find() ?: [];
        $this->notifyMemberSafely((int) $appointment['member_id'], 'appointment_update', [
            'status_text' => 'finished',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => (int) $appointment['id'],
            'route' => '/pages/appointment/detail',
            'payload' => ['appointment_id' => (int) $appointment['id']],
        ]);

        return $updated;
    }

    public function cancelDoctorAppointment(int $doctorId, array $data): array
    {
        $appointment = $this->assertDoctorAppointment($doctorId, (int) ($data['appointment_id'] ?? 0), [0, 1]);
        Db::transaction(function () use ($doctorId, $data, $appointment) {
            Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->update([
                'status' => 3,
                'cancel_by' => 'doctor',
                'cancel_reason' => (string) ($data['cancel_reason'] ?? ''),
                'canceled_at' => date('Y-m-d H:i:s'),
                'updated_by' => $doctorId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
            $this->releaseAppointmentSchedule($appointment);
        });

        $updated = Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->find() ?: [];
        $this->notifyMemberSafely((int) $appointment['member_id'], 'appointment_update', [
            'status_text' => 'canceled',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => (int) $appointment['id'],
            'route' => '/pages/appointment/detail',
            'payload' => ['appointment_id' => (int) $appointment['id']],
        ]);

        return $updated;
    }

    public function rejectDoctorAppointment(int $doctorId, array $data): array
    {
        $appointment = $this->assertDoctorAppointment($doctorId, (int) ($data['appointment_id'] ?? 0), [0]);
        Db::transaction(function () use ($doctorId, $data, $appointment) {
            Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->update([
                'status' => 4,
                'confirm_remark' => (string) ($data['confirm_remark'] ?? ''),
                'updated_by' => $doctorId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
            $this->releaseAppointmentSchedule($appointment);
        });

        $updated = Db::table('sa_doctor_appointment')->where('id', $appointment['id'])->find() ?: [];
        $this->notifyMemberSafely((int) $appointment['member_id'], 'appointment_update', [
            'status_text' => 'rejected',
        ], [
            'biz_type' => 'appointment',
            'biz_id' => (int) $appointment['id'],
            'route' => '/pages/appointment/detail',
            'payload' => ['appointment_id' => (int) $appointment['id']],
        ]);

        return $updated;
    }

    public function journals(int $memberId, array $params): array
    {
        return $this->paginate(fn () => Db::table('sa_member_journal')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->order('entry_date', 'desc')
            ->order('entry_time', 'desc')
            ->order('id', 'desc'), $params);
    }

    public function saveJournal(int $memberId, array $data): array
    {
        $entryDate = trim((string) ($data['entry_date'] ?? ''));
        $title = trim((string) ($data['title'] ?? ''));
        if ($entryDate === '' || $title === '') {
            throw new ApiException('日记日期和标题必须填写', 400);
        }

        $payload = $this->only($data, [
            'entry_date',
            'entry_time',
            'title',
            'content',
            'media',
            'mood_score',
            'is_private',
            'ai_access',
            'status',
            'remark',
        ]);
        if (array_key_exists('media', $payload)) {
            $payload['media'] = $this->jsonValue($payload['media']);
        }

        $journalId = (int) ($data['id'] ?? 0);
        if ($journalId > 0) {
            $exists = Db::table('sa_member_journal')
                ->where('id', $journalId)
                ->where('member_id', $memberId)
                ->whereNull('delete_time')
                ->find();
            if (!$exists) {
                throw new ApiException('日记不存在或无权操作', 404);
            }
        }

        $id = $this->saveRow('sa_member_journal', $payload, $memberId, $journalId);
        $this->awardJournalBadges($memberId, (int) $id);

        return Db::table('sa_member_journal')->where('id', $id)->find() ?: [];
    }

    public function deleteJournal(int $memberId, int $journalId): array
    {
        if ($journalId <= 0) {
            throw new ApiException('日记ID必须填写', 400);
        }

        $affected = Db::table('sa_member_journal')
            ->where('id', $journalId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->update([
                'delete_time' => date('Y-m-d H:i:s'),
                'updated_by' => $memberId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);

        return ['id' => $journalId, 'deleted' => $affected > 0];
    }

    public function memoirs(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_memoir')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time');

            if (!empty($params['source_month'])) {
                $query->where('source_month', trim((string) $params['source_month']));
            }

            return $query
                ->order('grant_level_rank', 'desc')
                ->order('source_month', 'desc')
                ->order('id', 'desc');
        }, $params);
    }

    public function memoirDetail(int $memberId, int $memoirId): array
    {
        $memoir = $this->assertOwnedRow('sa_member_memoir', $memberId, $memoirId, '回忆录不存在或无权访问');
        if ((int) ($memoir['status'] ?? 0) !== 1) {
            throw new ApiException('回忆录不存在或无权访问', 404);
        }

        return $memoir;
    }

    public function memoirConfigs(array $params): array
    {
        $query = Db::table('sa_member_memoir_config')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('id, name, code, generation_cycle, source_type, prompt_template, min_journal_count, start_day, sort');

        if (!empty($params['code'])) {
            $query->where('code', trim((string) $params['code']));
        }
        if (!empty($params['generation_cycle'])) {
            $query->where('generation_cycle', trim((string) $params['generation_cycle']));
        }
        if (!empty($params['source_type'])) {
            $query->where('source_type', trim((string) $params['source_type']));
        }

        return [
            'list' => $query
                ->order('sort', 'asc')
                ->order('id', 'asc')
                ->select()
                ->toArray(),
        ];
    }

    public function recoveryGoals(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_recovery_goal_log')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');

            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }
            if (!empty($params['goal_type'])) {
                $query->where('goal_type', trim((string) $params['goal_type']));
            }

            return $query
                ->orderRaw('target_date IS NULL ASC')
                ->order('target_date', 'asc')
                ->order('id', 'desc');
        }, $params);
    }

    public function saveRecoveryGoal(int $memberId, array $data): array
    {
        $goalText = trim((string) ($data['goal_text'] ?? ''));
        if ($goalText === '') {
            throw new ApiException('康复目标必须填写', 400);
        }

        $id = (int) ($data['id'] ?? 0);
        if ($id > 0) {
            $this->assertOwnedRow('sa_member_recovery_goal_log', $memberId, $id, '康复目标不存在或无权操作');
        }

        $payload = $this->only($data, [
            'goal_text',
            'goal_type',
            'target_date',
            'completed_time',
            'status',
            'remark',
        ]);
        $payload['goal_text'] = $goalText;
        $payload['goal_type'] = trim((string) ($payload['goal_type'] ?? '')) !== ''
            ? trim((string) $payload['goal_type'])
            : 'custom';
        if (!in_array($payload['goal_type'], ['custom', 'weekly', 'monthly'], true)) {
            throw new ApiException('康复目标类型参数错误', 400);
        }
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [1, 2, 3], '康复目标状态参数错误')
            : 1;
        foreach (['target_date', 'completed_time'] as $field) {
            if (array_key_exists($field, $payload) && trim((string) $payload[$field]) === '') {
                $payload[$field] = null;
            }
        }
        if ($payload['status'] === 2 && empty($payload['completed_time'])) {
            $payload['completed_time'] = date('Y-m-d H:i:s');
        }

        $rowId = $this->saveRow('sa_member_recovery_goal_log', $payload, $memberId, $id);
        return Db::table('sa_member_recovery_goal_log')->where('id', $rowId)->find() ?: [];
    }

    public function deleteRecoveryGoal(int $memberId, int $goalId): array
    {
        return $this->softDeleteOwnedRow('sa_member_recovery_goal_log', $memberId, $goalId, '康复目标ID必须填写');
    }

    public function triggerLogs(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_trigger_log')
                ->where('member_id', $memberId)
                ->whereNull('delete_time');

            if (!empty($params['trigger_type'])) {
                $query->where('trigger_type', trim((string) $params['trigger_type']));
            }
            if (isset($params['status']) && $params['status'] !== '') {
                $query->where('status', (int) $params['status']);
            }

            return $query->order('occurred_at', 'desc')->order('id', 'desc');
        }, $params);
    }

    public function saveTriggerLog(int $memberId, array $data): array
    {
        $triggerName = trim((string) ($data['trigger_name'] ?? ''));
        if ($triggerName === '') {
            throw new ApiException('触发因素名称必须填写', 400);
        }

        $id = (int) ($data['id'] ?? 0);
        if ($id > 0) {
            $this->assertOwnedRow('sa_member_trigger_log', $memberId, $id, '触发因素记录不存在或无权操作');
        }

        $payload = $this->only($data, [
            'trigger_name',
            'trigger_type',
            'intensity',
            'occurred_at',
            'response_action',
            'note',
            'status',
            'remark',
        ]);
        $payload['trigger_name'] = $triggerName;
        $payload['trigger_type'] = trim((string) ($payload['trigger_type'] ?? '')) !== ''
            ? trim((string) $payload['trigger_type'])
            : 'custom';
        if (!in_array($payload['trigger_type'], ['emotion', 'place', 'person', 'custom'], true)) {
            throw new ApiException('触发因素类型参数错误', 400);
        }
        $payload['intensity'] = (int) ($payload['intensity'] ?? 0);
        if ($payload['intensity'] < 0 || $payload['intensity'] > 10) {
            throw new ApiException('触发因素强度必须在0到10之间', 400);
        }
        $payload['occurred_at'] = trim((string) ($payload['occurred_at'] ?? '')) !== ''
            ? trim((string) $payload['occurred_at'])
            : date('Y-m-d H:i:s');
        $payload['status'] = isset($payload['status']) && $payload['status'] !== ''
            ? $this->intIn($payload['status'], [1, 2], '触发因素状态参数错误')
            : 1;

        $rowId = $this->saveRow('sa_member_trigger_log', $payload, $memberId, $id);
        return Db::table('sa_member_trigger_log')->where('id', $rowId)->find() ?: [];
    }

    public function deleteTriggerLog(int $memberId, int $triggerId): array
    {
        return $this->softDeleteOwnedRow('sa_member_trigger_log', $memberId, $triggerId, '触发因素记录ID必须填写');
    }

    public function messages(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = Db::table('sa_member_message')
                ->where('member_id', $memberId)
                ->where('status', 1)
                ->whereNull('delete_time');
            if (isset($params['is_read']) && $params['is_read'] !== '') {
                $query->where('is_read', (int) $params['is_read']);
            }
            if (isset($params['message_type']) && $params['message_type'] !== '') {
                $query->where('message_type', (int) $params['message_type']);
            }

            return $query->order('id', 'desc');
        }, $params);
    }

    public function readMessage(int $memberId, array $data): array
    {
        $query = Db::table('sa_member_message')
            ->where('member_id', $memberId)
            ->where('status', 1)
            ->whereNull('delete_time');

        $messageId = (int) ($data['message_id'] ?? 0);
        if ($messageId > 0) {
            $query->where('id', $messageId);
        } elseif ((int) ($data['all'] ?? 0) !== 1) {
            throw new ApiException('消息ID或全部已读标识必须填写', 400);
        }

        $affected = $query->update([
            'is_read' => 1,
            'read_time' => date('Y-m-d H:i:s'),
            'updated_by' => $memberId,
            'update_time' => date('Y-m-d H:i:s'),
        ]);

        return ['affected' => $affected];
    }

    private function assertApprovedDoctor(int $doctorId): array
    {
        $profile = Db::table('sa_help_doctor_profile')
            ->where('member_id', $doctorId)
            ->where('audit_status', 1)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$profile) {
            throw new ApiException('医生资质未通过审核或不可用', 403);
        }

        return $profile;
    }

    private function hasApprovedDoctorProfile(int $memberId): bool
    {
        if ($memberId <= 0) {
            return false;
        }

        return Db::table('sa_help_doctor_profile')
            ->where('member_id', $memberId)
            ->where('audit_status', 1)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->count() > 0;
    }

    private function roleFlags(array $profile, array $doctorProfile): array
    {
        $profileRole = $this->profileRole($profile);
        $doctorProfileSubmitted = $doctorProfile !== [];
        $doctorApproved = $this->isDoctorApproved($doctorProfile);
        $currentRole = $this->currentRole($profile, $doctorProfile);

        return [
            'profile_role' => $profileRole,
            'is_patient' => $currentRole === 'patient',
            'is_doctor' => $currentRole === 'doctor',
            'doctor_profile_submitted' => $doctorProfileSubmitted,
            'doctor_approved' => $doctorApproved,
        ];
    }

    private function currentRole(array $profile, array $doctorProfile): string
    {
        return $this->profileRole($profile) === 'doctor' && $this->isDoctorApproved($doctorProfile)
            ? 'doctor'
            : 'patient';
    }

    private function profileRole(array $profile): string
    {
        $role = trim((string) ($profile['member_role'] ?? ''));
        return in_array($role, ['patient', 'doctor'], true) ? $role : 'patient';
    }

    private function isDoctorApproved(array $doctorProfile): bool
    {
        if ($doctorProfile === []) {
            return false;
        }

        return (int) ($doctorProfile['audit_status'] ?? 0) === 1
            && (int) ($doctorProfile['status'] ?? 0) === 1;
    }

    private function assertMemberExists(int $memberId): array
    {
        if ($memberId <= 0) {
            throw new ApiException('会员ID参数错误', 400);
        }

        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$member) {
            throw new ApiException('会员不存在', 404);
        }

        return $member;
    }

    private function member(int $memberId): array
    {
        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->field('id, username, nickname, avatar, mobile, email, member_level_id, points_balance, last_login_ip, last_login_time, register_platform_id, status, create_time, update_time')
            ->find();
        if (!$member || (int) ($member['status'] ?? 0) !== 1) {
            throw new ApiException('会员不存在或状态异常', 401);
        }

        return $member;
    }

    private function assertOwnedRow(string $table, int $memberId, int $id, string $message): array
    {
        if ($id <= 0) {
            throw new ApiException('ID参数错误', 400);
        }

        $row = Db::table($table)
            ->where('id', $id)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$row) {
            throw new ApiException($message, 404);
        }

        return $row;
    }

    private function softDeleteOwnedRow(string $table, int $memberId, int $id, string $emptyMessage): array
    {
        if ($id <= 0) {
            throw new ApiException($emptyMessage, 400);
        }

        $affected = Db::table($table)
            ->where('id', $id)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->update([
                'delete_time' => date('Y-m-d H:i:s'),
                'updated_by' => $memberId,
                'update_time' => date('Y-m-d H:i:s'),
            ]);

        return ['id' => $id, 'deleted' => $affected > 0];
    }

    private function upsertDoctorPatientRelation(int $doctorId, int $memberId, string $bindSource): array
    {
        $this->assertMemberExists($memberId);
        $bindSource = in_array($bindSource, ['manual', 'system', 'appointment'], true) ? $bindSource : 'manual';
        $now = date('Y-m-d H:i:s');
        $exists = Db::table('sa_doctor_patient')
            ->where('doctor_id', $doctorId)
            ->where('member_id', $memberId)
            ->find();

        if ($exists) {
            Db::table('sa_doctor_patient')->where('id', $exists['id'])->update([
                'status' => 1,
                'bind_source' => $bindSource,
                'bind_time' => $now,
                'unbind_time' => null,
                'delete_time' => null,
                'updated_by' => $doctorId,
                'update_time' => $now,
            ]);

            return Db::table('sa_doctor_patient')->where('id', $exists['id'])->find() ?: [];
        }

        $id = Db::table('sa_doctor_patient')->insertGetId([
            'doctor_id' => $doctorId,
            'member_id' => $memberId,
            'status' => 1,
            'bind_source' => $bindSource,
            'bind_time' => $now,
            'created_by' => $doctorId,
            'updated_by' => $doctorId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return Db::table('sa_doctor_patient')->where('id', $id)->find() ?: [];
    }

    private function assertDoctorPatient(int $doctorId, int $memberId): array
    {
        $this->assertApprovedDoctor($doctorId);
        if ($memberId <= 0 || $memberId === $doctorId) {
            throw new ApiException('患者会员ID参数错误', 400);
        }

        $relation = Db::table('sa_doctor_patient')
            ->where('doctor_id', $doctorId)
            ->where('member_id', $memberId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$relation) {
            throw new ApiException('患者未绑定或无权操作', 403);
        }

        return $relation;
    }

    private function assertMemberDailyTask(int $memberId, int $taskId): array
    {
        if ($taskId <= 0) {
            throw new ApiException('任务ID必须填写', 400);
        }

        $task = Db::table('sa_daily_task')
            ->where('id', $taskId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$task) {
            throw new ApiException('任务不存在或无权访问', 404);
        }

        return $task;
    }

    private function awardTaskCompletionRewards(int $memberId, array $task): void
    {
        $taskId = (int) ($task['id'] ?? 0);
        if ($taskId <= 0) {
            return;
        }

        $points = max(0, (int) ($task['points_reward'] ?? 0));
        if ($points > 0) {
            $this->addPointLog($memberId, $points, 'daily_task', $taskId, '完成每日任务', (string) ($task['title'] ?? ''));
        }

        $taskCount = (int) Db::table('sa_daily_task')
            ->where('member_id', $memberId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->count();
        $this->awardBadgesByTrigger($memberId, 'task_count', $taskCount, 'daily_task', $taskId);

        if ((string) ($task['task_type'] ?? '') === 'checkin') {
            $this->awardCheckinStreakBadges($memberId, $taskId, (string) ($task['task_date'] ?? ''));
        }
    }

    private function addPointLog(int $memberId, int $points, string $sourceType, int $sourceId, string $title, string $remark = ''): void
    {
        if ($memberId <= 0 || $points === 0) {
            return;
        }

        (new HelpPointService())->addLog([
            'member_id' => $memberId,
            'points' => $points,
            'change_type' => $points > 0 ? 'income' : 'expense',
            'source_type' => $sourceType,
            'source_id' => $sourceId,
            'title' => $title,
            'remark' => $remark,
        ], $memberId);
    }

    private function awardBadgesByTrigger(int $memberId, string $triggerType, int $triggerValue, string $sourceType, int $sourceId): void
    {
        (new HelpBadgeService())->awardByTrigger($memberId, $triggerType, $triggerValue, $sourceType, $sourceId);
    }

    private function awardJournalBadges(int $memberId, int $journalId): void
    {
        $journalCount = (int) Db::table('sa_member_journal')
            ->where('member_id', $memberId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->count();
        $this->awardBadgesByTrigger($memberId, 'journal_count', $journalCount, 'journal', $journalId);
    }

    private function awardMaterialLearnBadges(int $memberId, int $historyId): void
    {
        $learnCount = (int) Db::table('sa_member_content_history')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->count();
        $this->awardBadgesByTrigger($memberId, 'material_learn', $learnCount, 'material_history', $historyId);
    }

    private function awardAppointmentDoneBadges(int $memberId, int $appointmentId): void
    {
        (new HelpBadgeService())->awardAppointmentDone($memberId, $appointmentId);
    }

    private function awardCheckinStreakBadges(int $memberId, int $taskId, string $taskDate): void
    {
        if ($taskDate === '') {
            return;
        }

        $dates = Db::table('sa_daily_task')
            ->where('member_id', $memberId)
            ->where('task_type', 'checkin')
            ->where('status', 1)
            ->where('task_date', '<=', $taskDate)
            ->whereNull('delete_time')
            ->distinct(true)
            ->order('task_date', 'desc')
            ->column('task_date');

        $expectedDate = new \DateTimeImmutable($taskDate);
        $streak = 0;
        foreach ($dates as $date) {
            $date = (string) $date;
            if ($date !== $expectedDate->format('Y-m-d')) {
                break;
            }

            $streak++;
            $expectedDate = $expectedDate->modify('-1 day');
        }

        $this->awardBadgesByTrigger($memberId, 'checkin_streak', $streak, 'daily_task', $taskId);
    }

    private function assertDoctorPlan(int $doctorId, int $memberId, int $planId): array
    {
        if ($planId <= 0) {
            throw new ApiException('治疗计划ID参数错误', 400);
        }

        $plan = Db::table('sa_treatment_plan')
            ->where('id', $planId)
            ->where('doctor_id', $doctorId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$plan) {
            throw new ApiException('治疗计划不存在或无权操作', 404);
        }

        return $plan;
    }

    private function assertDoctorStage(int $doctorId, int $memberId, int $stageId): array
    {
        if ($stageId <= 0) {
            throw new ApiException('治疗阶段ID参数错误', 400);
        }

        $stage = Db::table('sa_treatment_stage')
            ->alias('s')
            ->leftJoin('sa_treatment_plan p', 'p.id = s.plan_id AND p.delete_time IS NULL')
            ->where('s.id', $stageId)
            ->where('s.member_id', $memberId)
            ->where('p.doctor_id', $doctorId)
            ->whereNull('s.delete_time')
            ->field('s.*')
            ->find();
        if (!$stage) {
            throw new ApiException('治疗阶段不存在或无权操作', 404);
        }

        return $stage;
    }

    private function assertDoctorDailyTask(int $doctorId, int $memberId, int $taskId): array
    {
        if ($taskId <= 0) {
            throw new ApiException('任务ID参数错误', 400);
        }

        $task = Db::table('sa_daily_task')
            ->where('id', $taskId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if (!$task) {
            throw new ApiException('任务不存在或无权操作', 404);
        }

        $planId = (int) ($task['plan_id'] ?? 0);
        if ($planId > 0) {
            $this->assertDoctorPlan($doctorId, $memberId, $planId);
            return $task;
        }

        $stageId = (int) ($task['stage_id'] ?? 0);
        if ($stageId > 0) {
            $this->assertDoctorStage($doctorId, $memberId, $stageId);
            return $task;
        }

        if ((int) ($task['created_by'] ?? 0) !== $doctorId) {
            throw new ApiException('任务不存在或无权操作', 404);
        }

        return $task;
    }

    private function doctorPlanIds(int $doctorId, int $memberId): array
    {
        return array_map('intval', Db::table('sa_treatment_plan')
            ->where('doctor_id', $doctorId)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->column('id'));
    }

    private function doctorStageIds(array $planIds): array
    {
        $planIds = array_values(array_filter(array_map('intval', $planIds)));
        if ($planIds === []) {
            return [];
        }

        return array_map('intval', Db::table('sa_treatment_stage')
            ->whereIn('plan_id', $planIds)
            ->whereNull('delete_time')
            ->column('id'));
    }

    private function assertVisibleTemplateFolder(int $doctorId, string $folderId): array
    {
        $folder = Db::table('sa_doctor_task_template_folder')
            ->where('id', $folderId)
            ->whereIn('doctor_id', [0, $doctorId])
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$folder) {
            throw new ApiException('模板文件夹不存在或无权使用', 404);
        }

        return $folder;
    }

    private function assertDoctorOwnedTemplate(int $doctorId, string $id): array
    {
        if ($id === '') {
            throw new ApiException('模板ID必须填写', 400);
        }

        $template = Db::table('sa_doctor_task_template')
            ->where('id', $id)
            ->where('doctor_id', $doctorId)
            ->whereNull('delete_time')
            ->find();
        if (!$template) {
            throw new ApiException('任务模板不存在或无权操作', 404);
        }

        return $template;
    }

    private function assertDoctorOwnedAssessmentScale(int $doctorId, string $id): array
    {
        if ($id === '') {
            throw new ApiException('量表ID必须填写', 400);
        }

        $scale = Db::table('sa_doctor_assessment_scale')
            ->where('id', $id)
            ->where('doctor_id', $doctorId)
            ->whereNull('delete_time')
            ->find();
        if (!$scale) {
            throw new ApiException('评估量表不存在或无权操作', 404);
        }

        return $scale;
    }

    private function assertDoctorAppointment(int $doctorId, int $appointmentId, array $allowStatuses): array
    {
        $this->assertApprovedDoctor($doctorId);
        if ($appointmentId <= 0) {
            throw new ApiException('预约ID必须填写', 400);
        }

        $appointment = Db::table('sa_doctor_appointment')
            ->where('id', $appointmentId)
            ->where('doctor_id', $doctorId)
            ->whereNull('delete_time')
            ->find();
        if (!$appointment) {
            throw new ApiException('预约不存在或无权操作', 404);
        }
        if ($allowStatuses !== [] && !in_array((int) $appointment['status'], $allowStatuses, true)) {
            throw new ApiException('当前预约状态不可操作', 400);
        }

        return $appointment;
    }

    private function lockAvailableSchedule(array $data): array
    {
        $scheduleId = (int) ($data['schedule_id'] ?? 0);
        $doctorId = (int) ($data['doctor_id'] ?? 0);
        $appointDate = trim((string) ($data['appoint_date'] ?? ''));
        $timeSlot = trim((string) ($data['appoint_time_slot'] ?? ''));

        $query = Db::table('sa_doctor_schedule')
            ->where('status', 1)
            ->whereRaw('`booked_count` < `capacity`')
            ->whereNull('delete_time')
            ->lock(true);

        if ($scheduleId > 0) {
            $query->where('id', $scheduleId);
        } else {
            if ($doctorId <= 0 || $appointDate === '' || $timeSlot === '') {
                throw new ApiException('医生、预约日期和时间段必须填写', 400);
            }
            $query->where('doctor_id', $doctorId)
                ->where('schedule_date', $appointDate)
                ->where('time_slot', $timeSlot);
        }

        $schedule = $query->find();
        if (!$schedule) {
            throw new ApiException('排班不存在或当前时段不可预约', 404);
        }
        if ($doctorId > 0 && (int) $schedule['doctor_id'] !== $doctorId) {
            throw new ApiException('预约医生与排班不一致', 400);
        }

        $doctor = Db::table('sa_help_doctor_profile')
            ->where('member_id', (int) $schedule['doctor_id'])
            ->where('audit_status', 1)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$doctor) {
            throw new ApiException('医生不存在或未通过审核', 404);
        }

        return $schedule;
    }

    private function assertNoActiveAppointmentForSchedule(int $memberId, int $scheduleId): void
    {
        if ($memberId <= 0 || $scheduleId <= 0) {
            return;
        }

        $exists = Db::table('sa_doctor_appointment')
            ->where('member_id', $memberId)
            ->where('schedule_id', $scheduleId)
            ->whereIn('status', [0, 1])
            ->whereNull('delete_time')
            ->find();
        if ($exists) {
            throw new ApiException('该时段已有待处理预约，请勿重复预约', 400);
        }
    }

    private function releaseAppointmentSchedule(array $appointment): void
    {
        $scheduleId = (int) ($appointment['schedule_id'] ?? 0);
        if ($scheduleId <= 0 || !in_array((int) ($appointment['status'] ?? -1), [0, 1], true)) {
            return;
        }

        Db::execute(
            'UPDATE `sa_doctor_schedule`
            SET `booked_count` = IF(`booked_count` > 0, `booked_count` - 1, 0), `update_time` = NOW()
            WHERE `id` = ' . $scheduleId
        );
    }

    private function notifyMemberSafely(int $memberId, string $templateCode, array $variables, array $options): void
    {
        try {
            (new HelpPushService())->notifyMember($memberId, $templateCode, $variables, $options);
        } catch (Throwable) {
            // 通知失败不能影响主业务写入；具体发送结果会在消息中心记录里体现。
        }
    }

    private function notifyCommunityFollow(int $memberId, int $targetMemberId): void
    {
        if ($memberId <= 0 || $targetMemberId <= 0 || $memberId === $targetMemberId) {
            return;
        }

        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->field('id, nickname, username')
            ->find() ?: [];
        $nickname = trim((string) ($member['nickname'] ?? ''))
            ?: trim((string) ($member['username'] ?? ''))
            ?: 'Member #' . $memberId;

        $this->notifyMemberSafely($targetMemberId, 'community_follow', [
            'nickname' => $nickname,
        ], [
            'biz_type' => 'community_follow_member',
            'biz_id' => $memberId,
            'route' => '/pages/community/profile',
            'payload' => [
                'member_id' => $memberId,
            ],
        ]);
    }

    private function memberWithPassword(int $memberId): array
    {
        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->field('id, username, nickname, avatar, mobile, email, password_hash, status, update_time')
            ->find();
        if (!$member || (int) ($member['status'] ?? 2) !== 1) {
            throw new ApiException('会员不存在或状态异常', 401);
        }

        return (array) $member;
    }

    private function securityLinkedAccounts(int $memberId): array
    {
        return Db::table('sa_member_platform_rel')
            ->alias('rel')
            ->leftJoin('sa_member_platform platform', 'platform.id = rel.platform_id AND platform.delete_time IS NULL')
            ->where('rel.member_id', $memberId)
            ->where('rel.is_bind', 1)
            ->whereNull('rel.delete_time')
            ->field('platform.platform_code, platform.platform_name, rel.platform_openid, rel.bind_time')
            ->order('rel.bind_time', 'desc')
            ->order('rel.id', 'desc')
            ->select()
            ->toArray();
    }

    private function securityDevices(int $memberId): array
    {
        return Db::table('sa_member_push_device')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->field('id, device_id, platform, app_version, locale, timezone, is_active, last_active_time, logout_time, create_time, update_time')
            ->order('is_active', 'asc')
            ->order('last_active_time', 'desc')
            ->order('id', 'desc')
            ->select()
            ->toArray();
    }

    private function securityRecentLogins(int $memberId, int $limit = 10): array
    {
        return Db::table('sa_member_login_log')
            ->alias('log')
            ->leftJoin('sa_member_platform platform', 'platform.id = log.platform_id AND platform.delete_time IS NULL')
            ->where('log.member_id', $memberId)
            ->whereNull('log.delete_time')
            ->field('log.id, log.login_ip, log.login_location, log.user_agent, log.login_result, log.fail_reason, log.create_time, platform.platform_code, platform.platform_name')
            ->order('log.create_time', 'desc')
            ->limit($limit)
            ->select()
            ->toArray();
    }

    private function normalizeMobile(mixed $mobile): string
    {
        $mobile = trim((string) $mobile);
        if ($mobile === '' || !preg_match('/^1\d{10}$/', $mobile)) {
            throw new ApiException('请输入正确格式的手机号码', 400);
        }

        return $mobile;
    }

    private function normalizeEmail(mixed $email): string
    {
        $email = trim((string) $email);
        if ($email === '' || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }

        return $email;
    }

    private function assertEmailChangeTarget(int $memberId, string $email): void
    {
        $currentEmail = trim((string) ($this->memberWithPassword($memberId)['email'] ?? ''));
        if ($currentEmail !== '' && strcasecmp($currentEmail, $email) === 0) {
            throw new ApiException('新邮箱与当前绑定邮箱一致', 400);
        }
    }

    private function assertMobileChangeTarget(int $memberId, string $mobile): void
    {
        $currentMobile = trim((string) ($this->memberWithPassword($memberId)['mobile'] ?? ''));
        if ($currentMobile !== '' && $currentMobile === $mobile) {
            throw new ApiException('新手机号与当前绑定手机号一致', 400);
        }
    }

    private function assertEmailBindable(int $memberId, string $email): void
    {
        $member = (array) Db::table('sa_member')
            ->where('email', $email)
            ->whereNull('delete_time')
            ->field('id')
            ->find();
        if ($member !== [] && (int) ($member['id'] ?? 0) !== $memberId) {
            throw new ApiException('该邮箱已经绑定其他账号', 400);
        }
    }

    private function assertMobileBindable(int $memberId, string $mobile): void
    {
        $member = (array) Db::table('sa_member')
            ->where('mobile', $mobile)
            ->whereNull('delete_time')
            ->field('id')
            ->find();
        if ($member !== [] && (int) ($member['id'] ?? 0) !== $memberId) {
            throw new ApiException('该手机号已经绑定其他账号', 400);
        }
    }

    private function sendEmailCode(string $email): void
    {
        (new IndexLogic())->emailSend($email, 1);
    }

    private function sendSmsCode(string $mobile): void
    {
        $result = (new MemberLogic())->sendCode($mobile);
        if (!$result) {
            throw new ApiException('验证码发送失败，请稍后重试', 500);
        }
    }

    private function consumeEmailCode(string $email, string $code): void
    {
        $record = Db::table('sa_system_mail')
            ->where('email', $email)
            ->where('status', 'success')
            ->order('update_time', 'desc')
            ->find();
        if (!$record) {
            throw new ApiException('邮箱验证码错误或已过期，请填写正确的验证码', 400);
        }
        if ((string) ($record['code'] ?? '') !== $code) {
            throw new ApiException('邮箱验证码错误或已过期，请填写正确的验证码', 400);
        }
        if (time() - strtotime((string) ($record['update_time'] ?? $record['create_time'] ?? '')) > self::EMAIL_CODE_EXPIRES_IN) {
            throw new ApiException('邮箱验证码错误或已过期，请填写正确的验证码', 400);
        }
    }

    private function consumeSmsCode(string $mobile, string $code): void
    {
        $record = Db::table('saisms_record')
            ->where('mobile', $mobile)
            ->where('status', 'success')
            ->whereNull('delete_time')
            ->order('create_time', 'desc')
            ->find();
        if (!$record) {
            throw new ApiException('验证码错误或已过期', 400);
        }
        if ((int) ($record['is_verify'] ?? 2) === 1) {
            throw new ApiException('验证码错误或已过期', 400);
        }
        if (strtotime((string) ($record['create_time'] ?? '')) < time() - self::SMS_CODE_EXPIRES_IN) {
            throw new ApiException('验证码错误或已过期', 400);
        }
        if ((string) ($record['code'] ?? '') !== $code) {
            throw new ApiException('验证码错误或已过期', 400);
        }

        Db::table('saisms_record')->where('id', (int) $record['id'])->update([
            'is_verify' => 1,
            'update_time' => date('Y-m-d H:i:s'),
        ]);
    }

    private function memberPlatformId(string $platformCode): int
    {
        $platformId = (int) Db::table('sa_member_platform')
            ->where('platform_code', $platformCode)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->value('id');
        if ($platformId <= 0) {
            throw new ApiException($platformCode . ' 会员平台未初始化或未启用', 400);
        }

        return $platformId;
    }

    private function maskMobile(string $mobile): string
    {
        if (strlen($mobile) !== 11) {
            return $mobile;
        }

        return substr($mobile, 0, 3) . '****' . substr($mobile, -4);
    }

    private function maskEmail(string $email): string
    {
        [$name, $domain] = array_pad(explode('@', $email, 2), 2, '');
        if ($name === '' || $domain === '') {
            return $email;
        }
        if (mb_strlen($name) <= 2) {
            return mb_substr($name, 0, 1) . '***@' . $domain;
        }

        return mb_substr($name, 0, 1) . '***' . mb_substr($name, -1) . '@' . $domain;
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
        $now = date('Y-m-d H:i:s');

        return Db::table('sa_app_onboarding_page')
            ->where('scene', $scene !== '' ? $scene : 'first_launch')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->where(function ($query) use ($version) {
                $query->where('version', $version)->whereOr('version', '');
            })
            ->where('locale', $locale)
            ->where(function ($query) use ($now) {
                $query->whereNull('start_time')
                    ->whereOr('start_time', '0000-00-00 00:00:00')
                    ->whereOr('start_time', '<=', $now);
            })
            ->where(function ($query) use ($now) {
                $query->whereNull('end_time')
                    ->whereOr('end_time', '0000-00-00 00:00:00')
                    ->whereOr('end_time', '>=', $now);
            })
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    private function visibleMaterialQuery(int $memberId)
    {
        return Db::table('sa_content_material')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->whereRaw(sprintf(
                "((`material_type` = 'private' AND `member_id` = %d) OR (`material_type` <> 'private' AND (`is_public` = 1 OR `member_id` = %d)))",
                $memberId,
                $memberId
            ))
            ->where(function ($query) use ($memberId) {
                $query->where('audit_status', 2)->whereOr('member_id', $memberId);
            });
    }

    private function localizeMaterialCategory(array $row, string $locale): array
    {
        $row['name'] = $this->localizedMaterialText(
            (string) ($row['name'] ?? ''),
            $row['name_i18n'] ?? null,
            $locale
        );

        return $row;
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    private function localizeMaterialRows(array $rows, string $locale): array
    {
        return array_map(fn (array $row): array => $this->localizeMaterialRow($row, $locale), $rows);
    }

    private function appendMaterialInteractionFlags(array $rows, int $memberId): array
    {
        if ($rows === []) {
            return [];
        }

        $materialIds = array_values(array_unique(array_filter(array_map(
            static fn (array $row): int => (int) ($row['id'] ?? 0),
            $rows
        ))));
        if ($materialIds === []) {
            foreach ($rows as &$row) {
                $row['is_liked'] = false;
                $row['is_collected'] = false;
            }
            unset($row);

            return $rows;
        }

        $likedLookup = [];
        $collectedLookup = [];
        if ($memberId > 0) {
            $likedLookup = array_fill_keys(array_map(
                'intval',
                Db::table('sa_material_like')
                    ->where('member_id', $memberId)
                    ->whereIn('material_id', $materialIds)
                    ->whereNull('delete_time')
                    ->column('material_id')
            ), true);
            $collectedLookup = array_fill_keys(array_map(
                'intval',
                Db::table('sa_material_collect')
                    ->where('member_id', $memberId)
                    ->whereIn('material_id', $materialIds)
                    ->whereNull('delete_time')
                    ->column('material_id')
            ), true);
        }

        foreach ($rows as &$row) {
            $materialId = (int) ($row['id'] ?? 0);
            $row['is_liked'] = isset($likedLookup[$materialId]);
            $row['is_collected'] = isset($collectedLookup[$materialId]);
        }
        unset($row);

        return $rows;
    }

    private function localizeMaterialRow(array $row, string $locale): array
    {
        $row['title'] = $this->localizedMaterialText(
            (string) ($row['title'] ?? ''),
            $row['title_i18n'] ?? null,
            $locale
        );
        $row['summary'] = $this->localizedMaterialText(
            (string) ($row['summary'] ?? ''),
            $row['summary_i18n'] ?? null,
            $locale
        );
        if (array_key_exists('content_text', $row)) {
            $row['content_text'] = $this->localizedMaterialText(
                (string) ($row['content_text'] ?? ''),
                $row['content_text_i18n'] ?? null,
                $locale
            );
        }
        if (array_key_exists('image_urls', $row)) {
            $row['image_urls'] = $this->normalizeImageUrls($row['image_urls'] ?? null);
        }
        if ($this->isRejectedPrivateMaterial($row)) {
            $row['summary'] = '';
            $row['summary_i18n'] = null;
            $row['artist'] = '';
            $row['album'] = '';
            $row['cover_url'] = '';
            $row['content_url'] = '';
            $row['image_urls'] = [];
            $row['lyric_url'] = '';
            $row['content_text'] = '';
            $row['content_text_i18n'] = null;
            $row['tags'] = [];
            $row['duration_seconds'] = 0;
        }

        return $row;
    }

    private function isRejectedPrivateMaterial(array $row): bool
    {
        return (string) ($row['material_type'] ?? '') === 'private'
            && (int) ($row['audit_status'] ?? 0) === 3;
    }

    private function localizedMaterialText(string $fallback, mixed $i18n, string $locale): string
    {
        $values = $this->decodeJsonObject($i18n);
        if ($values === []) {
            return $fallback;
        }

        foreach ($this->materialLocaleCandidates($locale) as $candidate) {
            if (isset($values[$candidate]) && trim((string) $values[$candidate]) !== '') {
                return (string) $values[$candidate];
            }
        }

        return $fallback;
    }

    /**
     * @return array<int, string>
     */
    private function materialLocaleCandidates(string $locale): array
    {
        $locale = trim(str_replace('_', '-', $locale));
        $normalized = strtolower($locale);
        $language = strtok($normalized !== '' ? $normalized : self::DEFAULT_LOCALE, '-') ?: '';
        $candidates = [];

        foreach ([$locale, $normalized, $language] as $candidate) {
            if ($candidate !== '') {
                $candidates[] = $candidate;
            }
        }

        if ($language === 'zh') {
            array_push($candidates, 'zh-CN', 'zh-cn', 'zh');
        } elseif ($language === 'en') {
            array_push($candidates, 'en-US', 'en-us', 'en');
        }

        array_push($candidates, self::DEFAULT_LOCALE, strtolower(self::DEFAULT_LOCALE), 'en', self::DEFAULT_PROTOCOL_LOCALE, 'zh-CN', 'zh-cn', 'zh');

        return array_values(array_unique($candidates));
    }

    /**
     * @return array<string, mixed>
     */
    private function decodeJsonObject(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }
        if (!is_string($value) || trim($value) === '') {
            return [];
        }

        $decoded = json_decode($value, true);
        return is_array($decoded) ? $decoded : [];
    }

    private function communityTargetMemberId(int $memberId, int $targetMemberId): int
    {
        $resolved = $targetMemberId > 0 ? $targetMemberId : $memberId;
        if ($resolved <= 0) {
            throw new ApiException('目标会员ID必须填写', 400);
        }

        return $resolved;
    }

    private function communityMemberPayload(
        int $viewerId,
        array $member,
        array $profile = [],
        array $doctorProfile = []
    ): array {
        $targetMemberId = (int) ($member['id'] ?? 0);
        $followState = $this->communityFollowState($viewerId, $targetMemberId);
        $displayName = trim((string) ($member['nickname'] ?? ''))
            ?: trim((string) ($member['username'] ?? ''))
            ?: 'Member #' . $targetMemberId;
        $bio = $this->firstFilled(
            isset($profile['bio']) ? (string) $profile['bio'] : null,
            isset($profile['recovery_goal']) ? (string) $profile['recovery_goal'] : null,
            isset($doctorProfile['specialty']) ? (string) $doctorProfile['specialty'] : null
        );
        $startedAt = $this->firstFilled(
            isset($profile['create_time']) ? (string) $profile['create_time'] : null,
            isset($member['create_time']) ? (string) $member['create_time'] : null
        );

        return [
            'member_id' => $targetMemberId,
            'display_name' => $displayName,
            'avatar' => (string) ($member['avatar'] ?? ''),
            'bio' => $bio,
            'recovery_goal' => (string) ($profile['recovery_goal'] ?? ''),
            'member_role' => $this->currentRole($profile, $doctorProfile),
            'is_doctor' => $this->isDoctorApproved($doctorProfile),
            'doctor_title' => (string) ($doctorProfile['title'] ?? ''),
            'recovery_days' => $this->communityRecoveryDays($startedAt),
            'is_self' => $viewerId > 0 && $viewerId === $targetMemberId,
            'is_followed' => $followState['is_followed'],
            'is_mutual_follow' => $followState['is_mutual_follow'],
        ];
    }

    private function communityFollowState(int $viewerId, int $targetMemberId): array
    {
        if ($viewerId <= 0 || $targetMemberId <= 0 || $viewerId === $targetMemberId) {
            return ['is_followed' => false, 'is_mutual_follow' => false];
        }

        $isFollowed = $this->activeInteractionExists(
            'sa_community_follow_member',
            $viewerId,
            'target_member_id',
            $targetMemberId
        );
        if (!$isFollowed) {
            return ['is_followed' => false, 'is_mutual_follow' => false];
        }

        return [
            'is_followed' => true,
            'is_mutual_follow' => $this->activeInteractionExists(
                'sa_community_follow_member',
                $targetMemberId,
                'target_member_id',
                $viewerId
            ),
        ];
    }

    private function decorateCommunityMembers(array $rows, int $viewerId): array
    {
        foreach ($rows as &$row) {
            $member = [
                'id' => $row['member_id'] ?? 0,
                'username' => $row['username'] ?? '',
                'nickname' => $row['nickname'] ?? '',
                'avatar' => $row['avatar'] ?? '',
                'create_time' => $row['member_create_time'] ?? null,
            ];
            $profile = [
                'bio' => $row['bio'] ?? '',
                'recovery_goal' => $row['recovery_goal'] ?? '',
                'member_role' => $row['member_role'] ?? 'patient',
                'gender' => $row['gender'] ?? 3,
                'birthday' => $row['birthday'] ?? null,
                'create_time' => $row['profile_create_time'] ?? null,
            ];
            $doctorProfile = [
                'audit_status' => $row['doctor_audit_status'] ?? 0,
                'status' => $row['doctor_status'] ?? 0,
                'title' => $row['doctor_title'] ?? '',
                'specialty' => $row['doctor_specialty'] ?? '',
            ];
            $payload = $this->communityMemberPayload($viewerId, $member, $profile, $doctorProfile);
            $row = array_merge($row, $payload);
        }
        unset($row);

        return $rows;
    }

    private function communityRecoveryDays(string $startedAt): int
    {
        if ($startedAt === '') {
            return 0;
        }

        $timestamp = strtotime($startedAt);
        if ($timestamp === false) {
            return 0;
        }

        return max((int) floor((time() - $timestamp) / 86400) + 1, 0);
    }

    private function visibleCommunityPostQuery(int $memberId)
    {
        return Db::table('sa_community_post')
            ->alias('p')
            ->leftJoin('sa_member m', 'm.id = p.member_id AND m.delete_time IS NULL')
            ->where('p.status', 1)
            ->whereNull('p.delete_time')
            ->where(function ($query) use ($memberId) {
                $query->where('p.audit_status', 1)->whereOr('p.member_id', $memberId);
            });
    }

    private function assertVisibleCommunityPost(int $memberId, int $postId): array
    {
        if ($postId <= 0) {
            throw new ApiException('帖子ID必须填写', 400);
        }

        $post = $this->visibleCommunityPostQuery($memberId)
            ->where('p.id', $postId)
            ->field('p.*, m.nickname AS author_name, m.avatar AS author_avatar')
            ->find();
        if (!$post) {
            throw new ApiException('帖子不存在或无权访问', 404);
        }

        return $post;
    }

    private function assertVisibleCommunityComment(int $memberId, int $commentId): array
    {
        if ($commentId <= 0) {
            throw new ApiException('评论ID必须填写', 400);
        }

        $comment = Db::table('sa_community_comment')
            ->alias('c')
            ->where('c.id', $commentId)
            ->where('c.status', 1)
            ->whereNull('c.delete_time')
            ->where(function ($query) use ($memberId) {
                $query->where('c.audit_status', 1)->whereOr('c.member_id', $memberId);
            })
            ->find();
        if (!$comment) {
            throw new ApiException('评论不存在或无权访问', 404);
        }

        $this->assertVisibleCommunityPost($memberId, (int) $comment['post_id']);
        return $comment;
    }

    private function assertVisibleCommunityTag(int $tagId): void
    {
        if ($tagId <= 0) {
            throw new ApiException('标签ID必须填写', 400);
        }

        $exists = Db::table('sa_community_tag')
            ->where('id', $tagId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$exists) {
            throw new ApiException('标签不存在或已禁用', 404);
        }
    }

    private function assertCommunityTargetMember(int $memberId, int $targetMemberId): void
    {
        if ($targetMemberId <= 0 || $targetMemberId === $memberId) {
            throw new ApiException('关注会员ID参数错误', 400);
        }

        $exists = Db::table('sa_member')
            ->where('id', $targetMemberId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$exists) {
            throw new ApiException('关注会员不存在或已禁用', 404);
        }
    }

    private function decorateCommunityPosts(array $rows, int $memberId): array
    {
        foreach ($rows as &$row) {
            $postId = (int) ($row['id'] ?? 0);
            $authorId = (int) ($row['member_id'] ?? 0);
            $canTrackAuthor = $authorId > 0
                && $authorId !== $memberId
                && (int) ($row['is_anonymous'] ?? 2) !== 1;
            $followState = $canTrackAuthor
                ? $this->communityFollowState($memberId, $authorId)
                : ['is_followed' => false, 'is_mutual_follow' => false];
            $row['images'] = $this->decodeJsonArray($row['images'] ?? null);
            $row['tags'] = $this->decodeJsonArray($row['tags'] ?? null);
            $row['is_liked'] = $this->activeCommunityLikeExists($memberId, 1, $postId);
            $row['is_collected'] = $this->activeInteractionExists('sa_community_collect', $memberId, 'post_id', $postId);
            $row['is_followed_author'] = $followState['is_followed'];
            $row['is_mutual_follow_author'] = $followState['is_mutual_follow'];
            $this->applyCommunityAuthor($row);
        }
        unset($row);

        return $rows;
    }

    private function decorateCommunityComments(array $rows, int $memberId): array
    {
        foreach ($rows as &$row) {
            $row['attachments'] = $this->decodeJsonArray($row['attachments'] ?? null);
            $row['is_liked'] = $this->activeCommunityLikeExists($memberId, 2, (int) ($row['id'] ?? 0));
            $this->applyCommunityAuthor($row);
        }
        unset($row);

        return $rows;
    }

    private function applyCommunityAuthor(array &$row): void
    {
        if ((int) ($row['is_anonymous'] ?? 2) === 1) {
            $row['author_name'] = 'Anonymous';
            $row['author_avatar'] = '';
            return;
        }

        $row['author_name'] = trim((string) ($row['author_name'] ?? '')) ?: 'Member #' . (int) ($row['member_id'] ?? 0);
        $row['author_avatar'] = (string) ($row['author_avatar'] ?? '');
    }

    private function activeCommunityLikeExists(int $memberId, int $targetType, int $targetId): bool
    {
        return (bool) Db::table('sa_community_like')
            ->where('member_id', $memberId)
            ->where('target_type', $targetType)
            ->where('target_id', $targetId)
            ->whereNull('delete_time')
            ->find();
    }

    private function toggleCommunityLikeRow(int $memberId, int $targetType, int $targetId): bool
    {
        $now = date('Y-m-d H:i:s');
        $row = Db::table('sa_community_like')
            ->where('member_id', $memberId)
            ->where('target_type', $targetType)
            ->where('target_id', $targetId)
            ->find();

        if ($row && empty($row['delete_time'])) {
            Db::table('sa_community_like')->where('id', $row['id'])->update([
                'delete_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            return false;
        }

        if ($row) {
            Db::table('sa_community_like')->where('id', $row['id'])->update([
                'delete_time' => null,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            return true;
        }

        Db::table('sa_community_like')->insert([
            'member_id' => $memberId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return true;
    }

    private function syncCommunityCounter(string $target, int $targetId, string $field, bool $increase): void
    {
        $tables = [
            'post' => ['table' => 'sa_community_post', 'fields' => ['like_count', 'comment_count', 'collect_count']],
            'comment' => ['table' => 'sa_community_comment', 'fields' => ['like_count']],
        ];
        if (!isset($tables[$target]) || !in_array($field, $tables[$target]['fields'], true)) {
            return;
        }

        $operator = $increase ? '+' : '-';
        Db::execute(sprintf(
            'UPDATE `%1$s` SET `%2$s` = GREATEST(`%2$s` %3$s 1, 0), `update_time` = NOW() WHERE `id` = %4$d',
            $tables[$target]['table'],
            $field,
            $operator,
            $targetId
        ));
    }

    private function decodeJsonArray(mixed $value): array
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

    /**
     * @return array<int, string>
     */
    private function normalizeImageUrls(mixed $value): array
    {
        $items = $this->decodeJsonArray($value);
        $urls = [];
        foreach ($items as $item) {
            $url = trim((string) $item);
            if ($url !== '') {
                $urls[] = mb_substr($url, 0, 500);
            }
        }

        return array_values(array_unique($urls));
    }

    private function assertVisibleMaterial(int $memberId, int $materialId): void
    {
        if ($materialId <= 0) {
            throw new ApiException('素材ID必须填写', 400);
        }

        $exists = $this->visibleMaterialQuery($memberId)
            ->where('id', $materialId)
            ->find();
        if (!$exists) {
            throw new ApiException('素材不存在或无权访问', 404);
        }
    }

    private function decorateMaterialComments(array $comments, int $memberId): array
    {
        foreach ($comments as &$comment) {
            $commentId = (int) ($comment['id'] ?? 0);
            $comment['attachments'] = $this->decodeJsonArray($comment['attachments'] ?? null);
            $comment['is_liked'] = $commentId > 0
                && $this->activeInteractionExists('sa_material_comment_like', $memberId, 'comment_id', $commentId);
        }
        unset($comment);

        return $comments;
    }

    private function assertVisibleMaterialComment(int $memberId, int $commentId): array
    {
        if ($commentId <= 0) {
            throw new ApiException('评论ID必须填写', 400);
        }

        $comment = Db::table('sa_material_comment')
            ->where('id', $commentId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->where(function ($query) use ($memberId) {
                $query->where('audit_status', 1)->whereOr('member_id', $memberId);
            })
            ->find();
        if (!$comment) {
            throw new ApiException('评论不存在或无权访问', 404);
        }

        $this->assertVisibleMaterial($memberId, (int) $comment['material_id']);
        return $comment;
    }

    private function activeInteractionExists(string $table, int $memberId, string $field, int $targetId): bool
    {
        return (bool) Db::table($table)
            ->where('member_id', $memberId)
            ->where($field, $targetId)
            ->whereNull('delete_time')
            ->find();
    }

    private function toggleInteraction(string $table, int $memberId, string $field, int $targetId): bool
    {
        $now = date('Y-m-d H:i:s');
        $row = Db::table($table)
            ->where('member_id', $memberId)
            ->where($field, $targetId)
            ->find();

        if ($row && empty($row['delete_time'])) {
            Db::table($table)->where('id', $row['id'])->update([
                'delete_time' => $now,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            return false;
        }

        if ($row) {
            Db::table($table)->where('id', $row['id'])->update([
                'delete_time' => null,
                'updated_by' => $memberId,
                'update_time' => $now,
            ]);
            return true;
        }

        Db::table($table)->insert([
            'member_id' => $memberId,
            $field => $targetId,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return true;
    }

    private function syncMaterialCounter(int $materialId, string $field, bool $increase): void
    {
        $allowed = ['like_count', 'collect_count', 'comment_count'];
        if (!in_array($field, $allowed, true)) {
            return;
        }

        $operator = $increase ? '+' : '-';
        Db::execute(sprintf(
            'UPDATE `sa_content_material` SET `%1$s` = GREATEST(`%1$s` %2$s 1, 0), `update_time` = NOW() WHERE `id` = %3$d',
            $field,
            $operator,
            $materialId
        ));
    }

    private function syncMaterialCommentCounter(int $commentId, string $field, bool $increase): void
    {
        if ($field !== 'like_count') {
            return;
        }

        $operator = $increase ? '+' : '-';
        Db::execute(sprintf(
            'UPDATE `sa_material_comment` SET `%1$s` = GREATEST(`%1$s` %2$s 1, 0), `update_time` = NOW() WHERE `id` = %3$d',
            $field,
            $operator,
            $commentId
        ));
    }

    private function saveRow(string $table, array $payload, int $actorId, int $id = 0): int
    {
        $now = date('Y-m-d H:i:s');
        if ($id > 0) {
            $payload['updated_by'] = $actorId;
            $payload['update_time'] = $now;
            Db::table($table)->where('id', $id)->update($payload);
            return $id;
        }

        if (!array_key_exists('member_id', $payload)) {
            $payload['member_id'] = $actorId;
        }
        $payload['created_by'] = $actorId;
        $payload['updated_by'] = $actorId;
        $payload['create_time'] = $now;
        $payload['update_time'] = $now;

        return (int) Db::table($table)->insertGetId($payload);
    }

    private function paginate(callable $builder, array $params): array
    {
        [$page, $pageSize] = $this->pageParams($params);
        $offset = ($page - 1) * $pageSize;

        $total = (int) $builder()->count();
        $list = $builder()
            ->limit($offset, $pageSize)
            ->select()
            ->toArray();

        return [
            'list' => $list,
            'total' => $total,
            'page' => $page,
            'page_size' => $pageSize,
        ];
    }

    /**
     * @return array{0:int,1:int}
     */
    private function pageParams(array $params): array
    {
        $page = max(1, (int) ($params['page'] ?? 1));
        $pageSize = (int) ($params['page_size'] ?? 20);
        $pageSize = min(100, max(1, $pageSize));

        return [$page, $pageSize];
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

    private function localModelByInput(array $data): array
    {
        $modelId = (int) ($data['model_id'] ?? 0);
        $modelCode = trim((string) ($data['model_code'] ?? ''));
        if ($modelId <= 0 && $modelCode === '') {
            throw new ApiException('模型ID或模型编码必须填写', 400);
        }

        $query = Db::table('sa_local_model_catalog')
            ->where('status', 1)
            ->whereNull('delete_time');
        if ($modelId > 0) {
            $query->where('id', $modelId);
        } else {
            $query->where('code', $modelCode);
        }

        $model = $query->find();
        if (!$model) {
            throw new ApiException('模型不存在或不可下载', 404);
        }

        return $model;
    }

    private function chatModes(): array
    {
        return ['doctor', 'companion', 'patient'];
    }

    private function chatMode(mixed $value): string
    {
        $value = trim((string) $value);
        if (!in_array($value, $this->chatModes(), true)) {
            throw new ApiException('聊天模式参数错误', 400);
        }

        return $value;
    }

    private function assertChatSession(int $memberId, int $sessionId): array
    {
        $session = Db::table('sa_member_chat_session')
            ->where('id', $sessionId)
            ->where('member_id', $memberId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->find();
        if (!$session) {
            throw new ApiException('会话不存在或无权访问', 404);
        }

        return $session;
    }

    private function chatHistory(int $memberId, int $sessionId, int $limit = 20): array
    {
        $records = Db::table('sa_member_chat_record')
            ->where('member_id', $memberId)
            ->where('session_id', $sessionId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->whereIn('role', ['user', 'assistant'])
            ->field('role, content')
            ->order('message_time', 'desc')
            ->order('id', 'desc')
            ->limit($limit)
            ->select()
            ->toArray();

        return array_reverse($records);
    }

    private function chatSystemPrompt(int $memberId, string $chatMode): string
    {
        $prompts = [
            'doctor' => '你是一位谨慎、温和的 AI 心理医生助手。请优先安抚情绪、澄清问题、给出可执行建议。你不能冒充真实执业诊断，不要给出绝对化结论。如用户出现自伤、自杀、伤人、幻觉、失控等高风险信号，必须明确建议立刻联系家属、当地急救电话或尽快前往线下精神心理专科就医。',
            'companion' => '你是一位温柔、稳定、耐心的 AI 心理陪伴助手。请多倾听、多共情，避免说教，并帮助用户把当下感受表达清楚。',
            'patient' => '你是一位帮助用户整理病情和感受的 AI 助手。请帮助用户梳理症状、情绪、诱因和需要补充给医生的信息。',
        ];
        $prompt = $prompts[$chatMode] ?? $prompts['companion'];
        $customPrompt = trim((string) Db::table('sa_member_chat_config')
            ->where('member_id', $memberId)
            ->where('chat_mode', $chatMode)
            ->whereNull('delete_time')
            ->value('prompt_text'));

        if ($customPrompt !== '') {
            $prompt .= "\n\n用户额外要求：\n" . $customPrompt;
        }

        return $prompt;
    }

    private function chatAiMessage(string $systemPrompt, string $content): string
    {
        return "请严格遵守以下 HelpSupport 场景提示词：\n"
            . $systemPrompt
            . "\n\n用户消息：\n"
            . $content;
    }

    private function insertChatRecord(
        int $memberId,
        int $sessionId,
        string $chatMode,
        string $role,
        string $content,
        string $contentType,
        ?string $ext,
        string $now
    ): array {
        $id = Db::table('sa_member_chat_record')->insertGetId([
            'session_id' => $sessionId,
            'member_id' => $memberId,
            'chat_mode' => $chatMode,
            'role' => $role,
            'content' => $content,
            'content_type' => $contentType,
            'token_count' => 0,
            'message_time' => $now,
            'ext' => $ext,
            'status' => 1,
            'created_by' => $memberId,
            'updated_by' => $memberId,
            'create_time' => $now,
            'update_time' => $now,
        ]);

        return Db::table('sa_member_chat_record')->where('id', $id)->find() ?: [];
    }

    private function chatSummary(string $content, string $contentType = 'text'): string
    {
        $prefix = match ($contentType) {
            'image' => '[image] ',
            'file' => '[file] ',
            'voice' => '[voice] ',
            default => '',
        };
        $length = max(1, 120 - mb_strlen($prefix));

        return $prefix . mb_substr($content, 0, $length);
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
