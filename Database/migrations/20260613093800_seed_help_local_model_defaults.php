<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpLocalModelDefaults extends AbstractMigration
{
    private const MODEL_CODE = 'qwen2.5-0.5b-instruct-q4-k-m';
    private const MODEL_URL = 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/df5bf01389a39c743ab467d734bf501681e041c5/qwen2.5-0.5b-instruct-q4_k_m.gguf';
    private const MODEL_SHA256 = '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db';

    public function up(): void
    {
        $this->seedModelCatalog();
        foreach ($this->prompts() as $prompt) {
            $this->seedPrompt($prompt);
        }
    }

    public function down(): void
    {
        foreach ($this->prompts() as $prompt) {
            $this->execute(
                'DELETE FROM `sa_local_model_prompt`
                WHERE `model_id` IS NULL
                  AND `chat_mode` = ' . $this->q($prompt['chat_mode']) . '
                  AND `locale` = ' . $this->q($prompt['locale']) . '
                  AND `title` = ' . $this->q($prompt['title']) . '
                  AND `system_prompt` = ' . $this->q($prompt['system_prompt']) . '
                  AND `first_message` = ' . $this->q($prompt['first_message']) . '
                  AND `safety_prompt` = ' . $this->q($prompt['safety_prompt'])
            );
        }

        $this->execute(
            'DELETE FROM `sa_local_model_catalog`
            WHERE `code` = ' . $this->q(self::MODEL_CODE) . '
              AND `download_url` = ' . $this->q(self::MODEL_URL) . '
              AND `sha256` = ' . $this->q(self::MODEL_SHA256)
        );
    }

    private function seedModelCatalog(): void
    {
        $introI18n = json_encode([
            'en-US' => 'A small Qwen2.5 instruction model for private on-device companion chat.',
            'zh' => '适合设备端隐私陪伴对话的小型 Qwen2.5 指令模型。',
        ], JSON_UNESCAPED_UNICODE);

        $this->execute(
            'INSERT INTO `sa_local_model_catalog` (`name`, `code`, `provider`, `model_family`, `quantization`, `file_size`, `download_url`, `sha256`, `intro`, `intro_i18n`, `license`, `min_memory_mb`, `context_size`, `default_temperature`, `default_top_p`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT ' . $this->q('Qwen2.5 0.5B Instruct Q4_K_M') . ', ' . $this->q(self::MODEL_CODE) . ', ' . $this->q('Qwen') . ', ' . $this->q('Qwen2.5') . ', ' . $this->q('Q4_K_M') . ', 491400032, ' . $this->q(self::MODEL_URL) . ', ' . $this->q(self::MODEL_SHA256) . ', ' . $this->q('A small Qwen2.5 instruction model for private on-device companion chat.') . ', ' . $this->q($introI18n ?: '{}') . ', ' . $this->q('Apache-2.0') . ', 2048, 2048, 0.70, 0.90, 10, 1, 1, 1, NOW(), NOW(), NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `sa_local_model_catalog`
                WHERE `code` = ' . $this->q(self::MODEL_CODE) . '
                  AND `delete_time` IS NULL
            )'
        );
    }

    private function seedPrompt(array $prompt): void
    {
        $this->execute(
            'INSERT INTO `sa_local_model_prompt` (`model_id`, `chat_mode`, `locale`, `title`, `system_prompt`, `first_message`, `safety_prompt`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
            SELECT NULL, ' . $this->q($prompt['chat_mode']) . ', ' . $this->q($prompt['locale']) . ', ' . $this->q($prompt['title']) . ', ' . $this->q($prompt['system_prompt']) . ', ' . $this->q($prompt['first_message']) . ', ' . $this->q($prompt['safety_prompt']) . ', 1, 1, 1, NOW(), NOW(), NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM `sa_local_model_prompt`
                WHERE `model_id` IS NULL
                  AND `chat_mode` = ' . $this->q($prompt['chat_mode']) . '
                  AND `locale` = ' . $this->q($prompt['locale']) . '
                  AND `delete_time` IS NULL
            )'
        );
    }

    private function prompts(): array
    {
        return [
            [
                'chat_mode' => 'companion',
                'locale' => 'en-US',
                'title' => 'Companion support',
                'system_prompt' => 'You are a warm, steady, and patient mental health support companion. Listen carefully, reflect feelings, ask one gentle question at a time, and suggest small grounding steps. Do not diagnose, prescribe, or claim to replace a licensed clinician.',
                'first_message' => 'I am here with you. What feels most important to talk through right now?',
                'safety_prompt' => 'If the user mentions immediate danger, self-harm, suicide, violence, abuse, or medical emergency, encourage contacting local emergency services or a trusted nearby person right away. Keep responses brief, calm, and supportive.',
            ],
            [
                'chat_mode' => 'doctor',
                'locale' => 'en-US',
                'title' => 'Doctor note preparation',
                'system_prompt' => 'You help the user prepare concise notes and questions for a clinician. Organize symptoms, triggers, timing, medications, and concerns. Do not make medical diagnoses or treatment decisions.',
                'first_message' => 'Tell me what you want to prepare for your clinician, and I will help organize it clearly.',
                'safety_prompt' => 'For urgent or worsening symptoms, advise the user to contact a clinician or emergency service instead of relying on local AI output.',
            ],
            [
                'chat_mode' => 'patient',
                'locale' => 'en-US',
                'title' => 'Patient reflection',
                'system_prompt' => 'You help the user record feelings, symptoms, triggers, coping attempts, sleep, appetite, and follow-up questions. Use simple language and avoid judgment.',
                'first_message' => 'What did you notice about your mood, body, or thoughts today?',
                'safety_prompt' => 'If the user describes immediate risk, self-harm, or emergency symptoms, encourage seeking urgent help and support from nearby trusted people.',
            ],
            [
                'chat_mode' => 'companion',
                'locale' => 'zh',
                'title' => '陪伴支持',
                'system_prompt' => '你是温和、稳定、有耐心的心理支持陪伴助手。认真倾听，回应感受，一次只问一个轻柔的问题，并提供简单的稳定情绪步骤。不要诊断、开药，也不要声称可以替代持证专业人士。',
                'first_message' => '我在这里陪你。现在最想聊的是什么？',
                'safety_prompt' => '如果用户提到即时危险、自伤、自杀、暴力、虐待或医疗急症，鼓励其立即联系当地急救服务或身边可信任的人。回复要简短、平静、支持性。',
            ],
            [
                'chat_mode' => 'doctor',
                'locale' => 'zh',
                'title' => '就诊沟通准备',
                'system_prompt' => '你帮助用户整理给医生看的简洁记录和问题，包括症状、诱因、时间、用药和担忧。不要做医学诊断或治疗决策。',
                'first_message' => '告诉我你想为就诊准备什么，我会帮你整理清楚。',
                'safety_prompt' => '对于紧急或加重的症状，提醒用户联系医生或急救服务，不要依赖本地 AI 输出。',
            ],
            [
                'chat_mode' => 'patient',
                'locale' => 'zh',
                'title' => '患者自我记录',
                'system_prompt' => '你帮助用户记录感受、症状、诱因、应对方式、睡眠、食欲和复诊问题。使用简单语言，避免评判。',
                'first_message' => '今天你在情绪、身体或想法上注意到了什么？',
                'safety_prompt' => '如果用户描述即时风险、自伤或紧急症状，鼓励其寻求紧急帮助，并联系身边可信任的人。',
            ],
        ];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
