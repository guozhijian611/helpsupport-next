<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class AddHelpChatOnlineModelSelection extends AbstractMigration
{
    private const CHAT_MODE = 'ai_doctor';

    public function up(): void
    {
        $this->addTempSaveColumn();
        $this->seedRobotProfiles();
        $this->seedLocalPrompts();
    }

    public function down(): void
    {
        $this->removeSeededLocalPrompts();
        $this->removeSeededRobotProfiles();

        if ($this->hasTable('sa_member_chat_config')) {
            $table = $this->table('sa_member_chat_config');
            if ($table->hasColumn('temp_save')) {
                $table->removeColumn('temp_save')->update();
            }
        }
    }

    private function addTempSaveColumn(): void
    {
        if (!$this->hasTable('sa_member_chat_config')) {
            return;
        }

        $table = $this->table('sa_member_chat_config');
        if (!$table->hasColumn('temp_save')) {
            $table->addColumn('temp_save', 'string', [
                'limit' => 500,
                'default' => '',
                'null' => false,
                'comment' => '临时字符串配置，在线聊天保存最近选择的模型配置ID',
                'after' => 'prompt_text',
            ])->update();
        }
    }

    private function seedRobotProfiles(): void
    {
        if (!$this->hasTable('sa_ai_robot_profile')) {
            return;
        }

        foreach ($this->robotProfiles() as $profile) {
            $this->execute(
                'INSERT INTO `sa_ai_robot_profile` (`chat_mode`, `runtime_mode`, `display_name`, `display_name_en`, `description`, `description_en`, `avatar`, `dark_avatar`, `sort`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT ' . $this->q(self::CHAT_MODE) . ', ' . $this->q($profile['runtime_mode']) . ', ' . $this->q($profile['display_name']) . ', ' . $this->q($profile['display_name_en']) . ', ' . $this->q($profile['description']) . ', ' . $this->q($profile['description_en']) . ', ' . $this->q($profile['avatar']) . ', ' . $this->q($profile['avatar']) . ', ' . (int) $profile['sort'] . ', 1, 1, 1, NOW(), NOW(), NULL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM `sa_ai_robot_profile`
                     WHERE `chat_mode` = ' . $this->q(self::CHAT_MODE) . '
                       AND `runtime_mode` = ' . $this->q($profile['runtime_mode']) . '
                       AND `delete_time` IS NULL
                 )'
            );
        }
    }

    private function seedLocalPrompts(): void
    {
        if (!$this->hasTable('sa_local_model_prompt')) {
            return;
        }

        foreach ($this->localPrompts() as $prompt) {
            $this->execute(
                'INSERT INTO `sa_local_model_prompt` (`model_id`, `chat_mode`, `locale`, `title`, `system_prompt`, `first_message`, `safety_prompt`, `status`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
                 SELECT NULL, ' . $this->q(self::CHAT_MODE) . ', ' . $this->q($prompt['locale']) . ', ' . $this->q($prompt['title']) . ', ' . $this->q($prompt['system_prompt']) . ', ' . $this->q($prompt['first_message']) . ', ' . $this->q($prompt['safety_prompt']) . ', 1, 1, 1, NOW(), NOW(), NULL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM `sa_local_model_prompt`
                     WHERE `model_id` IS NULL
                       AND `chat_mode` = ' . $this->q(self::CHAT_MODE) . '
                       AND `locale` = ' . $this->q($prompt['locale']) . '
                       AND `delete_time` IS NULL
                 )'
            );
        }
    }

    private function removeSeededRobotProfiles(): void
    {
        if (!$this->hasTable('sa_ai_robot_profile')) {
            return;
        }

        foreach ($this->robotProfiles() as $profile) {
            $this->execute(
                'DELETE FROM `sa_ai_robot_profile`
                 WHERE `chat_mode` = ' . $this->q(self::CHAT_MODE) . '
                   AND `runtime_mode` = ' . $this->q($profile['runtime_mode']) . '
                   AND `display_name` = ' . $this->q($profile['display_name']) . '
                   AND `display_name_en` = ' . $this->q($profile['display_name_en']) . '
                   AND `description` = ' . $this->q($profile['description']) . '
                   AND `description_en` = ' . $this->q($profile['description_en']) . '
                   AND `avatar` = ' . $this->q($profile['avatar']) . '
                   AND `dark_avatar` = ' . $this->q($profile['avatar'])
            );
        }
    }

    private function removeSeededLocalPrompts(): void
    {
        if (!$this->hasTable('sa_local_model_prompt')) {
            return;
        }

        foreach ($this->localPrompts() as $prompt) {
            $this->execute(
                'DELETE FROM `sa_local_model_prompt`
                 WHERE `model_id` IS NULL
                   AND `chat_mode` = ' . $this->q(self::CHAT_MODE) . '
                   AND `locale` = ' . $this->q($prompt['locale']) . '
                   AND `title` = ' . $this->q($prompt['title']) . '
                   AND `system_prompt` = ' . $this->q($prompt['system_prompt']) . '
                   AND `first_message` = ' . $this->q($prompt['first_message']) . '
                   AND `safety_prompt` = ' . $this->q($prompt['safety_prompt'])
            );
        }
    }

    private function robotProfiles(): array
    {
        $avatar = 'https://api.dicebear.com/9.x/bottts-neutral/png?seed=' . rawurlencode('HelpSupport AI Clinician');

        return [
            [
                'runtime_mode' => 'online',
                'display_name' => 'AI 医生',
                'display_name_en' => 'AI clinician',
                'description' => '帮助整理健康问题、症状和就诊准备的 AI 助手',
                'description_en' => 'An AI assistant for organizing health concerns, symptoms, and visit preparation',
                'avatar' => $avatar,
                'sort' => 40,
            ],
            [
                'runtime_mode' => 'local',
                'display_name' => '本地 AI 医生',
                'display_name_en' => 'Local AI clinician',
                'description' => '使用本地模型整理健康问题和就诊准备',
                'description_en' => 'On-device help for organizing health concerns and visit preparation',
                'avatar' => $avatar,
                'sort' => 70,
            ],
        ];
    }

    private function localPrompts(): array
    {
        return [
            [
                'locale' => 'zh',
                'title' => '健康问题整理',
                'system_prompt' => '你是一位谨慎的 AI 健康信息助手。帮助用户整理症状、持续时间、诱因、用药和准备向医生咨询的问题。不要做诊断、开药、调整处方，也不要声称替代真实医生。',
                'first_message' => '请告诉我你现在最想整理的健康问题，我会帮你准备清晰的就诊信息。',
                'safety_prompt' => '如出现呼吸困难、胸痛、意识异常、大量出血、自伤风险或其他紧急情况，明确建议立即联系当地急救服务并寻求线下医疗帮助。',
            ],
            [
                'locale' => 'en-US',
                'title' => 'Health concern organizer',
                'system_prompt' => 'You are a cautious AI health information assistant. Help the user organize symptoms, duration, triggers, medications, and questions for a clinician. Do not diagnose, prescribe, change medication, or claim to replace a real clinician.',
                'first_message' => 'Tell me the health concern you want to organize, and I will help prepare clear information for a clinical visit.',
                'safety_prompt' => 'For breathing difficulty, chest pain, altered consciousness, major bleeding, self-harm risk, or another emergency, clearly advise contacting local emergency services and seeking in-person medical care immediately.',
            ],
        ];
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
