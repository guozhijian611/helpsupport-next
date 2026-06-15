<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedSystemMailTemplates extends AbstractMigration
{
    private const TABLE = 'sa_system_mail_template';

    public function up(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach ($this->templates() as $template) {
            $this->execute(
                "INSERT INTO `" . self::TABLE . "` (`name`, `code`, `subject`, `content`, `variables`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                SELECT
                    " . $this->quote($template['name']) . ",
                    " . $this->quote($template['code']) . ",
                    " . $this->quote($template['subject']) . ",
                    " . $this->quote($template['content']) . ",
                    " . $this->quote($template['variables']) . ",
                    " . (int) $template['sort'] . ",
                    1,
                    " . $this->quote($template['remark']) . ",
                    1,
                    1,
                    NOW(),
                    NOW(),
                    NULL
                WHERE NOT EXISTS (
                    SELECT 1 FROM `" . self::TABLE . "` WHERE `code` = " . $this->quote($template['code']) . "
                )"
            );
        }
    }

    public function down(): void
    {
        if (!$this->hasTable(self::TABLE)) {
            return;
        }

        foreach ($this->templates() as $template) {
            $this->execute(
                "DELETE FROM `" . self::TABLE . "`
                WHERE `code` = " . $this->quote($template['code']) . "
                  AND `name` = " . $this->quote($template['name']) . "
                  AND `subject` = " . $this->quote($template['subject']) . "
                  AND `content` = " . $this->quote($template['content']) . "
                  AND `variables` = " . $this->quote($template['variables']) . "
                  AND `sort` = " . (int) $template['sort'] . "
                  AND `status` = 1
                  AND `remark` = " . $this->quote($template['remark']) . "
                  AND `delete_time` IS NULL"
            );
        }
    }

    /**
     * @return array<int, array<string, string|int>>
     */
    private function templates(): array
    {
        return [
            [
                'name' => '注册验证码',
                'code' => 'register_code',
                'subject' => '欢迎注册 HelpSupport，验证码：{code}',
                'content' => '<h2>欢迎注册 HelpSupport</h2><p>您的注册验证码为：<strong>{code}</strong></p><p>验证码 {expire_minutes} 分钟内有效。如非本人操作，请忽略本邮件。</p>',
                'variables' => "code=验证码\nexpire_minutes=有效分钟数",
                'sort' => 10,
                'remark' => '用户注册账号时发送',
            ],
            [
                'name' => '找回密码验证码',
                'code' => 'password_reset_code',
                'subject' => 'HelpSupport 密码找回验证码：{code}',
                'content' => '<h2>密码找回验证</h2><p>您的密码找回验证码为：<strong>{code}</strong></p><p>验证码 {expire_minutes} 分钟内有效。如非本人操作，请尽快检查账号安全。</p>',
                'variables' => "code=验证码\nexpire_minutes=有效分钟数",
                'sort' => 20,
                'remark' => '用户找回密码时发送',
            ],
            [
                'name' => '登录验证码',
                'code' => 'login_code',
                'subject' => 'HelpSupport 登录验证码：{code}',
                'content' => '<h2>登录验证</h2><p>您的登录验证码为：<strong>{code}</strong></p><p>验证码 {expire_minutes} 分钟内有效。如非本人操作，请忽略本邮件。</p>',
                'variables' => "code=验证码\nexpire_minutes=有效分钟数",
                'sort' => 30,
                'remark' => '邮箱验证码登录时发送',
            ],
            [
                'name' => '邮箱绑定验证码',
                'code' => 'email_bind_code',
                'subject' => 'HelpSupport 邮箱绑定验证码：{code}',
                'content' => '<h2>邮箱绑定验证</h2><p>您正在绑定邮箱，验证码为：<strong>{code}</strong></p><p>验证码 {expire_minutes} 分钟内有效。如非本人操作，请忽略本邮件。</p>',
                'variables' => "code=验证码\nexpire_minutes=有效分钟数",
                'sort' => 40,
                'remark' => '绑定或更换邮箱时发送',
            ],
            [
                'name' => '账号安全通知',
                'code' => 'security_alert',
                'subject' => 'HelpSupport 账号安全通知',
                'content' => '<h2>账号安全提醒</h2><p>您好，{nickname}：</p><p>您的账号在 {operate_time} 发生了安全相关操作：{action}。</p><p>操作地点：{location}，设备：{device}。</p><p>如非本人操作，请立即修改密码并联系平台客服。</p>',
                'variables' => "nickname=用户昵称\naction=操作内容\noperate_time=操作时间\nlocation=操作地点\ndevice=设备信息",
                'sort' => 50,
                'remark' => '账号敏感操作通知',
            ],
            [
                'name' => '预约创建通知',
                'code' => 'appointment_created',
                'subject' => '您的医生预约已提交：{appointment_date} {time_slot}',
                'content' => '<h2>预约已提交</h2><p>您好，{member_name}：</p><p>您已提交医生预约，医生：{doctor_name}，时间：{appointment_date} {time_slot}。</p><p>当前状态：{status_text}。请留意后续通知。</p>',
                'variables' => "member_name=会员姓名\ndoctor_name=医生姓名\nappointment_date=预约日期\ntime_slot=预约时段\nstatus_text=状态文本",
                'sort' => 60,
                'remark' => '会员创建医生预约后发送',
            ],
            [
                'name' => '预约提醒通知',
                'code' => 'appointment_reminder',
                'subject' => '预约提醒：{appointment_date} {time_slot} 与 {doctor_name} 咨询',
                'content' => '<h2>预约提醒</h2><p>您好，{member_name}：</p><p>您将在 {appointment_date} {time_slot} 与 {doctor_name} 进行咨询。</p><p>请提前进入 HelpSupport，确保网络和设备状态正常。</p>',
                'variables' => "member_name=会员姓名\ndoctor_name=医生姓名\nappointment_date=预约日期\ntime_slot=预约时段",
                'sort' => 70,
                'remark' => '预约开始前提醒会员',
            ],
            [
                'name' => '医生审核通过通知',
                'code' => 'doctor_audit_pass',
                'subject' => '您的医生入驻审核已通过',
                'content' => '<h2>审核通过</h2><p>您好，{doctor_name}：</p><p>您的医生入驻申请已通过审核。请登录平台完善排班和服务信息。</p><p>审核时间：{audit_time}</p>',
                'variables' => "doctor_name=医生姓名\naudit_time=审核时间",
                'sort' => 80,
                'remark' => '医生资质审核通过后发送',
            ],
            [
                'name' => '医生审核驳回通知',
                'code' => 'doctor_audit_reject',
                'subject' => '您的医生入驻审核未通过',
                'content' => '<h2>审核未通过</h2><p>您好，{doctor_name}：</p><p>您的医生入驻申请未通过审核。</p><p>驳回原因：{reject_reason}</p><p>您可以根据提示修改资料后重新提交。</p>',
                'variables' => "doctor_name=医生姓名\nreject_reason=驳回原因",
                'sort' => 90,
                'remark' => '医生资质审核驳回后发送',
            ],
            [
                'name' => '扫码支付待确认通知',
                'code' => 'manual_scan_payment_notice',
                'subject' => '扫码支付待确认：{order_no}',
                'content' => '<h2>扫码支付待管理员确认</h2><p>订单号：{order_no}</p><p>订单名称：{order_name}</p><p>订单金额：{order_price}</p><p>收款渠道：{pay_channel}</p><p>会员ID：{member_id}</p><p>用户确认时间：{confirm_time}</p><p>请登录后台订单列表核对到账后点击“确认到账”。</p>',
                'variables' => "order_no=订单号\norder_name=订单名称\norder_price=订单金额\npay_channel=收款渠道\nmember_id=会员ID\nconfirm_time=用户确认时间",
                'sort' => 100,
                'remark' => '扫码支付用户确认付款后发送给管理员',
            ],
        ];
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
