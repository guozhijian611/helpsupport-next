-- HelpSupport 插件安装脚本
-- 说明：
-- 1. 本脚本仅维护 help 插件业务表，不覆盖 saiadmin/saiuser 的基础表。
-- 2. 依赖 sa_member 表已存在（来自 saiuser 插件）。

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 会员基础字段补齐
SET @sa_member_has_gender := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sa_member'
    AND COLUMN_NAME = 'gender'
);
SET @sa_member_gender_sql := IF(
  @sa_member_has_gender = 0,
  'ALTER TABLE `sa_member` ADD COLUMN `gender` tinyint(1) NOT NULL DEFAULT 0 COMMENT ''性别：1-男，2-女，3-保密'' AFTER `email`',
  'SELECT 1'
);
PREPARE sa_member_gender_stmt FROM @sa_member_gender_sql;
EXECUTE sa_member_gender_stmt;
DEALLOCATE PREPARE sa_member_gender_stmt;

SET @sa_member_has_birthday := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sa_member'
    AND COLUMN_NAME = 'birthday'
);
SET @sa_member_birthday_sql := IF(
  @sa_member_has_birthday = 0,
  'ALTER TABLE `sa_member` ADD COLUMN `birthday` date NULL DEFAULT NULL COMMENT ''出生日期'' AFTER `gender`',
  'SELECT 1'
);
PREPARE sa_member_birthday_stmt FROM @sa_member_birthday_sql;
EXECUTE sa_member_birthday_stmt;
DEALLOCATE PREPARE sa_member_birthday_stmt;

-- 第三方登录平台
INSERT INTO `sa_member_platform` (`platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`)
SELECT 'Google', 'GOOGLE', 1, 'H5 端 Google OAuth 登录', NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM `sa_member_platform` WHERE `platform_code` = 'GOOGLE' AND `delete_time` IS NULL
);

INSERT INTO `sa_member_platform` (`platform_name`, `platform_code`, `status`, `remark`, `create_time`, `update_time`)
SELECT 'Apple', 'APPLE', 1, 'H5 端 Apple OAuth 登录', NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM `sa_member_platform` WHERE `platform_code` = 'APPLE' AND `delete_time` IS NULL
);

-- 第三方登录配置组
INSERT INTO `sa_system_config_group` (`name`, `code`, `remark`, `create_time`, `update_time`)
SELECT 'Google 登录', 'help_google_oauth', 'H5 端 Google OAuth 登录配置', NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM `sa_system_config_group` WHERE `code` = 'help_google_oauth' AND `delete_time` IS NULL
);

UPDATE `sa_system_config_group`
SET `name` = 'Google 登录',
    `remark` = '用于 HelpSupport H5 端 Google OAuth 登录。请填写 Google Cloud Console 的 Web Client ID / Client Secret，回调地址请以后台配置页实时展示为准。',
    `update_time` = NOW()
WHERE `code` = 'help_google_oauth' AND `delete_time` IS NULL;

INSERT INTO `sa_system_config_group` (`name`, `code`, `remark`, `create_time`, `update_time`)
SELECT 'Apple 登录', 'help_apple_oauth', 'H5 端 Apple OAuth 登录配置', NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM `sa_system_config_group` WHERE `code` = 'help_apple_oauth' AND `delete_time` IS NULL
);

UPDATE `sa_system_config_group`
SET `name` = 'Apple 登录',
    `remark` = '用于 HelpSupport H5 端 Apple OAuth 登录。请填写 Apple Services ID 与生成好的 client secret JWT，回调地址请以后台配置页实时展示为准。',
    `update_time` = NOW()
WHERE `code` = 'help_apple_oauth' AND `delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'client_id', '', 'Client ID', 'input', 100, 'Google OAuth Web Client ID', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_google_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'client_id' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = 'Client ID',
    c.`input_type` = 'input',
    c.`sort` = 100,
    c.`remark` = '填写 Google Cloud Console 中 Web 应用的 Client ID。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_google_oauth' AND c.`key` = 'client_id' AND c.`delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'client_secret', '', 'Client Secret', 'textarea', 90, 'Google OAuth Web Client Secret', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_google_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'client_secret' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = 'Client Secret',
    c.`input_type` = 'textarea',
    c.`sort` = 90,
    c.`remark` = '填写与上方 Client ID 对应的 Client Secret。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_google_oauth' AND c.`key` = 'client_secret' AND c.`delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'scopes', 'openid email profile', '授权范围', 'input', 80, '多个 scope 以空格分隔', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_google_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'scopes' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = '授权范围',
    c.`input_type` = 'input',
    c.`sort` = 80,
    c.`remark` = '默认建议保留 openid email profile，多个 scope 用空格分隔。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_google_oauth' AND c.`key` = 'scopes' AND c.`delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'client_id', '', 'Client ID', 'input', 100, 'Apple Services ID', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_apple_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'client_id' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = 'Client ID',
    c.`input_type` = 'input',
    c.`sort` = 100,
    c.`remark` = '填写 Apple Developer 中配置的 Services ID。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_apple_oauth' AND c.`key` = 'client_id' AND c.`delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'client_secret', '', 'Client Secret', 'textarea', 90, 'Apple 生成的 client secret JWT', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_apple_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'client_secret' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = 'Client Secret',
    c.`input_type` = 'textarea',
    c.`sort` = 90,
    c.`remark` = '填写 Apple Developer 生成的 client secret JWT，不是原始私钥文件内容。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_apple_oauth' AND c.`key` = 'client_secret' AND c.`delete_time` IS NULL;

INSERT INTO `sa_system_config` (`group_id`, `key`, `value`, `name`, `input_type`, `sort`, `remark`, `create_time`, `update_time`)
SELECT g.`id`, 'scopes', 'name email', '授权范围', 'input', 80, '多个 scope 以空格分隔', NOW(), NOW()
FROM `sa_system_config_group` g
WHERE g.`code` = 'help_apple_oauth'
  AND NOT EXISTS (
    SELECT 1 FROM `sa_system_config` c
    WHERE c.`group_id` = g.`id` AND c.`key` = 'scopes' AND c.`delete_time` IS NULL
  );

UPDATE `sa_system_config` c
JOIN `sa_system_config_group` g ON g.`id` = c.`group_id`
SET c.`name` = '授权范围',
    c.`input_type` = 'input',
    c.`sort` = 80,
    c.`remark` = '默认建议保留 name email，多个 scope 用空格分隔。',
    c.`update_time` = NOW()
WHERE g.`code` = 'help_apple_oauth' AND c.`key` = 'scopes' AND c.`delete_time` IS NULL;

-- 社区标签
CREATE TABLE IF NOT EXISTS `sa_community_tag` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(50) NOT NULL COMMENT '标签名称',
  `tag_name_en` varchar(50) DEFAULT NULL COMMENT '英文标签名',
  `color` varchar(20) DEFAULT NULL COMMENT '标签颜色',
  `sort` int NOT NULL DEFAULT '100' COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=启用, 2=禁用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区标签';

-- 社区帖子
CREATE TABLE IF NOT EXISTS `sa_community_post` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '发帖用户ID',
  `content` text NOT NULL COMMENT '帖子内容',
  `images` json DEFAULT NULL COMMENT '图片URL数组',
  `link_url` varchar(500) DEFAULT NULL COMMENT '链接',
  `tags` json DEFAULT NULL COMMENT '标签数组',
  `is_anonymous` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否匿名：0=否, 1=是',
  `is_doctor_post` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否医生帖：0=否, 1=是',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '浏览数',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `comment_count` int NOT NULL DEFAULT '0' COMMENT '评论数',
  `collect_count` int NOT NULL DEFAULT '0' COMMENT '收藏数',
  `is_top` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否置顶',
  `audit_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '审核状态：0=待审核, 1=已通过, 2=已拒绝, 3=AI预审标记',
  `audit_remark` varchar(255) DEFAULT NULL COMMENT '审核备注',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=正常, 2=隐藏, 3=封禁',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_audit_status` (`audit_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区帖子';

-- 社区评论
CREATE TABLE IF NOT EXISTS `sa_community_comment` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `post_id` int NOT NULL COMMENT '帖子ID',
  `member_id` int NOT NULL COMMENT '评论用户ID',
  `parent_id` int NOT NULL DEFAULT '0' COMMENT '父评论ID（0=一级评论）',
  `reply_to_member_id` int DEFAULT NULL COMMENT '回复目标用户ID',
  `content` text NOT NULL COMMENT '评论内容',
  `attachments` json DEFAULT NULL COMMENT '评论附件URL数组',
  `is_anonymous` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否匿名',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `audit_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '审核状态：0=待审核, 1=已通过, 2=已拒绝',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=正常, 2=隐藏',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_post_id` (`post_id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区评论';

-- 社区点赞
CREATE TABLE IF NOT EXISTS `sa_community_like` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '用户ID',
  `target_type` tinyint(1) NOT NULL COMMENT '目标类型：1=帖子, 2=评论',
  `target_id` int NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_target` (`member_id`,`target_type`,`target_id`),
  KEY `idx_target` (`target_type`,`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区点赞';

-- 社区收藏
CREATE TABLE IF NOT EXISTS `sa_community_collect` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '用户ID',
  `post_id` int NOT NULL COMMENT '帖子ID',
  `create_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_post` (`member_id`,`post_id`),
  KEY `idx_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区收藏';

-- 关注标签
CREATE TABLE IF NOT EXISTS `sa_community_follow_tag` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '用户ID',
  `tag_id` int NOT NULL COMMENT '标签ID',
  `create_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_tag` (`member_id`,`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='关注标签';

-- 关注用户
CREATE TABLE IF NOT EXISTS `sa_community_follow_member` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '用户ID',
  `target_member_id` int NOT NULL COMMENT '被关注用户ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_target_member` (`member_id`,`target_member_id`),
  KEY `idx_target_member` (`target_member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户关注关系表';

-- 社区举报
CREATE TABLE IF NOT EXISTS `sa_community_report` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '举报人ID',
  `target_type` tinyint(1) NOT NULL COMMENT '举报类型：1=帖子, 2=评论, 3=用户',
  `target_id` int NOT NULL COMMENT '举报目标ID',
  `reason` varchar(50) NOT NULL COMMENT '举报原因分类',
  `description` varchar(500) DEFAULT NULL COMMENT '举报详细描述',
  `handle_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '处理状态：0=待处理, 1=已处理, 2=已忽略',
  `handle_remark` varchar(255) DEFAULT NULL COMMENT '处理备注',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_target` (`target_type`,`target_id`),
  KEY `idx_handle_status` (`handle_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区举报';

-- 内容分类
CREATE TABLE IF NOT EXISTS `sa_content_category` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL COMMENT '分类名称:入门/动机/应对技能/电影等',
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '大类：1=医疗教育, 2=娱乐资源',
  `sort` int NOT NULL DEFAULT '100',
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='资源分类表';

-- 教育与娱乐素材
CREATE TABLE IF NOT EXISTS `sa_content_material` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL DEFAULT '0' COMMENT '作者ID(0代表官方发布, 大于0代表用户私人上传)',
  `category_id` int NOT NULL COMMENT '分类ID',
  `media_type` varchar(20) NOT NULL COMMENT '资源类型：article/video/audio/pdf/epub/link',
  `title` varchar(100) NOT NULL COMMENT '资源标题',
  `cover_url` varchar(255) DEFAULT NULL COMMENT '封面图',
  `content_url` varchar(500) DEFAULT NULL COMMENT '媒体下载/外链/视频地址',
  `content_text` longtext COMMENT '富文本文章内容（若类型为article）',
  `is_public` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否公开：针对私人上传控制 1公开 0私密',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '阅读量/播放量',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1启用 2禁用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_public_status` (`member_id`,`is_public`,`status`),
  KEY `idx_category_status` (`category_id`,`status`),
  KEY `idx_media_type` (`media_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='教育与娱乐素材表';

-- 素材收藏
CREATE TABLE IF NOT EXISTS `sa_material_collect` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '收藏用户ID',
  `material_id` int NOT NULL COMMENT '素材ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_material` (`member_id`,`material_id`),
  KEY `idx_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='素材收藏表';

-- 素材点赞
CREATE TABLE IF NOT EXISTS `sa_material_like` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '点赞用户ID',
  `material_id` int NOT NULL COMMENT '素材ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_material` (`member_id`,`material_id`),
  KEY `idx_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='素材点赞表';

-- 素材评论
CREATE TABLE IF NOT EXISTS `sa_material_comment` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `material_id` int NOT NULL COMMENT '素材ID',
  `member_id` int NOT NULL COMMENT '评论用户ID',
  `content` text COMMENT '评论内容',
  `attachments` json DEFAULT NULL COMMENT '评论图片URL数组',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=正常, 2=隐藏',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_material_id` (`material_id`),
  KEY `idx_member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='素材评论表';

-- 素材评论点赞
CREATE TABLE IF NOT EXISTS `sa_material_comment_like` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '点赞用户ID',
  `comment_id` int NOT NULL COMMENT '素材评论ID',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_comment` (`member_id`,`comment_id`),
  KEY `idx_comment_id` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='素材评论点赞表';

-- 会员日记
CREATE TABLE IF NOT EXISTS `sa_member_journal` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '会员ID',
  `entry_date` date NOT NULL COMMENT '记录日期',
  `entry_time` time DEFAULT NULL COMMENT '记录时间',
  `title` varchar(80) NOT NULL COMMENT '标题',
  `content` text COMMENT '内容',
  `media` json DEFAULT NULL COMMENT '图片数组',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=正常, 2=隐藏',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_date` (`member_id`,`entry_date`),
  KEY `idx_member_status` (`member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员日记表';

CREATE TABLE IF NOT EXISTS `sa_member_memoir` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '会员ID',
  `grant_level_id` int NOT NULL DEFAULT '0' COMMENT '解锁等级ID',
  `grant_level_rank` int NOT NULL DEFAULT '0' COMMENT '解锁等级序号',
  `grant_level_name` varchar(50) NOT NULL DEFAULT '' COMMENT '解锁等级名称',
  `title` varchar(120) NOT NULL COMMENT '回忆录标题',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '回忆录描述',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '封面图',
  `video_url` varchar(500) NOT NULL COMMENT '视频地址',
  `source_month` varchar(7) NOT NULL DEFAULT '' COMMENT '来源月份',
  `journal_count` int NOT NULL DEFAULT '0' COMMENT '日记数量',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=正常, 2=隐藏',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_level_rank` (`member_id`,`grant_level_rank`),
  KEY `idx_member_status` (`member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员专属回忆录表';

-- 会员内容浏览历史
CREATE TABLE IF NOT EXISTS `sa_member_content_history` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '会员ID',
  `content_id` int NOT NULL COMMENT '内容ID',
  `content_type` varchar(20) NOT NULL COMMENT '内容类型',
  `title` varchar(120) NOT NULL COMMENT '内容标题',
  `author_name` varchar(60) DEFAULT NULL COMMENT '作者名称',
  `route` varchar(255) NOT NULL COMMENT '页面路由',
  `viewed_at` datetime NOT NULL COMMENT '最近浏览时间',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_content` (`member_id`,`content_type`,`content_id`),
  KEY `idx_member_viewed_at` (`member_id`,`viewed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员内容浏览历史表';

-- 治疗计划
CREATE TABLE IF NOT EXISTS `sa_treatment_plan` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '患者ID',
  `doctor_id` int NOT NULL DEFAULT '0' COMMENT '创建医生的ID(0代表AI创建)',
  `title` varchar(100) NOT NULL COMMENT '计划大标题（如：戒除前90天计划）',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1=进行中, 2=已完成, 3=终止',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_status` (`member_id`,`status`),
  KEY `idx_doctor_status` (`doctor_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='治疗计划表';

-- 治疗阶段
CREATE TABLE IF NOT EXISTS `sa_treatment_stage` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `plan_id` int NOT NULL COMMENT '所属计划ID',
  `member_id` int NOT NULL COMMENT '患者ID冗余',
  `stage_name` varchar(50) NOT NULL COMMENT '阶段名称（如：第一阶段评估）',
  `start_date` date NOT NULL COMMENT '起止日期-开始',
  `end_date` date NOT NULL COMMENT '起止日期-结束',
  `stage_target` varchar(255) DEFAULT NULL COMMENT '阶段目标',
  `sort` int NOT NULL DEFAULT '100' COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：0=待开始 1=进行中 2=完成',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_plan_sort` (`plan_id`,`sort`),
  KEY `idx_member_status` (`member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='治疗计划阶段表';

-- 每日任务
CREATE TABLE IF NOT EXISTS `sa_daily_task` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '患者ID',
  `stage_id` int NOT NULL DEFAULT '0' COMMENT '所属阶段ID(若有关联阶段)',
  `task_date` date NOT NULL COMMENT '任务具体日期',
  `start_time` time DEFAULT NULL COMMENT '任务开始时间',
  `end_time` time DEFAULT NULL COMMENT '任务结束时间',
  `title` varchar(100) NOT NULL COMMENT '关键任务标题',
  `description` text COMMENT '任务描述/详情',
  `reminders` json DEFAULT NULL COMMENT '提醒配置规则',
  `source` varchar(20) NOT NULL DEFAULT 'timeline' COMMENT '任务来源',
  `points_reward` int NOT NULL DEFAULT '10' COMMENT '完成奖励分数',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0待办 1完成 2跳过 3延期',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_date` (`member_id`,`task_date`),
  KEY `idx_stage_date` (`stage_id`,`task_date`),
  KEY `idx_member_status` (`member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='每日时间线任务表';

-- 医生预约
CREATE TABLE IF NOT EXISTS `sa_doctor_appointment` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '患者ID',
  `doctor_id` int NOT NULL COMMENT '预约的医生ID',
  `appoint_date` date NOT NULL COMMENT '预约日期',
  `appoint_time_slot` varchar(50) NOT NULL COMMENT '预约细分时间段如: 14:00-15:00',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0待确认 1已确认 2已完成 3已取消',
  `meet_type` varchar(20) DEFAULT NULL COMMENT '接诊方式类型',
  `meet_link` varchar(255) DEFAULT NULL COMMENT '连线地址',
  `confirm_remark` varchar(255) DEFAULT NULL COMMENT '医生确认备注/接诊说明',
  `remark` varchar(500) DEFAULT NULL COMMENT '预约备注',
  `cancel_reason` varchar(255) DEFAULT NULL COMMENT '取消原因',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_doctor_date` (`doctor_id`,`appoint_date`),
  KEY `idx_member_status` (`member_id`,`status`),
  KEY `idx_doctor_slot_status` (`doctor_id`,`appoint_date`,`appoint_time_slot`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医生预约表';

-- 医生患者绑定关系
CREATE TABLE IF NOT EXISTS `sa_doctor_patient` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `doctor_id` int NOT NULL COMMENT '医生ID',
  `member_id` int NOT NULL COMMENT '患者ID',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态:1绑定中,0已解绑',
  `bind_source` varchar(20) DEFAULT 'manual' COMMENT '绑定来源',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_doctor_member` (`doctor_id`,`member_id`),
  KEY `idx_member_status` (`member_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医生患者绑定关系表';

-- 医生任务模板文件夹
CREATE TABLE IF NOT EXISTS `sa_doctor_task_template_folder` (
  `id` varchar(64) NOT NULL COMMENT '主键ID',
  `doctor_id` int NOT NULL COMMENT '医生ID',
  `name` varchar(50) NOT NULL COMMENT '文件夹名称',
  `color` varchar(20) NOT NULL DEFAULT '#5E8FE6' COMMENT '主题颜色',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_doctor_update_time` (`doctor_id`,`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医生任务模板文件夹表';

-- 医生任务模板
CREATE TABLE IF NOT EXISTS `sa_doctor_task_template` (
  `id` varchar(64) NOT NULL COMMENT '主键ID',
  `doctor_id` int NOT NULL COMMENT '医生ID',
  `folder_id` varchar(64) NOT NULL COMMENT '所属文件夹ID',
  `stage` varchar(20) NOT NULL COMMENT '所属阶段',
  `title` varchar(100) NOT NULL COMMENT '模板名称',
  `description` text COMMENT '模板描述',
  `priority` varchar(10) NOT NULL DEFAULT '一般' COMMENT '优先级',
  `start_time` varchar(5) NOT NULL DEFAULT '09:00' COMMENT '开始时间',
  `end_time` varchar(5) NOT NULL DEFAULT '09:30' COMMENT '结束时间',
  `frequency` varchar(20) NOT NULL DEFAULT '每日' COMMENT '执行频率',
  `reward_score` int NOT NULL DEFAULT '0' COMMENT '奖励积分',
  `color` varchar(20) NOT NULL DEFAULT '#5E8FE6' COMMENT '主题颜色',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_doctor_folder` (`doctor_id`,`folder_id`),
  KEY `idx_doctor_stage` (`doctor_id`,`stage`),
  KEY `idx_doctor_update_time` (`doctor_id`,`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医生任务模板表';

-- 医生评估量表
CREATE TABLE IF NOT EXISTS `sa_doctor_assessment_scale` (
  `id` varchar(64) NOT NULL COMMENT '主键ID',
  `doctor_id` int NOT NULL COMMENT '医生ID',
  `title` varchar(100) NOT NULL COMMENT '量表名称',
  `stage` varchar(20) NOT NULL COMMENT '所属阶段',
  `description` varchar(500) DEFAULT NULL COMMENT '量表简介',
  `total_score` int NOT NULL DEFAULT '0' COMMENT '量表总分',
  `questions` json DEFAULT NULL COMMENT '题目配置JSON',
  `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT '状态:draft/published',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_doctor_stage` (`doctor_id`,`stage`),
  KEY `idx_doctor_status` (`doctor_id`,`status`),
  KEY `idx_doctor_update_time` (`doctor_id`,`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='医生评估量表表';

-- 会员量表提交结果
CREATE TABLE IF NOT EXISTS `sa_member_assessment_result` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '患者ID',
  `doctor_id` int NOT NULL DEFAULT '0' COMMENT '医生ID',
  `task_id` int NOT NULL COMMENT '关联任务ID',
  `assessment_id` varchar(64) DEFAULT NULL COMMENT '量表ID',
  `assessment_title` varchar(100) NOT NULL COMMENT '量表名称',
  `task_title` varchar(100) NOT NULL COMMENT '任务标题',
  `stage_key` varchar(20) DEFAULT NULL COMMENT '阶段标识',
  `question_count` int NOT NULL DEFAULT '0' COMMENT '题目数',
  `total_score` int NOT NULL DEFAULT '0' COMMENT '总分',
  `achieved_score` int NOT NULL DEFAULT '0' COMMENT '实得分',
  `answers` json DEFAULT NULL COMMENT '作答结果JSON',
  `assessment_snapshot` json DEFAULT NULL COMMENT '量表快照JSON',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_task` (`member_id`,`task_id`),
  KEY `idx_doctor_member` (`doctor_id`,`member_id`),
  KEY `idx_member_create_time` (`member_id`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员量表提交结果表';

-- AI聊天配置
CREATE TABLE IF NOT EXISTS `sa_member_chat_config` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '患者ID',
  `chat_mode` varchar(50) NOT NULL COMMENT '模式: doctor/companion/patient',
  `prompt_text` text COMMENT '用户设定的模式描述和前置提示',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_member_mode` (`member_id`,`chat_mode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='AI聊天用户专属预置模式配置';

-- 会员聊天会话
CREATE TABLE IF NOT EXISTS `sa_member_chat_session` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '会员ID',
  `chat_mode` varchar(50) NOT NULL COMMENT '会话模式: doctor/companion/patient',
  `session_name` varchar(100) NOT NULL COMMENT '会话名称',
  `last_message` varchar(500) DEFAULT NULL COMMENT '最后一条消息摘要',
  `last_message_time` datetime DEFAULT NULL COMMENT '最后消息时间',
  `is_pinned` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否置顶',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态:1有效,0无效',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_mode_status` (`member_id`,`chat_mode`,`status`),
  KEY `idx_member_last_time` (`member_id`,`last_message_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员聊天会话表';

-- 会员聊天记录
CREATE TABLE IF NOT EXISTS `sa_member_chat_record` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `session_id` int NOT NULL COMMENT '会话ID',
  `member_id` int NOT NULL COMMENT '会员ID',
  `chat_mode` varchar(50) NOT NULL COMMENT '会话模式: doctor/companion/patient',
  `role` varchar(20) NOT NULL DEFAULT 'user' COMMENT '消息角色:user/assistant/system',
  `content` text NOT NULL COMMENT '消息内容',
  `content_type` varchar(20) NOT NULL DEFAULT 'text' COMMENT '内容类型:text/image/file',
  `token_count` int NOT NULL DEFAULT '0' COMMENT 'token消耗数',
  `message_time` datetime DEFAULT NULL COMMENT '消息时间',
  `ext` json DEFAULT NULL COMMENT '扩展信息',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态:1有效,0无效',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_session_time` (`session_id`,`message_time`),
  KEY `idx_member_mode_status` (`member_id`,`chat_mode`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员聊天记录表';

-- 会员消息中心
CREATE TABLE IF NOT EXISTS `sa_member_message` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL COMMENT '接收会员ID',
  `message_type` tinyint(1) NOT NULL COMMENT '消息类型:1关注 2回复 3任务 4预约',
  `title` varchar(100) NOT NULL COMMENT '消息标题',
  `content` varchar(500) NOT NULL COMMENT '消息内容',
  `device_token` varchar(255) DEFAULT NULL COMMENT '设备推送token',
  `is_pushed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已推送:0未推送,1已推送',
  `push_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '推送状态:0待推送,1成功,2失败',
  `push_time` datetime DEFAULT NULL COMMENT '推送完成时间',
  `is_read` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已读:0未读,1已读',
  `read_time` datetime DEFAULT NULL COMMENT '已读时间',
  `biz_type` varchar(50) DEFAULT NULL COMMENT '业务类型',
  `biz_id` int DEFAULT '0' COMMENT '业务ID',
  `ext` json DEFAULT NULL COMMENT '扩展信息',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态:1有效,2禁用',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_read_status` (`member_id`,`is_read`,`status`),
  KEY `idx_member_type` (`member_id`,`message_type`),
  KEY `idx_member_push_status` (`member_id`,`is_pushed`,`push_status`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='会员消息中心表';

-- Help 模块业务字典类型
INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-是否', 'help_yes_no', 1, '0/1 布尔状态', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_yes_no' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-有效状态', 'help_valid_status', 1, '1有效 0无效', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_valid_status' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-消息类型', 'help_message_type', 1, '消息通知类型', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_message_type' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-推送状态', 'help_push_status', 1, '消息推送执行状态', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_push_status' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-聊天模式', 'help_chat_mode', 1, 'AI聊天模式', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_chat_mode' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-聊天角色', 'help_chat_role', 1, '聊天消息角色', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_chat_role' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-内容类型', 'help_content_type', 1, '聊天消息内容类型', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_content_type' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT '帮助模块-素材公开状态', 'help_material_public_status', 1, '素材公开或私密状态', 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_system_dict_type` WHERE `code` = 'help_material_public_status' AND `delete_time` IS NULL);

-- Help 模块业务字典数据
INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '是', '1', '#67c23a', 'help_yes_no', 100, 1, '布尔真', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_yes_no' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_yes_no' AND `value` = '1' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '否', '0', '#909399', 'help_yes_no', 90, 1, '布尔假', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_yes_no' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_yes_no' AND `value` = '0' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '有效', '1', '#67c23a', 'help_valid_status', 100, 1, '有效状态', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_valid_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_valid_status' AND `value` = '1' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '无效', '0', '#f56c6c', 'help_valid_status', 90, 1, '无效状态', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_valid_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_valid_status' AND `value` = '0' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '关注通知', '1', '#409eff', 'help_message_type', 100, 1, '关注类消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_message_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_message_type' AND `value` = '1' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '回复通知', '2', '#67c23a', 'help_message_type', 90, 1, '回复类消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_message_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_message_type' AND `value` = '2' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '任务通知', '3', '#e6a23c', 'help_message_type', 80, 1, '任务类消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_message_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_message_type' AND `value` = '3' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '预约通知', '4', '#f56c6c', 'help_message_type', 70, 1, '预约类消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_message_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_message_type' AND `value` = '4' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '待推送', '0', '#909399', 'help_push_status', 100, 1, '待处理', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_push_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_push_status' AND `value` = '0' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '推送成功', '1', '#67c23a', 'help_push_status', 90, 1, '推送成功', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_push_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_push_status' AND `value` = '1' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '推送失败', '2', '#f56c6c', 'help_push_status', 80, 1, '推送失败', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_push_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_push_status' AND `value` = '2' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '医生模式', 'doctor', '#409eff', 'help_chat_mode', 100, 1, '医生咨询', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_mode' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_mode' AND `value` = 'doctor' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '陪伴模式', 'companion', '#67c23a', 'help_chat_mode', 90, 1, '陪伴支持', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_mode' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_mode' AND `value` = 'companion' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '患者模式', 'patient', '#e6a23c', 'help_chat_mode', 80, 1, '患者自述', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_mode' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_mode' AND `value` = 'patient' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '用户', 'user', '#409eff', 'help_chat_role', 100, 1, '用户消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_role' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_role' AND `value` = 'user' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, 'AI助手', 'assistant', '#67c23a', 'help_chat_role', 90, 1, '助手回复', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_role' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_role' AND `value` = 'assistant' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '系统', 'system', '#909399', 'help_chat_role', 80, 1, '系统消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_chat_role' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_chat_role' AND `value` = 'system' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '文本', 'text', '#409eff', 'help_content_type', 100, 1, '文本消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_content_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_content_type' AND `value` = 'text' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '图片', 'image', '#67c23a', 'help_content_type', 90, 1, '图片消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_content_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_content_type' AND `value` = 'image' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '文件', 'file', '#e6a23c', 'help_content_type', 80, 1, '文件消息', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_content_type' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_content_type' AND `value` = 'file' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '公开', '1', '#67c23a', 'help_material_public_status', 100, 1, '允许所有用户查看', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_material_public_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_material_public_status' AND `value` = '1' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, '私密', '0', '#909399', 'help_material_public_status', 90, 1, '仅指定范围可见', 1, 1, NOW(), NOW()
FROM `sa_system_dict_type` t
WHERE t.`code` = 'help_material_public_status' AND t.`delete_time` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `sa_system_dict_data` WHERE `code` = 'help_material_public_status' AND `value` = '0' AND `delete_time` IS NULL);

INSERT INTO `sa_system_dict_type` (`name`, `code`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT v.name, v.code, v.status, v.remark, 1, 1, NOW(), NOW()
FROM (
    SELECT '帮助模块-预约状态' AS name, 'help_appointment_status' AS code, 1 AS status, '门诊预约处理状态' AS remark
    UNION ALL SELECT '帮助模块-任务状态', 'help_task_status', 1, '日常任务执行状态'
    UNION ALL SELECT '帮助模块-任务来源', 'help_task_source', 1, '任务生成来源'
    UNION ALL SELECT '帮助模块-阶段状态', 'help_stage_status', 1, '治疗阶段状态'
    UNION ALL SELECT '帮助模块-计划状态', 'help_plan_status', 1, '治疗计划状态'
    UNION ALL SELECT '帮助模块-分类类型', 'help_category_type', 1, '内容分类大类'
    UNION ALL SELECT '帮助模块-素材公开状态', 'help_material_public_status', 1, '素材公开或私密状态'
    UNION ALL SELECT '帮助模块-举报目标类型', 'help_report_target_type', 1, '举报目标类型'
    UNION ALL SELECT '帮助模块-举报处理状态', 'help_report_handle_status', 1, '举报处理状态'
    UNION ALL SELECT '帮助模块-评论审核状态', 'help_comment_audit_status', 1, '评论审核状态'
    UNION ALL SELECT '帮助模块-评论显示状态', 'help_comment_status', 1, '评论显示状态'
    UNION ALL SELECT '帮助模块-素材类型', 'help_material_type', 1, '内容素材资源类型'
    UNION ALL SELECT '帮助模块-素材状态', 'help_material_status', 1, '内容素材启用状态'
    UNION ALL SELECT '帮助模块-帖子审核状态', 'help_post_audit_status', 1, '帖子审核状态'
    UNION ALL SELECT '帮助模块-帖子显示状态', 'help_post_status', 1, '帖子显示状态'
) v
LEFT JOIN `sa_system_dict_type` t
    ON t.`code` = v.code AND t.`delete_time` IS NULL
WHERE t.`id` IS NULL;

INSERT INTO `sa_system_dict_data` (`type_id`, `label`, `value`, `color`, `code`, `sort`, `status`, `remark`, `created_by`, `updated_by`, `create_time`, `update_time`)
SELECT t.id, v.label, v.value, v.color, v.code, v.sort, 1, v.remark, 1, 1, NOW(), NOW()
FROM (
    SELECT 'help_appointment_status' AS code, '待确认' AS label, '0' AS value, '#909399' AS color, 100 AS sort, '等待确认' AS remark
    UNION ALL SELECT 'help_appointment_status', '已确认', '1', '#409eff', 90, '已确认待就诊'
    UNION ALL SELECT 'help_appointment_status', '已完成', '2', '#67c23a', 80, '预约已完成'
    UNION ALL SELECT 'help_appointment_status', '已取消', '3', '#f56c6c', 70, '预约已取消'
    UNION ALL SELECT 'help_task_status', '待办', '0', '#909399', 100, '待执行任务'
    UNION ALL SELECT 'help_task_status', '已完成', '1', '#67c23a', 90, '任务已完成'
    UNION ALL SELECT 'help_task_status', '已跳过', '2', '#e6a23c', 80, '任务已跳过'
    UNION ALL SELECT 'help_task_status', '已延期', '3', '#f56c6c', 70, '任务已延期'
    UNION ALL SELECT 'help_task_source', '阶段计划', 'timeline', '#409eff', 100, '阶段预设任务'
    UNION ALL SELECT 'help_task_source', 'AI对话', 'chat', '#67c23a', 90, 'AI 对话生成'
    UNION ALL SELECT 'help_task_source', '手动创建', 'manual', '#e6a23c', 80, '人工创建'
    UNION ALL SELECT 'help_stage_status', '待开始', '0', '#909399', 100, '阶段待启动'
    UNION ALL SELECT 'help_stage_status', '进行中', '1', '#409eff', 90, '阶段执行中'
    UNION ALL SELECT 'help_stage_status', '已完成', '2', '#67c23a', 80, '阶段已完成'
    UNION ALL SELECT 'help_plan_status', '进行中', '1', '#409eff', 100, '计划执行中'
    UNION ALL SELECT 'help_plan_status', '已完成', '2', '#67c23a', 90, '计划已完成'
    UNION ALL SELECT 'help_plan_status', '已终止', '3', '#f56c6c', 80, '计划终止'
    UNION ALL SELECT 'help_category_type', '医疗教育', '1', '#409eff', 100, '医疗教育内容'
    UNION ALL SELECT 'help_category_type', '娱乐资源', '2', '#67c23a', 90, '娱乐资源内容'
    UNION ALL SELECT 'help_material_public_status', '公开', '1', '#67c23a', 100, '允许所有用户查看'
    UNION ALL SELECT 'help_material_public_status', '私密', '0', '#909399', 90, '仅指定范围可见'
    UNION ALL SELECT 'help_report_target_type', '帖子', '1', '#409eff', 100, '举报帖子'
    UNION ALL SELECT 'help_report_target_type', '评论', '2', '#67c23a', 90, '举报评论'
    UNION ALL SELECT 'help_report_target_type', '用户', '3', '#e6a23c', 80, '举报用户'
    UNION ALL SELECT 'help_report_handle_status', '待处理', '0', '#909399', 100, '等待处理'
    UNION ALL SELECT 'help_report_handle_status', '已处理', '1', '#67c23a', 90, '已处理完成'
    UNION ALL SELECT 'help_report_handle_status', '已忽略', '2', '#e6a23c', 80, '已忽略'
    UNION ALL SELECT 'help_comment_audit_status', '待审核', '0', '#909399', 100, '待人工审核'
    UNION ALL SELECT 'help_comment_audit_status', '已通过', '1', '#67c23a', 90, '审核通过'
    UNION ALL SELECT 'help_comment_audit_status', '已拒绝', '2', '#f56c6c', 80, '审核拒绝'
    UNION ALL SELECT 'help_comment_status', '正常', '1', '#67c23a', 100, '评论正常展示'
    UNION ALL SELECT 'help_comment_status', '隐藏', '2', '#e6a23c', 90, '评论隐藏'
    UNION ALL SELECT 'help_material_type', '文章', 'article', '#409eff', 100, '图文文章'
    UNION ALL SELECT 'help_material_type', '视频', 'video', '#67c23a', 90, '视频资源'
    UNION ALL SELECT 'help_material_type', '音频', 'audio', '#e6a23c', 80, '音频资源'
    UNION ALL SELECT 'help_material_type', 'PDF', 'pdf', '#f56c6c', 70, 'PDF 文档'
    UNION ALL SELECT 'help_material_type', 'EPUB', 'epub', '#909399', 60, 'EPUB 电子书'
    UNION ALL SELECT 'help_material_type', '链接', 'link', '#8e44ad', 50, '外部链接'
    UNION ALL SELECT 'help_material_status', '启用', '1', '#67c23a', 100, '素材启用'
    UNION ALL SELECT 'help_material_status', '禁用', '2', '#f56c6c', 90, '素材禁用'
    UNION ALL SELECT 'help_post_audit_status', '待审核', '0', '#909399', 100, '待审核'
    UNION ALL SELECT 'help_post_audit_status', '已通过', '1', '#67c23a', 90, '审核通过'
    UNION ALL SELECT 'help_post_audit_status', '已拒绝', '2', '#f56c6c', 80, '审核拒绝'
    UNION ALL SELECT 'help_post_audit_status', 'AI预审标记', '3', '#e6a23c', 70, 'AI 预审标记'
    UNION ALL SELECT 'help_post_status', '正常', '1', '#67c23a', 100, '帖子正常展示'
    UNION ALL SELECT 'help_post_status', '隐藏', '2', '#e6a23c', 90, '帖子隐藏'
    UNION ALL SELECT 'help_post_status', '封禁', '3', '#f56c6c', 80, '帖子封禁'
) v
JOIN `sa_system_dict_type` t
    ON t.`code` = v.code AND t.`delete_time` IS NULL
LEFT JOIN `sa_system_dict_data` d
    ON d.`code` = v.code AND d.`value` = v.value AND d.`delete_time` IS NULL
WHERE d.`id` IS NULL;

-- 默认标签
INSERT INTO `sa_community_tag` (`tag_name`, `tag_name_en`, `color`, `sort`, `status`, `create_time`)
SELECT '求助', 'help', '#5B8FF9', 100, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_community_tag` WHERE `tag_name` = '求助');

INSERT INTO `sa_community_tag` (`tag_name`, `tag_name_en`, `color`, `sort`, `status`, `create_time`)
SELECT '经验', 'experience', '#61DDAA', 90, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_community_tag` WHERE `tag_name` = '经验');

INSERT INTO `sa_community_tag` (`tag_name`, `tag_name_en`, `color`, `sort`, `status`, `create_time`)
SELECT '里程碑', 'milestone', '#65789B', 80, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_community_tag` WHERE `tag_name` = '里程碑');

-- 默认教育分类
INSERT INTO `sa_content_category` (`name`, `type`, `sort`, `status`, `create_time`)
SELECT '入门', 1, 100, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_content_category` WHERE `name` = '入门' AND `type` = 1);

INSERT INTO `sa_content_category` (`name`, `type`, `sort`, `status`, `create_time`)
SELECT '动机与认知', 1, 90, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_content_category` WHERE `name` = '动机与认知' AND `type` = 1);

INSERT INTO `sa_content_category` (`name`, `type`, `sort`, `status`, `create_time`)
SELECT '应对技能', 1, 80, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_content_category` WHERE `name` = '应对技能' AND `type` = 1);

INSERT INTO `sa_content_category` (`name`, `type`, `sort`, `status`, `create_time`)
SELECT '复发预防', 1, 70, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_content_category` WHERE `name` = '复发预防' AND `type` = 1);

INSERT INTO `sa_content_category` (`name`, `type`, `sort`, `status`, `create_time`)
SELECT '家属指南', 1, 60, 1, NOW()
WHERE NOT EXISTS (SELECT 1 FROM `sa_content_category` WHERE `name` = '家属指南' AND `type` = 1);

SET FOREIGN_KEY_CHECKS = 1;
