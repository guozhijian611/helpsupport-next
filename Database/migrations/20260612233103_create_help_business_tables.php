<?php

declare(strict_types=1);

use Phinx\Migration\AbstractMigration;

final class CreateHelpBusinessTables extends AbstractMigration
{
    private const TABLES = [
        'sa_content_category',
        'sa_content_material',
        'sa_material_collect',
        'sa_material_like',
        'sa_material_comment',
        'sa_material_comment_like',
        'sa_treatment_plan',
        'sa_treatment_stage',
        'sa_daily_task',
        'sa_member_assessment_result',
        'sa_doctor_patient',
        'sa_doctor_task_template_folder',
        'sa_doctor_task_template',
        'sa_doctor_assessment_scale',
        'sa_doctor_appointment',
        'sa_member_content_history',
        'sa_member_journal',
        'sa_member_memoir',
        'sa_member_message',
        'sa_member_recovery_goal_log',
        'sa_member_trigger_log',
    ];

    public function up(): void
    {
        foreach ($this->createTableSql() as $sql) {
            $this->execute($sql);
        }
    }

    public function down(): void
    {
        foreach (array_reverse(self::TABLES) as $table) {
            $this->execute(sprintf('DROP TABLE IF EXISTS `%s`', $table));
        }
    }

    /**
     * @return string[]
     */
    private function createTableSql(): array
    {
        return [
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_content_category` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `parent_id` int unsigned NOT NULL DEFAULT 0 COMMENT '父级分类ID',
    `name` varchar(80) NOT NULL COMMENT '分类名称',
    `name_i18n` json DEFAULT NULL COMMENT '多语言分类名称',
    `type` varchar(30) NOT NULL DEFAULT 'education' COMMENT '分类类型:education/entertainment/private',
    `icon` varchar(255) DEFAULT NULL COMMENT '分类图标',
    `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_parent_sort` (`parent_id`, `sort`),
    KEY `idx_type_status` (`type`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 内容分类表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_content_material` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL DEFAULT 0 COMMENT '作者会员ID,0为官方内容',
    `category_id` int unsigned NOT NULL DEFAULT 0 COMMENT '分类ID',
    `media_type` varchar(20) NOT NULL DEFAULT 'article' COMMENT '素材类型:article/video/audio/pdf/epub/link',
    `material_type` varchar(30) NOT NULL DEFAULT 'education' COMMENT '内容大类:education/entertainment/private',
    `title` varchar(160) NOT NULL COMMENT '素材标题',
    `title_i18n` json DEFAULT NULL COMMENT '多语言标题',
    `summary` varchar(500) DEFAULT NULL COMMENT '摘要',
    `cover_url` varchar(500) DEFAULT NULL COMMENT '封面图',
    `content_url` varchar(500) DEFAULT NULL COMMENT '媒体地址或外链',
    `content_text` longtext COMMENT '富文本内容',
    `tags` json DEFAULT NULL COMMENT '标签列表',
    `duration_seconds` int unsigned NOT NULL DEFAULT 0 COMMENT '音视频时长秒数',
    `is_public` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否公开:1公开,2私密',
    `is_recommended` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否推荐:1是,2否',
    `view_count` int unsigned NOT NULL DEFAULT 0 COMMENT '浏览量',
    `like_count` int unsigned NOT NULL DEFAULT 0 COMMENT '点赞数',
    `collect_count` int unsigned NOT NULL DEFAULT 0 COMMENT '收藏数',
    `comment_count` int unsigned NOT NULL DEFAULT 0 COMMENT '评论数',
    `audit_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '审核状态:1待审,2通过,3拒绝',
    `audit_remark` varchar(500) DEFAULT NULL COMMENT '审核备注',
    `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_category_status` (`category_id`, `status`),
    KEY `idx_member_public_status` (`member_id`, `is_public`, `status`),
    KEY `idx_material_type` (`material_type`, `media_type`),
    KEY `idx_recommend_sort` (`is_recommended`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 教育与娱乐素材表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_material_collect` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '收藏会员ID',
    `material_id` int unsigned NOT NULL COMMENT '素材ID',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_material` (`member_id`, `material_id`),
    KEY `idx_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 素材收藏表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_material_like` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '点赞会员ID',
    `material_id` int unsigned NOT NULL COMMENT '素材ID',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_material` (`member_id`, `material_id`),
    KEY `idx_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 素材点赞表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_material_comment` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `material_id` int unsigned NOT NULL COMMENT '素材ID',
    `member_id` int unsigned NOT NULL COMMENT '评论会员ID',
    `parent_id` int unsigned NOT NULL DEFAULT 0 COMMENT '父评论ID',
    `content` text COMMENT '评论内容',
    `attachments` json DEFAULT NULL COMMENT '附件列表',
    `like_count` int unsigned NOT NULL DEFAULT 0 COMMENT '点赞数',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1正常,2隐藏',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_material_id` (`material_id`),
    KEY `idx_member_id` (`member_id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 素材评论表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_material_comment_like` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '点赞会员ID',
    `comment_id` int unsigned NOT NULL COMMENT '评论ID',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_comment` (`member_id`, `comment_id`),
    KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 素材评论点赞表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_treatment_plan` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID',
    `doctor_id` int unsigned NOT NULL DEFAULT 0 COMMENT '医生会员ID,0为AI创建',
    `title` varchar(160) NOT NULL COMMENT '计划标题',
    `description` text COMMENT '计划说明',
    `start_date` date DEFAULT NULL COMMENT '开始日期',
    `end_date` date DEFAULT NULL COMMENT '结束日期',
    `source_type` varchar(20) NOT NULL DEFAULT 'manual' COMMENT '来源:manual/ai/template',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1进行中,2已完成,3已终止',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_doctor_status` (`doctor_id`, `status`),
    KEY `idx_date_range` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 治疗计划表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_treatment_stage` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `plan_id` int unsigned NOT NULL COMMENT '所属计划ID',
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID冗余',
    `stage_key` varchar(30) DEFAULT NULL COMMENT '阶段标识',
    `stage_name` varchar(80) NOT NULL COMMENT '阶段名称',
    `start_date` date NOT NULL COMMENT '阶段开始日期',
    `end_date` date NOT NULL COMMENT '阶段结束日期',
    `stage_target` varchar(500) DEFAULT NULL COMMENT '阶段目标',
    `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
    `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态:0待开始,1进行中,2完成',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_plan_sort` (`plan_id`, `sort`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_stage_key` (`stage_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 治疗计划阶段表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_daily_task` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID',
    `plan_id` int unsigned NOT NULL DEFAULT 0 COMMENT '计划ID',
    `stage_id` int unsigned NOT NULL DEFAULT 0 COMMENT '阶段ID',
    `task_date` date NOT NULL COMMENT '任务日期',
    `start_time` time DEFAULT NULL COMMENT '开始时间',
    `end_time` time DEFAULT NULL COMMENT '结束时间',
    `title` varchar(160) NOT NULL COMMENT '任务标题',
    `description` text COMMENT '任务描述',
    `task_type` varchar(30) NOT NULL DEFAULT 'daily' COMMENT '任务类型:daily/assessment/material/checkin',
    `source` varchar(20) NOT NULL DEFAULT 'timeline' COMMENT '来源:chat/timeline/manual/template',
    `source_id` varchar(80) DEFAULT NULL COMMENT '来源ID',
    `reminders` json DEFAULT NULL COMMENT '提醒规则',
    `attachments` json DEFAULT NULL COMMENT '附件列表',
    `points_reward` int NOT NULL DEFAULT 10 COMMENT '奖励积分',
    `completed_time` datetime DEFAULT NULL COMMENT '完成时间',
    `completion_note` varchar(500) DEFAULT NULL COMMENT '完成备注',
    `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态:0待办,1完成,2跳过,3延期',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_date` (`member_id`, `task_date`),
    KEY `idx_stage_date` (`stage_id`, `task_date`),
    KEY `idx_plan_date` (`plan_id`, `task_date`),
    KEY `idx_member_status` (`member_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 每日任务表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_assessment_result` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID',
    `doctor_id` int unsigned NOT NULL DEFAULT 0 COMMENT '医生会员ID',
    `task_id` int unsigned NOT NULL DEFAULT 0 COMMENT '关联任务ID',
    `assessment_id` varchar(64) DEFAULT NULL COMMENT '量表ID',
    `assessment_title` varchar(160) NOT NULL COMMENT '量表名称',
    `task_title` varchar(160) DEFAULT NULL COMMENT '任务标题',
    `stage_key` varchar(30) DEFAULT NULL COMMENT '阶段标识',
    `question_count` int unsigned NOT NULL DEFAULT 0 COMMENT '题目数',
    `total_score` int NOT NULL DEFAULT 0 COMMENT '总分',
    `achieved_score` int NOT NULL DEFAULT 0 COMMENT '实得分',
    `result_level` varchar(40) DEFAULT NULL COMMENT '评估等级',
    `answers` json DEFAULT NULL COMMENT '作答结果',
    `assessment_snapshot` json DEFAULT NULL COMMENT '量表快照',
    `suggestions` text COMMENT '评估建议',
    `assessed_at` datetime DEFAULT NULL COMMENT '评估时间',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_task` (`member_id`, `task_id`),
    KEY `idx_doctor_member` (`doctor_id`, `member_id`),
    KEY `idx_member_create_time` (`member_id`, `create_time`),
    KEY `idx_assessment_id` (`assessment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员量表提交结果表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_doctor_patient` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `doctor_id` int unsigned NOT NULL COMMENT '医生会员ID',
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1绑定中,2已解绑',
    `bind_source` varchar(20) NOT NULL DEFAULT 'manual' COMMENT '绑定来源:manual/system/appointment',
    `bind_time` datetime DEFAULT NULL COMMENT '绑定时间',
    `unbind_time` datetime DEFAULT NULL COMMENT '解绑时间',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_doctor_member` (`doctor_id`, `member_id`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_doctor_status` (`doctor_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生患者绑定关系表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_doctor_task_template_folder` (
    `id` varchar(64) NOT NULL COMMENT '主键ID',
    `doctor_id` int unsigned NOT NULL DEFAULT 0 COMMENT '医生会员ID,0为系统模板',
    `name` varchar(80) NOT NULL COMMENT '文件夹名称',
    `color` varchar(20) NOT NULL DEFAULT '#5E8FE6' COMMENT '主题颜色',
    `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_doctor_sort` (`doctor_id`, `sort`),
    KEY `idx_doctor_update_time` (`doctor_id`, `update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生任务模板文件夹表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_doctor_task_template` (
    `id` varchar(64) NOT NULL COMMENT '主键ID',
    `doctor_id` int unsigned NOT NULL DEFAULT 0 COMMENT '医生会员ID,0为系统模板',
    `folder_id` varchar(64) NOT NULL DEFAULT '' COMMENT '所属文件夹ID',
    `stage` varchar(30) NOT NULL DEFAULT '' COMMENT '所属阶段',
    `title` varchar(160) NOT NULL COMMENT '模板名称',
    `description` text COMMENT '模板描述',
    `task_type` varchar(30) NOT NULL DEFAULT 'daily' COMMENT '任务类型',
    `priority` varchar(20) NOT NULL DEFAULT 'normal' COMMENT '优先级',
    `start_time` varchar(5) NOT NULL DEFAULT '09:00' COMMENT '开始时间',
    `end_time` varchar(5) NOT NULL DEFAULT '09:30' COMMENT '结束时间',
    `frequency` varchar(20) NOT NULL DEFAULT 'daily' COMMENT '执行频率',
    `reward_score` int NOT NULL DEFAULT 0 COMMENT '奖励积分',
    `color` varchar(20) NOT NULL DEFAULT '#5E8FE6' COMMENT '主题颜色',
    `reminder_rule` json DEFAULT NULL COMMENT '提醒规则',
    `attachments` json DEFAULT NULL COMMENT '附件列表',
    `sort` int NOT NULL DEFAULT 100 COMMENT '排序',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1启用,2禁用',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_doctor_folder` (`doctor_id`, `folder_id`),
    KEY `idx_doctor_stage` (`doctor_id`, `stage`),
    KEY `idx_doctor_update_time` (`doctor_id`, `update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生任务模板表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_doctor_assessment_scale` (
    `id` varchar(64) NOT NULL COMMENT '主键ID',
    `doctor_id` int unsigned NOT NULL DEFAULT 0 COMMENT '医生会员ID,0为系统量表',
    `title` varchar(160) NOT NULL COMMENT '量表名称',
    `stage` varchar(30) NOT NULL DEFAULT '' COMMENT '所属阶段',
    `description` varchar(500) DEFAULT NULL COMMENT '量表简介',
    `total_score` int NOT NULL DEFAULT 0 COMMENT '量表总分',
    `questions` json DEFAULT NULL COMMENT '题目配置',
    `scoring_rule` json DEFAULT NULL COMMENT '评分规则',
    `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '状态:draft/published/disabled',
    `published_at` datetime DEFAULT NULL COMMENT '发布时间',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_doctor_stage` (`doctor_id`, `stage`),
    KEY `idx_doctor_status` (`doctor_id`, `status`),
    KEY `idx_doctor_update_time` (`doctor_id`, `update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生评估量表表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_doctor_appointment` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '患者会员ID',
    `doctor_id` int unsigned NOT NULL COMMENT '医生会员ID',
    `appoint_date` date NOT NULL COMMENT '预约日期',
    `appoint_time_slot` varchar(50) NOT NULL COMMENT '预约时间段',
    `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态:0待确认,1已确认,2已完成,3已取消,4已拒绝',
    `meet_type` varchar(20) DEFAULT NULL COMMENT '接诊方式:link/address/phone',
    `meet_link` varchar(500) DEFAULT NULL COMMENT '连线地址或接诊地点',
    `confirm_remark` varchar(500) DEFAULT NULL COMMENT '医生确认备注',
    `remark` varchar(500) DEFAULT NULL COMMENT '患者预约备注',
    `cancel_reason` varchar(500) DEFAULT NULL COMMENT '取消原因',
    `cancel_by` varchar(20) DEFAULT NULL COMMENT '取消方:member/doctor/system',
    `confirmed_at` datetime DEFAULT NULL COMMENT '确认时间',
    `finished_at` datetime DEFAULT NULL COMMENT '完成时间',
    `canceled_at` datetime DEFAULT NULL COMMENT '取消时间',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_doctor_date` (`doctor_id`, `appoint_date`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_doctor_slot_status` (`doctor_id`, `appoint_date`, `appoint_time_slot`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 医生预约表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_content_history` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `content_id` int unsigned NOT NULL COMMENT '内容ID',
    `content_type` varchar(30) NOT NULL COMMENT '内容类型',
    `title` varchar(160) NOT NULL COMMENT '内容标题',
    `author_name` varchar(80) DEFAULT NULL COMMENT '作者名称',
    `route` varchar(500) NOT NULL COMMENT '页面路由',
    `progress` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '浏览进度百分比',
    `duration_seconds` int unsigned NOT NULL DEFAULT 0 COMMENT '停留时长秒数',
    `viewed_at` datetime NOT NULL COMMENT '最近浏览时间',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_content` (`member_id`, `content_type`, `content_id`),
    KEY `idx_member_viewed_at` (`member_id`, `viewed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员内容浏览历史表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_journal` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `entry_date` date NOT NULL COMMENT '记录日期',
    `entry_time` time DEFAULT NULL COMMENT '记录时间',
    `title` varchar(120) NOT NULL COMMENT '标题',
    `content` text COMMENT '内容',
    `media` json DEFAULT NULL COMMENT '媒体列表',
    `mood_score` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '心情分值',
    `is_private` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否私密:1是,2否',
    `ai_access` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否允许AI访问:1是,2否',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1正常,2隐藏',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_date` (`member_id`, `entry_date`),
    KEY `idx_member_status` (`member_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员日记表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_memoir` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `grant_level_id` int unsigned NOT NULL DEFAULT 0 COMMENT '解锁等级ID',
    `grant_level_rank` int NOT NULL DEFAULT 0 COMMENT '解锁等级序号',
    `grant_level_name` varchar(80) NOT NULL DEFAULT '' COMMENT '解锁等级名称',
    `title` varchar(160) NOT NULL COMMENT '回忆录标题',
    `description` varchar(500) NOT NULL DEFAULT '' COMMENT '回忆录描述',
    `cover` varchar(500) NOT NULL DEFAULT '' COMMENT '封面图',
    `video_url` varchar(500) NOT NULL DEFAULT '' COMMENT '视频地址',
    `source_month` varchar(7) NOT NULL DEFAULT '' COMMENT '来源月份',
    `journal_count` int unsigned NOT NULL DEFAULT 0 COMMENT '日记数量',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1正常,2隐藏',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_member_level_rank` (`member_id`, `grant_level_rank`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_member_month` (`member_id`, `source_month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员专属回忆录表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_message` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '接收会员ID',
    `message_type` tinyint(1) NOT NULL COMMENT '消息类型:1关注,2回复,3任务,4预约,5系统',
    `title` varchar(160) NOT NULL COMMENT '消息标题',
    `content` varchar(1000) NOT NULL COMMENT '消息内容',
    `device_token` varchar(255) DEFAULT NULL COMMENT '设备推送token',
    `is_pushed` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否已推送:1是,2否',
    `push_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '推送状态:0待推送,1成功,2失败',
    `push_time` datetime DEFAULT NULL COMMENT '推送完成时间',
    `is_read` tinyint(1) NOT NULL DEFAULT 2 COMMENT '是否已读:1是,2否',
    `read_time` datetime DEFAULT NULL COMMENT '已读时间',
    `biz_type` varchar(50) DEFAULT NULL COMMENT '业务类型',
    `biz_id` int unsigned NOT NULL DEFAULT 0 COMMENT '业务ID',
    `route` varchar(500) DEFAULT NULL COMMENT '跳转路由',
    `ext` json DEFAULT NULL COMMENT '扩展信息',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1有效,2禁用',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_read_status` (`member_id`, `is_read`, `status`),
    KEY `idx_member_type` (`member_id`, `message_type`),
    KEY `idx_member_push_status` (`member_id`, `is_pushed`, `push_status`, `status`),
    KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员消息中心表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_recovery_goal_log` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `goal_text` varchar(500) NOT NULL COMMENT '恢复目标',
    `goal_type` varchar(30) NOT NULL DEFAULT 'custom' COMMENT '目标类型:custom/weekly/monthly',
    `target_date` date DEFAULT NULL COMMENT '目标日期',
    `completed_time` datetime DEFAULT NULL COMMENT '完成时间',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1进行中,2已完成,3已放弃',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_status` (`member_id`, `status`),
    KEY `idx_member_target_date` (`member_id`, `target_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员恢复目标记录表'
SQL,
            <<<'SQL'
CREATE TABLE IF NOT EXISTS `sa_member_trigger_log` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `member_id` int unsigned NOT NULL COMMENT '会员ID',
    `trigger_name` varchar(120) NOT NULL COMMENT '触发因素名称',
    `trigger_type` varchar(30) NOT NULL DEFAULT 'custom' COMMENT '触发类型:emotion/place/person/custom',
    `intensity` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '强度0-10',
    `occurred_at` datetime NOT NULL COMMENT '发生时间',
    `response_action` varchar(500) DEFAULT NULL COMMENT '应对动作',
    `note` text COMMENT '记录说明',
    `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态:1有效,2忽略',
    `remark` varchar(255) DEFAULT NULL COMMENT '备注',
    `created_by` int(11) DEFAULT NULL COMMENT '创建者',
    `updated_by` int(11) DEFAULT NULL COMMENT '更新者',
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_member_occurred` (`member_id`, `occurred_at`),
    KEY `idx_member_type` (`member_id`, `trigger_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='HelpSupport 会员触发因素记录表'
SQL,
        ];
    }
}
