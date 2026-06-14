<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use plugin\saiadmin\exception\ApiException;
use plugin\saiuser\app\api\logic\common\IndexLogic;
use plugin\saiuser\app\admin\logic\member\MemberLogic;
use think\facade\Db;
use Tinywan\Jwt\JwtToken;
use Throwable;

class HelpAuthService
{
    private const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
    private const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';

    public function accountLogin(array $data): array
    {
        $username = trim((string) ($data['username'] ?? ''));
        $password = (string) ($data['password'] ?? '');
        if ($username === '' || $password === '') {
            throw new ApiException('账号和密码必须填写', 400);
        }

        $token = (new MemberLogic())->login($username, $password, '1');
        $memberId = (int) Db::table('sa_member')
            ->where('username', $username)
            ->whereNull('delete_time')
            ->value('id');

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
            'email' => $this->maskEmail($email),
            'expires_in' => 600,
            'resend_after' => 120,
        ];
    }

    public function accountRegister(array $data): array
    {
        $username = trim((string) ($data['username'] ?? ''));
        $email = trim((string) ($data['email'] ?? ''));
        $password = (string) ($data['password'] ?? '');
        $emailCode = trim((string) ($data['email_code'] ?? ''));
        if ($username === '' || $email === '' || $password === '' || $emailCode === '') {
            throw new ApiException('账号、邮箱、密码和邮箱验证码必须填写', 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('请输入正确的邮箱格式', 400);
        }
        if (mb_strlen($username) < 3 || mb_strlen($username) > 32) {
            throw new ApiException('账号长度需为 3-32 个字符', 400);
        }
        if (strlen($password) < 6) {
            throw new ApiException('密码长度不能少于 6 位', 400);
        }
        $memberRole = trim((string) ($data['member_role'] ?? 'patient'));
        if (!in_array($memberRole, ['patient', 'doctor'], true)) {
            throw new ApiException('会员身份参数错误', 400);
        }

        (new MemberLogic())->emailReg([
            'username' => $username,
            'email' => $email,
            'password' => $password,
            'email_code' => $emailCode,
        ]);

        $memberId = (int) Db::table('sa_member')
            ->where('username', $username)
            ->whereNull('delete_time')
            ->value('id');
        $data['member_role'] = $memberRole;
        $this->syncRegisterProfile($memberId, $data);
        $this->syncNickname($memberId, (string) ($data['nickname'] ?? ''));

        $token = (new MemberLogic())->login($username, $password, '1');
        return $this->sessionPayload($token, $memberId);
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

        return [
            'token' => $token,
            'member' => $this->member($memberId),
            'profile' => $this->rowByMember('sa_help_member_profile', $memberId),
            'doctor_profile' => $this->rowByMember('sa_help_doctor_profile', $memberId),
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
