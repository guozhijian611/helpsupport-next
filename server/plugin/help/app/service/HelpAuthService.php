<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\api\logic\common\IndexLogic;
use plugin\saiuser\app\admin\logic\member\MemberLogic;
use plugin\saiuser\app\model\member\Member;
use think\facade\Db;
use Tinywan\Jwt\JwtToken;
use Throwable;

class HelpAuthService
{
    private const REGISTER_TYPE_EMAIL = 'email';
    private const REGISTER_TYPE_PHONE = 'phone';
    private const EMAIL_CODE_EXPIRES_IN = 600;
    private const SMS_CODE_EXPIRES_IN = 300;
    private const CODE_RESEND_AFTER = 120;
    private const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
    private const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';
    private const CALLBACK_STRATEGY_ID_TOKEN = 'id_token';
    private const BINDING_STRATEGY_VERIFIED_OR_CREATE = 'verified_email_or_create';
    private const BINDING_STRATEGY_CREATE_NEW = 'create_new';
    private const BINDING_STRATEGY_VERIFIED_ONLY = 'verified_email_only';

    public function accountLogin(array $data): array
    {
        $identifier = trim((string) ($data['username'] ?? $data['account'] ?? ''));
        $password = (string) ($data['password'] ?? '');
        if ($identifier === '' || $password === '') {
            throw new ApiException('账号和密码必须填写', 400);
        }

        $member = $this->resolveMemberByIdentifier($identifier);
        if ($member === []) {
            throw new ApiException('账号或密码错误，请重新输入!', 400);
        }

        $token = (new MemberLogic())->login((string) $member['username'], $password, '1');
        $memberId = (int) ($member['id'] ?? 0);

        return $this->sessionPayload($token, $memberId);
    }

    public function sendRegisterEmail(array $data): array
    {
        $email = trim((string) ($data['email'] ?? ''));
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }

        (new IndexLogic())->emailSend($email, 1);

        return [
            'sent' => true,
            'target' => $this->maskEmail($email),
            'expires_in' => self::EMAIL_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function sendRegisterPhone(array $data): array
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $this->assertMobileAvailable($mobile, true);
        $this->sendSmsCode($mobile);

        return [
            'sent' => true,
            'target' => $this->maskMobile($mobile),
            'expires_in' => self::SMS_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function sendForgotEmail(array $data): array
    {
        $email = trim((string) ($data['email'] ?? ''));
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }

        (new IndexLogic())->emailSend($email, 2);

        return [
            'sent' => true,
            'target' => $this->maskEmail($email),
            'expires_in' => self::EMAIL_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function sendForgotPhone(array $data): array
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $this->assertMobileAvailable($mobile, false);
        $this->sendSmsCode($mobile);

        return [
            'sent' => true,
            'target' => $this->maskMobile($mobile),
            'expires_in' => self::SMS_CODE_EXPIRES_IN,
            'resend_after' => self::CODE_RESEND_AFTER,
        ];
    }

    public function accountRegister(array $data): array
    {
        $password = (string) ($data['password'] ?? '');
        $registerType = $this->resolveAuthType(
            (string) ($data['register_type'] ?? ''),
            array_key_exists('mobile', $data) || array_key_exists('mobile_code', $data),
            array_key_exists('email', $data) || array_key_exists('email_code', $data)
        );
        $this->assertPassword($password);
        $memberRole = $this->memberRoleFromData($data);

        $account = $registerType === self::REGISTER_TYPE_PHONE
            ? $this->registerByPhone($data)
            : $this->registerByEmail($data);

        $memberId = (int) ($account['member_id'] ?? 0);
        $data['member_role'] = $memberRole;
        $this->syncRegisterProfile($memberId, $data);
        $this->syncNickname($memberId, (string) ($data['nickname'] ?? ''));

        $token = (new MemberLogic())->login((string) ($account['username'] ?? ''), $password, '1');
        return $this->sessionPayload($token, $memberId);
    }

    public function passwordReset(array $data): array
    {
        $resetType = $this->resolveAuthType(
            (string) ($data['reset_type'] ?? ''),
            array_key_exists('mobile', $data) || array_key_exists('mobile_code', $data),
            array_key_exists('email', $data) || array_key_exists('email_code', $data)
        );
        $password = (string) ($data['password'] ?? '');
        $this->assertPassword($password);

        if ($resetType === self::REGISTER_TYPE_PHONE) {
            $this->resetPasswordByPhone($data);
        } else {
            $this->resetPasswordByEmail($data);
        }

        return ['reset' => true];
    }

    public function refreshToken(): array
    {
        $extend = [];
        $token = JwtToken::refreshToken($extend);
        $memberId = (int) ($extend['id'] ?? 0);

        return $this->sessionPayload($token, $memberId);
    }

    public function googleLogin(array $data): array
    {
        $idToken = trim((string) ($data['id_token'] ?? ''));
        if ($idToken === '') {
            throw new ApiException('Google ID Token 必须填写', 400);
        }

        $config = $this->oauthConfig('help_google_oauth');
        if (($config['enabled'] ?? '2') !== '1') {
            throw new ApiException('Google 登录未启用', 400);
        }
        $this->assertIdTokenCallbackStrategy($config, 'Google');

        $audiences = $this->nonEmptyValues($config, ['web_client_id', 'ios_client_id', 'android_client_id']);
        if ($audiences === []) {
            throw new ApiException('Google Client ID 未配置', 400);
        }

        $payload = $this->decodeJwtByJwks($idToken, self::GOOGLE_JWKS_URL, 'Google ID Token 验证失败');
        $issuer = (string) ($payload['iss'] ?? '');
        if (!in_array($issuer, ['https://accounts.google.com', 'accounts.google.com'], true)) {
            throw new ApiException('Google ID Token 签发方不可信', 401);
        }
        $audience = (string) ($payload['aud'] ?? '');
        if (!in_array($audience, $audiences, true)) {
            throw new ApiException('Google ID Token 受众不匹配', 401);
        }
        $openid = trim((string) ($payload['sub'] ?? ''));
        if ($openid === '') {
            throw new ApiException('Google ID Token 缺少用户标识', 401);
        }
        if (array_key_exists('email', $payload) && !$this->truthy($payload['email_verified'] ?? false)) {
            throw new ApiException('Google 邮箱未验证', 401);
        }

        $platformId = $this->platformId('GOOGLE');
        $this->applyOauthBindingStrategy($platformId, $openid, (string) ($payload['email'] ?? ''), true, $config, 'Google');
        $token = (new MemberLogic())->thirdPlatform([
            'platform_id' => $platformId,
            'openid' => $openid,
            'nickname' => trim((string) ($payload['name'] ?? '')),
            'avatar' => trim((string) ($payload['picture'] ?? '')),
        ]);

        $memberId = $this->memberIdByPlatform($platformId, $openid);
        $this->syncThirdPartyProfile($memberId, $data);
        $this->syncVerifiedEmail($memberId, (string) ($payload['email'] ?? ''), true);

        return $this->sessionPayload($token, $memberId);
    }

    public function appleLogin(array $data): array
    {
        $identityToken = trim((string) ($data['identity_token'] ?? ''));
        if ($identityToken === '') {
            throw new ApiException('Apple identityToken 必须填写', 400);
        }

        $config = $this->oauthConfig('help_apple_oauth');
        if (($config['enabled'] ?? '2') !== '1') {
            throw new ApiException('Apple 登录未启用', 400);
        }
        $this->assertIdTokenCallbackStrategy($config, 'Apple');

        $audiences = $this->nonEmptyValues($config, ['bundle_id', 'service_id']);
        if ($audiences === []) {
            throw new ApiException('Apple Bundle ID 或 Service ID 未配置', 400);
        }

        $payload = $this->decodeJwtByJwks($identityToken, self::APPLE_JWKS_URL, 'Apple identityToken 验证失败');
        if (($payload['iss'] ?? '') !== 'https://appleid.apple.com') {
            throw new ApiException('Apple identityToken 签发方不可信', 401);
        }
        $audience = (string) ($payload['aud'] ?? '');
        if (!in_array($audience, $audiences, true)) {
            throw new ApiException('Apple identityToken 受众不匹配', 401);
        }
        $openid = trim((string) ($payload['sub'] ?? ''));
        if ($openid === '') {
            throw new ApiException('Apple identityToken 缺少用户标识', 401);
        }

        $platformId = $this->platformId('APPLE');
        $this->applyOauthBindingStrategy(
            $platformId,
            $openid,
            (string) ($payload['email'] ?? ''),
            $this->truthy($payload['email_verified'] ?? false),
            $config,
            'Apple'
        );
        $token = (new MemberLogic())->thirdPlatform([
            'platform_id' => $platformId,
            'openid' => $openid,
            'nickname' => trim((string) ($data['full_name'] ?? '')),
            'avatar' => '',
        ]);

        $memberId = $this->memberIdByPlatform($platformId, $openid);
        $this->syncThirdPartyProfile($memberId, $data);
        $this->syncVerifiedEmail(
            $memberId,
            (string) ($payload['email'] ?? ''),
            $this->truthy($payload['email_verified'] ?? false)
        );

        return $this->sessionPayload($token, $memberId);
    }

    private function sessionPayload(array $token, int $memberId): array
    {
        if ($memberId <= 0) {
            throw new ApiException('会员登录状态异常', 401);
        }

        $token['token_type'] = $token['token_type'] ?? 'Bearer';
        $token['expires_in'] = $token['expires_in'] ?? config('plugin.saiuser.saithink.access_exp', 24 * 3600);

        $member = $this->member($memberId);
        $profile = $this->rowByMember('sa_help_member_profile', $memberId);
        $doctorProfile = $this->rowByMember('sa_help_doctor_profile', $memberId);

        return [
            'token' => $token,
            'member' => $member,
            'profile' => $profile,
            'doctor_profile' => $doctorProfile,
            'current_role' => $this->currentRole($profile, $doctorProfile),
            'role_flags' => $this->roleFlags($profile, $doctorProfile),
        ];
    }

    private function member(int $memberId): array
    {
        $member = Db::table('sa_member')
            ->where('id', $memberId)
            ->whereNull('delete_time')
            ->field('id, username, nickname, avatar, mobile, email, member_level_id, points_balance, last_login_ip, last_login_time, register_platform_id, status, create_time, update_time')
            ->find();
        if (!$member || (int) $member['status'] !== 1) {
            throw new ApiException('会员不存在或状态异常', 401);
        }

        return $member;
    }

    private function rowByMember(string $table, int $memberId): array
    {
        $row = Db::table($table)
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();

        return $row ?: [];
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

    private function oauthConfig(string $code): array
    {
        $groups = $this->configGroups([$code]);
        return $groups[$code] ?? [];
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

    private function resolveMemberByIdentifier(string $identifier): array
    {
        $identifier = trim($identifier);
        if ($identifier === '') {
            return [];
        }

        return (array) Db::table('sa_member')
            ->whereNull('delete_time')
            ->where(function ($query) use ($identifier) {
                $query->where('username', $identifier)
                    ->whereOr('email', $identifier)
                    ->whereOr('mobile', $identifier);
            })
            ->find();
    }

    private function resolveAuthType(string $type, bool $hasPhoneSignal, bool $hasEmailSignal): string
    {
        $type = strtolower(trim($type));
        if (in_array($type, [self::REGISTER_TYPE_EMAIL, self::REGISTER_TYPE_PHONE], true)) {
            return $type;
        }
        if ($hasPhoneSignal && !$hasEmailSignal) {
            return self::REGISTER_TYPE_PHONE;
        }

        return self::REGISTER_TYPE_EMAIL;
    }

    private function memberRoleFromData(array $data): string
    {
        $memberRole = trim((string) ($data['member_role'] ?? 'patient'));
        if (!in_array($memberRole, ['patient', 'doctor'], true)) {
            throw new ApiException('会员身份参数错误', 400);
        }

        return $memberRole;
    }

    private function registerByEmail(array $data): array
    {
        $email = trim((string) ($data['email'] ?? ''));
        $emailCode = trim((string) ($data['email_code'] ?? ''));
        if ($email === '' || $emailCode === '') {
            throw new ApiException('邮箱、邮箱验证码和密码必须填写', 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }
        $this->assertEmailAvailable($email, true);
        $this->assertEmailCode($email, $emailCode);

        return $this->createMemberAccount([
            'platform_code' => 'EMAIL',
            'email' => $email,
            'password' => (string) ($data['password'] ?? ''),
            'username' => (string) ($data['username'] ?? ''),
            'nickname' => (string) ($data['nickname'] ?? ''),
        ]);
    }

    private function registerByPhone(array $data): array
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $mobileCode = trim((string) ($data['mobile_code'] ?? ''));
        if ($mobileCode === '') {
            throw new ApiException('手机号验证码必须填写', 400);
        }
        $this->assertMobileAvailable($mobile, true);
        $this->consumeSmsCode($mobile, $mobileCode);

        return $this->createMemberAccount([
            'platform_code' => 'MOBILE',
            'mobile' => $mobile,
            'password' => (string) ($data['password'] ?? ''),
            'username' => (string) ($data['username'] ?? ''),
            'nickname' => (string) ($data['nickname'] ?? ''),
        ]);
    }

    private function resetPasswordByEmail(array $data): void
    {
        $email = trim((string) ($data['email'] ?? ''));
        $emailCode = trim((string) ($data['email_code'] ?? ''));
        if ($email === '' || $emailCode === '') {
            throw new ApiException('邮箱、邮箱验证码和新密码必须填写', 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }

        $member = $this->memberByField('email', $email);
        if ($member === []) {
            throw new ApiException('邮箱查找失败，请检查邮箱是否正确', 404);
        }

        $this->assertEmailCode($email, $emailCode);
        $this->updateMemberPassword((int) $member['id'], (string) ($data['password'] ?? ''));
    }

    private function resetPasswordByPhone(array $data): void
    {
        $mobile = $this->normalizeMobile($data['mobile'] ?? '');
        $mobileCode = trim((string) ($data['mobile_code'] ?? ''));
        if ($mobileCode === '') {
            throw new ApiException('手机号验证码和新密码必须填写', 400);
        }

        $member = $this->memberByField('mobile', $mobile);
        if ($member === []) {
            throw new ApiException('手机号查找失败，请检查手机号是否正确', 404);
        }

        $this->consumeSmsCode($mobile, $mobileCode);
        $this->updateMemberPassword((int) $member['id'], (string) ($data['password'] ?? ''));
    }

    private function createMemberAccount(array $data): array
    {
        $username = $this->normalizeUsername((string) ($data['username'] ?? ''));
        $nickname = $this->normalizeNickname((string) ($data['nickname'] ?? ''), $username);
        $platformCode = trim((string) ($data['platform_code'] ?? ''));
        $email = trim((string) ($data['email'] ?? ''));
        $mobile = trim((string) ($data['mobile'] ?? ''));
        $avatarBase = rtrim((string) config('plugin.saiuser.saithink.avatar', ''), '/');
        $avatar = $avatarBase !== '' ? $avatarBase . '/' . rawurlencode($username) . '.png' : '';
        $platformId = $this->platformId($platformCode);
        $now = date('Y-m-d H:i:s');

        return Db::transaction(function () use ($username, $nickname, $email, $mobile, $avatar, $platformId, $now, $data) {
            $memberId = (int) Db::table('sa_member')->insertGetId([
                'username' => $username,
                'nickname' => $nickname,
                'avatar' => $avatar,
                'password_hash' => password_hash((string) $data['password'], PASSWORD_DEFAULT),
                'email' => $email !== '' ? $email : null,
                'mobile' => $mobile !== '' ? $mobile : null,
                'member_level_id' => 1,
                'points_balance' => 0,
                'register_platform_id' => $platformId,
                'status' => 1,
                'create_time' => $now,
                'update_time' => $now,
            ]);

            Db::table('sa_member_platform_rel')->insert([
                'member_id' => $memberId,
                'platform_id' => $platformId,
                'platform_openid' => $email !== '' ? $email : $mobile,
                'is_bind' => 1,
                'bind_time' => $now,
                'create_time' => $now,
                'update_time' => $now,
            ]);

            return [
                'member_id' => $memberId,
                'username' => $username,
            ];
        });
    }

    private function normalizeUsername(string $username): string
    {
        $username = trim($username);
        if ($username === '') {
            return 'u' . Member::createUserSn();
        }
        if (mb_strlen($username) < 3 || mb_strlen($username) > 32) {
            throw new ApiException('账号长度需为 3-32 个字符', 400);
        }

        $exists = Db::table('sa_member')
            ->where('username', $username)
            ->whereNull('delete_time')
            ->find();
        if ($exists) {
            throw new ApiException('账号已存在，请更换后重试', 400);
        }

        return $username;
    }

    private function normalizeNickname(string $nickname, string $username): string
    {
        $nickname = trim($nickname);
        if ($nickname === '') {
            return $username;
        }

        return mb_substr($nickname, 0, 80);
    }

    private function assertPassword(string $password): void
    {
        if ($password === '') {
            throw new ApiException('密码必须填写', 400);
        }
        if (strlen($password) < 6) {
            throw new ApiException('密码长度不能少于 6 位', 400);
        }
    }

    private function assertEmailAvailable(string $email, bool $shouldBeAvailable): void
    {
        $member = $this->memberByField('email', $email);
        if ($shouldBeAvailable && $member !== []) {
            throw new ApiException('该邮箱账号已经注册，请更换邮箱或者直接登录！', 400);
        }
        if (!$shouldBeAvailable && $member === []) {
            throw new ApiException('邮箱查找失败，请检查邮箱是否正确', 404);
        }
    }

    private function assertMobileAvailable(string $mobile, bool $shouldBeAvailable): void
    {
        $member = $this->memberByField('mobile', $mobile);
        if ($shouldBeAvailable && $member !== []) {
            throw new ApiException('该手机号已经注册，请直接登录或找回密码', 400);
        }
        if (!$shouldBeAvailable && $member === []) {
            throw new ApiException('手机号查找失败，请检查手机号是否正确', 404);
        }
    }

    private function memberByField(string $field, string $value): array
    {
        return (array) Db::table('sa_member')
            ->where($field, $value)
            ->whereNull('delete_time')
            ->find();
    }

    private function assertEmailCode(string $email, string $code): void
    {
        $model = Db::table('sa_system_mail')
            ->where('email', $email)
            ->where('status', 'success')
            ->order('update_time', 'desc')
            ->find();
        if (!$model) {
            throw new ApiException('邮箱验证码获取失败，请确认邮件是否正确发送', 400);
        }
        if ((string) ($model['code'] ?? '') !== $code) {
            throw new ApiException('邮箱验证码错误或已过期，请填写正确的验证码', 400);
        }
        if (time() - strtotime((string) ($model['update_time'] ?? $model['create_time'] ?? '')) > self::EMAIL_CODE_EXPIRES_IN) {
            throw new ApiException('邮箱验证码错误或已过期，请填写正确的验证码', 400);
        }
    }

    private function sendSmsCode(string $mobile): void
    {
        $result = (new MemberLogic())->sendCode($mobile);
        if (!$result) {
            throw new ApiException('验证码发送失败，请稍后重试', 500);
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

    private function updateMemberPassword(int $memberId, string $password): void
    {
        Db::table('sa_member')
            ->where('id', $memberId)
            ->update([
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                'update_time' => date('Y-m-d H:i:s'),
            ]);
    }

    private function normalizeMobile(mixed $mobile): string
    {
        $mobile = trim((string) $mobile);
        if ($mobile === '' || !preg_match('/^1\d{10}$/', $mobile)) {
            throw new ApiException('请输入正确格式的手机号码', 400);
        }

        return $mobile;
    }

    private function decodeJwtByJwks(string $token, string $jwksUrl, string $message): array
    {
        try {
            JWT::$leeway = 60;
            $decoded = JWT::decode($token, JWK::parseKeySet($this->fetchJwks($jwksUrl)));
            return json_decode(json_encode($decoded, JSON_THROW_ON_ERROR), true, 512, JSON_THROW_ON_ERROR);
        } catch (Throwable $e) {
            throw new ApiException($message, 401);
        }
    }

    private function fetchJwks(string $url): array
    {
        $context = stream_context_create([
            'http' => [
                'timeout' => 5,
                'ignore_errors' => true,
                'header' => "Accept: application/json\r\n",
            ],
        ]);
        $body = @file_get_contents($url, false, $context);
        if (!is_string($body) || $body === '') {
            throw new ApiException('第三方登录公钥拉取失败', 502);
        }

        $jwks = json_decode($body, true);
        if (!is_array($jwks) || empty($jwks['keys']) || !is_array($jwks['keys'])) {
            throw new ApiException('第三方登录公钥格式错误', 502);
        }

        return $jwks;
    }

    private function platformId(string $code): int
    {
        $id = (int) Db::table('sa_member_platform')
            ->where('platform_code', $code)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->value('id');
        if ($id <= 0) {
            throw new ApiException($code . ' 会员平台未初始化或未启用', 400);
        }

        return $id;
    }

    private function memberIdByPlatform(int $platformId, string $openid): int
    {
        $memberId = (int) Db::table('sa_member_platform_rel')
            ->where('platform_id', $platformId)
            ->where('platform_openid', $openid)
            ->where('is_bind', 1)
            ->whereNull('delete_time')
            ->value('member_id');
        if ($memberId <= 0) {
            throw new ApiException('第三方账号绑定关系异常', 401);
        }

        return $memberId;
    }

    private function assertIdTokenCallbackStrategy(array $config, string $provider): void
    {
        $strategy = trim((string) ($config['callback_strategy'] ?? self::CALLBACK_STRATEGY_ID_TOKEN));
        if ($strategy === '') {
            $strategy = self::CALLBACK_STRATEGY_ID_TOKEN;
        }
        if ($strategy !== self::CALLBACK_STRATEGY_ID_TOKEN) {
            throw new ApiException($provider . ' 登录暂仅支持 ID Token 直连模式', 400);
        }
    }

    private function applyOauthBindingStrategy(
        int $platformId,
        string $openid,
        string $email,
        bool $verified,
        array $config,
        string $provider
    ): void {
        if ($this->platformRelExists($platformId, $openid)) {
            return;
        }

        $strategy = trim((string) ($config['binding_strategy'] ?? self::BINDING_STRATEGY_VERIFIED_OR_CREATE));
        if ($strategy === '') {
            $strategy = self::BINDING_STRATEGY_VERIFIED_OR_CREATE;
        }
        if (!in_array($strategy, [
            self::BINDING_STRATEGY_VERIFIED_OR_CREATE,
            self::BINDING_STRATEGY_CREATE_NEW,
            self::BINDING_STRATEGY_VERIFIED_ONLY,
        ], true)) {
            throw new ApiException($provider . ' 登录绑定策略配置错误', 400);
        }
        if ($strategy === self::BINDING_STRATEGY_CREATE_NEW) {
            return;
        }

        $bound = $this->ensureVerifiedEmailBinding($platformId, $openid, $email, $verified);
        if ($strategy === self::BINDING_STRATEGY_VERIFIED_ONLY && !$bound) {
            throw new ApiException($provider . ' 登录未找到可绑定的已验证邮箱账号', 401);
        }
    }

    private function platformRelExists(int $platformId, string $openid): bool
    {
        if ($openid === '') {
            return false;
        }

        return Db::table('sa_member_platform_rel')
            ->where('platform_id', $platformId)
            ->where('platform_openid', $openid)
            ->where('is_bind', 1)
            ->whereNull('delete_time')
            ->find() !== null;
    }

    private function ensureVerifiedEmailBinding(int $platformId, string $openid, string $email, bool $verified): bool
    {
        $email = trim($email);
        if (!$verified || $email === '' || $openid === '') {
            return false;
        }

        if ($this->platformRelExists($platformId, $openid)) {
            return true;
        }

        $members = Db::table('sa_member')
            ->where('email', $email)
            ->where('status', 1)
            ->whereNull('delete_time')
            ->field('id')
            ->limit(2)
            ->select()
            ->toArray();
        if (count($members) !== 1) {
            return false;
        }

        $now = date('Y-m-d H:i:s');
        try {
            Db::table('sa_member_platform_rel')->insert([
                'member_id' => (int) $members[0]['id'],
                'platform_id' => $platformId,
                'platform_openid' => $openid,
                'is_bind' => 1,
                'bind_time' => $now,
                'create_time' => $now,
                'update_time' => $now,
            ]);
        } catch (Throwable) {
            // 并发登录时可能已有请求完成绑定，后续 thirdPlatform 会按已存在关系登录。
        }

        return $this->platformRelExists($platformId, $openid);
    }

    private function syncVerifiedEmail(int $memberId, string $email, bool $verified): void
    {
        $email = trim($email);
        if (!$verified || $email === '') {
            return;
        }

        $currentEmail = (string) Db::table('sa_member')->where('id', $memberId)->value('email');
        if ($currentEmail !== '') {
            return;
        }

        Db::table('sa_member')
            ->where('id', $memberId)
            ->update([
                'email' => $email,
                'update_time' => date('Y-m-d H:i:s'),
            ]);
    }

    private function syncRegisterProfile(int $memberId, array $data): void
    {
        if ($memberId <= 0) {
            throw new ApiException('会员注册状态异常', 401);
        }

        $memberRole = trim((string) ($data['member_role'] ?? 'patient'));
        if (!in_array($memberRole, ['patient', 'doctor'], true)) {
            throw new ApiException('会员身份参数错误', 400);
        }

        $payload = [
            'member_role' => $memberRole,
            'status' => 1,
        ];
        foreach (['locale', 'timezone'] as $field) {
            $value = trim((string) ($data[$field] ?? ''));
            if ($value !== '') {
                $payload[$field] = $value;
            }
        }

        $now = date('Y-m-d H:i:s');
        $exists = Db::table('sa_help_member_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if ($exists) {
            $payload['updated_by'] = $memberId;
            $payload['update_time'] = $now;
            Db::table('sa_help_member_profile')->where('id', $exists['id'])->update($payload);
            return;
        }

        $payload['member_id'] = $memberId;
        $payload['created_by'] = $memberId;
        $payload['updated_by'] = $memberId;
        $payload['create_time'] = $now;
        $payload['update_time'] = $now;
        Db::table('sa_help_member_profile')->insert($payload);
    }

    private function syncThirdPartyProfile(int $memberId, array $data): void
    {
        if ($memberId <= 0) {
            throw new ApiException('会员登录状态异常', 401);
        }

        $memberRole = trim((string) ($data['member_role'] ?? ''));
        if ($memberRole !== '' && !in_array($memberRole, ['patient', 'doctor'], true)) {
            throw new ApiException('会员身份参数错误', 400);
        }

        $payload = [];
        foreach (['locale', 'timezone'] as $field) {
            $value = trim((string) ($data[$field] ?? ''));
            if ($value !== '') {
                $payload[$field] = $value;
            }
        }

        $now = date('Y-m-d H:i:s');
        $exists = Db::table('sa_help_member_profile')
            ->where('member_id', $memberId)
            ->whereNull('delete_time')
            ->find();
        if ($exists) {
            if ($memberRole !== '') {
                $payload['member_role'] = $memberRole;
            }
            if ($payload === []) {
                return;
            }

            $payload['updated_by'] = $memberId;
            $payload['update_time'] = $now;
            Db::table('sa_help_member_profile')->where('id', $exists['id'])->update($payload);
            return;
        }

        $payload['member_id'] = $memberId;
        $payload['member_role'] = $memberRole !== '' ? $memberRole : 'patient';
        $payload['status'] = 1;
        $payload['created_by'] = $memberId;
        $payload['updated_by'] = $memberId;
        $payload['create_time'] = $now;
        $payload['update_time'] = $now;
        Db::table('sa_help_member_profile')->insert($payload);
    }

    private function syncNickname(int $memberId, string $nickname): void
    {
        $nickname = trim($nickname);
        if ($memberId <= 0 || $nickname === '') {
            return;
        }

        Db::table('sa_member')
            ->where('id', $memberId)
            ->update([
                'nickname' => mb_substr($nickname, 0, 80),
                'update_time' => date('Y-m-d H:i:s'),
            ]);
    }

    private function maskEmail(string $email): string
    {
        [$name, $domain] = array_pad(explode('@', $email, 2), 2, '');
        if ($name === '' || $domain === '') {
            return '';
        }

        return mb_substr($name, 0, 1) . '***@' . $domain;
    }

    private function maskMobile(string $mobile): string
    {
        if (strlen($mobile) !== 11) {
            return '';
        }

        return substr($mobile, 0, 3) . '****' . substr($mobile, -4);
    }

    private function nonEmptyValues(array $data, array $keys): array
    {
        $values = [];
        foreach ($keys as $key) {
            $value = trim((string) ($data[$key] ?? ''));
            if ($value !== '') {
                $values[] = $value;
            }
        }

        return array_values(array_unique($values));
    }

    private function truthy(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        return in_array(strtolower((string) $value), ['1', 'true', 'yes'], true);
    }
}
