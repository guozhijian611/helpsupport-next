<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedMemberProtocolEnUsDefaults extends AbstractMigration
{
    public function up(): void
    {
        if (!$this->hasTable('sa_member_protocol')) {
            return;
        }

        foreach ($this->defaultProtocols() as $protocol) {
            $exists = $this->query(sprintf(
                'SELECT id FROM `sa_member_protocol` WHERE `protocol_type` = %d AND `locale` = %s AND `delete_time` IS NULL LIMIT 1',
                $protocol['protocol_type'],
                $this->quote($protocol['locale']),
            ))->fetch();
            if ($exists) {
                continue;
            }

            $this->execute(sprintf(
                'INSERT INTO `sa_member_protocol` (`protocol_type`, `locale`, `title`, `content`, `status`, `create_time`, `update_time`) VALUES (%d, %s, %s, %s, 1, NOW(), NOW())',
                $protocol['protocol_type'],
                $this->quote($protocol['locale']),
                $this->quote($protocol['title']),
                $this->quote($protocol['content']),
            ));
        }
    }

    public function down(): void
    {
        // 默认英文协议可能已经被后台编辑过，回滚时不自动删除，避免误删用户内容。
    }

    /**
     * @return array<int, array{protocol_type:int, locale:string, title:string, content:string}>
     */
    private function defaultProtocols(): array
    {
        return [
            [
                'protocol_type' => 1,
                'locale' => 'en-US',
                'title' => 'User Agreement',
                'content' => <<<'HTML'
<p><strong>1. Acceptance</strong></p><p>By registering, signing in, or using HelpSupport, you confirm that you have read and accepted this User Agreement.</p><p><strong>2. Account</strong></p><p>You must provide accurate information and keep your account credentials safe. You are responsible for activities under your account.</p><p><strong>3. Proper Use</strong></p><p>You may not use the service for unlawful, harmful, fraudulent, or abusive activity, and you may not interfere with the stability or security of the service.</p><p><strong>4. Changes</strong></p><p>We may update this agreement from time to time. Continued use of the service means you accept the updated version.</p>
HTML,
            ],
            [
                'protocol_type' => 2,
                'locale' => 'en-US',
                'title' => 'Privacy Policy',
                'content' => <<<'HTML'
<p><strong>1. Information We Collect</strong></p><p>We may collect account details, device information, usage records, and other data required to provide and improve HelpSupport.</p><p><strong>2. How We Use Information</strong></p><p>Your information is used to deliver features, keep your account secure, respond to requests, and improve product quality.</p><p><strong>3. Data Protection</strong></p><p>We apply reasonable technical and organizational safeguards to protect personal information, but no system can guarantee absolute security.</p><p><strong>4. Your Rights</strong></p><p>You may contact us to request access, correction, or deletion of personal information, subject to applicable law.</p>
HTML,
            ],
            [
                'protocol_type' => 3,
                'locale' => 'en-US',
                'title' => 'Recharge Agreement',
                'content' => <<<'HTML'
<p><strong>1. Recharge Confirmation</strong></p><p>Before completing a recharge, please review the amount, payment method, and the applicable rules shown in the app.</p><p><strong>2. Credit Delivery</strong></p><p>After a successful payment, the corresponding balance, points, or entitlements will be credited to your account according to the product description.</p><p><strong>3. Refunds</strong></p><p>Except where required by law or caused by platform error, completed recharge transactions are generally non-refundable.</p><p><strong>4. Service Adjustments</strong></p><p>We may adjust recharge products, pricing, or related benefits with prior notice shown in the service.</p>
HTML,
            ],
            [
                'protocol_type' => 4,
                'locale' => 'en-US',
                'title' => 'Terms of Use',
                'content' => <<<'HTML'
<p><strong>1. Scope</strong></p><p>These Terms of Use govern your access to and use of HelpSupport and its related features.</p><p><strong>2. Eligibility</strong></p><p>You should use the service only if you are legally able to accept this agreement. Minors should use the service with the consent of a parent or guardian.</p><p><strong>3. Content and Conduct</strong></p><p>You must not publish illegal, infringing, abusive, or misleading content, and you must not attempt to obtain unauthorized access to the system.</p><p><strong>4. Liability</strong></p><p>The service is provided on an as-available basis. To the extent permitted by law, we are not liable for indirect losses caused by service interruption, device issues, or third-party factors.</p>
HTML,
            ],
        ];
    }

    private function quote(string $value): string
    {
        return $this->getAdapter()->getConnection()->quote($value);
    }
}
