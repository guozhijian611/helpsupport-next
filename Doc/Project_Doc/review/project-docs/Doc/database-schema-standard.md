# B8AIadmin 数据表结构规范

> 来源：当前本地 MySQL 数据库 `b8aiadmin` 的 42 张表结构；`saiuser` 插件表已按 `server/runtime/saipackage/saiuser/install.sql` 校对。历史备份文件：`Database/backups/b8aiadmin_20260529_014358.sql`。本文档只记录表结构、字段语义、软删除、审计与数据权限约定，不记录 INSERT 初始化数据或密钥值。

## 一、全局约定

### 1. 字段命名

- 表名与字段名统一使用小写蛇形命名，例如 `sa_system_user`、`created_by`。
- 主键字段优先使用 `id`，当前大多数表为 `AUTO_INCREMENT` 自增主键。
- 关联表保留独立 `id` 主键，并使用 `user_id`、`role_id`、`dept_id`、`menu_id`、`post_id`、`group_id`、`member_id`、`platform_id` 等字段表达关系。

### 2. SaiAdmin 布尔与状态值

- 常规 SaiAdmin 是否类字段统一记录为：`1` 表示是，`2` 表示否。典型字段包括 `is_link`、`is_href`、`is_iframe`、`is_keep_alive`、`is_hidden`、`is_fixed_tab`、`is_full_page`、`singleton`、`build_menu`、`generate_model`、`generate_menus`、`is_full`。
- saiai 插件当前存在 `0/1` 是否字段，例如 `saiai_config.is_default` 为 `1是/0否`、`saiai_chat_group.is_top` 默认 `0`。这些字段以 SQL 注释和现有代码为准，新增业务表不要混用。
- saiuser 插件存在多处 `0/1` 与多值状态字段，例如 `sa_member.status` 为 `1正常/2冻结/3注销`，`sa_member_platform.status` 为 `1启用/0禁用`，`sa_member_platform_rel.is_bind` 为是否绑定。使用时以字段注释为准。
- 代码生成器元数据表存在历史反向枚举，例如 `sa_tool_generate_columns.is_pk` 为 `1 非主键 / 2 主键`，`is_required` 为 `1 非必填 / 2 必填`。这些字段以 SQL 注释为准，新增业务表不要沿用反向枚举。
- 历史核心表中已明确写入 `0/1` 的字段按 SQL 注释执行，例如 `sa_system_user.is_super` 为 `1是/0否`，`sa_system_user.status`、`sa_system_role.status`、`sa_system_dept.status` 为 `1启用/0禁用`。新增业务表建议避免混用。
- 字典状态、登录状态等已在字段注释中定义 `1/2` 的字段，以字段注释为准，例如 `1正常/2停用`、`1成功/2失败`。

### 3. 软删除约定

- `delete_time` 是软删除字段：`NULL` 表示未删除，非 `NULL` 表示已删除。
- 业务查询默认应过滤 `delete_time IS NULL`，恢复、回收站、审计场景才读取非空数据。
- 纯关联表如果没有 `delete_time`，删除即代表物理解除关系，例如 `sa_system_role_menu`、`sa_system_user_role`。

### 4. 创建人与更新人

- `created_by` 记录创建用户 ID，是业务数据归属与“仅本人”数据权限的关键字段。
- `updated_by` 记录最后更新用户 ID，用于审计追踪，不建议作为数据归属判断依据。
- 新增需要参与数据权限的业务表，应同时包含 `created_by`、`updated_by`、`create_time`、`update_time`、`delete_time`；saiuser 会员域表当前主要通过 `member_id`、`platform_id` 建立业务归属。

### 5. 数据权限相关字段

| 对象 | 字段 | 说明 |
| --- | --- | --- |
| 用户 | `sa_system_user.dept_id` | 用户主归属部门。 |
| 用户 | `sa_system_user.is_super` | 超级管理员标识，`1` 跳过权限检查，`0` 不跳过。 |
| 角色 | `sa_system_role.data_scope` | 数据范围：`1` 全部，`2` 本部门及下属，`3` 本部门，`4` 仅本人，`5` 自定义。 |
| 角色部门 | `sa_system_role_dept.role_id`、`dept_id` | 自定义数据权限的角色-部门授权。 |
| 角色菜单 | `sa_system_role_menu.role_id`、`menu_id` | 角色菜单/按钮/API 权限授权。 |
| 菜单权限 | `sa_system_menu.slug` | 权限标识，建议与后端 `Permission` 注解和前端按钮权限保持一致。 |
| 业务数据 | `created_by` | “仅本人”数据范围与创建归属的基础字段。 |
| AI 会话 | `saiai_chat.user_id`、`saiai_chat.group_id` | AI 对话记录归属用户与会话分组。 |
| AI 分组 | `saiai_chat_group.user_id` | AI 会话分组归属用户。 |
| 会员主体 | `sa_member.id`、`sa_member.member_level_id`、`sa_member.register_platform_id` | 会员身份、等级和注册平台归属。 |
| 会员关联 | `sa_member_platform_rel.member_id`、`platform_id`、`platform_openid` | 第三方平台账号绑定关系。 |
| 会员日志 | `sa_member_login_log.member_id`、`sa_member_points_log.member_id` | 会员登录、积分流水归属。 |
| 低代码生成 | `saicode_column.table_id`、`saicode_table.belong_menu_id` | 低代码生成字段与业务表、所属菜单的关联。 |
| 支付订单 | `saipay_order.member_id`、`saipay_order.order_id`、`saipay_order.order_no` | 支付订单归属会员、关联业务订单与唯一订单号。 |
| 短信记录 | `saisms_record.mobile`、`code`、`is_verify` | 短信验证码接收手机号、验证码与验证状态。 |
| 短信配置 | `saisms_config.gateway`、`saisms_tag.gateway` | 短信网关配置与短信模板标签关联。 |

## 二、数据表清单

| 序号 | 分组 | 表名 | 表说明 | 字段数 | 软删除 | 创建人 | 更新人 | 权限/审计备注 |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| 1 | 文章内容 | `sa_article` | 文章表 | 18 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 2 | 文章内容 | `sa_article_banner` | 文章轮播图 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 3 | 文章内容 | `sa_article_category` | 文章分类表 | 12 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 4 | 会员插件 | `sa_member` | 会员基础信息表 | 17 | 是 | 否 | 否 | 平台来源、会员主体信息 |
| 5 | 会员插件 | `sa_member_level` | 会员等级表 | 13 | 是 | 否 | 否 | - |
| 6 | 会员插件 | `sa_member_login_log` | 会员登录日志表 | 12 | 是 | 否 | 否 | 会员归属、平台来源 |
| 7 | 会员插件 | `sa_member_platform` | 多平台配置表 | 8 | 是 | 否 | 否 | - |
| 8 | 会员插件 | `sa_member_platform_rel` | 会员-平台关联表（多平台账号绑定） | 10 | 是 | 否 | 否 | 会员归属、平台来源 |
| 9 | 会员插件 | `sa_member_points_log` | 积分变动记录表 | 13 | 是 | 否 | 否 | 会员归属、平台来源 |
| 10 | 会员插件 | `sa_member_protocol` | 使用协议 | 8 | 是 | 否 | 否 | - |
| 11 | 会员插件 | `sa_site_info` | 站点信息表 | 13 | 是 | 否 | 否 | 站点配置 |
| 12 | 系统核心 | `sa_system_attachment` | 附件信息表 | 18 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 13 | 系统核心 | `sa_system_category` | 附件分类表 | 12 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 14 | 系统核心 | `sa_system_config` | 参数配置信息表 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 15 | 系统核心 | `sa_system_config_group` | 参数配置分组表 | 9 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 16 | 系统核心 | `sa_system_dept` | 部门表 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 17 | 系统核心 | `sa_system_dict_data` | 字典数据表 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 18 | 系统核心 | `sa_system_dict_type` | 字典类型表 | 10 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 19 | 系统核心 | `sa_system_login_log` | 登录日志表 | 15 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 20 | 系统核心 | `sa_system_mail` | 邮件记录 | 11 | 是 | 否 | 否 | - |
| 21 | 系统核心 | `sa_system_menu` | 菜单权限表 | 26 | 是 | 是 | 是 | 创建人归属、更新人审计、菜单与按钮权限 |
| 22 | 系统核心 | `sa_system_oper_log` | 操作日志表 | 15 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 23 | 系统核心 | `sa_system_post` | 岗位信息表 | 11 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 24 | 系统核心 | `sa_system_role` | 角色表 | 13 | 是 | 是 | 是 | 创建人归属、更新人审计、角色数据范围 |
| 25 | 系统核心 | `sa_system_role_dept` | 角色-自定义数据权限关联 | 3 | 否 | 否 | 否 | 自定义部门数据权限 |
| 26 | 系统核心 | `sa_system_role_menu` | 角色权限关联 | 3 | 否 | 否 | 否 | 角色菜单权限 |
| 27 | 系统核心 | `sa_system_user` | 用户表 | 21 | 是 | 是 | 是 | 创建人归属、更新人审计、用户部门/超管标识 |
| 28 | 系统核心 | `sa_system_user_post` | 用户与岗位关联表 | 3 | 否 | 否 | 否 | 用户岗位授权 |
| 29 | 系统核心 | `sa_system_user_role` | 用户角色关联 | 3 | 否 | 否 | 否 | 用户角色授权 |
| 30 | 系统工具 | `sa_tool_crontab` | 定时任务信息表 | 15 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 31 | 系统工具 | `sa_tool_crontab_log` | 定时任务执行日志表 | 10 | 是 | 否 | 否 | - |
| 32 | 系统工具 | `sa_tool_generate_columns` | 代码生成业务字段表 | 25 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 33 | 系统工具 | `sa_tool_generate_tables` | 代码生成业务表 | 28 | 是 | 是 | 是 | 创建人归属、更新人审计 |
| 34 | AI 插件 | `saiai_chat` | AI对话记录表 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计、AI 对话归属用户/分组 |
| 35 | AI 插件 | `saiai_chat_group` | AI对话分组表 | 9 | 是 | 是 | 是 | 创建人归属、更新人审计、AI 会话归属用户 |
| 36 | AI 插件 | `saiai_config` | AI配置表 | 14 | 是 | 是 | 是 | 创建人归属、更新人审计、AI 平台配置审计 |
| 37 | 低代码插件 | `saicode_column` | 代码生成业务字段表 | 33 | 是 | 是 | 是 | 创建人归属、更新人审计、低代码字段配置 |
| 38 | 低代码插件 | `saicode_table` | 低代码数据表 | 28 | 是 | 是 | 是 | 创建人归属、更新人审计、低代码表配置 |
| 39 | 支付插件 | `saipay_order` | 订单记录表 | 21 | 是 | 是 | 是 | 创建人归属、更新人审计、支付订单归属 |
| 40 | 短信插件 | `saisms_config` | 短信配置 | 12 | 是 | 是 | 是 | 创建人归属、更新人审计、短信网关配置 |
| 41 | 短信插件 | `saisms_record` | 短信记录 | 10 | 否 | 否 | 否 | 短信发送与验证码验证记录 |
| 42 | 短信插件 | `saisms_tag` | 短信标签 | 12 | 是 | 是 | 是 | 创建人归属、更新人审计、短信模板标签 |

## 三、逐表结构

### sa_article（文章表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `category_id` | `int NOT NULL` | 是 | `-` | 分类id | - |
| `title` | `varchar(255) NOT NULL DEFAULT ''` | 是 | `''` | 文章标题 | - |
| `author` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 文章作者 | - |
| `image` | `varchar(1000) DEFAULT ''` | 否 | `''` | 文章图片 | - |
| `describe` | `varchar(1000) NOT NULL` | 是 | `-` | 文章简介 | - |
| `content` | `text NOT NULL` | 是 | `-` | 文章内容 | - |
| `views` | `int DEFAULT '0'` | 否 | `'0'` | 浏览次数 | - |
| `sort` | `int unsigned DEFAULT '100'` | 否 | `'100'` | 排序 | - |
| `status` | `tinyint unsigned DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `is_link` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否外链 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `link_url` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 链接地址 | - |
| `is_hot` | `tinyint unsigned DEFAULT '2'` | 否 | `'2'` | 是否热门 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_category_id&#96; (&#96;category_id&#96;) USING BTREE</code> |

### sa_article_banner（文章轮播图）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `banner_type` | `int DEFAULT NULL` | 否 | `NULL` | 类型 | - |
| `image` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 图片地址 | - |
| `is_href` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 是否链接 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `url` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 链接地址 | - |
| `title` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 标题 | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `sort` | `int DEFAULT '0'` | 否 | `'0'` | 排序 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 描述 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_article_category（文章分类表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `parent_id` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 父级ID | - |
| `category_name` | `varchar(255) NOT NULL` | 是 | `-` | 分类标题 | - |
| `describe` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 分类简介 | - |
| `image` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 分类图片 | - |
| `sort` | `int unsigned DEFAULT '100'` | 否 | `'100'` | 排序 | - |
| `status` | `tinyint unsigned DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_member（会员基础信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：平台来源、会员主体信息

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 会员ID | - |
| `username` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 用户名 | - |
| `nickname` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 昵称 | - |
| `avatar` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 头像 | - |
| `mobile` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 手机号 | 会员个人信息字段，查询、导出、日志中注意脱敏。 |
| `email` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 邮箱 | 会员个人信息字段，查询、导出、日志中注意脱敏。 |
| `password_hash` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 密码哈希 | 密码哈希字段，只记录结构，不记录真实值。 |
| `member_level_id` | `int NOT NULL DEFAULT '1'` | 是 | `'1'` | 会员等级ID | 会员等级字段，关联 `sa_member_level.id`。 |
| `points_balance` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 当前积分余额 | - |
| `last_login_ip` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 最后登录IP | - |
| `last_login_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 最后登录时间 | - |
| `register_platform_id` | `tinyint DEFAULT NULL` | 否 | `NULL` | 注册平台 | 会员平台字段，关联 `sa_member_platform.id`。 |
| `status` | `tinyint NOT NULL DEFAULT '1'` | 是 | `'1'` | 状态：1-正常，2-冻结，3-注销 | 状态枚举按字段注释使用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 更新时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_mobile&#96; (&#96;mobile&#96;) USING BTREE</code> |

### sa_member_level（会员等级表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：-

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 等级ID | - |
| `level_name` | `varchar(50) NOT NULL` | 是 | `-` | 等级名称：如普通会员、白银、黄金 | - |
| `level_code` | `varchar(20) NOT NULL` | 是 | `-` | 等级标识：如NORMAL、SILVER、GOLD | - |
| `min_points` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 升级所需最低积分 | - |
| `max_points` | `int DEFAULT NULL` | 否 | `NULL` | 等级上限积分（null表示无上限） | - |
| `level_icon` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 等级图标URL（多平台通用） | - |
| `privileges` | `text` | 否 | `-` | 等级权益（JSON格式，如{"discount":0.9,"free_shipping":true}） | - |
| `sort` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 排序 | - |
| `status` | `tinyint NOT NULL DEFAULT '1'` | 是 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;uk_level_code&#96; (&#96;level_code&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_min_points&#96; (&#96;min_points&#96;) USING BTREE</code> |

### sa_member_login_log（会员登录日志表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：会员归属、平台来源

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint NOT NULL AUTO_INCREMENT` | 是 | `-` | 日志ID | - |
| `member_id` | `bigint NOT NULL` | 是 | `-` | 会员ID（关联member表） | 会员业务归属字段，关联 `sa_member.id`。 |
| `platform_id` | `tinyint NOT NULL` | 是 | `-` | 登录平台ID（关联member_platform表） | 会员平台字段，关联 `sa_member_platform.id`。 |
| `login_type` | `tinyint DEFAULT NULL` | 否 | `NULL` | 登录方式 | - |
| `login_ip` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 登录IP | - |
| `login_location` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 登录地点（通过IP解析） | - |
| `user_agent` | `text` | 否 | `-` | 用户代理（浏览器/设备信息） | - |
| `login_result` | `tinyint DEFAULT NULL` | 否 | `NULL` | 登录结果：1-成功，0-失败 | - |
| `fail_reason` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 失败原因（如密码错误、账号冻结） | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_member_id&#96; (&#96;member_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_platform_time&#96; (&#96;platform_id&#96;) USING BTREE</code> |

### sa_member_platform（多平台配置表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：-

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `tinyint NOT NULL AUTO_INCREMENT` | 是 | `-` | 平台ID | - |
| `platform_name` | `varchar(50) NOT NULL` | 是 | `-` | 平台名称：PC、小程序、公众号、H5、钉钉、企业微信 | - |
| `platform_code` | `varchar(20) NOT NULL` | 是 | `-` | 平台唯一标识：如PC-WEB、MINI-PROGRAM、WECHAT-OFFICIAL、H5、DINGTALK、WEWORK | - |
| `status` | `tinyint NOT NULL DEFAULT '1'` | 是 | `'1'` | 状态：1-启用，0-禁用 | 历史状态字段按注释使用 1启用、0禁用；新增业务状态建议统一 1启用、2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;uk_platform_code&#96; (&#96;platform_code&#96;) USING BTREE</code> |

### sa_member_platform_rel（会员-平台关联表（多平台账号绑定））

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：会员归属、平台来源

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint NOT NULL AUTO_INCREMENT` | 是 | `-` | 自增ID | - |
| `member_id` | `bigint NOT NULL` | 是 | `-` | 会员ID（关联member表） | 会员业务归属字段，关联 `sa_member.id`。 |
| `platform_id` | `tinyint NOT NULL` | 是 | `-` | 平台ID（关联member_platform表） | 会员平台字段，关联 `sa_member_platform.id`。 |
| `platform_openid` | `varchar(100) NOT NULL` | 是 | `-` | 平台唯一标识（如微信openid、钉钉unionid） | 第三方平台唯一标识，属于敏感绑定凭据，避免明文外泄。 |
| `is_bind` | `tinyint NOT NULL DEFAULT '1'` | 是 | `'1'` | 是否绑定 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `bind_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 绑定时间 | - |
| `unbind_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 解绑时间（null表示未解绑） | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;uk_platform_openid&#96; (&#96;platform_id&#96;,&#96;platform_openid&#96;) USING BTREE COMMENT '同一平台openid唯一'</code> |
| <code>KEY &#96;idx_member_id&#96; (&#96;member_id&#96;) USING BTREE</code> |

### sa_member_points_log（积分变动记录表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：会员归属、平台来源

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 记录ID | - |
| `member_id` | `int NOT NULL` | 是 | `-` | 会员ID（关联member表） | 会员业务归属字段，关联 `sa_member.id`。 |
| `platform_id` | `tinyint NOT NULL` | 是 | `-` | 操作平台ID（关联member_platform表） | 会员平台字段，关联 `sa_member_platform.id`。 |
| `points_change` | `int NOT NULL` | 是 | `-` | 积分变动值（正数增加，负数减少） | - |
| `points_before` | `int NOT NULL` | 是 | `-` | 变动前积分 | - |
| `points_after` | `int NOT NULL` | 是 | `-` | 变动后积分 | - |
| `operate_type` | `tinyint NOT NULL` | 是 | `-` | 操作类型：1-充值，2-消费 | - |
| `operate_desc` | `varchar(200) NOT NULL` | 是 | `-` | 操作描述 | - |
| `related_id` | `int DEFAULT NULL` | 否 | `NULL` | 关联业务ID（如订单号、任务ID） | - |
| `order_no` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 订单号 | - |
| `create_time` | `datetime NOT NULL DEFAULT CURRENT_TIMESTAMP` | 是 | `CURRENT_TIMESTAMP` | - | 创建时间字段。 |
| `update_time` | `datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 是 | `CURRENT_TIMESTAMP` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_member_id&#96; (&#96;member_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_related_id&#96; (&#96;related_id&#96;) USING BTREE</code> |

### sa_member_protocol（使用协议）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：-

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `protocol_type` | `tinyint(1) DEFAULT NULL` | 否 | `NULL` | 协议类型 | - |
| `title` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 协议标题 | - |
| `content` | `text` | 否 | `-` | 协议内容 | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_site_info（站点信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 结构来源：`server/runtime/saipackage/saiuser/install.sql`
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：站点配置

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `site_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 站点名称 | - |
| `site_logo` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 站点logo | - |
| `site_desc` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 站点描述 | - |
| `site_keywords` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 站点关键词 | - |
| `site_copyright` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 版权信息 | - |
| `site_record_number` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备案号 | - |
| `site_config` | `text` | 否 | `-` | 站点配置 | - |
| `contact` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 联系方式 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 更新时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_system_attachment（附件信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `category_id` | `int DEFAULT '0'` | 否 | `'0'` | 文件分类 | - |
| `storage_mode` | `smallint DEFAULT '1'` | 否 | `'1'` | 存储模式 (1 本地 2 阿里云 3 七牛云 4 腾讯云) | - |
| `origin_name` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 原文件名 | - |
| `object_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 新文件名 | - |
| `hash` | `varchar(64) DEFAULT NULL` | 否 | `NULL` | 文件hash | - |
| `mime_type` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 资源类型 | - |
| `storage_path` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 存储目录 | - |
| `suffix` | `varchar(10) DEFAULT NULL` | 否 | `NULL` | 文件后缀 | - |
| `size_byte` | `bigint DEFAULT NULL` | 否 | `NULL` | 字节数 | - |
| `size_info` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 文件大小 | - |
| `url` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | url地址 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;hash&#96; (&#96;hash&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_url&#96; (&#96;url&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_create_time&#96; (&#96;create_time&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_category_id&#96; (&#96;category_id&#96;) USING BTREE</code> |

### sa_system_category（附件分类表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | 分类ID | - |
| `parent_id` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 父id | - |
| `level` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 组集关系 | - |
| `category_name` | `varchar(100) NOT NULL DEFAULT ''` | 是 | `''` | 分类名称 | - |
| `sort` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 排序 | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;pid&#96; (&#96;parent_id&#96;) USING BTREE</code> |
| <code>KEY &#96;sort&#96; (&#96;sort&#96;) USING BTREE</code> |

### sa_system_config（参数配置信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `group_id` | `int DEFAULT NULL` | 否 | `NULL` | 组id | - |
| `key` | `varchar(32) NOT NULL` | 是 | `-` | 配置键名 | - |
| `value` | `text` | 否 | `-` | 配置值 | - |
| `name` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 配置名称 | - |
| `input_type` | `varchar(32) DEFAULT NULL` | 否 | `NULL` | 数据输入类型 | - |
| `config_select_data` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 配置选项数据 | - |
| `sort` | `smallint unsigned DEFAULT '0'` | 否 | `'0'` | 排序 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建人 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新人 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;,&#96;key&#96;) USING BTREE</code> |
| <code>KEY &#96;group_id&#96; (&#96;group_id&#96;) USING BTREE</code> |

### sa_system_config_group（参数配置分组表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字典名称 | - |
| `code` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 字典标示 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建人 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新人 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_system_dept（部门表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `parent_id` | `bigint unsigned DEFAULT '0'` | 否 | `'0'` | 父级ID，0为根节点 | - |
| `name` | `varchar(64) NOT NULL` | 是 | `-` | 部门名称 | - |
| `code` | `varchar(64) DEFAULT NULL` | 否 | `NULL` | 部门编码 | - |
| `leader_id` | `bigint unsigned DEFAULT NULL` | 否 | `NULL` | 部门负责人ID | - |
| `level` | `varchar(255) DEFAULT ''` | 否 | `''` | 祖级列表，格式: 0,1,5, (便于查询子孙节点) | - |
| `sort` | `int DEFAULT '0'` | 否 | `'0'` | 排序，数字越小越靠前 | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态: 1启用, 0禁用 | 历史状态字段按注释使用 1启用、0禁用；新增业务状态建议统一 1启用、2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_parent_id&#96; (&#96;parent_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_path&#96; (&#96;level&#96;) USING BTREE</code> |

### sa_system_dict_data（字典数据表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `type_id` | `int unsigned DEFAULT NULL` | 否 | `NULL` | 字典类型ID | - |
| `label` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字典标签 | - |
| `value` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 字典值 | - |
| `color` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字典颜色 | - |
| `code` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 字典标示 | - |
| `sort` | `smallint unsigned DEFAULT '0'` | 否 | `'0'` | 排序 | - |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 状态 (1正常 2停用) | 状态枚举按字段注释使用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;type_id&#96; (&#96;type_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_code&#96; (&#96;code&#96;) USING BTREE</code> |

### sa_system_dict_type（字典类型表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字典名称 | - |
| `code` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 字典标示 | - |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 状态 (1正常 2停用) | 状态枚举按字段注释使用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_code&#96; (&#96;code&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_name&#96; (&#96;name&#96;) USING BTREE</code> |

### sa_system_login_log（登录日志表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `username` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 用户名 | - |
| `ip` | `varchar(45) DEFAULT NULL` | 否 | `NULL` | 登录IP地址 | - |
| `ip_location` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | IP所属地 | - |
| `os` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 操作系统 | - |
| `browser` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 浏览器 | - |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 登录状态 (1成功 2失败) | 状态枚举按字段注释使用。 |
| `message` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 提示消息 | - |
| `login_time` | `datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 是 | `CURRENT_TIMESTAMP` | 登录时间 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 更新时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;username&#96; (&#96;username&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_create_time&#96; (&#96;create_time&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_login_time&#96; (&#96;login_time&#96;) USING BTREE</code> |

### sa_system_mail（邮件记录）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：-

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `gateway` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 网关 | - |
| `from` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 发送人 | - |
| `email` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 接收人 | - |
| `code` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 验证码 | - |
| `content` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 邮箱内容 | - |
| `status` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 发送状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `response` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 返回结果 | - |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_create_time&#96; (&#96;create_time&#96;) USING BTREE</code> |

### sa_system_menu（菜单权限表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、菜单与按钮权限

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `parent_id` | `bigint unsigned DEFAULT '0'` | 否 | `'0'` | 父级ID | - |
| `name` | `varchar(64) NOT NULL` | 是 | `-` | 菜单名称 | - |
| `code` | `varchar(64) DEFAULT NULL` | 否 | `NULL` | 组件名称 | - |
| `slug` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 权限标识，如 user:list, user:add | 权限标识字段，通常与后端 Permission 标识、前端按钮权限对应。 |
| `type` | `tinyint(1) NOT NULL DEFAULT '1'` | 是 | `'1'` | 类型: 1目录, 2菜单, 3按钮/API | - |
| `path` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 路由地址(前端)或API路径(后端) | - |
| `component` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 前端组件路径，如 layout/User | - |
| `method` | `varchar(10) DEFAULT NULL` | 否 | `NULL` | 请求方式 | - |
| `icon` | `varchar(64) DEFAULT NULL` | 否 | `NULL` | 图标 | - |
| `sort` | `int DEFAULT '100'` | 否 | `'100'` | 排序 | - |
| `link_url` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 外部链接 | - |
| `is_iframe` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否iframe | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `is_keep_alive` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否缓存 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `is_hidden` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否隐藏 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `is_fixed_tab` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否固定标签页 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `is_full_page` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否全屏 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `generate_id` | `int DEFAULT '0'` | 否 | `'0'` | 生成id | - |
| `generate_key` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 生成key | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | - | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_parent_id&#96; (&#96;parent_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_slug&#96; (&#96;slug&#96;) USING BTREE</code> |

### sa_system_oper_log（操作日志表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `username` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 用户名 | - |
| `app` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 应用名称 | - |
| `method` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 请求方式 | - |
| `router` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 请求路由 | - |
| `service_name` | `varchar(30) DEFAULT NULL` | 否 | `NULL` | 业务名称 | - |
| `ip` | `varchar(45) DEFAULT NULL` | 否 | `NULL` | 请求IP地址 | - |
| `ip_location` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | IP所属地 | - |
| `request_data` | `text` | 否 | `-` | 请求数据 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 更新时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;username&#96; (&#96;username&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_create_time&#96; (&#96;create_time&#96;) USING BTREE</code> |

### sa_system_post（岗位信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 岗位名称 | - |
| `code` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 岗位代码 | - |
| `sort` | `smallint unsigned DEFAULT '0'` | 否 | `'0'` | 排序 | - |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 状态 (1正常 2停用) | 状态枚举按字段注释使用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_system_role（角色表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、角色数据范围

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `name` | `varchar(64) NOT NULL` | 是 | `-` | 角色名称 | - |
| `code` | `varchar(64) NOT NULL` | 是 | `-` | 角色标识(英文唯一)，如: hr_manager | - |
| `level` | `int DEFAULT '1'` | 否 | `'1'` | 角色级别(1-100)：用于行政控制，不可操作级别>=自己的角色 | - |
| `data_scope` | `tinyint DEFAULT '1'` | 否 | `'1'` | 数据范围: 1全部, 2本部门及下属, 3本部门, 4仅本人, 5自定义 | 角色数据范围：1全部，2本部门及下属，3本部门，4仅本人，5自定义。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `sort` | `int DEFAULT '100'` | 否 | `'100'` | - | - |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态: 1启用, 0禁用 | 历史状态字段按注释使用 1启用、0禁用；新增业务状态建议统一 1启用、2禁用/停用。 |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;uk_slug&#96; (&#96;code&#96;) USING BTREE</code> |

### sa_system_role_dept（角色-自定义数据权限关联）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：无
- 创建/更新人：无 / 无
- 权限/审计备注：自定义部门数据权限

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `role_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 角色关联字段。 |
| `dept_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 部门归属字段，配合角色数据范围实现部门数据权限。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_role_id&#96; (&#96;role_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_dept_id&#96; (&#96;dept_id&#96;) USING BTREE</code> |

### sa_system_role_menu（角色权限关联）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：无
- 创建/更新人：无 / 无
- 权限/审计备注：角色菜单权限

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `role_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 角色关联字段。 |
| `menu_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 菜单/权限关联字段。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_menu_id&#96; (&#96;menu_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_role_id&#96; (&#96;role_id&#96;) USING BTREE</code> |

### sa_system_user（用户表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、用户部门/超管标识

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `username` | `varchar(64) NOT NULL` | 是 | `-` | 登录账号 | - |
| `password` | `varchar(255) NOT NULL` | 是 | `-` | 加密密码 | - |
| `realname` | `varchar(64) DEFAULT NULL` | 否 | `NULL` | 真实姓名 | - |
| `gender` | `varchar(10) DEFAULT NULL` | 否 | `NULL` | 性别 | - |
| `avatar` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 头像 | - |
| `email` | `varchar(128) DEFAULT NULL` | 否 | `NULL` | 邮箱 | - |
| `phone` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 手机号 | - |
| `signed` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 个性签名 | - |
| `dashboard` | `varchar(255) DEFAULT 'work'` | 否 | `'work'` | 工作台 | - |
| `dept_id` | `bigint unsigned DEFAULT NULL` | 否 | `NULL` | 主归属部门 | 部门归属字段，配合角色数据范围实现部门数据权限。 |
| `is_super` | `tinyint(1) DEFAULT '0'` | 否 | `'0'` | 是否超级管理员: 1是(跳过权限检查), 0否 | 按字段注释使用 0/1 枚举；新增 SaiAdmin 是否类字段优先使用 1=是、2=否。 |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态: 1启用, 0禁用 | 历史状态字段按注释使用 1启用、0禁用；新增业务状态建议统一 1启用、2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `login_time` | `timestamp NULL DEFAULT NULL` | 否 | `NULL` | 最后登录时间 | - |
| `login_ip` | `varchar(45) DEFAULT NULL` | 否 | `NULL` | 最后登录IP | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;uk_username&#96; (&#96;username&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_dept_id&#96; (&#96;dept_id&#96;) USING BTREE</code> |

### sa_system_user_post（用户与岗位关联表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：无
- 创建/更新人：无 / 无
- 权限/审计备注：用户岗位授权

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `user_id` | `bigint unsigned NOT NULL` | 是 | `-` | 用户主键 | 用户关联字段。 |
| `post_id` | `bigint unsigned NOT NULL` | 是 | `-` | 岗位主键 | - |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_user_id&#96; (&#96;user_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_post_id&#96; (&#96;post_id&#96;) USING BTREE</code> |

### sa_system_user_role（用户角色关联）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：无
- 创建/更新人：无 / 无
- 权限/审计备注：用户角色授权

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `user_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 用户关联字段。 |
| `role_id` | `bigint unsigned NOT NULL` | 是 | `-` | - | 角色关联字段。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_role_id&#96; (&#96;role_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_user_id&#96; (&#96;user_id&#96;) USING BTREE</code> |

### sa_tool_crontab（定时任务信息表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `name` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 任务名称 | - |
| `type` | `smallint DEFAULT '4'` | 否 | `'4'` | 任务类型 | - |
| `target` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 调用任务字符串 | - |
| `parameter` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 调用任务参数 | - |
| `task_style` | `tinyint(1) DEFAULT NULL` | 否 | `NULL` | 执行类型 | - |
| `rule` | `varchar(32) DEFAULT NULL` | 否 | `NULL` | 任务执行表达式 | - |
| `singleton` | `smallint DEFAULT '1'` | 否 | `'1'` | 是否单次执行 (1 是 2 不是) | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 状态 (1正常 2停用) | 状态枚举按字段注释使用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_tool_crontab_log（定时任务执行日志表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：无 / 无
- 权限/审计备注：-

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `crontab_id` | `int unsigned DEFAULT NULL` | 否 | `NULL` | 任务ID | - |
| `name` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 任务名称 | - |
| `target` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 任务调用目标字符串 | - |
| `parameter` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 任务调用参数 | - |
| `exception_info` | `varchar(2000) DEFAULT NULL` | 否 | `NULL` | 异常信息 | - |
| `status` | `smallint DEFAULT '1'` | 否 | `'1'` | 执行状态 (1成功 2失败) | 状态枚举按字段注释使用。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_tool_generate_columns（代码生成业务字段表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `table_id` | `int unsigned DEFAULT NULL` | 否 | `NULL` | 所属表ID | - |
| `column_name` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 字段名称 | - |
| `column_comment` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 字段注释 | - |
| `column_type` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字段类型 | - |
| `default_value` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 默认值 | - |
| `is_pk` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非主键 2 主键 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_required` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非必填 2 必填 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_insert` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非插入字段 2 插入字段 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_edit` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非编辑字段 2 编辑字段 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_list` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非列表显示字段 2 列表显示字段 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_query` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非查询字段 2 查询字段 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `is_sort` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非排序 2 排序 | 代码生成器元数据字段，按 SQL 注释使用；注意它与常规 1=是、2=否 约定不同。 |
| `query_type` | `varchar(100) DEFAULT 'eq'` | 否 | `'eq'` | 查询方式 eq 等于, neq 不等于, gt 大于, lt 小于, like 范围 | - |
| `view_type` | `varchar(100) DEFAULT 'text'` | 否 | `'text'` | 页面控件,text, textarea, password, select, checkbox, radio, date, upload, ma-upload(封装的上传控件) | - |
| `dict_type` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 字典类型 | - |
| `allow_roles` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 允许查看该字段的角色 | - |
| `options` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 字段其他设置 | - |
| `sort` | `tinyint unsigned DEFAULT '0'` | 否 | `'0'` | 排序 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### sa_tool_generate_tables（代码生成业务表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `table_name` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 表名称 | - |
| `table_comment` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 表注释 | - |
| `stub` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | stub类型 | - |
| `template` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 模板名称 | - |
| `namespace` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 命名空间 | - |
| `package_name` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 控制器包名 | - |
| `business_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 业务名称 | - |
| `class_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 类名称 | - |
| `menu_name` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 生成菜单名 | - |
| `belong_menu_id` | `int DEFAULT NULL` | 否 | `NULL` | 所属菜单 | - |
| `tpl_category` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 生成类型,single 单表CRUD,tree 树表CRUD,parent_sub父子表CRUD | - |
| `generate_type` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 压缩包下载 2 生成到模块 | - |
| `generate_path` | `varchar(100) DEFAULT 'saiadmin-artd'` | 否 | `'saiadmin-artd'` | 前端根目录 | - |
| `generate_model` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 软删除 2 非软删除 | - |
| `generate_menus` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 生成菜单列表 | - |
| `build_menu` | `smallint DEFAULT '1'` | 否 | `'1'` | 是否构建菜单 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `component_type` | `smallint DEFAULT '1'` | 否 | `'1'` | 组件显示方式 | - |
| `options` | `varchar(1500) DEFAULT NULL` | 否 | `NULL` | 其他业务选项 | - |
| `form_width` | `int DEFAULT '800'` | 否 | `'800'` | 表单宽度 | - |
| `is_full` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 是否全屏 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `source` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 数据源 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### saiai_chat（AI对话记录表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、AI 对话归属用户/分组

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `group_id` | `int DEFAULT NULL` | 否 | `NULL` | 分组ID | AI 对话分组关联字段。 |
| `user_id` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 用户ID | AI 会话归属用户字段，关联系统用户。 |
| `role` | `varchar(20) NOT NULL DEFAULT 'user'` | 是 | `'user'` | 角色 | - |
| `model` | `varchar(50) DEFAULT ''` | 否 | `''` | 模型名称 | - |
| `content` | `text` | 否 | `-` | 消息内容 | - |
| `tokens` | `int DEFAULT '0'` | 否 | `'0'` | 消耗token数 | - |
| `ip` | `varchar(50) DEFAULT ''` | 否 | `''` | IP地址 | - |
| `user_agent` | `varchar(255) DEFAULT ''` | 否 | `''` | User Agent | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建人 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 修改人 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_user_id&#96; (&#96;user_id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_session_id&#96; (&#96;group_id&#96;) USING BTREE</code> |

### saiai_chat_group（AI对话分组表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、AI 会话归属用户

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `user_id` | `int NOT NULL DEFAULT '0'` | 是 | `'0'` | 用户ID | AI 会话归属用户字段，关联系统用户。 |
| `title` | `varchar(255) DEFAULT ''` | 否 | `''` | 会话标题 | - |
| `is_top` | `tinyint DEFAULT '0'` | 否 | `'0'` | 是否置顶 | 按字段注释使用 0/1 枚举；新增 SaiAdmin 是否类字段优先使用 1=是、2=否。 |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>KEY &#96;idx_user_id&#96; (&#96;user_id&#96;) USING BTREE</code> |

### saiai_config（AI配置表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、AI 平台配置审计

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int NOT NULL AUTO_INCREMENT` | 是 | `-` | - | - |
| `name` | `varchar(50) NOT NULL` | 是 | `-` | 配置名称 | - |
| `type` | `varchar(20) NOT NULL` | 是 | `-` | 平台类型: gemini, openai, deepseek | - |
| `ai_url` | `varchar(255) NOT NULL` | 是 | `-` | API URL | AI 平台 API 地址字段。 |
| `ai_key` | `varchar(255) NOT NULL` | 是 | `-` | API Key | AI 平台密钥字段，文档只记录结构，不记录实际密钥值。 |
| `model` | `varchar(50) NOT NULL` | 是 | `-` | 模型名称 | - |
| `is_default` | `tinyint(1) NOT NULL DEFAULT '0'` | 是 | `'0'` | 是否默认: 1是,0否 | 按字段注释使用 0/1 枚举；新增 SaiAdmin 是否类字段优先使用 1=是、2=否。 |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | - | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### saicode_column（代码生成业务字段表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、低代码字段配置

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `table_id` | `int unsigned DEFAULT NULL` | 否 | `NULL` | 所属表ID | 关联 `saicode_table.id`。 |
| `column_name` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 字段名称 | - |
| `column_comment` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 字段注释 | - |
| `column_type` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 字段类型 | - |
| `column_width` | `int DEFAULT '0'` | 否 | `'0'` | 列表宽度 | - |
| `default_value` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 默认值 | - |
| `is_pk` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非主键 2 主键 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_required` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非必填 2 必填 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_insert` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非插入字段 2 插入字段 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_edit` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非编辑字段 2 编辑字段 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_list` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非列表显示字段 2 列表显示字段 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_query` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非查询字段 2 查询字段 | 代码生成器历史反向枚举，以字段注释为准。 |
| `is_sort` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 非排序 2 排序 | 代码生成器历史反向枚举，以字段注释为准。 |
| `query_type` | `varchar(100) DEFAULT 'eq'` | 否 | `'eq'` | 查询方式 | - |
| `view_type` | `varchar(100) DEFAULT 'input'` | 否 | `'input'` | 页面控件 | - |
| `dict_type` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 字典类型 | - |
| `options` | `text` | 否 | `-` | 字段其他设置 | - |
| `list_sort` | `smallint unsigned DEFAULT '0'` | 否 | `'0'` | 列表排序 | - |
| `span` | `smallint DEFAULT NULL` | 否 | `NULL` | 布局 | - |
| `form_sort` | `smallint unsigned DEFAULT '0'` | 否 | `'0'` | 字段排序 | - |
| `query_component` | `varchar(200) DEFAULT 'input'` | 否 | `'input'` | 查询控件 | - |
| `query_dict` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 查询字典 | - |
| `query_span` | `int DEFAULT '6'` | 否 | `'6'` | 搜索栅格宽度 | - |
| `query_sort` | `int DEFAULT '0'` | 否 | `'0'` | 搜索排序 | - |
| `query_options` | `text` | 否 | `-` | 查询属性配置 | - |
| `table_field` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 列表名称 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### saicode_table（低代码数据表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、低代码表配置

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 主键 | - |
| `table_name` | `varchar(200) DEFAULT NULL` | 否 | `NULL` | 表名称 | - |
| `table_comment` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 表注释 | - |
| `stub` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | stub类型 | - |
| `template` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 模板名称 | - |
| `namespace` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 命名空间 | - |
| `package_name` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 控制器包名 | - |
| `business_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 业务名称 | - |
| `class_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 类名称 | - |
| `menu_name` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 生成菜单名 | - |
| `belong_menu_id` | `int DEFAULT NULL` | 否 | `NULL` | 所属菜单 | 关联 `sa_system_menu.id`。 |
| `tpl_category` | `varchar(100) DEFAULT NULL` | 否 | `NULL` | 生成类型 | - |
| `generate_type` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 压缩包下载 2 生成到模块 | - |
| `generate_model` | `smallint DEFAULT '1'` | 否 | `'1'` | 1 软删除 2 非软删除 | - |
| `generate_path` | `varchar(100) DEFAULT 'saiadmin-artd'` | 否 | `'saiadmin-artd'` | 前端根目录 | - |
| `generate_menus` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 生成菜单列表 | - |
| `component_type` | `smallint DEFAULT '1'` | 否 | `'1'` | 组件方式 | - |
| `form_width` | `int DEFAULT '600'` | 否 | `'600'` | 宽度 | - |
| `is_full` | `smallint DEFAULT '1'` | 否 | `'1'` | 是否全屏 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `span` | `smallint DEFAULT NULL` | 否 | `NULL` | 布局 | - |
| `options` | `varchar(1500) DEFAULT NULL` | 否 | `NULL` | 其他业务选项 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `source` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 数据源 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### saipay_order（订单记录表）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、支付订单归属

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 订单ID | - |
| `plugin` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 插件平台 | 支付插件来源字段。 |
| `order_no` | `varchar(50) NOT NULL DEFAULT ''` | 是 | `''` | 订单号 | 订单唯一编号，受唯一索引 `unx_order_no` 约束。 |
| `order_name` | `varchar(255) NOT NULL` | 是 | `-` | 订单名称 | - |
| `order_price` | `decimal(10,2) unsigned NOT NULL` | 是 | `-` | 订单金额 | 金额字段，单位和精度以业务代码为准。 |
| `pay_price` | `decimal(10,2) unsigned DEFAULT NULL` | 否 | `NULL` | 支付金额 | 金额字段，单位和精度以业务代码为准。 |
| `remark` | `varchar(255) DEFAULT ''` | 否 | `''` | 备注留言 | - |
| `pay_method` | `varchar(60) NOT NULL DEFAULT ''` | 是 | `''` | 支付方式 | 支付方式字段，通常对应支付渠道/方式字典。 |
| `pay_type` | `varchar(60) DEFAULT NULL` | 否 | `NULL` | 支付类型 | - |
| `pay_status` | `tinyint unsigned DEFAULT '0'` | 否 | `'0'` | 付款状态 | 支付状态枚举按支付插件业务代码使用。 |
| `pay_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 付款时间 | 支付成功或状态变更时间字段。 |
| `trade_no` | `varchar(255) DEFAULT '0'` | 否 | `'0'` | 第三方交易 | 第三方支付平台交易号。 |
| `pay_url` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 支付链接 | 支付跳转或收银台链接。 |
| `pay_url_expire` | `datetime DEFAULT NULL` | 否 | `NULL` | 过期时间 | 支付链接过期时间。 |
| `member_id` | `int DEFAULT NULL` | 否 | `NULL` | 关联用户 | 支付订单归属会员字段，关联 `sa_member.id`。 |
| `order_id` | `int DEFAULT NULL` | 否 | `NULL` | 关联订单 | 关联业务订单 ID。 |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建者 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新者 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;unx_order_no&#96; (&#96;order_no&#96;)</code> |
| <code>KEY &#96;idx_plugin&#96; (&#96;plugin&#96;)</code> |
| <code>KEY &#96;idx_trade_no&#96; (&#96;trade_no&#96;)</code> |
| <code>KEY &#96;idx_pay_time&#96; (&#96;pay_time&#96;)</code> |
| <code>KEY &#96;idx_pay_method&#96; (&#96;pay_method&#96;)</code> |

### saisms_config（短信配置）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、短信网关配置

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `gateway` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 网关标识 | 短信网关唯一标识，受唯一索引 `unx_gateway` 约束。 |
| `config_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 网关名称 | - |
| `config` | `varchar(1000) DEFAULT NULL` | 否 | `NULL` | 配置 | 短信网关配置字段，文档只记录结构，不记录实际密钥值。 |
| `status` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 状态 | 状态字段；新增业务建议统一 1启用/正常，2禁用/停用。 |
| `sort` | `smallint DEFAULT '100'` | 否 | `'100'` | 排序 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建人 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新人 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
| <code>UNIQUE KEY &#96;unx_gateway&#96; (&#96;gateway&#96;) USING BTREE</code> |

### saisms_record（短信记录）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：无
- 创建/更新人：无 / 无
- 权限/审计备注：短信发送与验证码验证记录

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `gateway` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 网关 | 短信网关标识，通常关联 `saisms_config.gateway`。 |
| `mobile` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 手机号码 | 个人信息字段，查询、导出、日志中注意脱敏。 |
| `code` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 验证码 | 验证码字段，日志和响应中避免明文暴露。 |
| `content` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 短信内容 | - |
| `status` | `varchar(20) DEFAULT NULL` | 否 | `NULL` | 发送状态 | 发送状态以短信网关返回和业务代码为准。 |
| `response` | `varchar(500) DEFAULT NULL` | 否 | `NULL` | 返回结果 | 网关响应结果，可能包含敏感信息，展示时注意脱敏。 |
| `is_verify` | `tinyint(1) DEFAULT '2'` | 否 | `'2'` | 是否验证 | SaiAdmin 是否类字段约定：1=是，2=否。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |

### saisms_tag（短信标签）

- 存储引擎：InnoDB
- 字符集：utf8mb4
- 排序规则：utf8mb4_0900_ai_ci
- 行格式：DYNAMIC
- 软删除：`delete_time`
- 创建/更新人：`created_by` / `updated_by`
- 权限/审计备注：创建人归属、更新人审计、短信模板标签

| 字段 | 定义 | 必填 | 默认值 | 说明 | 规范备注 |
| --- | --- | --- | --- | --- | --- |
| `id` | `int unsigned NOT NULL AUTO_INCREMENT` | 是 | `-` | 编号 | - |
| `tag_name` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 标签名称 | - |
| `gateway` | `varchar(50) DEFAULT NULL` | 否 | `NULL` | 网关标识 | 短信网关标识，通常关联 `saisms_config.gateway`。 |
| `sms_type` | `tinyint(1) DEFAULT '1'` | 否 | `'1'` | 短信类型 | 短信类型枚举按短信插件业务代码使用。 |
| `template_id` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 模板编号 | 第三方短信平台模板编号。 |
| `content` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 短信内容 | - |
| `remark` | `varchar(255) DEFAULT NULL` | 否 | `NULL` | 备注 | - |
| `created_by` | `int DEFAULT NULL` | 否 | `NULL` | 创建人 | 创建人字段：记录创建用户 ID，也是数据归属/本人数据权限的重要依据。 |
| `updated_by` | `int DEFAULT NULL` | 否 | `NULL` | 更新人 | 更新人字段：记录最后更新用户 ID，用于审计追踪。 |
| `create_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 创建时间 | 创建时间字段。 |
| `update_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 修改时间 | 更新时间字段。 |
| `delete_time` | `datetime DEFAULT NULL` | 否 | `NULL` | 删除时间 | 软删除字段：NULL 表示未删除，非 NULL 表示已删除。 |

| 索引/约束 |
| --- |
| <code>PRIMARY KEY (&#96;id&#96;) USING BTREE</code> |
