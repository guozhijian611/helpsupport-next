<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class SeedHelpComprehensiveDemoData extends AbstractMigration
{
    private const MAIN_PATIENT_ID = 986170008;
    private const EXISTING_DEMO_DOCTOR_ID = 986170009;

    private const MEMBER_DOCTOR_LIN = 986170020;
    private const MEMBER_DOCTOR_CHEN = 986170021;
    private const MEMBER_PATIENT_AMY = 986170022;
    private const MEMBER_PATIENT_JAY = 986170023;
    private const MEMBER_PATIENT_LUNA = 986170024;
    private const MEMBER_PATIENT_NOAH = 986170025;

    public function up(): void
    {
        $this->seedMembers();
        $this->seedMemberProfiles();
        $this->seedDoctorProfiles();
        $this->seedPushPreferences();
        $this->seedLoginLogs();

        $this->seedDoctorSchedules();
        $this->seedDoctorAppointments();
        $this->seedDoctorPatientBindings();
        $this->syncScheduleBookedCounts([8101, 8102, 8103, 8104, 8105, 8106, 8107]);

        $this->seedTreatmentPlans();
        $this->seedTreatmentStages();
        $this->seedDailyTasks();

        $this->seedMemberMessages();
        $this->seedPointLogs();
        $this->syncPointsBalances([
            self::MAIN_PATIENT_ID,
            self::MEMBER_PATIENT_AMY,
            self::MEMBER_PATIENT_JAY,
            self::MEMBER_PATIENT_LUNA,
        ]);
        $this->seedMemberBadges();
        $this->seedMemberJournals();
        $this->seedMemoirConfigs();
        $this->seedMemberMemoirs();

        $this->seedContentCategories();
        $this->seedContentMaterials();
        $this->seedContentHistory();
        $this->seedMaterialCollects();

        $this->seedCommunityTags();
        $this->seedCommunityFollowTags();
        $this->seedCommunityPosts();
        $this->seedCommunityComments();
        $this->seedCommunityLikes();
        $this->seedCommunityCollects();
        $this->seedCommunityFollowMembers();
        $this->syncCommunityPostStats([9021, 9022, 9023, 9024, 9025, 9026]);
        $this->syncCommunityCommentLikeStats([9031, 9032, 9033, 9034, 9035, 9036, 9037, 9038]);

        $this->seedMemberChatConfigs();
        $this->seedMemberChatSessions();
        $this->seedMemberChatRecords();
        $this->syncChatSessionSummaries([9111, 9112, 9113, 9114, 9115]);

        $this->seedLocalModels();
        $this->seedLocalModelPrompts();
        $this->seedLocalModelDownloadLogs();
    }

    public function down(): void
    {
        $this->deleteIds('sa_local_model_download_log', [9221, 9222, 9223, 9224]);
        $this->deleteIds('sa_local_model_prompt', [9211, 9212, 9213, 9214, 9215, 9216]);
        $this->deleteIds('sa_member_chat_record', [
            9121, 9122, 9123, 9124,
            9125, 9126, 9127, 9128,
            9129, 9130, 9131, 9132,
            9133, 9134, 9135, 9136,
            9137, 9138, 9139, 9140,
        ]);
        $this->deleteIds('sa_member_chat_session', [9111, 9112, 9113, 9114, 9115]);
        $this->deleteIds('sa_member_chat_config', [9101, 9102, 9103, 9104, 9105, 9106, 9107]);

        $this->deleteIds('sa_community_like', [9041, 9042, 9043, 9044, 9045, 9046, 9047, 9048]);
        $this->deleteIds('sa_community_collect', [9051, 9052, 9053]);
        $this->deleteIds('sa_community_comment', [9031, 9032, 9033, 9034, 9035, 9036, 9037, 9038]);
        $this->deleteIds('sa_community_post', [9021, 9022, 9023, 9024, 9025, 9026]);
        $this->deleteIds('sa_community_follow_tag', [9011, 9012, 9013, 9014, 9015, 9016, 9017, 9018]);
        $this->deleteIds('sa_community_follow_member', [9061, 9062, 9063, 9064, 9065]);
        $this->deleteIds('sa_community_tag', [9001, 9002, 9003, 9004, 9005]);

        $this->deleteIds('sa_material_collect', [8931, 8932, 8933, 8934]);
        $this->deleteIds('sa_member_content_history', [8921, 8922, 8923, 8924, 8925, 8926]);
        $this->deleteIds('sa_content_material', [8911, 8912, 8913, 8914, 8915, 8916, 8917, 8918]);
        $this->deleteIds('sa_content_category', [8901, 8902, 8903, 8904]);

        $this->deleteIds('sa_member_memoir', [8811, 8812, 8813]);
        $this->deleteIds('sa_member_memoir_config', [8801, 8802]);
        $this->deleteIds('sa_member_journal', [8701, 8702, 8703, 8704, 8705, 8706, 8707, 8708, 8709, 8710]);
        $this->deleteIds('sa_member_badge', [8601, 8602, 8603, 8604]);
        $this->deleteIds('sa_member_point_log', [8501, 8502, 8503, 8504, 8505, 8506, 8507, 8508]);
        $this->deleteIds('sa_member_message', [8401, 8402, 8403, 8404, 8405, 8406, 8407, 8408, 8409, 8410]);

        $this->deleteIds('sa_daily_task', [8331, 8332, 8333, 8334, 8335, 8336, 8337, 8338, 8339, 8340, 8341, 8342]);
        $this->deleteIds('sa_treatment_stage', [8311, 8312, 8313, 8314, 8315, 8316, 8317]);
        $this->deleteIds('sa_treatment_plan', [8301, 8302, 8303]);

        $this->deleteIds('sa_doctor_patient', [9231, 9232, 9233, 9234]);
        $this->deleteIds('sa_doctor_appointment', [8201, 8202, 8203, 8204]);
        $this->deleteIds('sa_doctor_schedule', [8101, 8102, 8103, 8104, 8105, 8106, 8107]);
        $this->deleteIds('sa_member_login_log', [9241, 9242, 9243, 9244, 9245, 9246]);
        $this->deleteIds('sa_member_push_preference', [9251, 9252, 9253, 9254]);

        $this->deleteIds('sa_help_doctor_profile', [9311, 9312]);
        $this->deleteIds('sa_help_member_profile', [9301, 9302, 9303, 9304, 9305, 9306]);
        $this->deleteIds('sa_local_model_catalog', [9201, 9202]);
        $this->deleteIds('sa_member', [
            self::MEMBER_DOCTOR_LIN,
            self::MEMBER_DOCTOR_CHEN,
            self::MEMBER_PATIENT_AMY,
            self::MEMBER_PATIENT_JAY,
            self::MEMBER_PATIENT_LUNA,
            self::MEMBER_PATIENT_NOAH,
        ]);

        $this->syncPointsBalances([self::MAIN_PATIENT_ID]);
    }

    private function seedMembers(): void
    {
        $members = [
            [
                'id' => self::MEMBER_DOCTOR_LIN,
                'username' => 'doctor_lin',
                'nickname' => '林清岚',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Lin%20Qinglan',
                'mobile' => '13800002020',
                'email' => 'doctor-lin@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.2.20',
                'last_login_time' => $this->dt(-1, '21:20:00'),
                'register_platform_id' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-40, '09:10:00'),
                'update_time' => $this->dt(-1, '21:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => self::MEMBER_DOCTOR_CHEN,
                'username' => 'doctor_chen',
                'nickname' => '陈川医生',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Chen%20Chuan',
                'mobile' => '13800002021',
                'email' => 'doctor-chen@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.2.21',
                'last_login_time' => $this->dt(-2, '18:40:00'),
                'register_platform_id' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-32, '10:00:00'),
                'update_time' => $this->dt(-2, '18:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => self::MEMBER_PATIENT_AMY,
                'username' => 'amy_recover',
                'nickname' => 'Amy恢复中',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Amy%20Recover',
                'mobile' => '13800002022',
                'email' => 'amy@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.3.22',
                'last_login_time' => $this->dt(-1, '22:05:00'),
                'register_platform_id' => 2,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-18, '08:45:00'),
                'update_time' => $this->dt(-1, '22:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => self::MEMBER_PATIENT_JAY,
                'username' => 'night_shift_jay',
                'nickname' => '夜班Jay',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Night%20Shift%20Jay',
                'mobile' => '13800002023',
                'email' => 'jay@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.3.23',
                'last_login_time' => $this->dt(0, '07:35:00'),
                'register_platform_id' => 2,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-15, '14:15:00'),
                'update_time' => $this->dt(0, '07:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => self::MEMBER_PATIENT_LUNA,
                'username' => 'luna_mom',
                'nickname' => 'Luna妈妈',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Luna%20Mom',
                'mobile' => '13800002024',
                'email' => 'luna@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.3.24',
                'last_login_time' => $this->dt(-1, '20:15:00'),
                'register_platform_id' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-12, '11:20:00'),
                'update_time' => $this->dt(-1, '20:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => self::MEMBER_PATIENT_NOAH,
                'username' => 'noah_reset',
                'nickname' => 'Noah Reset',
                'avatar' => 'https://api.dicebear.com/9.x/initials/svg?seed=Noah%20Reset',
                'mobile' => '13800002025',
                'email' => 'noah@helpsupport.test',
                'member_level_id' => 1,
                'points_balance' => 0,
                'last_login_ip' => '10.10.3.25',
                'last_login_time' => $this->dt(-2, '16:10:00'),
                'register_platform_id' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:member',
                'create_time' => $this->dt(-10, '16:00:00'),
                'update_time' => $this->dt(-2, '16:10:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($members as $member) {
            $this->insertIfMissing('sa_member', $member, '`id` = ' . (int) $member['id']);
        }
    }

    private function seedMemberProfiles(): void
    {
        $profiles = [
            [
                'id' => 9301,
                'member_id' => self::MEMBER_DOCTOR_LIN,
                'member_role' => 'doctor',
                'gender' => 2,
                'birthday' => '1987-04-15',
                'bio' => '擅长睡眠重建、术后恢复期的生活方式支持和复诊沟通。',
                'recovery_goal' => '帮助患者建立稳定可执行的康复节律。',
                'trigger_tags' => $this->json(['睡眠片段化', '复诊焦虑', '晚间反刍']),
                'locale' => 'zh-CN',
                'timezone' => 'Asia/Shanghai',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-40, '09:20:00'),
                'update_time' => $this->dt(-1, '21:25:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9302,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'member_role' => 'doctor',
                'gender' => 1,
                'birthday' => '1985-09-02',
                'bio' => '聚焦情绪波动、夜班作息和复诊前问题梳理。',
                'recovery_goal' => '把复杂感受拆解成可追踪、可沟通的线索。',
                'trigger_tags' => $this->json(['夜班疲劳', '压力峰值', '沟通准备']),
                'locale' => 'zh-CN',
                'timezone' => 'Asia/Shanghai',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-32, '10:05:00'),
                'update_time' => $this->dt(-2, '18:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9303,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'member_role' => 'patient',
                'gender' => 2,
                'birthday' => '1994-08-19',
                'bio' => '正在做产后睡眠修复，希望把夜间碎片化睡眠拉回到可控范围。',
                'recovery_goal' => '连续两周把总睡眠时长稳定到 6 小时以上。',
                'trigger_tags' => $this->json(['夜间频繁醒来', '照顾宝宝后难以再入睡', '午后情绪下降']),
                'locale' => 'zh-CN',
                'timezone' => 'Asia/Shanghai',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-18, '08:50:00'),
                'update_time' => $this->dt(-1, '22:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9304,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'member_role' => 'patient',
                'gender' => 1,
                'birthday' => '1991-01-07',
                'bio' => '夜班后总是白天补觉失败，想重新建立休息和运动节律。',
                'recovery_goal' => '减少夜班后的焦躁感，恢复白天补觉质量。',
                'trigger_tags' => $this->json(['夜班轮转', '咖啡依赖', '下班后情绪空档']),
                'locale' => 'zh-CN',
                'timezone' => 'Asia/Shanghai',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-15, '14:20:00'),
                'update_time' => $this->dt(0, '07:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9305,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'member_role' => 'patient',
                'gender' => 2,
                'birthday' => '1996-02-22',
                'bio' => 'Trying to balance newborn care, fragmented sleep and family support routines.',
                'recovery_goal' => 'Build one dependable bedtime reset routine every evening.',
                'trigger_tags' => $this->json(['newborn care', 'fragmented sleep', 'family communication']),
                'locale' => 'en-US',
                'timezone' => 'America/Los_Angeles',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-12, '11:25:00'),
                'update_time' => $this->dt(-1, '20:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9306,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'member_role' => 'patient',
                'gender' => 1,
                'birthday' => '1989-11-03',
                'bio' => 'Preparing for follow-up visits and trying to organize symptom notes in English.',
                'recovery_goal' => 'Turn scattered notes into weekly summaries before each appointment.',
                'trigger_tags' => $this->json(['appointment prep', 'symptom tracking', 'language switching']),
                'locale' => 'en-US',
                'timezone' => 'America/New_York',
                'onboarding_version' => 'v2',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-10, '16:05:00'),
                'update_time' => $this->dt(-2, '16:15:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($profiles as $profile) {
            $this->insertIfMissing('sa_help_member_profile', $profile, '`member_id` = ' . (int) $profile['member_id']);
        }
    }

    private function seedDoctorProfiles(): void
    {
        $profiles = [
            [
                'id' => 9311,
                'member_id' => self::MEMBER_DOCTOR_LIN,
                'real_name' => '林清岚',
                'title' => '副主任医师',
                'hospital' => '海城睡眠与康复中心',
                'department' => '睡眠医学门诊',
                'specialty' => '睡眠节律重建、轻中度焦虑伴失眠、术后作息恢复',
                'license_no' => 'DOC-LIN-2026-2001',
                'certification_images' => $this->json([
                    'https://picsum.photos/seed/doctor-lin-cert-1/1200/900',
                    'https://picsum.photos/seed/doctor-lin-cert-2/1200/900',
                ]),
                'audit_status' => 1,
                'audit_remark' => '演示医生资料已审核通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-20, '10:10:00'),
                'approved_time' => $this->dt(-20, '10:10:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-24, '15:10:00'),
                'update_time' => $this->dt(-20, '10:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9312,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'real_name' => '陈川',
                'title' => '主治医师',
                'hospital' => '青禾身心支持门诊',
                'department' => '康复心理协作门诊',
                'specialty' => '夜班作息调整、复诊前沟通训练、阶段性情绪支持',
                'license_no' => 'DOC-CHEN-2026-2002',
                'certification_images' => $this->json([
                    'https://picsum.photos/seed/doctor-chen-cert-1/1200/900',
                ]),
                'audit_status' => 1,
                'audit_remark' => '演示医生资料已审核通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-18, '11:20:00'),
                'approved_time' => $this->dt(-18, '11:20:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-22, '13:00:00'),
                'update_time' => $this->dt(-18, '11:20:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($profiles as $profile) {
            $this->insertIfMissing('sa_help_doctor_profile', $profile, '`member_id` = ' . (int) $profile['member_id']);
        }
    }

    private function seedPushPreferences(): void
    {
        $rows = [
            [
                'id' => 9251,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'is_push_enabled' => 1,
                'is_task_reminder_enabled' => 1,
                'is_community_enabled' => 1,
                'is_appointment_enabled' => 1,
                'is_audit_notice_enabled' => 1,
                'is_local_companion_enabled' => 1,
                'quiet_start_time' => '22:30:00',
                'quiet_end_time' => '07:00:00',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-18, '08:55:00'),
                'update_time' => $this->dt(-1, '22:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9252,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'is_push_enabled' => 1,
                'is_task_reminder_enabled' => 1,
                'is_community_enabled' => 2,
                'is_appointment_enabled' => 1,
                'is_audit_notice_enabled' => 1,
                'is_local_companion_enabled' => 1,
                'quiet_start_time' => '00:30:00',
                'quiet_end_time' => '08:30:00',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-15, '14:25:00'),
                'update_time' => $this->dt(0, '07:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9253,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'is_push_enabled' => 1,
                'is_task_reminder_enabled' => 1,
                'is_community_enabled' => 1,
                'is_appointment_enabled' => 2,
                'is_audit_notice_enabled' => 1,
                'is_local_companion_enabled' => 1,
                'quiet_start_time' => '21:30:00',
                'quiet_end_time' => '06:30:00',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-12, '11:30:00'),
                'update_time' => $this->dt(-1, '20:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9254,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'is_push_enabled' => 1,
                'is_task_reminder_enabled' => 2,
                'is_community_enabled' => 1,
                'is_appointment_enabled' => 1,
                'is_audit_notice_enabled' => 1,
                'is_local_companion_enabled' => 2,
                'quiet_start_time' => null,
                'quiet_end_time' => null,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-10, '16:10:00'),
                'update_time' => $this->dt(-2, '16:15:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_push_preference', $row, '`member_id` = ' . (int) $row['member_id']);
        }
    }

    private function seedLoginLogs(): void
    {
        $rows = [
            [
                'id' => 9241,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'platform_id' => 2,
                'login_type' => 1,
                'login_ip' => '10.10.3.22',
                'login_location' => '上海',
                'user_agent' => 'uni-app iOS Demo Device',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(-2, '22:20:00'),
                'update_time' => $this->dt(-2, '22:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9242,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'platform_id' => 2,
                'login_type' => 1,
                'login_ip' => '10.10.3.22',
                'login_location' => '上海',
                'user_agent' => 'uni-app iOS Demo Device',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(-1, '22:05:00'),
                'update_time' => $this->dt(-1, '22:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9243,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'platform_id' => 2,
                'login_type' => 1,
                'login_ip' => '10.10.3.23',
                'login_location' => '杭州',
                'user_agent' => 'uni-app Android Demo Device',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(-1, '07:55:00'),
                'update_time' => $this->dt(-1, '07:55:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9244,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'platform_id' => 2,
                'login_type' => 1,
                'login_ip' => '10.10.3.23',
                'login_location' => '杭州',
                'user_agent' => 'uni-app Android Demo Device',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(0, '07:35:00'),
                'update_time' => $this->dt(0, '07:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9245,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'platform_id' => 1,
                'login_type' => 2,
                'login_ip' => '10.10.3.24',
                'login_location' => 'San Jose',
                'user_agent' => 'Flutter iPhone 16 Pro Simulator',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(-1, '20:15:00'),
                'update_time' => $this->dt(-1, '20:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9246,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'platform_id' => 1,
                'login_type' => 2,
                'login_ip' => '10.10.3.25',
                'login_location' => 'New York',
                'user_agent' => 'Flutter iPhone 16 Pro Simulator',
                'login_result' => 1,
                'fail_reason' => null,
                'create_time' => $this->dt(-2, '16:10:00'),
                'update_time' => $this->dt(-2, '16:10:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_login_log', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedDoctorSchedules(): void
    {
        $rows = [
            [
                'id' => 8101,
                'doctor_id' => self::EXISTING_DEMO_DOCTOR_ID,
                'schedule_date' => $this->d(4),
                'time_slot' => '19:00-19:30',
                'start_time' => '19:00:00',
                'end_time' => '19:30:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/doctor-demo-evening',
                'price' => 0.00,
                'currency' => 'USD',
                'capacity' => 2,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:05:00'),
                'update_time' => $this->dt(0, '09:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8102,
                'doctor_id' => self::EXISTING_DEMO_DOCTOR_ID,
                'schedule_date' => $this->d(5),
                'time_slot' => '09:00-09:30',
                'start_time' => '09:00:00',
                'end_time' => '09:30:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/doctor-demo-morning',
                'price' => 0.00,
                'currency' => 'USD',
                'capacity' => 1,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:06:00'),
                'update_time' => $this->dt(0, '09:06:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8103,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'schedule_date' => $this->d(3),
                'time_slot' => '10:00-10:30',
                'start_time' => '10:00:00',
                'end_time' => '10:30:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/lin-morning-1',
                'price' => 19.90,
                'currency' => 'USD',
                'capacity' => 2,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:07:00'),
                'update_time' => $this->dt(0, '09:07:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8104,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'schedule_date' => $this->d(3),
                'time_slot' => '10:30-11:00',
                'start_time' => '10:30:00',
                'end_time' => '11:00:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/lin-morning-2',
                'price' => 19.90,
                'currency' => 'USD',
                'capacity' => 2,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:08:00'),
                'update_time' => $this->dt(0, '09:08:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8105,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'schedule_date' => $this->d(6),
                'time_slot' => '19:30-20:00',
                'start_time' => '19:30:00',
                'end_time' => '20:00:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/lin-evening',
                'price' => 29.90,
                'currency' => 'USD',
                'capacity' => 1,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:09:00'),
                'update_time' => $this->dt(0, '09:09:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8106,
                'doctor_id' => self::MEMBER_DOCTOR_CHEN,
                'schedule_date' => $this->d(4),
                'time_slot' => '14:00-14:30',
                'start_time' => '14:00:00',
                'end_time' => '14:30:00',
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/chen-afternoon',
                'price' => 15.00,
                'currency' => 'USD',
                'capacity' => 1,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:10:00'),
                'update_time' => $this->dt(0, '09:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8107,
                'doctor_id' => self::MEMBER_DOCTOR_CHEN,
                'schedule_date' => $this->d(7),
                'time_slot' => '08:30-09:00',
                'start_time' => '08:30:00',
                'end_time' => '09:00:00',
                'meet_type' => 'phone',
                'meet_link' => '+1-202-555-0109',
                'price' => 12.50,
                'currency' => 'USD',
                'capacity' => 1,
                'booked_count' => 0,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:schedule',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:11:00'),
                'update_time' => $this->dt(0, '09:11:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_doctor_schedule', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedDoctorAppointments(): void
    {
        $rows = [
            [
                'id' => 8201,
                'member_id' => self::MAIN_PATIENT_ID,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'schedule_id' => 8103,
                'appoint_date' => $this->d(3),
                'appoint_time_slot' => '10:00-10:30',
                'price' => 19.90,
                'currency' => 'USD',
                'status' => 0,
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/lin-morning-1',
                'confirm_remark' => null,
                'remark' => 'demo:help-comprehensive:初次复诊前沟通',
                'cancel_reason' => null,
                'cancel_by' => null,
                'confirmed_at' => null,
                'finished_at' => null,
                'canceled_at' => null,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:20:00'),
                'update_time' => $this->dt(0, '09:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8202,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'doctor_id' => self::MEMBER_DOCTOR_CHEN,
                'schedule_id' => 8106,
                'appoint_date' => $this->d(4),
                'appoint_time_slot' => '14:00-14:30',
                'price' => 15.00,
                'currency' => 'USD',
                'status' => 2,
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/chen-afternoon',
                'confirm_remark' => '已经确认，建议提前整理一周睡眠时段。',
                'remark' => 'demo:help-comprehensive:产后睡眠回访',
                'cancel_reason' => null,
                'cancel_by' => null,
                'confirmed_at' => $this->dt(1, '12:00:00'),
                'finished_at' => $this->dt(4, '14:40:00'),
                'canceled_at' => null,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '11:35:00'),
                'update_time' => $this->dt(4, '14:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8203,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'schedule_id' => 8105,
                'appoint_date' => $this->d(6),
                'appoint_time_slot' => '19:30-20:00',
                'price' => 29.90,
                'currency' => 'USD',
                'status' => 3,
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/lin-evening',
                'confirm_remark' => null,
                'remark' => 'demo:help-comprehensive:夜班后恢复咨询',
                'cancel_reason' => '临时加班，改约下周。',
                'cancel_by' => 'member',
                'confirmed_at' => null,
                'finished_at' => null,
                'canceled_at' => $this->dt(5, '18:20:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:25:00'),
                'update_time' => $this->dt(5, '18:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8204,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'doctor_id' => self::EXISTING_DEMO_DOCTOR_ID,
                'schedule_id' => 8102,
                'appoint_date' => $this->d(5),
                'appoint_time_slot' => '09:00-09:30',
                'price' => 0.00,
                'currency' => 'USD',
                'status' => 1,
                'meet_type' => 'link',
                'meet_link' => 'https://meet.helpsupport.test/doctor-demo-morning',
                'confirm_remark' => '已预留英文沟通时段，请带上最近三天记录。',
                'remark' => 'demo:help-comprehensive:family support follow-up',
                'cancel_reason' => null,
                'cancel_by' => null,
                'confirmed_at' => $this->dt(1, '09:30:00'),
                'finished_at' => null,
                'canceled_at' => null,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:30:00'),
                'update_time' => $this->dt(1, '09:30:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_doctor_appointment', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedDoctorPatientBindings(): void
    {
        $rows = [
            [
                'id' => 9231,
                'doctor_id' => self::EXISTING_DEMO_DOCTOR_ID,
                'member_id' => self::MAIN_PATIENT_ID,
                'status' => 1,
                'bind_source' => 'appointment',
                'bind_time' => $this->dt(-2, '20:00:00'),
                'unbind_time' => null,
                'remark' => 'demo:help-comprehensive:existing-follow-up',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '20:00:00'),
                'update_time' => $this->dt(-2, '20:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9232,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'member_id' => self::MAIN_PATIENT_ID,
                'status' => 1,
                'bind_source' => 'manual',
                'bind_time' => $this->dt(0, '09:40:00'),
                'unbind_time' => null,
                'remark' => 'demo:help-comprehensive:plan-follow',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:40:00'),
                'update_time' => $this->dt(0, '09:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9233,
                'doctor_id' => self::MEMBER_DOCTOR_CHEN,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'status' => 1,
                'bind_source' => 'appointment',
                'bind_time' => $this->dt(1, '11:35:00'),
                'unbind_time' => null,
                'remark' => 'demo:help-comprehensive:postpartum-support',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '11:35:00'),
                'update_time' => $this->dt(1, '11:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9234,
                'doctor_id' => self::EXISTING_DEMO_DOCTOR_ID,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'status' => 1,
                'bind_source' => 'appointment',
                'bind_time' => $this->dt(1, '09:30:00'),
                'unbind_time' => null,
                'remark' => 'demo:help-comprehensive:english-follow-up',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '09:30:00'),
                'update_time' => $this->dt(1, '09:30:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_doctor_patient',
                $row,
                '`doctor_id` = ' . (int) $row['doctor_id'] . ' AND `member_id` = ' . (int) $row['member_id']
            );
        }
    }

    private function seedTreatmentPlans(): void
    {
        $rows = [
            [
                'id' => 8301,
                'member_id' => self::MAIN_PATIENT_ID,
                'doctor_id' => self::MEMBER_DOCTOR_LIN,
                'title' => '21 天情绪与作息协同计划',
                'description' => '围绕晚间降噪、晨间重启和复诊前线索整理，连续三周观察睡眠与情绪的联动。',
                'start_date' => $this->d(-3),
                'end_date' => $this->d(18),
                'source_type' => 'manual',
                'status' => 1,
                'remark' => 'demo:help-comprehensive:plan',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '08:30:00'),
                'update_time' => $this->dt(0, '10:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8302,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'doctor_id' => self::MEMBER_DOCTOR_CHEN,
                'title' => '14 天产后睡眠修复计划',
                'description' => '通过白天补觉窗口、晚间交接和焦虑高峰应对，降低夜间碎片化睡眠的负担。',
                'start_date' => $this->d(-1),
                'end_date' => $this->d(13),
                'source_type' => 'manual',
                'status' => 1,
                'remark' => 'demo:help-comprehensive:plan',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:15:00'),
                'update_time' => $this->dt(0, '10:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8303,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'doctor_id' => 0,
                'title' => '夜班后恢复节律计划',
                'description' => '从夜班后补觉、咖啡截止时间和下班后情绪缓冲三个切口，试着把恢复节律拉回稳定区间。',
                'start_date' => $this->d(0),
                'end_date' => $this->d(10),
                'source_type' => 'ai',
                'status' => 1,
                'remark' => 'demo:help-comprehensive:plan',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '08:10:00'),
                'update_time' => $this->dt(0, '10:10:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_treatment_plan', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedTreatmentStages(): void
    {
        $rows = [
            [
                'id' => 8311,
                'plan_id' => 8301,
                'member_id' => self::MAIN_PATIENT_ID,
                'stage_key' => 'evening_reset',
                'stage_name' => '晚间降噪与入睡准备',
                'start_date' => $this->d(-3),
                'end_date' => $this->d(3),
                'stage_target' => '连续 7 天把睡前 30 分钟改造成低刺激时段。',
                'sort' => 10,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '08:35:00'),
                'update_time' => $this->dt(0, '10:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8312,
                'plan_id' => 8301,
                'member_id' => self::MAIN_PATIENT_ID,
                'stage_key' => 'morning_anchor',
                'stage_name' => '晨间重启与白天稳定',
                'start_date' => $this->d(4),
                'end_date' => $this->d(10),
                'stage_target' => '固定晨起光照与轻活动，让白天困意不过度堆积。',
                'sort' => 20,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '08:36:00'),
                'update_time' => $this->dt(0, '10:16:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8313,
                'plan_id' => 8301,
                'member_id' => self::MAIN_PATIENT_ID,
                'stage_key' => 'followup_brief',
                'stage_name' => '复诊沟通与线索整理',
                'start_date' => $this->d(11),
                'end_date' => $this->d(18),
                'stage_target' => '把一周内最重要的变化浓缩成可沟通的 3 个线索。',
                'sort' => 30,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '08:37:00'),
                'update_time' => $this->dt(0, '10:17:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8314,
                'plan_id' => 8302,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'stage_key' => 'safe_rest',
                'stage_name' => '安全休息窗口',
                'start_date' => $this->d(-1),
                'end_date' => $this->d(5),
                'stage_target' => '每天至少争取一次 25 分钟的稳定补觉窗口。',
                'sort' => 10,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:20:00'),
                'update_time' => $this->dt(0, '10:18:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8315,
                'plan_id' => 8302,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'stage_key' => 'micro_routine',
                'stage_name' => '微型晚间例行程序',
                'start_date' => $this->d(6),
                'end_date' => $this->d(13),
                'stage_target' => '用 10 分钟例行程序降低再入睡时的紧张感。',
                'sort' => 20,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:21:00'),
                'update_time' => $this->dt(0, '10:19:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8316,
                'plan_id' => 8303,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'stage_key' => 'shift_buffer',
                'stage_name' => '夜班后缓冲段',
                'start_date' => $this->d(0),
                'end_date' => $this->d(5),
                'stage_target' => '下班后 90 分钟内不再追加咖啡因并完成降速动作。',
                'sort' => 10,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '08:15:00'),
                'update_time' => $this->dt(0, '10:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8317,
                'plan_id' => 8303,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'stage_key' => 'offday_reset',
                'stage_name' => '休息日回正',
                'start_date' => $this->d(6),
                'end_date' => $this->d(10),
                'stage_target' => '休息日不把起床时间推迟超过 90 分钟。',
                'sort' => 20,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:stage',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '08:16:00'),
                'update_time' => $this->dt(0, '10:21:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_treatment_stage', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedDailyTasks(): void
    {
        $rows = [
            [
                'id' => 8331,
                'member_id' => self::MAIN_PATIENT_ID,
                'plan_id' => 8301,
                'stage_id' => 8311,
                'task_date' => $this->d(-1),
                'start_time' => '21:30:00',
                'end_time' => '21:45:00',
                'title' => '把卧室灯光切换到暖色低亮度',
                'description' => '睡前 30 分钟只保留一个暖色光源，避免继续刷强刺激内容。',
                'task_type' => 'daily',
                'source' => 'timeline',
                'source_id' => 'demo-evening-light',
                'reminders' => $this->json([['type' => 'push', 'time' => '21:20']]),
                'attachments' => $this->json([]),
                'points_reward' => 10,
                'completed_time' => $this->dt(-1, '21:43:00'),
                'completion_note' => '完成了，入睡前心跳没那么快。',
                'status' => 1,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '18:00:00'),
                'update_time' => $this->dt(-1, '21:43:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8332,
                'member_id' => self::MAIN_PATIENT_ID,
                'plan_id' => 8301,
                'stage_id' => 8311,
                'task_date' => $this->d(0),
                'start_time' => '22:00:00',
                'end_time' => '22:12:00',
                'title' => '完成 12 分钟身体扫描音频',
                'description' => '跟着音频做一轮扫描，重点观察肩颈和胸口紧绷感。',
                'task_type' => 'material',
                'source' => 'template',
                'source_id' => 'material-8912',
                'reminders' => $this->json([['type' => 'push', 'time' => '21:50']]),
                'attachments' => $this->json(['material_id' => 8912]),
                'points_reward' => 15,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '22:00:00'),
                'update_time' => $this->dt(0, '10:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8333,
                'member_id' => self::MAIN_PATIENT_ID,
                'plan_id' => 8301,
                'stage_id' => 8311,
                'task_date' => $this->d(1),
                'start_time' => '07:40:00',
                'end_time' => '07:55:00',
                'title' => '晨起光照 15 分钟',
                'description' => '起床后尽快到窗边或室外，让大脑收到白天开始的信号。',
                'task_type' => 'daily',
                'source' => 'timeline',
                'source_id' => 'demo-morning-light',
                'reminders' => $this->json([['type' => 'push', 'time' => '07:30']]),
                'attachments' => $this->json([]),
                'points_reward' => 10,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:31:00'),
                'update_time' => $this->dt(0, '10:31:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8334,
                'member_id' => self::MAIN_PATIENT_ID,
                'plan_id' => 8301,
                'stage_id' => 8312,
                'task_date' => $this->d(4),
                'start_time' => '12:30:00',
                'end_time' => '12:40:00',
                'title' => '午后困意记录',
                'description' => '记录困意、脑雾和咖啡摄入时间，为下一次复诊做线索。',
                'task_type' => 'assessment',
                'source' => 'manual',
                'source_id' => 'demo-midday-check',
                'reminders' => $this->json([['type' => 'push', 'time' => '12:20']]),
                'attachments' => $this->json([]),
                'points_reward' => 8,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:32:00'),
                'update_time' => $this->dt(0, '10:32:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8335,
                'member_id' => self::MAIN_PATIENT_ID,
                'plan_id' => 8301,
                'stage_id' => 8313,
                'task_date' => $this->d(11),
                'start_time' => '20:30:00',
                'end_time' => '20:50:00',
                'title' => '复诊前整理三条重点线索',
                'description' => '写下过去一周最重要的触发点、恢复动作和还没解决的问题。',
                'task_type' => 'checkin',
                'source' => 'manual',
                'source_id' => 'demo-followup-brief',
                'reminders' => $this->json([['type' => 'push', 'time' => '20:00']]),
                'attachments' => $this->json([]),
                'points_reward' => 20,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:33:00'),
                'update_time' => $this->dt(0, '10:33:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8336,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'plan_id' => 8302,
                'stage_id' => 8314,
                'task_date' => $this->d(0),
                'start_time' => '13:00:00',
                'end_time' => '13:25:00',
                'title' => '争取一次 25 分钟稳定补觉',
                'description' => '让家人接手 25 分钟照护，给自己留一段完整休息窗口。',
                'task_type' => 'daily',
                'source' => 'timeline',
                'source_id' => 'demo-postpartum-rest',
                'reminders' => $this->json([['type' => 'push', 'time' => '12:40']]),
                'attachments' => $this->json([]),
                'points_reward' => 15,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:30:00'),
                'update_time' => $this->dt(0, '10:34:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8337,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'plan_id' => 8302,
                'stage_id' => 8314,
                'task_date' => $this->d(1),
                'start_time' => '21:10:00',
                'end_time' => '21:20:00',
                'title' => '写下今晚最想放过自己的一个念头',
                'description' => '不用解决全部问题，只把今晚最消耗的一句话写出来。',
                'task_type' => 'checkin',
                'source' => 'manual',
                'source_id' => 'demo-self-kindness',
                'reminders' => $this->json([['type' => 'push', 'time' => '21:00']]),
                'attachments' => $this->json([]),
                'points_reward' => 12,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:31:00'),
                'update_time' => $this->dt(0, '10:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8338,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'plan_id' => 8302,
                'stage_id' => 8315,
                'task_date' => $this->d(6),
                'start_time' => '21:30:00',
                'end_time' => '21:40:00',
                'title' => '完成 10 分钟地面化练习',
                'description' => '跟着音频把注意力带回触感、呼吸和周围空间。',
                'task_type' => 'material',
                'source' => 'template',
                'source_id' => 'material-8918',
                'reminders' => $this->json([['type' => 'push', 'time' => '21:20']]),
                'attachments' => $this->json(['material_id' => 8918]),
                'points_reward' => 10,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '09:32:00'),
                'update_time' => $this->dt(0, '10:36:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8339,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'plan_id' => 8303,
                'stage_id' => 8316,
                'task_date' => $this->d(0),
                'start_time' => '08:20:00',
                'end_time' => '08:30:00',
                'title' => '下班后 10 分钟慢走降速',
                'description' => '不要马上刷手机，先给身体一个降速过渡区。',
                'task_type' => 'daily',
                'source' => 'timeline',
                'source_id' => 'demo-shift-walk',
                'reminders' => $this->json([['type' => 'push', 'time' => '08:10']]),
                'attachments' => $this->json([]),
                'points_reward' => 10,
                'completed_time' => $this->dt(0, '08:31:00'),
                'completion_note' => '完成，回家后没直接瘫在床上。',
                'status' => 1,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '08:00:00'),
                'update_time' => $this->dt(0, '08:31:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8340,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'plan_id' => 8303,
                'stage_id' => 8316,
                'task_date' => $this->d(1),
                'start_time' => '09:00:00',
                'end_time' => '09:05:00',
                'title' => '记录最后一杯咖啡时间',
                'description' => '确认是否在计划中的截止时间前结束咖啡因摄入。',
                'task_type' => 'assessment',
                'source' => 'manual',
                'source_id' => 'demo-last-coffee',
                'reminders' => $this->json([['type' => 'push', 'time' => '08:50']]),
                'attachments' => $this->json([]),
                'points_reward' => 6,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:37:00'),
                'update_time' => $this->dt(0, '10:37:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8341,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'plan_id' => 8303,
                'stage_id' => 8317,
                'task_date' => $this->d(6),
                'start_time' => '11:00:00',
                'end_time' => '11:15:00',
                'title' => '休息日把起床时间控制在 90 分钟内',
                'description' => '避免休息日和上班日时差继续扩大。',
                'task_type' => 'daily',
                'source' => 'manual',
                'source_id' => 'demo-offday-wake',
                'reminders' => $this->json([['type' => 'push', 'time' => '10:40']]),
                'attachments' => $this->json([]),
                'points_reward' => 12,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:38:00'),
                'update_time' => $this->dt(0, '10:38:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8342,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'plan_id' => 0,
                'stage_id' => 0,
                'task_date' => $this->d(2),
                'start_time' => '20:40:00',
                'end_time' => '20:50:00',
                'title' => 'Write three family support boundaries',
                'description' => 'List three short phrases you can reuse when asking for help at night.',
                'task_type' => 'checkin',
                'source' => 'manual',
                'source_id' => 'demo-family-boundary',
                'reminders' => $this->json([['type' => 'push', 'time' => '20:30']]),
                'attachments' => $this->json([]),
                'points_reward' => 8,
                'completed_time' => null,
                'completion_note' => null,
                'status' => 0,
                'remark' => 'demo:help-comprehensive:task',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:39:00'),
                'update_time' => $this->dt(0, '10:39:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_daily_task', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedMemberMessages(): void
    {
        $rows = [
            [
                'id' => 8401,
                'member_id' => self::MAIN_PATIENT_ID,
                'message_type' => 3,
                'title' => '今晚还有一个睡前任务',
                'content' => '你还有一项“身体扫描音频”待完成，建议在 22:00 前开始。',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '21:50:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'daily_task',
                'biz_id' => 8332,
                'route' => '/pages/plan/index',
                'ext' => $this->json(['task_id' => 8332]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '21:50:00'),
                'update_time' => $this->dt(0, '21:50:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8402,
                'member_id' => self::MAIN_PATIENT_ID,
                'message_type' => 4,
                'title' => '新的复诊时段待确认',
                'content' => '林清岚医生为你开放了 3 天后的沟通时段，是否前往确认？',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '09:25:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'appointment',
                'biz_id' => 8201,
                'route' => '/pages/doctor/appointments',
                'ext' => $this->json(['appointment_id' => 8201]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:25:00'),
                'update_time' => $this->dt(0, '09:25:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8403,
                'member_id' => self::MAIN_PATIENT_ID,
                'message_type' => 2,
                'title' => '你的社区帖子收到了医生回复',
                'content' => '陈川医生建议你把最明显的触发点记录成固定模板，方便复诊前复盘。',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '15:10:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'community_comment',
                'biz_id' => 9031,
                'route' => '/pages/community/index',
                'ext' => $this->json(['post_id' => 9021, 'comment_id' => 9031]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '15:10:00'),
                'update_time' => $this->dt(0, '15:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8404,
                'member_id' => self::MAIN_PATIENT_ID,
                'message_type' => 5,
                'title' => '本周回顾素材已准备好',
                'content' => '系统已为你整理好复诊提问清单和情绪记录模版，可直接查看。',
                'device_token' => null,
                'is_pushed' => 2,
                'push_status' => 0,
                'push_time' => null,
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'system_material',
                'biz_id' => 8914,
                'route' => '/pages/materials/index',
                'ext' => $this->json(['material_id' => 8914]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '17:40:00'),
                'update_time' => $this->dt(0, '17:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8405,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'message_type' => 4,
                'title' => '医生回访已完成',
                'content' => '陈川医生建议你把“能补觉的窗口”放到每天同一时段尝试。',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(4, '14:45:00'),
                'is_read' => 1,
                'read_time' => $this->dt(4, '15:00:00'),
                'biz_type' => 'appointment',
                'biz_id' => 8202,
                'route' => '/pages/doctor/appointments',
                'ext' => $this->json(['appointment_id' => 8202]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(4, '14:45:00'),
                'update_time' => $this->dt(4, '15:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8406,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'message_type' => 3,
                'title' => '今天有一项补觉任务待完成',
                'content' => '午后 25 分钟稳定补觉任务还未开始，完成后可获得 15 积分。',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '12:40:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'daily_task',
                'biz_id' => 8336,
                'route' => '/pages/plan/index',
                'ext' => $this->json(['task_id' => 8336]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '12:40:00'),
                'update_time' => $this->dt(0, '12:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8407,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'message_type' => 5,
                'title' => '夜班后恢复计划已更新',
                'content' => 'AI 根据你今天的完成情况，把下一次起床提醒调整到了更稳妥的时间。',
                'device_token' => null,
                'is_pushed' => 2,
                'push_status' => 0,
                'push_time' => null,
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'treatment_plan',
                'biz_id' => 8303,
                'route' => '/pages/plan/index',
                'ext' => $this->json(['plan_id' => 8303]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:45:00'),
                'update_time' => $this->dt(0, '10:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8408,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'message_type' => 1,
                'title' => 'You have a new community follower',
                'content' => 'Amy恢复中 followed your family-support note and wants to see more of your updates.',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '18:10:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'community_follow',
                'biz_id' => 9062,
                'route' => '/pages/community/profile',
                'ext' => $this->json(['follow_member_id' => 9062]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '18:10:00'),
                'update_time' => $this->dt(0, '18:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8409,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'message_type' => 5,
                'title' => 'Your appointment prep kit is ready',
                'content' => 'A new follow-up checklist and symptom summary template has been added to your material library.',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(0, '13:05:00'),
                'is_read' => 2,
                'read_time' => null,
                'biz_type' => 'system_material',
                'biz_id' => 8917,
                'route' => '/pages/materials/index',
                'ext' => $this->json(['material_id' => 8917]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '13:05:00'),
                'update_time' => $this->dt(0, '13:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8410,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'message_type' => 4,
                'title' => '原预约已取消',
                'content' => '你已取消与林清岚医生的夜班后恢复咨询，系统已保留原计划记录。',
                'device_token' => null,
                'is_pushed' => 1,
                'push_status' => 1,
                'push_time' => $this->dt(5, '18:20:00'),
                'is_read' => 1,
                'read_time' => $this->dt(5, '18:30:00'),
                'biz_type' => 'appointment',
                'biz_id' => 8203,
                'route' => '/pages/doctor/appointments',
                'ext' => $this->json(['appointment_id' => 8203]),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:message',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(5, '18:20:00'),
                'update_time' => $this->dt(5, '18:30:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_message', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedPointLogs(): void
    {
        $rows = [
            [
                'id' => 8501,
                'member_id' => self::MAIN_PATIENT_ID,
                'points' => 15,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8331,
                'title' => '完成晚间降噪任务',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 60,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '21:45:00'),
                'update_time' => $this->dt(-1, '21:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8502,
                'member_id' => self::MAIN_PATIENT_ID,
                'points' => 20,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8333,
                'title' => '连续晨起打卡奖励',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 80,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '08:00:00'),
                'update_time' => $this->dt(1, '08:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8503,
                'member_id' => self::MAIN_PATIENT_ID,
                'points' => -10,
                'change_type' => 'expense',
                'source_type' => 'demo_seed',
                'source_id' => 8201,
                'title' => '预约复诊消耗积分抵扣',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 70,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:26:00'),
                'update_time' => $this->dt(0, '09:26:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8504,
                'member_id' => self::MAIN_PATIENT_ID,
                'points' => 30,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8301,
                'title' => '完成一周阶段回顾',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 100,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(4, '20:30:00'),
                'update_time' => $this->dt(4, '20:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8505,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'points' => 10,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8336,
                'title' => '完成稳定补觉窗口',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 10,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '13:30:00'),
                'update_time' => $this->dt(0, '13:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8506,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'points' => 20,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8202,
                'title' => '完成医生回访总结',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 30,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(4, '15:00:00'),
                'update_time' => $this->dt(4, '15:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8507,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'points' => 15,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8339,
                'title' => '完成夜班后缓冲任务',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 15,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '08:31:00'),
                'update_time' => $this->dt(0, '08:31:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8508,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'points' => 5,
                'change_type' => 'income',
                'source_type' => 'demo_seed',
                'source_id' => 8342,
                'title' => '完成家庭支持边界练习',
                'remark' => 'demo:help-comprehensive:points',
                'balance_after' => 5,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(2, '21:00:00'),
                'update_time' => $this->dt(2, '21:00:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_point_log', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedMemberBadges(): void
    {
        $rows = [
            [
                'id' => 8601,
                'member_id' => self::MAIN_PATIENT_ID,
                'rule_id' => 0,
                'badge_code' => 'demo_sleep_streak_7',
                'badge_name' => '七日节律坚持者',
                'source_type' => 'demo_seed',
                'source_id' => 8301,
                'award_time' => $this->dt(4, '20:35:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(4, '20:35:00'),
                'update_time' => $this->dt(4, '20:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8602,
                'member_id' => self::MAIN_PATIENT_ID,
                'rule_id' => 0,
                'badge_code' => 'demo_reflection_star',
                'badge_name' => '复盘星标用户',
                'source_type' => 'demo_seed',
                'source_id' => 8335,
                'award_time' => $this->dt(11, '21:00:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(11, '21:00:00'),
                'update_time' => $this->dt(11, '21:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8603,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'rule_id' => 0,
                'badge_code' => 'demo_newmom_resilience',
                'badge_name' => '韧性新手妈妈',
                'source_type' => 'demo_seed',
                'source_id' => 8302,
                'award_time' => $this->dt(6, '22:00:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(6, '22:00:00'),
                'update_time' => $this->dt(6, '22:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8604,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'rule_id' => 0,
                'badge_code' => 'demo_shift_keeper',
                'badge_name' => '夜班恢复坚持者',
                'source_type' => 'demo_seed',
                'source_id' => 8303,
                'award_time' => $this->dt(5, '10:00:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(5, '10:00:00'),
                'update_time' => $this->dt(5, '10:00:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_member_badge',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `badge_code` = ' . $this->q($row['badge_code']) . ' AND `delete_time` IS NULL'
            );
        }
    }

    private function seedMemberJournals(): void
    {
        $rows = [
            [
                'id' => 8701,
                'member_id' => self::MAIN_PATIENT_ID,
                'entry_date' => $this->d(0),
                'entry_time' => '21:48:00',
                'title' => '今晚情绪起伏比昨天小一点',
                'content' => '睡前还是会想工作，但把注意力拉回呼吸之后，胸口紧绷感没有持续太久。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '21:48:00'),
                'update_time' => $this->dt(0, '21:48:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8702,
                'member_id' => self::MAIN_PATIENT_ID,
                'entry_date' => $this->d(-1),
                'entry_time' => '22:05:00',
                'title' => '凌晨醒来后没有立刻抓手机',
                'content' => '中途醒来一次，但我先做了几轮呼吸，醒来的时间没有拉得很长。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '22:05:00'),
                'update_time' => $this->dt(-1, '22:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8703,
                'member_id' => self::MAIN_PATIENT_ID,
                'entry_date' => $this->d(-2),
                'entry_time' => '20:50:00',
                'title' => '午后困意最明显的时间是 14:30',
                'content' => '今天记录了咖啡时间和困意变化，发现午后脑雾和前一晚入睡时间有点相关。',
                'media' => $this->json([]),
                'mood_score' => 3,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '20:50:00'),
                'update_time' => $this->dt(-2, '20:50:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8704,
                'member_id' => self::MAIN_PATIENT_ID,
                'entry_date' => $this->d(-4),
                'entry_time' => '21:30:00',
                'title' => '准备把复诊问题按主题归类',
                'content' => '如果只说“睡不好”太模糊了，准备分成入睡、惊醒、白天困意三块描述。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-4, '21:30:00'),
                'update_time' => $this->dt(-4, '21:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8705,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'entry_date' => $this->d(-1),
                'entry_time' => '23:10:00',
                'title' => '今天争取到了 20 分钟完整安静时间',
                'content' => '虽然还是会中断，但终于不是一直绷着神经，感觉自己恢复了一点点。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '23:10:00'),
                'update_time' => $this->dt(-1, '23:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8706,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'entry_date' => $this->d(0),
                'entry_time' => '21:35:00',
                'title' => '最难的是一醒来就担心下一次什么时候又会醒',
                'content' => '医生说可以先记录“醒来后最先冒出的想法”，这样更容易找到固定触发点。',
                'media' => $this->json([]),
                'mood_score' => 3,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '21:35:00'),
                'update_time' => $this->dt(0, '21:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8707,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'entry_date' => $this->d(1),
                'entry_time' => '22:20:00',
                'title' => '今晚先放过没做完的家务',
                'content' => '我把“明天再处理”写在纸上，心里反而没有那么堵。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '22:20:00'),
                'update_time' => $this->dt(1, '22:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8708,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'entry_date' => $this->d(0),
                'entry_time' => '09:15:00',
                'title' => '夜班后最想逃的是回家路上那段空档',
                'content' => '只要一停下来就想继续刷短视频，今天先做了慢走，感觉没那么失控。',
                'media' => $this->json([]),
                'mood_score' => 3,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '09:15:00'),
                'update_time' => $this->dt(0, '09:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8709,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'entry_date' => $this->d(1),
                'entry_time' => '10:10:00',
                'title' => '咖啡喝太晚会让第二天更漂',
                'content' => '把最后一杯咖啡时间提早之后，虽然还困，但脑子没有昨天那么炸。',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(1, '10:10:00'),
                'update_time' => $this->dt(1, '10:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8710,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'entry_date' => $this->d(0),
                'entry_time' => '20:45:00',
                'title' => 'A small boundary worked tonight',
                'content' => 'I asked for one uninterrupted 15-minute break before bedtime, and the whole evening felt less chaotic.',
                'media' => $this->json([]),
                'mood_score' => 4,
                'is_private' => 1,
                'ai_access' => 1,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:journal',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:45:00'),
                'update_time' => $this->dt(0, '20:45:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_journal', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedMemoirConfigs(): void
    {
        $rows = [
            [
                'id' => 8801,
                'name' => '演示周回顾卡',
                'code' => 'demo_weekly_reframe',
                'generation_cycle' => 'weekly',
                'source_type' => 'journal',
                'prompt_template' => '请把本周日记整理成“做到了什么、最难的是什么、下周准备尝试什么”三段。',
                'min_journal_count' => 2,
                'start_day' => 1,
                'sort' => 20,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-5, '10:00:00'),
                'update_time' => $this->dt(-5, '10:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8802,
                'name' => '演示季度里程碑',
                'code' => 'demo_quarterly_milestone',
                'generation_cycle' => 'quarterly',
                'source_type' => 'journal',
                'prompt_template' => '请整理本季度最重要的康复里程碑、仍待解决的阻力和想继续保留的支持动作。',
                'min_journal_count' => 6,
                'start_day' => 1,
                'sort' => 30,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-5, '10:05:00'),
                'update_time' => $this->dt(-5, '10:05:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_memoir_config', $row, '`code` = ' . $this->q($row['code']) . ' AND `delete_time` IS NULL');
        }
    }

    private function seedMemberMemoirs(): void
    {
        $rows = [
            [
                'id' => 8811,
                'member_id' => self::MAIN_PATIENT_ID,
                'grant_level_id' => 1,
                'grant_level_rank' => 3,
                'grant_level_name' => '节律重建者',
                'title' => '第二周节律重建回顾',
                'description' => '把惊醒、午后困意和复诊前问题重新串起来后，节律感开始清晰。',
                'cover' => 'https://picsum.photos/seed/memoir-main-patient/1200/800',
                'video_url' => '',
                'source_month' => substr($this->d(0), 0, 7),
                'journal_count' => 4,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:memoir',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(5, '21:30:00'),
                'update_time' => $this->dt(5, '21:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8812,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'grant_level_id' => 1,
                'grant_level_rank' => 1,
                'grant_level_name' => '温柔坚持者',
                'title' => '第一周产后自我照顾',
                'description' => '最重要的变化不是睡得更久，而是终于开始给自己留出安静窗口。',
                'cover' => 'https://picsum.photos/seed/memoir-amy/1200/800',
                'video_url' => '',
                'source_month' => substr($this->d(0), 0, 7),
                'journal_count' => 3,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:memoir',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(6, '22:10:00'),
                'update_time' => $this->dt(6, '22:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8813,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'grant_level_id' => 1,
                'grant_level_rank' => 1,
                'grant_level_name' => '回正尝试者',
                'title' => '夜班后的第一段稳定期',
                'description' => '先稳住下班后那 90 分钟，比一口气改完整个作息更现实。',
                'cover' => 'https://picsum.photos/seed/memoir-jay/1200/800',
                'video_url' => '',
                'source_month' => substr($this->d(0), 0, 7),
                'journal_count' => 2,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:memoir',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(5, '10:10:00'),
                'update_time' => $this->dt(5, '10:10:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_member_memoir',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `grant_level_rank` = ' . (int) $row['grant_level_rank']
            );
        }
    }

    private function seedContentCategories(): void
    {
        $rows = [
            [
                'id' => 8901,
                'parent_id' => 0,
                'name' => '睡眠科学',
                'name_i18n' => $this->json(['zh-CN' => '睡眠科学', 'en-US' => 'Sleep Science']),
                'type' => 'education',
                'icon' => 'i-tabler-moon-stars',
                'sort' => 10,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:category',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '09:00:00'),
                'update_time' => $this->dt(-3, '09:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8902,
                'parent_id' => 0,
                'name' => '情绪调节',
                'name_i18n' => $this->json(['zh-CN' => '情绪调节', 'en-US' => 'Emotion Regulation']),
                'type' => 'education',
                'icon' => 'i-tabler-heart',
                'sort' => 20,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:category',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '09:01:00'),
                'update_time' => $this->dt(-3, '09:01:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8903,
                'parent_id' => 0,
                'name' => '医生沟通',
                'name_i18n' => $this->json(['zh-CN' => '医生沟通', 'en-US' => 'Doctor Communication']),
                'type' => 'education',
                'icon' => 'i-tabler-stethoscope',
                'sort' => 30,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:category',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '09:02:00'),
                'update_time' => $this->dt(-3, '09:02:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8904,
                'parent_id' => 0,
                'name' => '家庭支持',
                'name_i18n' => $this->json(['zh-CN' => '家庭支持', 'en-US' => 'Family Support']),
                'type' => 'education',
                'icon' => 'i-tabler-home-heart',
                'sort' => 40,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:category',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-3, '09:03:00'),
                'update_time' => $this->dt(-3, '09:03:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_content_category', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedContentMaterials(): void
    {
        $rows = [
            [
                'id' => 8911,
                'member_id' => 0,
                'category_id' => 8901,
                'media_type' => 'article',
                'material_type' => 'education',
                'title' => '睡前 5 分钟身体扫描',
                'title_i18n' => $this->json(['zh-CN' => '睡前 5 分钟身体扫描', 'en-US' => '5-minute Body Scan Before Bed']),
                'summary' => '一套适合睡前快速降噪的身体扫描步骤。',
                'cover_url' => 'https://picsum.photos/seed/material-8911/1200/800',
                'content_url' => '',
                'content_text' => '<p>把注意力从脚底一路带回头顶，不急着放松，只做观察。</p><p>当你发现又开始想事情，就轻轻回到身体感觉。</p>',
                'tags' => $this->json(['睡前练习', '身体扫描']),
                'duration_seconds' => 300,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 128,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:00:00'),
                'sort' => 10,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:00:00'),
                'update_time' => $this->dt(-2, '12:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8912,
                'member_id' => 0,
                'category_id' => 8902,
                'media_type' => 'audio',
                'material_type' => 'education',
                'title' => '惊醒后回到呼吸的 3 分钟音频',
                'title_i18n' => $this->json(['zh-CN' => '惊醒后回到呼吸的 3 分钟音频', 'en-US' => '3-minute Audio For Returning To Breath']),
                'summary' => '适合夜间醒来后快速降低警觉水平的短音频。',
                'cover_url' => 'https://picsum.photos/seed/material-8912/1200/800',
                'content_url' => 'https://cdn.helpsupport.test/demo/audio/return-to-breath.mp3',
                'content_text' => '<p>这段音频会带你把注意力放回呼吸和身体接触面。</p>',
                'tags' => $this->json(['呼吸', '夜间惊醒']),
                'duration_seconds' => 180,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 96,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:05:00'),
                'sort' => 20,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:05:00'),
                'update_time' => $this->dt(-2, '12:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8913,
                'member_id' => 0,
                'category_id' => 8901,
                'media_type' => 'video',
                'material_type' => 'education',
                'title' => '白天光照与午后困意管理',
                'title_i18n' => $this->json(['zh-CN' => '白天光照与午后困意管理', 'en-US' => 'Light Exposure And Afternoon Sleepiness']),
                'summary' => '解释为什么晨间光照会影响午后困意和入睡时间。',
                'cover_url' => 'https://picsum.photos/seed/material-8913/1200/800',
                'content_url' => 'https://cdn.helpsupport.test/demo/video/daylight-reset.mp4',
                'content_text' => '<p>内容包括晨间光照、午后困意、咖啡窗口三个关键点。</p>',
                'tags' => $this->json(['晨间光照', '困意管理']),
                'duration_seconds' => 420,
                'is_public' => 1,
                'is_recommended' => 2,
                'view_count' => 75,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:10:00'),
                'sort' => 30,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:10:00'),
                'update_time' => $this->dt(-2, '12:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8914,
                'member_id' => self::MEMBER_DOCTOR_LIN,
                'category_id' => 8903,
                'media_type' => 'pdf',
                'material_type' => 'education',
                'title' => '复诊提问清单模板',
                'title_i18n' => $this->json(['zh-CN' => '复诊提问清单模板', 'en-US' => 'Follow-up Question Checklist']),
                'summary' => '帮助你在复诊前用同一结构整理症状变化、疑问和目标。',
                'cover_url' => 'https://picsum.photos/seed/material-8914/1200/800',
                'content_url' => 'https://cdn.helpsupport.test/demo/pdf/follow-up-checklist.pdf',
                'content_text' => '<p>按“变化、触发点、想问医生的事”三栏填写。</p>',
                'tags' => $this->json(['复诊', '提问模板']),
                'duration_seconds' => 0,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 61,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:15:00'),
                'sort' => 40,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:15:00'),
                'update_time' => $this->dt(-2, '12:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8915,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'category_id' => 8901,
                'media_type' => 'article',
                'material_type' => 'education',
                'title' => '夜班人群如何安排补觉',
                'title_i18n' => $this->json(['zh-CN' => '夜班人群如何安排补觉', 'en-US' => 'Recovery Sleep For Shift Workers']),
                'summary' => '针对夜班后的补觉节律给出几个更可执行的窗口建议。',
                'cover_url' => 'https://picsum.photos/seed/material-8915/1200/800',
                'content_url' => '',
                'content_text' => '<p>核心不是“补够所有觉”，而是先保护最关键的恢复窗口。</p>',
                'tags' => $this->json(['夜班', '补觉']),
                'duration_seconds' => 0,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 54,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:20:00'),
                'sort' => 50,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:20:00'),
                'update_time' => $this->dt(-2, '12:20:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8916,
                'member_id' => 0,
                'category_id' => 8904,
                'media_type' => 'link',
                'material_type' => 'education',
                'title' => '产后支持资源目录',
                'title_i18n' => $this->json(['zh-CN' => '产后支持资源目录', 'en-US' => 'Postpartum Support Directory']),
                'summary' => '把睡眠、情绪、家属支持相关的外部帮助资源放到一个入口里。',
                'cover_url' => 'https://picsum.photos/seed/material-8916/1200/800',
                'content_url' => 'https://support.helpsupport.test/postpartum-directory',
                'content_text' => '<p>适合把家庭支持、情绪支持和热线资源统一收藏。</p>',
                'tags' => $this->json(['产后支持', '家属资源']),
                'duration_seconds' => 0,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 43,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:25:00'),
                'sort' => 60,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:25:00'),
                'update_time' => $this->dt(-2, '12:25:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8917,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'category_id' => 8903,
                'media_type' => 'article',
                'material_type' => 'education',
                'title' => '如何向医生描述一周内的睡眠变化',
                'title_i18n' => $this->json(['zh-CN' => '如何向医生描述一周内的睡眠变化', 'en-US' => 'How To Describe A Week Of Sleep Changes']),
                'summary' => '用 3 个问题把散乱感受整理成医生能快速抓住的线索。',
                'cover_url' => 'https://picsum.photos/seed/material-8917/1200/800',
                'content_url' => '',
                'content_text' => '<p>建议从“最明显的变化、最稳定的触发点、最想知道的问题”三个角度来写。</p>',
                'tags' => $this->json(['复诊', '睡眠记录']),
                'duration_seconds' => 0,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 68,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:30:00'),
                'sort' => 70,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:30:00'),
                'update_time' => $this->dt(-2, '12:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8918,
                'member_id' => 0,
                'category_id' => 8902,
                'media_type' => 'audio',
                'material_type' => 'education',
                'title' => '焦虑高峰时的地面化练习',
                'title_i18n' => $this->json(['zh-CN' => '焦虑高峰时的地面化练习', 'en-US' => 'Grounding Practice For Anxiety Peaks']),
                'summary' => '把注意力从脑内反复转回到五感和当下环境。',
                'cover_url' => 'https://picsum.photos/seed/material-8918/1200/800',
                'content_url' => 'https://cdn.helpsupport.test/demo/audio/grounding-practice.mp3',
                'content_text' => '<p>适合在情绪开始往上冲的时候立刻使用，帮助身体先降一点速。</p>',
                'tags' => $this->json(['地面化', '焦虑']),
                'duration_seconds' => 240,
                'is_public' => 1,
                'is_recommended' => 1,
                'view_count' => 88,
                'like_count' => 0,
                'collect_count' => 0,
                'comment_count' => 0,
                'audit_status' => 2,
                'audit_remark' => '演示内容已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(-2, '12:35:00'),
                'sort' => 80,
                'status' => 1,
                'remark' => 'demo:help-comprehensive:material',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '11:35:00'),
                'update_time' => $this->dt(-2, '12:35:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_content_material', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedContentHistory(): void
    {
        $rows = [
            [
                'id' => 8921,
                'member_id' => self::MAIN_PATIENT_ID,
                'content_id' => 8911,
                'content_type' => 'education',
                'title' => '睡前 5 分钟身体扫描',
                'author_name' => 'HelpSupport',
                'route' => '/materials/detail/8911',
                'progress' => 92.50,
                'duration_seconds' => 280,
                'viewed_at' => $this->dt(0, '22:12:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '22:12:00'),
                'update_time' => $this->dt(0, '22:12:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8922,
                'member_id' => self::MAIN_PATIENT_ID,
                'content_id' => 8914,
                'content_type' => 'education',
                'title' => '复诊提问清单模板',
                'author_name' => '林清岚',
                'route' => '/materials/detail/8914',
                'progress' => 100.00,
                'duration_seconds' => 360,
                'viewed_at' => $this->dt(0, '17:45:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '17:45:00'),
                'update_time' => $this->dt(0, '17:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8923,
                'member_id' => self::MAIN_PATIENT_ID,
                'content_id' => 8918,
                'content_type' => 'education',
                'title' => '焦虑高峰时的地面化练习',
                'author_name' => 'HelpSupport',
                'route' => '/materials/detail/8918',
                'progress' => 67.00,
                'duration_seconds' => 160,
                'viewed_at' => $this->dt(-1, '21:58:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '21:58:00'),
                'update_time' => $this->dt(-1, '21:58:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8924,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'content_id' => 8916,
                'content_type' => 'education',
                'title' => '产后支持资源目录',
                'author_name' => 'HelpSupport',
                'route' => '/materials/detail/8916',
                'progress' => 100.00,
                'duration_seconds' => 210,
                'viewed_at' => $this->dt(0, '14:10:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '14:10:00'),
                'update_time' => $this->dt(0, '14:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8925,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'content_id' => 8915,
                'content_type' => 'education',
                'title' => '夜班人群如何安排补觉',
                'author_name' => '陈川',
                'route' => '/materials/detail/8915',
                'progress' => 74.00,
                'duration_seconds' => 240,
                'viewed_at' => $this->dt(0, '10:50:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:50:00'),
                'update_time' => $this->dt(0, '10:50:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8926,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'content_id' => 8917,
                'content_type' => 'education',
                'title' => '如何向医生描述一周内的睡眠变化',
                'author_name' => '陈川',
                'route' => '/materials/detail/8917',
                'progress' => 100.00,
                'duration_seconds' => 300,
                'viewed_at' => $this->dt(-1, '20:30:00'),
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:30:00'),
                'update_time' => $this->dt(-1, '20:30:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_member_content_history',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `content_type` = ' . $this->q($row['content_type']) . ' AND `content_id` = ' . (int) $row['content_id']
            );
        }
    }

    private function seedMaterialCollects(): void
    {
        $rows = [
            [
                'id' => 8931,
                'member_id' => self::MAIN_PATIENT_ID,
                'material_id' => 8912,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '22:15:00'),
                'update_time' => $this->dt(0, '22:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8932,
                'member_id' => self::MAIN_PATIENT_ID,
                'material_id' => 8914,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '17:50:00'),
                'update_time' => $this->dt(0, '17:50:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8933,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'material_id' => 8916,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '14:12:00'),
                'update_time' => $this->dt(0, '14:12:00'),
                'delete_time' => null,
            ],
            [
                'id' => 8934,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'material_id' => 8917,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:32:00'),
                'update_time' => $this->dt(-1, '20:32:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_material_collect',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `material_id` = ' . (int) $row['material_id']
            );
        }
    }

    private function seedCommunityTags(): void
    {
        $rows = [
            [
                'id' => 9001,
                'tag_name' => '演示·睡眠恢复',
                'tag_name_i18n' => $this->json(['zh-CN' => '演示·睡眠恢复', 'en-US' => 'Demo · Sleep Recovery']),
                'color' => '#FF9585',
                'sort' => 10,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '10:00:00'),
                'update_time' => $this->dt(-2, '10:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9002,
                'tag_name' => '演示·复诊准备',
                'tag_name_i18n' => $this->json(['zh-CN' => '演示·复诊准备', 'en-US' => 'Demo · Appointment Prep']),
                'color' => '#5A81DA',
                'sort' => 20,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '10:01:00'),
                'update_time' => $this->dt(-2, '10:01:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9003,
                'tag_name' => '演示·情绪调节',
                'tag_name_i18n' => $this->json(['zh-CN' => '演示·情绪调节', 'en-US' => 'Demo · Emotional Support']),
                'color' => '#986FF5',
                'sort' => 30,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '10:02:00'),
                'update_time' => $this->dt(-2, '10:02:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9004,
                'tag_name' => '演示·夜班修复',
                'tag_name_i18n' => $this->json(['zh-CN' => '演示·夜班修复', 'en-US' => 'Demo · Shift Recovery']),
                'color' => '#FFAE4D',
                'sort' => 40,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '10:03:00'),
                'update_time' => $this->dt(-2, '10:03:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9005,
                'tag_name' => '演示·家属支持',
                'tag_name_i18n' => $this->json(['zh-CN' => '演示·家属支持', 'en-US' => 'Demo · Family Support']),
                'color' => '#A4C3CC',
                'sort' => 50,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '10:04:00'),
                'update_time' => $this->dt(-2, '10:04:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_community_tag', $row, '`tag_name` = ' . $this->q($row['tag_name']) . ' AND `delete_time` IS NULL');
        }
    }

    private function seedCommunityFollowTags(): void
    {
        $rows = [
            ['id' => 9011, 'member_id' => self::MAIN_PATIENT_ID, 'tag_id' => 9001],
            ['id' => 9012, 'member_id' => self::MAIN_PATIENT_ID, 'tag_id' => 9002],
            ['id' => 9013, 'member_id' => self::MAIN_PATIENT_ID, 'tag_id' => 9003],
            ['id' => 9014, 'member_id' => self::MEMBER_PATIENT_AMY, 'tag_id' => 9001],
            ['id' => 9015, 'member_id' => self::MEMBER_PATIENT_AMY, 'tag_id' => 9005],
            ['id' => 9016, 'member_id' => self::MEMBER_PATIENT_JAY, 'tag_id' => 9004],
            ['id' => 9017, 'member_id' => self::MEMBER_PATIENT_LUNA, 'tag_id' => 9005],
            ['id' => 9018, 'member_id' => self::MEMBER_PATIENT_NOAH, 'tag_id' => 9002],
        ];

        foreach ($rows as &$row) {
            $row['created_by'] = 1;
            $row['updated_by'] = 1;
            $row['create_time'] = $this->dt(-1, '18:00:00');
            $row['update_time'] = $this->dt(-1, '18:00:00');
            $row['delete_time'] = null;
        }
        unset($row);

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_community_follow_tag',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `tag_id` = ' . (int) $row['tag_id']
            );
        }
    }

    private function seedCommunityPosts(): void
    {
        $rows = [
            [
                'id' => 9021,
                'member_id' => self::MAIN_PATIENT_ID,
                'content' => '【演示】这两天我发现，只要晚饭后继续处理工作消息，晚上脑子就停不下来。现在先试着把最担心的三件事写下来，再去做睡前身体扫描，入睡前没那么炸了。',
                'images' => $this->json([]),
                'link_url' => '',
                'tags' => $this->json(['演示·睡眠恢复', '演示·情绪调节']),
                'is_anonymous' => 2,
                'is_doctor_post' => 2,
                'view_count' => 46,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 2,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:00:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '10:55:00'),
                'update_time' => $this->dt(0, '11:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9022,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'content' => '【演示】今天终于争取到了一段完整的 20 分钟安静时间。虽然不长，但第一次感觉自己不是只能被动等宝宝睡着之后再硬撑。',
                'images' => $this->json(['https://picsum.photos/seed/community-9022/1200/900']),
                'link_url' => '',
                'tags' => $this->json(['演示·睡眠恢复', '演示·家属支持']),
                'is_anonymous' => 2,
                'is_doctor_post' => 2,
                'view_count' => 38,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 2,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:05:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:02:00'),
                'update_time' => $this->dt(0, '11:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9023,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'content' => '【演示】夜班后最难熬的是回家路上那段空档，脑子又累又停不下来。今天试了慢走 10 分钟，意外地没有直接陷进短视频里。',
                'images' => $this->json([]),
                'link_url' => '',
                'tags' => $this->json(['演示·夜班修复']),
                'is_anonymous' => 2,
                'is_doctor_post' => 2,
                'view_count' => 29,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 2,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:10:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:08:00'),
                'update_time' => $this->dt(0, '11:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9024,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'content' => '【演示】如果你准备复诊又怕一开口就乱，可以先只记三件事：最明显的变化、最稳定的触发点、最想问医生的问题。先缩小范围，比硬凑完整周报更有效。',
                'images' => $this->json([]),
                'link_url' => '',
                'tags' => $this->json(['演示·复诊准备', '演示·情绪调节']),
                'is_anonymous' => 2,
                'is_doctor_post' => 1,
                'view_count' => 52,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 1,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:12:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:11:00'),
                'update_time' => $this->dt(0, '11:12:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9025,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'content' => '【演示】A short scripted phrase helped tonight: “I need 15 quiet minutes before the next feeding.” Having the sentence ready made it much easier to ask for help.',
                'images' => $this->json([]),
                'link_url' => '',
                'tags' => $this->json(['演示·家属支持']),
                'is_anonymous' => 2,
                'is_doctor_post' => 2,
                'view_count' => 21,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 2,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:15:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:13:00'),
                'update_time' => $this->dt(0, '11:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9026,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'content' => '【演示】I started grouping follow-up notes into “what changed”, “what triggers it”, and “what I want to ask”. It feels less overwhelming than trying to describe everything at once.',
                'images' => $this->json([]),
                'link_url' => '',
                'tags' => $this->json(['演示·复诊准备']),
                'is_anonymous' => 2,
                'is_doctor_post' => 2,
                'view_count' => 18,
                'like_count' => 0,
                'comment_count' => 0,
                'collect_count' => 0,
                'is_top' => 2,
                'audit_status' => 1,
                'audit_remark' => '演示帖子已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:18:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:16:00'),
                'update_time' => $this->dt(0, '11:18:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_community_post', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedCommunityComments(): void
    {
        $rows = [
            [
                'id' => 9031,
                'post_id' => 9021,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'parent_id' => 0,
                'reply_to_member_id' => self::MAIN_PATIENT_ID,
                'content' => '【演示评论】可以先把“最常见的三个触发点”固定下来，下次复诊会更容易说清楚。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:30:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:28:00'),
                'update_time' => $this->dt(0, '11:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9032,
                'post_id' => 9021,
                'member_id' => self::MAIN_PATIENT_ID,
                'parent_id' => 9031,
                'reply_to_member_id' => self::MEMBER_DOCTOR_CHEN,
                'content' => '【演示评论】这个建议很有用，我准备把它写进今晚的回顾里。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:35:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:34:00'),
                'update_time' => $this->dt(0, '11:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9033,
                'post_id' => 9022,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_PATIENT_AMY,
                'content' => '【演示评论】20 分钟已经很了不起了，能被安静对待一下真的会不一样。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:40:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:39:00'),
                'update_time' => $this->dt(0, '11:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9034,
                'post_id' => 9022,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_PATIENT_AMY,
                'content' => '【演示评论】先把这 20 分钟守住，不急着一次解决所有睡眠问题。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:45:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:44:00'),
                'update_time' => $this->dt(0, '11:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9035,
                'post_id' => 9023,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_PATIENT_JAY,
                'content' => '【演示评论】慢走这个方法我也想试试，感觉先让身体慢下来很重要。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:50:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:49:00'),
                'update_time' => $this->dt(0, '11:50:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9036,
                'post_id' => 9024,
                'member_id' => self::MAIN_PATIENT_ID,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_DOCTOR_CHEN,
                'content' => '【演示评论】“三件事”这个结构对我很有帮助，终于没那么怕一开口就乱。',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '11:55:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:54:00'),
                'update_time' => $this->dt(0, '11:55:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9037,
                'post_id' => 9026,
                'member_id' => self::MEMBER_DOCTOR_CHEN,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_PATIENT_NOAH,
                'content' => '【演示评论】That structure is good. If possible, add one concrete example for each section before your appointment.',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '12:00:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '11:59:00'),
                'update_time' => $this->dt(0, '12:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9038,
                'post_id' => 9025,
                'member_id' => self::MEMBER_PATIENT_NOAH,
                'parent_id' => 0,
                'reply_to_member_id' => self::MEMBER_PATIENT_LUNA,
                'content' => '【演示评论】Having the sentence ready is huge. I should probably prepare one for appointments too.',
                'attachments' => $this->json([]),
                'is_anonymous' => 2,
                'like_count' => 0,
                'audit_status' => 1,
                'audit_remark' => '演示评论已通过',
                'audit_by' => 1,
                'audit_time' => $this->dt(0, '12:05:00'),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '12:04:00'),
                'update_time' => $this->dt(0, '12:05:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_community_comment', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedCommunityLikes(): void
    {
        $rows = [
            ['id' => 9041, 'member_id' => self::MAIN_PATIENT_ID, 'target_type' => 1, 'target_id' => 9024],
            ['id' => 9042, 'member_id' => self::MEMBER_PATIENT_AMY, 'target_type' => 1, 'target_id' => 9021],
            ['id' => 9043, 'member_id' => self::MEMBER_PATIENT_JAY, 'target_type' => 1, 'target_id' => 9021],
            ['id' => 9044, 'member_id' => self::MEMBER_PATIENT_LUNA, 'target_type' => 2, 'target_id' => 9031],
            ['id' => 9045, 'member_id' => self::MEMBER_DOCTOR_LIN, 'target_type' => 1, 'target_id' => 9022],
            ['id' => 9046, 'member_id' => self::MEMBER_DOCTOR_CHEN, 'target_type' => 1, 'target_id' => 9023],
            ['id' => 9047, 'member_id' => self::MEMBER_PATIENT_NOAH, 'target_type' => 1, 'target_id' => 9025],
            ['id' => 9048, 'member_id' => self::MAIN_PATIENT_ID, 'target_type' => 2, 'target_id' => 9034],
        ];

        foreach ($rows as &$row) {
            $row['created_by'] = 1;
            $row['updated_by'] = 1;
            $row['create_time'] = $this->dt(0, '12:10:00');
            $row['update_time'] = $this->dt(0, '12:10:00');
            $row['delete_time'] = null;
        }
        unset($row);

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_community_like',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `target_type` = ' . (int) $row['target_type'] . ' AND `target_id` = ' . (int) $row['target_id']
            );
        }
    }

    private function seedCommunityCollects(): void
    {
        $rows = [
            ['id' => 9051, 'member_id' => self::MAIN_PATIENT_ID, 'post_id' => 9024],
            ['id' => 9052, 'member_id' => self::MEMBER_PATIENT_AMY, 'post_id' => 9021],
            ['id' => 9053, 'member_id' => self::MEMBER_PATIENT_LUNA, 'post_id' => 9026],
        ];

        foreach ($rows as &$row) {
            $row['created_by'] = 1;
            $row['updated_by'] = 1;
            $row['create_time'] = $this->dt(0, '12:15:00');
            $row['update_time'] = $this->dt(0, '12:15:00');
            $row['delete_time'] = null;
        }
        unset($row);

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_community_collect',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `post_id` = ' . (int) $row['post_id']
            );
        }
    }

    private function seedCommunityFollowMembers(): void
    {
        $rows = [
            ['id' => 9061, 'member_id' => self::MAIN_PATIENT_ID, 'target_member_id' => self::MEMBER_DOCTOR_LIN],
            ['id' => 9062, 'member_id' => self::MEMBER_PATIENT_AMY, 'target_member_id' => self::MEMBER_PATIENT_LUNA],
            ['id' => 9063, 'member_id' => self::MEMBER_PATIENT_JAY, 'target_member_id' => self::MEMBER_DOCTOR_CHEN],
            ['id' => 9064, 'member_id' => self::MEMBER_PATIENT_LUNA, 'target_member_id' => self::MEMBER_PATIENT_AMY],
            ['id' => 9065, 'member_id' => self::MEMBER_PATIENT_NOAH, 'target_member_id' => self::MEMBER_DOCTOR_CHEN],
        ];

        foreach ($rows as &$row) {
            $row['created_by'] = 1;
            $row['updated_by'] = 1;
            $row['create_time'] = $this->dt(-1, '18:30:00');
            $row['update_time'] = $this->dt(-1, '18:30:00');
            $row['delete_time'] = null;
        }
        unset($row);

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_community_follow_member',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `target_member_id` = ' . (int) $row['target_member_id']
            );
        }
    }

    private function seedMemberChatConfigs(): void
    {
        $rows = [
            [
                'id' => 9101,
                'member_id' => self::MAIN_PATIENT_ID,
                'chat_mode' => 'companion',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 你是睡前陪伴助手，先帮我把注意力从反刍拉回到当下。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:00:00'),
                'update_time' => $this->dt(-1, '20:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9102,
                'member_id' => self::MAIN_PATIENT_ID,
                'chat_mode' => 'doctor',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 帮我把这一周的睡眠变化整理成复诊可直接描述的线索。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:05:00'),
                'update_time' => $this->dt(-1, '20:05:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9103,
                'member_id' => self::MAIN_PATIENT_ID,
                'chat_mode' => 'patient',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 帮我记录患者视角的症状、触发点和完成情况。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:10:00'),
                'update_time' => $this->dt(-1, '20:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9104,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'chat_mode' => 'companion',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 帮我先安顿下来，再决定今晚只做一个最重要的小动作。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:15:00'),
                'update_time' => $this->dt(-1, '20:15:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9105,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'chat_mode' => 'patient',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 帮我把今天最耗能的一刻和稍微好一点的时刻都记下来。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:16:00'),
                'update_time' => $this->dt(-1, '20:16:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9106,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'chat_mode' => 'companion',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] 帮我把夜班后的空档拆成几个更容易做到的小缓冲动作。',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:18:00'),
                'update_time' => $this->dt(-1, '20:18:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9107,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'chat_mode' => 'patient',
                'prompt_text' => '[DEMO-HELP-COMPREHENSIVE] Help me capture family-support notes in simple English before bedtime.',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '20:20:00'),
                'update_time' => $this->dt(-1, '20:20:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing(
                'sa_member_chat_config',
                $row,
                '`member_id` = ' . (int) $row['member_id'] . ' AND `chat_mode` = ' . $this->q($row['chat_mode'])
            );
        }
    }

    private function seedMemberChatSessions(): void
    {
        $rows = [
            [
                'id' => 9111,
                'member_id' => self::MAIN_PATIENT_ID,
                'chat_mode' => 'companion',
                'session_name' => '演示·今晚更好入睡',
                'last_message' => '',
                'last_message_time' => null,
                'is_pinned' => 1,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:30:00'),
                'update_time' => $this->dt(0, '20:30:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9112,
                'member_id' => self::MAIN_PATIENT_ID,
                'chat_mode' => 'doctor',
                'session_name' => '演示·复诊前想问医生',
                'last_message' => '',
                'last_message_time' => null,
                'is_pinned' => 1,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:35:00'),
                'update_time' => $this->dt(0, '20:35:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9113,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'chat_mode' => 'patient',
                'session_name' => '演示·产后碎片睡眠记录',
                'last_message' => '',
                'last_message_time' => null,
                'is_pinned' => 2,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:40:00'),
                'update_time' => $this->dt(0, '20:40:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9114,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'chat_mode' => 'companion',
                'session_name' => '演示·夜班后情绪缓冲',
                'last_message' => '',
                'last_message_time' => null,
                'is_pinned' => 2,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:45:00'),
                'update_time' => $this->dt(0, '20:45:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9115,
                'member_id' => self::MEMBER_PATIENT_LUNA,
                'chat_mode' => 'patient',
                'session_name' => 'Demo · Family Support Notes',
                'last_message' => '',
                'last_message_time' => null,
                'is_pinned' => 2,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '20:50:00'),
                'update_time' => $this->dt(0, '20:50:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_member_chat_session', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedMemberChatRecords(): void
    {
        $rows = [
            [9121, 9111, self::MAIN_PATIENT_ID, 'companion', 'user', '今晚一想到明天的会，我脑子就停不下来。', 0, $this->dt(0, '21:00:00')],
            [9122, 9111, self::MAIN_PATIENT_ID, 'companion', 'assistant', '先不要急着解决明天，把注意力放回现在。你愿意先跟我做三次缓慢呼吸吗？', 38, $this->dt(0, '21:00:20')],
            [9123, 9111, self::MAIN_PATIENT_ID, 'companion', 'user', '可以，我现在胸口有点紧。', 0, $this->dt(0, '21:01:10')],
            [9124, 9111, self::MAIN_PATIENT_ID, 'companion', 'assistant', '那先只做一件事：把肩膀放低，然后把明天最担心的一件事写成一句话。', 44, $this->dt(0, '21:01:40')],

            [9125, 9112, self::MAIN_PATIENT_ID, 'doctor', 'user', '我想在复诊时讲清楚“夜里惊醒”和“白天脑雾”，怎么说更有效？', 0, $this->dt(0, '17:20:00')],
            [9126, 9112, self::MAIN_PATIENT_ID, 'doctor', 'assistant', '先分成三个部分：什么时候最明显、通常被什么触发、你已经尝试过什么。', 52, $this->dt(0, '17:20:30')],
            [9127, 9112, self::MAIN_PATIENT_ID, 'doctor', 'user', '那我是不是可以把午后困意也放进去？', 0, $this->dt(0, '17:21:00')],
            [9128, 9112, self::MAIN_PATIENT_ID, 'doctor', 'assistant', '可以，而且午后困意很适合作为“白天功能受影响”的具体例子。', 35, $this->dt(0, '17:21:20')],

            [9129, 9113, self::MEMBER_PATIENT_AMY, 'patient', 'user', '今天最累的是刚哄睡完又开始想下一次什么时候会醒。', 0, $this->dt(0, '21:05:00')],
            [9130, 9113, self::MEMBER_PATIENT_AMY, 'patient', 'assistant', '我先记下来了：疲惫不是最难的，最难的是持续的预期紧张。', 33, $this->dt(0, '21:05:20')],
            [9131, 9113, self::MEMBER_PATIENT_AMY, 'patient', 'user', '是的，但今天也有一个 20 分钟安静时间。', 0, $this->dt(0, '21:05:50')],
            [9132, 9113, self::MEMBER_PATIENT_AMY, 'patient', 'assistant', '这很重要，我会把它标记成“今天稍微好一点的时刻”。', 29, $this->dt(0, '21:06:10')],

            [9133, 9114, self::MEMBER_PATIENT_JAY, 'companion', 'user', '夜班后我最容易在回家路上失控刷手机。', 0, $this->dt(0, '09:40:00')],
            [9134, 9114, self::MEMBER_PATIENT_JAY, 'companion', 'assistant', '那先不要和“完全不刷”对抗，先把它变成“回家前 10 分钟只慢走”。', 42, $this->dt(0, '09:40:20')],
            [9135, 9114, self::MEMBER_PATIENT_JAY, 'companion', 'user', '这样我反而比较做得到。', 0, $this->dt(0, '09:41:00')],
            [9136, 9114, self::MEMBER_PATIENT_JAY, 'companion', 'assistant', '对，先把恢复节律撑起来，再去调别的细节。', 30, $this->dt(0, '09:41:20')],

            [9137, 9115, self::MEMBER_PATIENT_LUNA, 'patient', 'user', 'I need a simple way to ask for help before bedtime.', 0, $this->dt(0, '20:55:00')],
            [9138, 9115, self::MEMBER_PATIENT_LUNA, 'patient', 'assistant', 'Try one reusable sentence first: “I need 15 quiet minutes before the next feeding.”', 31, $this->dt(0, '20:55:18')],
            [9139, 9115, self::MEMBER_PATIENT_LUNA, 'patient', 'user', 'That feels clear enough to actually say out loud.', 0, $this->dt(0, '20:55:50')],
            [9140, 9115, self::MEMBER_PATIENT_LUNA, 'patient', 'assistant', 'Great. I will save it as tonight’s support script so you can reuse it tomorrow.', 27, $this->dt(0, '20:56:10')],
        ];

        foreach ($rows as $row) {
            $data = [
                'id' => $row[0],
                'session_id' => $row[1],
                'member_id' => $row[2],
                'chat_mode' => $row[3],
                'role' => $row[4],
                'content' => $row[5],
                'content_type' => 'text',
                'token_count' => $row[6],
                'message_time' => $row[7],
                'ext' => $this->json([]),
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $row[7],
                'update_time' => $row[7],
                'delete_time' => null,
            ];

            $this->insertIfMissing('sa_member_chat_record', $data, '`id` = ' . (int) $data['id']);
        }
    }

    private function seedLocalModels(): void
    {
        $rows = [
            [
                'id' => 9201,
                'name' => 'HelpSupport Companion 2B Q4_K_M',
                'code' => 'helpsupport-companion-2b-q4-k-m',
                'provider' => 'HelpSupport',
                'model_family' => 'Qwen2.5',
                'quantization' => 'Q4_K_M',
                'file_size' => 1879048192,
                'download_url' => 'https://cdn.helpsupport.test/models/helpsupport-companion-2b-q4-k-m.gguf',
                'sha256' => '4d5c26f0c8f5cf69d95bcda4321f8b47a9876aa0d8f1b451fe9a998f12345678',
                'intro' => '针对晚间陪伴与简单情绪缓冲优化的轻量本地模型。',
                'intro_i18n' => $this->json([
                    'zh-CN' => '针对晚间陪伴与简单情绪缓冲优化的轻量本地模型。',
                    'en-US' => 'A lightweight local model tuned for bedtime companionship and basic emotional grounding.',
                ]),
                'license' => 'Demo Research License',
                'min_memory_mb' => 4096,
                'context_size' => 8192,
                'default_temperature' => 0.65,
                'default_top_p' => 0.85,
                'sort' => 20,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:00:00'),
                'update_time' => $this->dt(-2, '16:00:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9202,
                'name' => 'HelpSupport Doctor Notes 3B Q4_K_M',
                'code' => 'helpsupport-doctor-notes-3b-q4-k-m',
                'provider' => 'HelpSupport',
                'model_family' => 'Qwen2.5',
                'quantization' => 'Q4_K_M',
                'file_size' => 2684354560,
                'download_url' => 'https://cdn.helpsupport.test/models/helpsupport-doctor-notes-3b-q4-k-m.gguf',
                'sha256' => '8130cbcab45d3cf9791a2876bbf45d7f34567bca921f1289a111cdef87654321',
                'intro' => '偏向复诊线索整理与沟通提纲生成的本地模型。',
                'intro_i18n' => $this->json([
                    'zh-CN' => '偏向复诊线索整理与沟通提纲生成的本地模型。',
                    'en-US' => 'A local model oriented toward follow-up note structuring and doctor communication briefs.',
                ]),
                'license' => 'Demo Research License',
                'min_memory_mb' => 6144,
                'context_size' => 12288,
                'default_temperature' => 0.45,
                'default_top_p' => 0.90,
                'sort' => 30,
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:05:00'),
                'update_time' => $this->dt(-2, '16:05:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_local_model_catalog', $row, '`code` = ' . $this->q($row['code']));
        }
    }

    private function seedLocalModelPrompts(): void
    {
        $rows = [
            [
                'id' => 9211,
                'model_id' => 9201,
                'chat_mode' => 'companion',
                'locale' => 'zh',
                'title' => '演示陪伴支持',
                'system_prompt' => '你是一个温和但不过度说教的睡前陪伴助手，优先帮助用户回到当下并拆小动作。',
                'first_message' => '我们先不急着解决全部问题，只选今晚最需要的一件小事。',
                'safety_prompt' => '不要替代医生诊断；遇到高风险内容时提示用户寻求线下帮助。',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:10:00'),
                'update_time' => $this->dt(-2, '16:10:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9212,
                'model_id' => 9201,
                'chat_mode' => 'companion',
                'locale' => 'en-US',
                'title' => 'Demo Companion Support',
                'system_prompt' => 'You are a calm bedtime companion. Help the user return to the present moment and choose one small next step.',
                'first_message' => 'We do not need to solve everything tonight. Let us pick one small thing first.',
                'safety_prompt' => 'Do not replace clinical advice. Escalate clearly when risk signals appear.',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:11:00'),
                'update_time' => $this->dt(-2, '16:11:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9213,
                'model_id' => 9201,
                'chat_mode' => 'patient',
                'locale' => 'zh',
                'title' => '演示患者记录',
                'system_prompt' => '帮用户记录患者视角的触发点、完成情况和稍微好一点的时刻。',
                'first_message' => '今天最消耗你的时刻是什么？也别忘了记录一个稍微好一点的时刻。',
                'safety_prompt' => '不输出医疗结论；保持记录与整理导向。',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:12:00'),
                'update_time' => $this->dt(-2, '16:12:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9214,
                'model_id' => 9201,
                'chat_mode' => 'patient',
                'locale' => 'en-US',
                'title' => 'Demo Patient Reflection',
                'system_prompt' => 'Capture the patient perspective: what felt hardest, what felt slightly better, and what pattern is emerging.',
                'first_message' => 'What took the most energy today? What felt even slightly easier?',
                'safety_prompt' => 'Stay in reflection mode. Do not present medical certainty.',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:13:00'),
                'update_time' => $this->dt(-2, '16:13:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9215,
                'model_id' => 9202,
                'chat_mode' => 'doctor',
                'locale' => 'zh',
                'title' => '演示复诊提纲',
                'system_prompt' => '把患者一周内的变化整理成复诊时可直接表达的三段线索。',
                'first_message' => '先告诉我这一周最明显的变化、最稳定的触发点，以及你最想问医生的问题。',
                'safety_prompt' => '保持提纲整理角色，不代替医生判断。',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:14:00'),
                'update_time' => $this->dt(-2, '16:14:00'),
                'delete_time' => null,
            ],
            [
                'id' => 9216,
                'model_id' => 9202,
                'chat_mode' => 'doctor',
                'locale' => 'en-US',
                'title' => 'Demo Follow-up Brief',
                'system_prompt' => 'Turn a week of symptoms and notes into a concise follow-up brief for a doctor visit.',
                'first_message' => 'Share the biggest change, the clearest trigger, and the main question you want to ask.',
                'safety_prompt' => 'Organize only. Do not make clinical decisions.',
                'status' => 1,
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-2, '16:15:00'),
                'update_time' => $this->dt(-2, '16:15:00'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_local_model_prompt', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function seedLocalModelDownloadLogs(): void
    {
        $rows = [
            [
                'id' => 9221,
                'member_id' => self::MAIN_PATIENT_ID,
                'model_id' => 1,
                'model_code' => 'qwen2.5-0.5b-instruct-q4-k-m',
                'model_name' => 'Qwen2.5 0.5B Instruct Q4_K_M',
                'platform' => 'ios',
                'app_version' => '1.0.0-demo',
                'locale' => 'zh-CN',
                'download_status' => 'success',
                'file_size' => 603979776,
                'downloaded_size' => 603979776,
                'sha256' => 'existing-demo-model-sha256',
                'duration_seconds' => 124,
                'error_code' => '',
                'error_message' => '',
                'started_at' => $this->dt(-1, '19:00:00'),
                'finished_at' => $this->dt(-1, '19:02:04'),
                'ext' => $this->json(['network' => 'wifi']),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:model-log',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(-1, '19:00:00'),
                'update_time' => $this->dt(-1, '19:02:04'),
                'delete_time' => null,
            ],
            [
                'id' => 9222,
                'member_id' => self::MAIN_PATIENT_ID,
                'model_id' => 9201,
                'model_code' => 'helpsupport-companion-2b-q4-k-m',
                'model_name' => 'HelpSupport Companion 2B Q4_K_M',
                'platform' => 'ios',
                'app_version' => '1.0.0-demo',
                'locale' => 'zh-CN',
                'download_status' => 'success',
                'file_size' => 1879048192,
                'downloaded_size' => 1879048192,
                'sha256' => '4d5c26f0c8f5cf69d95bcda4321f8b47a9876aa0d8f1b451fe9a998f12345678',
                'duration_seconds' => 318,
                'error_code' => '',
                'error_message' => '',
                'started_at' => $this->dt(0, '16:00:00'),
                'finished_at' => $this->dt(0, '16:05:18'),
                'ext' => $this->json(['network' => 'wifi']),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:model-log',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '16:00:00'),
                'update_time' => $this->dt(0, '16:05:18'),
                'delete_time' => null,
            ],
            [
                'id' => 9223,
                'member_id' => self::MEMBER_PATIENT_AMY,
                'model_id' => 9201,
                'model_code' => 'helpsupport-companion-2b-q4-k-m',
                'model_name' => 'HelpSupport Companion 2B Q4_K_M',
                'platform' => 'android',
                'app_version' => '1.0.0-demo',
                'locale' => 'en-US',
                'download_status' => 'failed',
                'file_size' => 1879048192,
                'downloaded_size' => 734003200,
                'sha256' => '',
                'duration_seconds' => 141,
                'error_code' => 'NETWORK_INTERRUPTED',
                'error_message' => 'Connection dropped during large file transfer.',
                'started_at' => $this->dt(0, '16:20:00'),
                'finished_at' => $this->dt(0, '16:22:21'),
                'ext' => $this->json(['network' => '4g']),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:model-log',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '16:20:00'),
                'update_time' => $this->dt(0, '16:22:21'),
                'delete_time' => null,
            ],
            [
                'id' => 9224,
                'member_id' => self::MEMBER_PATIENT_JAY,
                'model_id' => 9202,
                'model_code' => 'helpsupport-doctor-notes-3b-q4-k-m',
                'model_name' => 'HelpSupport Doctor Notes 3B Q4_K_M',
                'platform' => 'ios',
                'app_version' => '1.0.0-demo',
                'locale' => 'zh-CN',
                'download_status' => 'canceled',
                'file_size' => 2684354560,
                'downloaded_size' => 1124073472,
                'sha256' => '',
                'duration_seconds' => 205,
                'error_code' => 'USER_CANCELED',
                'error_message' => 'Download canceled after shift started.',
                'started_at' => $this->dt(0, '17:00:00'),
                'finished_at' => $this->dt(0, '17:03:25'),
                'ext' => $this->json(['network' => 'wifi']),
                'status' => 1,
                'remark' => 'demo:help-comprehensive:model-log',
                'created_by' => 1,
                'updated_by' => 1,
                'create_time' => $this->dt(0, '17:00:00'),
                'update_time' => $this->dt(0, '17:03:25'),
                'delete_time' => null,
            ],
        ];

        foreach ($rows as $row) {
            $this->insertIfMissing('sa_local_model_download_log', $row, '`id` = ' . (int) $row['id']);
        }
    }

    private function syncPointsBalances(array $memberIds): void
    {
        foreach ($memberIds as $memberId) {
            $row = $this->fetchRow(
                'SELECT COALESCE(SUM(`points`), 0) AS `total`
                 FROM `sa_member_point_log`
                 WHERE `member_id` = ' . (int) $memberId . ' AND `delete_time` IS NULL'
            );

            $this->updateValues(
                'sa_member',
                [
                    'points_balance' => (int) ($row['total'] ?? 0),
                    'update_time' => $this->dt(0, '23:10:00'),
                ],
                '`id` = ' . (int) $memberId
            );
        }
    }

    private function syncScheduleBookedCounts(array $scheduleIds): void
    {
        foreach ($scheduleIds as $scheduleId) {
            $row = $this->fetchRow(
                'SELECT COUNT(*) AS `total`
                 FROM `sa_doctor_appointment`
                 WHERE `schedule_id` = ' . (int) $scheduleId . ' AND `status` IN (0, 1, 2) AND `delete_time` IS NULL'
            );

            $this->updateValues(
                'sa_doctor_schedule',
                [
                    'booked_count' => (int) ($row['total'] ?? 0),
                    'update_time' => $this->dt(0, '23:15:00'),
                ],
                '`id` = ' . (int) $scheduleId
            );
        }
    }

    private function syncCommunityPostStats(array $postIds): void
    {
        foreach ($postIds as $postId) {
            $commentRow = $this->fetchRow(
                'SELECT COUNT(*) AS `total`
                 FROM `sa_community_comment`
                 WHERE `post_id` = ' . (int) $postId . ' AND `delete_time` IS NULL'
            );
            $likeRow = $this->fetchRow(
                'SELECT COUNT(*) AS `total`
                 FROM `sa_community_like`
                 WHERE `target_type` = 1 AND `target_id` = ' . (int) $postId . ' AND `delete_time` IS NULL'
            );
            $collectRow = $this->fetchRow(
                'SELECT COUNT(*) AS `total`
                 FROM `sa_community_collect`
                 WHERE `post_id` = ' . (int) $postId . ' AND `delete_time` IS NULL'
            );

            $this->updateValues(
                'sa_community_post',
                [
                    'comment_count' => (int) ($commentRow['total'] ?? 0),
                    'like_count' => (int) ($likeRow['total'] ?? 0),
                    'collect_count' => (int) ($collectRow['total'] ?? 0),
                    'update_time' => $this->dt(0, '23:20:00'),
                ],
                '`id` = ' . (int) $postId
            );
        }
    }

    private function syncCommunityCommentLikeStats(array $commentIds): void
    {
        foreach ($commentIds as $commentId) {
            $row = $this->fetchRow(
                'SELECT COUNT(*) AS `total`
                 FROM `sa_community_like`
                 WHERE `target_type` = 2 AND `target_id` = ' . (int) $commentId . ' AND `delete_time` IS NULL'
            );

            $this->updateValues(
                'sa_community_comment',
                [
                    'like_count' => (int) ($row['total'] ?? 0),
                    'update_time' => $this->dt(0, '23:25:00'),
                ],
                '`id` = ' . (int) $commentId
            );
        }
    }

    private function syncChatSessionSummaries(array $sessionIds): void
    {
        foreach ($sessionIds as $sessionId) {
            $row = $this->fetchRow(
                'SELECT `content`, `message_time`
                 FROM `sa_member_chat_record`
                 WHERE `session_id` = ' . (int) $sessionId . ' AND `delete_time` IS NULL
                 ORDER BY `message_time` DESC, `id` DESC
                 LIMIT 1'
            );

            if (!$row) {
                continue;
            }

            $this->updateValues(
                'sa_member_chat_session',
                [
                    'last_message' => (string) $row['content'],
                    'last_message_time' => (string) $row['message_time'],
                    'update_time' => $this->dt(0, '23:30:00'),
                ],
                '`id` = ' . (int) $sessionId
            );
        }
    }

    private function insertIfMissing(string $table, array $data, string $where): void
    {
        $columns = array_map(
            static fn (string $column): string => '`' . $column . '`',
            array_keys($data)
        );
        $values = array_map(fn (mixed $value): string => $this->sqlValue($value), array_values($data));

        $this->execute(
            'INSERT INTO `' . $table . '` (' . implode(', ', $columns) . ')
             SELECT ' . implode(', ', $values) . '
             WHERE NOT EXISTS (
                 SELECT 1 FROM `' . $table . '` WHERE ' . $where . '
             )'
        );
    }

    private function updateValues(string $table, array $data, string $where): void
    {
        $assignments = [];
        foreach ($data as $column => $value) {
            $assignments[] = '`' . $column . '` = ' . $this->sqlValue($value);
        }

        $this->execute(
            'UPDATE `' . $table . '`
             SET ' . implode(', ', $assignments) . '
             WHERE ' . $where
        );
    }

    private function deleteIds(string $table, array $ids): void
    {
        if ($ids === []) {
            return;
        }

        $this->execute(
            'DELETE FROM `' . $table . '`
             WHERE `id` IN (' . implode(', ', array_map('intval', $ids)) . ')'
        );
    }

    private function d(int $daysOffset): string
    {
        return (new \DateTimeImmutable('today'))
            ->modify(sprintf('%+d day', $daysOffset))
            ->format('Y-m-d');
    }

    private function dt(int $daysOffset, string $time): string
    {
        return $this->d($daysOffset) . ' ' . $time;
    }

    private function json(array $value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    }

    private function sqlValue(mixed $value): string
    {
        if ($value === null) {
            return 'NULL';
        }

        if (is_int($value) || is_float($value)) {
            return (string) $value;
        }

        return $this->q((string) $value);
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
