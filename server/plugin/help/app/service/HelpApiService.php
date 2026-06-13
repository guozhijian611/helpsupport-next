<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use plugin\saiai\app\service\AiFactory;
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

    public function markOnboardingSeen(int $memberId, string $version): array
    {
        $version = trim($version);
        if ($version === '') {
            throw new ApiException('引导页版本必须填写', 400);
        }

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

    public function materialCategories(array $params): array
    {
        $query = Db::table('sa_content_category')
            ->where('status', 1)
            ->whereNull('delete_time');

        if (!empty($params['type'])) {
            $query->where('type', (string) $params['type']);
        }

        return $query
            ->order('sort', 'asc')
            ->order('id', 'asc')
            ->select()
            ->toArray();
    }

    public function materials(int $memberId, array $params): array
    {
        return $this->paginate(function () use ($memberId, $params) {
            $query = $this->visibleMaterialQuery($memberId)
                ->field('id, member_id, category_id, media_type, material_type, title, title_i18n, summary, cover_url, content_url, duration_seconds, is_public, is_recommended, view_count, like_count, collect_count, comment_count, sort, create_time');

            if (!empty($params['material_type'])) {
                $query->where('material_type', (string) $params['material_type']);
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
                    $query->where('title', 'like', $keyword)->whereOr('summary', 'like', $keyword);
                });
            }

            return $query->order('is_recommended', 'asc')->order('sort', 'asc')->order('id', 'desc');
        }, $params);
    }

    public function materialDetail(int $memberId, int $materialId): array
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
        $material['comments'] = Db::table('sa_material_comment')
            ->where('material_id', $materialId)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->order('id', 'desc')
            ->limit(10)
            ->select()
            ->toArray();

        return $material;
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

        $this->saveRow('sa_member_content_history', $payload, $memberId, $exists['id'] ?? 0);

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
        return $this->paginate(fn () => Db::table('sa_material_collect')
            ->alias('c')
            ->leftJoin('sa_content_material m', 'm.id = c.material_id AND m.delete_time IS NULL')
            ->where('c.member_id', $memberId)
            ->whereNull('c.delete_time')
            ->field('c.id AS collect_id, c.create_time AS collect_time, m.*')
            ->order('c.id', 'desc'), $params);
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
        $this->saveRow('sa_daily_task', $payload, $memberId, $taskId);

        return Db::table('sa_daily_task')->where('id', $taskId)->find() ?: [];
    }

    public function assessmentResults(int $memberId, array $params): array
    {
        return $this->paginate(fn () => Db::table('sa_member_assessment_result')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->order('id', 'desc'), $params);
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
        $doctorId = (int) ($data['doctor_id'] ?? 0);
        $appointDate = trim((string) ($data['appoint_date'] ?? ''));
        $timeSlot = trim((string) ($data['appoint_time_slot'] ?? ''));
        if ($doctorId <= 0 || $appointDate === '' || $timeSlot === '') {
            throw new ApiException('医生、预约日期和时间段必须填写', 400);
        }
        if ($doctorId === $memberId) {
            throw new ApiException('不能预约自己', 400);
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

        $payload = $this->only($data, ['meet_type', 'meet_link', 'remark']);
        $payload['member_id'] = $memberId;
        $payload['doctor_id'] = $doctorId;
        $payload['appoint_date'] = $appointDate;
        $payload['appoint_time_slot'] = $timeSlot;
        $payload['status'] = 0;

        $id = $this->saveRow('sa_doctor_appointment', $payload, $memberId);
        return Db::table('sa_doctor_appointment')->where('id', $id)->find() ?: [];
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

        $this->saveRow('sa_doctor_appointment', [
            'status' => 3,
            'cancel_by' => 'member',
            'cancel_reason' => (string) ($data['cancel_reason'] ?? ''),
            'canceled_at' => date('Y-m-d H:i:s'),
        ], $memberId, $appointmentId);

        return Db::table('sa_doctor_appointment')->where('id', $appointmentId)->find() ?: [];
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

    private function visibleMaterialQuery(int $memberId)
    {
        return Db::table('sa_content_material')
            ->where('status', 1)
            ->whereNull('delete_time')
            ->whereRaw('(is_public = 1 OR member_id = ' . $memberId . ')');
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
