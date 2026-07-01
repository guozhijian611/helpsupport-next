<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateHelpCoreTables extends AbstractMigration
{
    private const REMARK = 'phinx:20260612230839_create_help_core_tables';

    public function up(): void
    {
        $this->createMemberTables();
        $this->createPushTables();
        $this->createCommunityTables();
        $this->createChatTables();
        $this->createLocalModelTables();
        $this->createOnboardingTable();
        $this->seedPlatforms();
        $this->seedOauthConfig();
    }

    public function down(): void
    {
        foreach ([
            'sa_app_onboarding_page',
            'sa_local_model_prompt',
            'sa_local_model_catalog',
            'sa_member_chat_record',
            'sa_member_chat_session',
            'sa_member_chat_config',
            'sa_community_report',
            'sa_community_follow_member',
            'sa_community_follow_tag',
            'sa_community_collect',
            'sa_community_like',
            'sa_community_comment',
            'sa_community_post',
            'sa_community_tag',
            'sa_member_push_preference',
            'sa_member_push_device',
            'sa_help_doctor_profile',
            'sa_help_member_profile',
        ] as $table) {
            $this->execute("DROP TABLE IF EXISTS `{$table}`");
        }

        $this->deleteOauthConfig();
        $this->execute(
            'DELETE FROM `sa_member_platform`
             WHERE `platform_code` IN (' . $this->q('GOOGLE') . ', ' . $this->q('APPLE') . ')
               AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_member_platform_rel`
                   WHERE `sa_member_platform_rel`.`platform_id` = `sa_member_platform`.`id`
                     AND `sa_member_platform_rel`.`delete_time` IS NULL
               )'
        );
    }

    private function createMemberTables(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_help_member_profile` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `member_role` varchar(20) NOT NULL DEFAULT 'patient' COMMENT '业务身份 patient/doctor',
                `gender` tinyint(1) NOT NULL DEFAULT 3 COMMENT '性别 1男 2女 3保密',
                `birthday` date DEFAULT NULL COMMENT '生日',
                `bio` varchar(500) NOT NULL DEFAULT '' COMMENT '个人简介',
                `profile_background` varchar(500) NOT NULL DEFAULT '' COMMENT '个人主页背景图',
                `recovery_goal` varchar(500) NOT NULL DEFAULT '' COMMENT '康复目标',
                `trigger_tags` json DEFAULT NULL COMMENT '重点触发因素',
                `locale` varchar(20) NOT NULL DEFAULT 'en-US' COMMENT '当前语言',
                `timezone` varchar(64) NOT NULL DEFAULT '' COMMENT '当前时区',
                `onboarding_version` varchar(50) NOT NULL DEFAULT '' COMMENT '已看引导版本',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1正常 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_id` (`member_id`) USING BTREE,
                KEY `idx_role_status` (`member_role`, `status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='HelpSupport会员扩展资料表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_help_doctor_profile` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '医生会员ID',
                `real_name` varchar(80) NOT NULL DEFAULT '' COMMENT '真实姓名',
                `title` varchar(80) NOT NULL DEFAULT '' COMMENT '职称',
                `hospital` varchar(160) NOT NULL DEFAULT '' COMMENT '医院/机构',
                `department` varchar(120) NOT NULL DEFAULT '' COMMENT '科室',
                `specialty` varchar(500) NOT NULL DEFAULT '' COMMENT '专业方向',
                `license_no` varchar(120) NOT NULL DEFAULT '' COMMENT '执业证书编号',
                `certification_images` json DEFAULT NULL COMMENT '证书图片数组',
                `audit_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态 0待审核 1已通过 2已拒绝',
                `audit_remark` varchar(500) NOT NULL DEFAULT '' COMMENT '审核备注',
                `audit_by` int(11) DEFAULT NULL COMMENT '审核人',
                `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
                `approved_time` datetime DEFAULT NULL COMMENT '通过时间',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1正常 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_id` (`member_id`) USING BTREE,
                KEY `idx_audit_status` (`audit_status`) USING BTREE,
                KEY `idx_status` (`status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='HelpSupport医生资质资料表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createPushTables(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_member_push_device` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `device_id` varchar(128) NOT NULL DEFAULT '' COMMENT '设备标识',
                `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '平台 ios/android',
                `fcm_token` varchar(512) NOT NULL DEFAULT '' COMMENT 'FCM Token',
                `apns_token` varchar(512) NOT NULL DEFAULT '' COMMENT 'APNs Token',
                `app_version` varchar(50) NOT NULL DEFAULT '' COMMENT 'App版本',
                `locale` varchar(20) NOT NULL DEFAULT 'en-US' COMMENT '当前语言',
                `timezone` varchar(64) NOT NULL DEFAULT '' COMMENT '当前时区',
                `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否有效 1是 2否',
                `last_active_time` datetime DEFAULT NULL COMMENT '最近活跃时间',
                `logout_time` datetime DEFAULT NULL COMMENT '退出或踢下线时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_device_platform` (`member_id`, `device_id`, `platform`) USING BTREE,
                KEY `idx_member_active` (`member_id`, `is_active`) USING BTREE,
                KEY `idx_fcm_token` (`fcm_token`(191)) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员推送设备表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_member_push_preference` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `is_push_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '总通知开关 1是 2否',
                `is_task_reminder_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '任务提醒 1是 2否',
                `is_community_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '社区互动 1是 2否',
                `is_appointment_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '预约提醒 1是 2否',
                `is_audit_notice_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核/系统通知 1是 2否',
                `is_local_companion_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '本地陪伴提醒 1是 2否',
                `quiet_start_time` time DEFAULT NULL COMMENT '免打扰开始时间',
                `quiet_end_time` time DEFAULT NULL COMMENT '免打扰结束时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_id` (`member_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员推送偏好表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createCommunityTables(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_tag` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `tag_name` varchar(50) NOT NULL COMMENT '标签名称',
                `tag_name_i18n` json DEFAULT NULL COMMENT '多语言标签名',
                `color` varchar(20) NOT NULL DEFAULT '' COMMENT '标签颜色',
                `sort` int(11) NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_status_sort` (`status`, `sort`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区标签表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_post` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '发帖会员ID',
                `content` text NOT NULL COMMENT '帖子内容',
                `images` json DEFAULT NULL COMMENT '图片URL数组',
                `link_url` varchar(500) NOT NULL DEFAULT '' COMMENT '链接',
                `tags` json DEFAULT NULL COMMENT '标签数组',
                `is_anonymous` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否匿名 1是 2否',
                `is_doctor_post` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否医生帖 1是 2否',
                `view_count` int(11) NOT NULL DEFAULT 0 COMMENT '浏览数',
                `like_count` int(11) NOT NULL DEFAULT 0 COMMENT '点赞数',
                `comment_count` int(11) NOT NULL DEFAULT 0 COMMENT '评论数',
                `collect_count` int(11) NOT NULL DEFAULT 0 COMMENT '收藏数',
                `is_top` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否置顶 1是 2否',
                `audit_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核状态 0待审核 1已通过 2已拒绝 3AI预审标记',
                `audit_remark` varchar(500) NOT NULL DEFAULT '' COMMENT '审核备注',
                `audit_by` int(11) DEFAULT NULL COMMENT '审核人',
                `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1正常 2隐藏 3封禁',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_member_id` (`member_id`) USING BTREE,
                KEY `idx_audit_status` (`audit_status`) USING BTREE,
                KEY `idx_create_time` (`create_time`) USING BTREE,
                KEY `idx_status_top` (`status`, `is_top`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区帖子表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_comment` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `post_id` bigint(20) unsigned NOT NULL COMMENT '帖子ID',
                `member_id` int(11) NOT NULL COMMENT '评论会员ID',
                `parent_id` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '父评论ID',
                `reply_to_member_id` int(11) DEFAULT NULL COMMENT '回复目标会员ID',
                `content` text NOT NULL COMMENT '评论内容',
                `attachments` json DEFAULT NULL COMMENT '附件数组',
                `is_anonymous` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否匿名 1是 2否',
                `like_count` int(11) NOT NULL DEFAULT 0 COMMENT '点赞数',
                `audit_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核状态 0待审核 1已通过 2已拒绝',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1正常 2隐藏',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_post_id` (`post_id`) USING BTREE,
                KEY `idx_member_id` (`member_id`) USING BTREE,
                KEY `idx_parent_id` (`parent_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区评论表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_like` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `target_type` tinyint(1) NOT NULL COMMENT '目标类型 1帖子 2评论',
                `target_id` bigint(20) unsigned NOT NULL COMMENT '目标ID',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_target` (`member_id`, `target_type`, `target_id`) USING BTREE,
                KEY `idx_target` (`target_type`, `target_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区点赞表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_collect` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `post_id` bigint(20) unsigned NOT NULL COMMENT '帖子ID',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_post` (`member_id`, `post_id`) USING BTREE,
                KEY `idx_post_id` (`post_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区收藏表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_follow_tag` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `tag_id` bigint(20) unsigned NOT NULL COMMENT '标签ID',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_tag` (`member_id`, `tag_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区关注标签表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_follow_member` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `target_member_id` int(11) NOT NULL COMMENT '被关注会员ID',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_target_member` (`member_id`, `target_member_id`) USING BTREE,
                KEY `idx_target_member` (`target_member_id`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区关注会员表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_community_report` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '举报会员ID',
                `target_type` tinyint(1) NOT NULL COMMENT '举报类型 1帖子 2评论 3用户',
                `target_id` bigint(20) unsigned NOT NULL COMMENT '举报目标ID',
                `reason` varchar(100) NOT NULL COMMENT '举报原因',
                `description` varchar(500) NOT NULL DEFAULT '' COMMENT '举报描述',
                `handle_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '处理状态 0待处理 1已处理 2已忽略',
                `handle_remark` varchar(500) NOT NULL DEFAULT '' COMMENT '处理备注',
                `handle_by` int(11) DEFAULT NULL COMMENT '处理人',
                `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_target` (`target_type`, `target_id`) USING BTREE,
                KEY `idx_handle_status` (`handle_status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区举报表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createChatTables(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_member_chat_config` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `chat_mode` varchar(50) NOT NULL COMMENT '模式 doctor/companion/patient',
                `prompt_text` text COMMENT '用户模式描述和前置提示',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_member_mode` (`member_id`, `chat_mode`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员AI聊天预置配置表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_member_chat_session` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `chat_mode` varchar(50) NOT NULL COMMENT '会话模式 doctor/companion/patient',
                `session_name` varchar(100) NOT NULL DEFAULT '' COMMENT '会话名称',
                `last_message` varchar(500) NOT NULL DEFAULT '' COMMENT '最后消息摘要',
                `last_message_time` datetime DEFAULT NULL COMMENT '最后消息时间',
                `is_pinned` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否置顶 1是 2否',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1有效 2无效',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_member_mode_status` (`member_id`, `chat_mode`, `status`) USING BTREE,
                KEY `idx_member_last_time` (`member_id`, `last_message_time`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员AI聊天会话表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_member_chat_record` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `session_id` bigint(20) unsigned NOT NULL COMMENT '会话ID',
                `member_id` int(11) NOT NULL COMMENT '会员ID',
                `chat_mode` varchar(50) NOT NULL COMMENT '会话模式 doctor/companion/patient',
                `role` varchar(20) NOT NULL DEFAULT 'user' COMMENT '消息角色 user/assistant/system',
                `content` text NOT NULL COMMENT '消息内容',
                `content_type` varchar(20) NOT NULL DEFAULT 'text' COMMENT '内容类型 text/image/file',
                `token_count` int(11) NOT NULL DEFAULT 0 COMMENT 'Token消耗数',
                `message_time` datetime DEFAULT NULL COMMENT '消息时间',
                `ext` json DEFAULT NULL COMMENT '扩展信息',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1有效 2无效',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_session_time` (`session_id`, `message_time`) USING BTREE,
                KEY `idx_member_mode_status` (`member_id`, `chat_mode`, `status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员AI聊天记录表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createLocalModelTables(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_local_model_catalog` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `name` varchar(120) NOT NULL COMMENT '模型显示名称',
                `code` varchar(80) NOT NULL COMMENT '模型编码',
                `provider` varchar(80) NOT NULL DEFAULT '' COMMENT '模型来源',
                `model_family` varchar(80) NOT NULL DEFAULT '' COMMENT '模型家族',
                `quantization` varchar(40) NOT NULL DEFAULT '' COMMENT '量化类型',
                `file_size` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '文件大小字节',
                `download_url` varchar(1000) NOT NULL DEFAULT '' COMMENT '模型下载地址',
                `sha256` varchar(64) NOT NULL DEFAULT '' COMMENT 'SHA256校验值',
                `intro` varchar(1000) NOT NULL DEFAULT '' COMMENT '默认介绍',
                `intro_i18n` json DEFAULT NULL COMMENT '多语言介绍',
                `license` varchar(255) NOT NULL DEFAULT '' COMMENT '许可证说明',
                `min_memory_mb` int(11) NOT NULL DEFAULT 0 COMMENT '推荐最小内存MB',
                `context_size` int(11) NOT NULL DEFAULT 0 COMMENT '默认上下文长度',
                `default_temperature` decimal(4,2) NOT NULL DEFAULT 0.70 COMMENT '默认温度',
                `default_top_p` decimal(4,2) NOT NULL DEFAULT 0.90 COMMENT '默认top_p',
                `sort` int(11) NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE KEY `uk_code` (`code`) USING BTREE,
                KEY `idx_status_sort` (`status`, `sort`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='本地模型目录表' ROW_FORMAT=DYNAMIC"
        );

        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_local_model_prompt` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `model_id` bigint(20) unsigned DEFAULT NULL COMMENT '关联模型ID，空表示通用提示词',
                `chat_mode` varchar(50) NOT NULL COMMENT '聊天模式 doctor/companion/patient',
                `locale` varchar(20) NOT NULL DEFAULT 'en-US' COMMENT '语言',
                `title` varchar(160) NOT NULL DEFAULT '' COMMENT '提示词标题',
                `system_prompt` text COMMENT '系统提示词',
                `first_message` varchar(1000) NOT NULL DEFAULT '' COMMENT '默认开场白',
                `safety_prompt` text COMMENT '安全边界提示',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_model_mode_locale` (`model_id`, `chat_mode`, `locale`) USING BTREE,
                KEY `idx_status` (`status`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='本地模型提示词表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function createOnboardingTable(): void
    {
        $this->execute(
            "CREATE TABLE IF NOT EXISTS `sa_app_onboarding_page` (
                `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
                `scene` varchar(50) NOT NULL DEFAULT 'first_launch' COMMENT '场景',
                `version` varchar(50) NOT NULL DEFAULT '' COMMENT '配置版本',
                `locale` varchar(20) NOT NULL DEFAULT 'en-US' COMMENT '语言',
                `title` varchar(160) NOT NULL DEFAULT '' COMMENT '标题',
                `description` varchar(1000) NOT NULL DEFAULT '' COMMENT '说明',
                `image` varchar(1000) NOT NULL DEFAULT '' COMMENT '图片URL或附件路径',
                `button_text` varchar(120) NOT NULL DEFAULT '' COMMENT '按钮文案',
                `action_type` varchar(40) NOT NULL DEFAULT 'next' COMMENT '动作类型 next/skip/route/external_url',
                `action_value` varchar(500) NOT NULL DEFAULT '' COMMENT '动作值',
                `sort` int(11) NOT NULL DEFAULT 100 COMMENT '排序',
                `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 2禁用',
                `start_time` datetime DEFAULT NULL COMMENT '生效开始时间',
                `end_time` datetime DEFAULT NULL COMMENT '生效结束时间',
                `created_by` int(11) DEFAULT NULL COMMENT '创建者',
                `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
                `create_time` datetime DEFAULT NULL COMMENT '创建时间',
                `update_time` datetime DEFAULT NULL COMMENT '修改时间',
                `delete_time` datetime DEFAULT NULL COMMENT '删除时间',
                PRIMARY KEY (`id`) USING BTREE,
                KEY `idx_scene_version_locale_status` (`scene`, `version`, `locale`, `status`) USING BTREE,
                KEY `idx_sort` (`sort`) USING BTREE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='App引导页配置表' ROW_FORMAT=DYNAMIC"
        );
    }

    private function seedPlatforms(): void
    {
        foreach ([
            ['Google', 'GOOGLE', 'HelpSupport Google 登录平台'],
            ['Apple', 'APPLE', 'HelpSupport Apple 登录平台'],
        ] as [$name, $code, $remark]) {
            $this->execute(
                'INSERT INTO `sa_member_platform` (`platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`, `delete_time`)
                 SELECT ' . $this->q($name) . ', ' . $this->q($code) . ', 1, ' . $this->q(self::REMARK . ':' . $remark) . ', NOW(), NOW(), NULL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM `sa_member_platform`
                     WHERE `platform_code` = ' . $this->q($code) . '
                       AND `delete_time` IS NULL
                 )'
            );
        }
    }

    private function seedOauthConfig(): void
    {
        $enabledOptions = [
            ['label' => '启用', 'value' => '1'],
            ['label' => '禁用', 'value' => '2'],
        ];
        $groups = [
            'help_google_oauth' => [
                'name' => 'Google 登录',
                'remark' => 'HelpSupport Flutter Google 登录配置。服务端校验 Google ID Token 后复用 saiuser 会员体系。',
                'items' => [
                    ['web_client_id', 'Web Client ID', '', 'input', 100, 'Google Web Client ID，用于服务端校验 aud。'],
                    ['ios_client_id', 'iOS Client ID', '', 'input', 90, 'Google iOS Client ID。'],
                    ['android_client_id', 'Android Client ID', '', 'input', 80, 'Google Android Client ID。'],
                    ['enabled', '启用状态', '2', 'radio', 70, '1启用 2禁用。', $enabledOptions],
                ],
            ],
            'help_apple_oauth' => [
                'name' => 'Apple 登录',
                'remark' => 'HelpSupport Flutter Apple 登录配置。服务端校验 Apple identityToken 后复用 saiuser 会员体系。',
                'items' => [
                    ['team_id', 'Team ID', '', 'input', 100, 'Apple Developer Team ID。'],
                    ['bundle_id', 'Bundle ID', '', 'input', 90, 'iOS App Bundle ID。'],
                    ['service_id', 'Service ID', '', 'input', 80, 'Web/Android 场景使用的 Services ID。'],
                    ['key_id', 'Key ID', '', 'input', 70, 'Sign in with Apple 私钥 Key ID。'],
                    ['private_key', 'Private Key', '', 'textarea', 60, 'Sign in with Apple 私钥内容，生产环境应通过安全配置注入。'],
                    ['enabled', '启用状态', '2', 'radio', 50, '1启用 2禁用。', $enabledOptions],
                ],
            ],
            'help_firebase_push' => [
                'name' => 'Firebase 推送',
                'remark' => 'HelpSupport Firebase Cloud Messaging 服务端推送配置。',
                'items' => [
                    ['project_id', 'Firebase Project ID', '', 'input', 100, 'Firebase 项目 ID。'],
                    ['service_account_json', 'Service Account JSON', '', 'textarea', 90, '服务端 FCM 发送使用的 Service Account JSON，生产环境应通过安全配置注入。'],
                    ['enabled', '启用状态', '2', 'radio', 80, '1启用 2禁用。', $enabledOptions],
                ],
            ],
        ];

        foreach ($groups as $code => $group) {
            $this->insertConfigGroup($code, $group['name'], $group['remark']);
            foreach ($group['items'] as $item) {
                [$key, $name, $value, $inputType, $sort, $remark] = $item;
                $this->insertConfigItem($code, $key, $name, $value, $inputType, $sort, $remark, $item[6] ?? null);
            }
        }
    }

    private function deleteOauthConfig(): void
    {
        foreach (['help_google_oauth', 'help_apple_oauth', 'help_firebase_push'] as $code) {
            $this->execute(
                'DELETE FROM `sa_system_config`
                 WHERE `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND `group_id` IN (
                       SELECT `id` FROM `sa_system_config_group`
                       WHERE `code` = ' . $this->q($code) . '
                   )'
            );
            $this->execute(
                'DELETE FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q($code) . '
                   AND `remark` LIKE ' . $this->q(self::REMARK . ':%') . '
                   AND NOT EXISTS (
                       SELECT 1 FROM `sa_system_config`
                       WHERE `sa_system_config`.`group_id` = `sa_system_config_group`.`id`
                   )'
            );
        }
    }

    private function insertConfigGroup(string $code, string $name, string $remark): void
    {
        $this->execute(
            'INSERT INTO `sa_system_config_group` (`name`, `code`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT ' . $this->q($name) . ', ' . $this->q($code) . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             WHERE NOT EXISTS (
                 SELECT 1 FROM `sa_system_config_group`
                 WHERE `code` = ' . $this->q($code) . '
                   AND `delete_time` IS NULL
             )'
        );
    }

    private function insertConfigItem(string $groupCode, string $key, string $name, string $value, string $inputType, int $sort, string $remark, ?array $selectData = null): void
    {
        $this->execute(
            'INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `config_select_data`, `sort`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`, `delete_time`)
             SELECT `id`, ' . $this->q($key) . ', ' . $this->q($value) . ', ' . $this->q($name) . ', ' . $this->q($inputType) . ', ' . $this->configSelectDataSql($selectData) . ', ' . $sort . ', ' . $this->q(self::REMARK . ':' . $remark) . ', 1, 1, NOW(), NOW(), NULL
             FROM `sa_system_config_group`
             WHERE `code` = ' . $this->q($groupCode) . '
               AND `delete_time` IS NULL
               AND NOT EXISTS (
                   SELECT 1 FROM `sa_system_config`
                   WHERE `group_id` = `sa_system_config_group`.`id`
                     AND `key` = ' . $this->q($key) . '
                     AND `delete_time` IS NULL
               )
             LIMIT 1'
        );
    }

    private function configSelectDataSql(?array $selectData): string
    {
        if ($selectData === null) {
            return 'NULL';
        }

        return $this->q($this->json($selectData));
    }

    private function json(array $value): string
    {
        return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '[]';
    }

    private function q(mixed $value): string
    {
        return $this->getAdapter()->getConnection()->quote((string) $value);
    }
}
