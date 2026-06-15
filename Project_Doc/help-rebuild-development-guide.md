# HelpSupport 父框架重做开发文档

本文用于指导 HelpSupport 重新开发：后端与管理端基于父框架 `b8aiadmin` 重新搭建，移动端改为 Flutter 重新实现。旧项目只作为业务、UI、接口与数据结构参考，不作为新项目的直接延续。

## 1. 重做目标

### 1.1 目标

- 使用父框架 `/Users/openb8/Downloads/项目/b8aiadmin` 作为新的后端与 admin 基线。
- 新建或重建 `help` 业务插件，保持 SaiAdmin/Webman 插件模式。
- 使用 Phinx 管理 HelpSupport 业务表、菜单、权限、字典和初始化配置。
- 使用 APIDOC/OpenAPI 作为 Flutter API 契约来源。
- Flutter 端重新开发患者端与医生端，复用现有 UI 设计稿和静态素材，不复用 UniApp 页面结构，并从第一版开始支持多语言国际化。
- 后台管理端重新用 SaiCode + 手写扩展完成 CRUD 与业务审核页面。
- 本地 AI 对话模式使用 `llama.cpp` + `llama_cpp_dart` 方案，模型下载链接、介绍、提示词和默认参数由后台配置。
- 登录体系接入 Google 登录、Apple 登录和 Firebase FCM 推送，JWT 单设备登录直接启用父框架已有开关。

### 1.2 非目标

- 不在当前旧后端上继续补丁式修复。
- 不继续维护 UniApp 作为主移动端。
- 不把 `Databasse/helpsupport.sql` 直接当成新项目最终数据库源头。
- 不为旧字段、旧接口路径、旧前端封装做兼容别名，除非后续明确要求兼容。

## 2. 当前项目可复用资料

| 来源 | 用途 | 说明 |
| --- | --- | --- |
| `开发需求.md` | 产品需求主源头 | 已整合 PRD、原始需求和 UI 缺口，是功能拆分依据 |
| `医疗支持图片ui/` | Flutter UI 还原依据 | 覆盖登录、AI、社区、计划、医生端、素材、预约、我的等页面 |
| `review/` | 归档资料包 | 已包含数据库、结构说明、UI 图、静态素材和构建静态资源 |
| `server/plugin/help/config/route.php` | 旧 API 参考 | 只参考业务接口分组，不直接沿用实现 |
| `server/plugin/help/app/*` | 旧业务逻辑参考 | 可参考实体和流程，但需重新按父框架规范实现 |
| `saiadmin-artd/src/views/plugin/help` | 后台模块参考 | 可参考模块覆盖范围，不直接复制生成结果 |
| `helpsupport_flutter/` | Flutter 原型和素材参考 | 可复用 assets、主题方向和部分静态页面经验 |

## 3. 新项目推荐结构

建议新建独立工作目录，例如：

```text
helpsupport-next/
├── server/                 # 来自父框架 b8aiadmin 的 Webman/SaiAdmin 后端
├── saiadmin-artd/          # 来自父框架 b8aiadmin 的管理端
├── flutter_app/            # 新 Flutter 移动端
├── Database/               # 父框架基线 + HelpSupport 增量迁移
├── Doc/                    # 项目文档
├── OpenAPI/                # OpenAPI 导出快照
└── review/                 # 可选，只保留需求和 UI 参考，不作为运行时代码
```

如果继续在当前仓库内开发，建议先创建新分支，并明确废弃旧 `helpsupport-frontend/` 主开发路径。

## 4. 父框架初始化流程

### 4.1 复制基线

从父框架复制以下目录作为新项目起点：

```text
/Users/openb8/Downloads/项目/b8aiadmin/server
/Users/openb8/Downloads/项目/b8aiadmin/saiadmin-artd
/Users/openb8/Downloads/项目/b8aiadmin/Database
/Users/openb8/Downloads/项目/b8aiadmin/Doc
/Users/openb8/Downloads/项目/b8aiadmin/OpenAPI
/Users/openb8/Downloads/项目/b8aiadmin/packages
/Users/openb8/Downloads/项目/b8aiadmin/.codex/skills
```

不要复制父框架的 `node_modules/`、`vendor/`、`runtime/`、`dist/`、`.env`。

### 4.2 后端安装

在新项目 `server/` 执行：

```bash
composer install
php webman b8:install
php webman b8:migrate:status
php webman route:list
```

首次安装应以父框架 `Database/b8aiadmin.sql` 为基础库，HelpSupport 业务表通过 `Database/migrations/` 逐步加入。

### 4.3 创建业务插件

```bash
cd server
php webman sai:plugin help
```

插件目标结构：

```text
server/plugin/help/
├── app/
│   ├── admin/
│   │   ├── controller/
│   │   ├── logic/
│   │   └── validate/
│   ├── api/
│   │   ├── controller/
│   │   ├── logic/
│   │   └── validate/
│   ├── model/
│   └── service/
├── config/
│   └── route.php
└── README.md
```

建议把移动端 API 放在 `app/api`，后台 CRUD 放在 `app/admin`，复杂业务服务放在 `app/service`。

## 5. 后端开发规范

### 5.1 统一响应

新业务 API 使用父框架全局辅助函数：

```php
return ok($data);
return ok('保存成功');
return fail('参数错误');
return fail('无权限操作', 403);
```

响应格式固定为：

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "trace_id": "可选"
}
```

Flutter 端必须按业务 `code` 判断成功，不只依赖 HTTP 状态码。

### 5.2 路由分组

建议新 API 路径保留 `/app/help` 前缀：

| 分组 | 路径 | 登录要求 | 用途 |
| --- | --- | --- | --- |
| 公共配置 | `/app/help/common/*` | 否 | 协议、运行配置、版本信息、引导页配置 |
| 认证 | `/app/help/auth/*` | 部分 | 登录、注册、个人资料、退出登录 |
| 首页 | `/app/help/home/*` | 是 | 首页聚合、最近会话、消息红点 |
| AI | `/app/help/chat/*` | 是 | 会话、记录、在线对话、实时配置 |
| 本地模型 | `/app/help/local-model/*` | 是 | 模型目录、下载配置、提示词、校验信息 |
| 社区 | `/app/help/community/*` | 是 | 帖子、评论、关注、收藏、举报、审核 |
| 计划 | `/app/help/plan/*` | 是 | 患者计划、任务、评估量表 |
| 素材 | `/app/help/material/*` | 是 | 教育素材、私人素材、历史、收藏 |
| 预约 | `/app/help/appointment/*` | 是 | 医生列表、时段、预约、取消 |
| 医生日程 | `/app/help/doctor/*` | 是 | 患者、治疗计划、模板、审核 |
| 我的 | `/app/help/me/*` | 是 | 个人主页、隐私、荣誉、回忆录 |
| 推送 | `/app/help/push/*` | 是 | 设备 token 注册、注销、推送偏好 |

非标准动作必须显式写入 `server/plugin/help/config/route.php`。标准后台 CRUD 可依赖 SaiCode 生成的插件默认路由，但前端 API 必须与实际路径一致。

### 5.3 认证与用户体系

- 复用父框架 `saiuser` 会员体系作为患者/医生登录主体。
- 会员基础表继续使用 `sa_member`。
- 用户身份通过扩展资料字段或独立资料表区分：`patient`、`doctor`。
- 医生资质审核必须由后台管理端完成，审核通过前不可使用医生专属能力。
- Token 使用 `Authorization: Bearer <access_token>`。
- JWT 单设备登录必须启用：父框架已经在 `server/config/plugin/tinywan/jwt/app.php` 提供 `is_single_device` 开关，新项目只需要将其设为 `true` 并验证 Redis。
- 开启单设备登录后 Redis 是强依赖，部署前必须确认 Redis 连接、过期时间和重启策略。
- 单设备登录只负责让旧 access token 失效，不等于自动清理推送 token；推送设备状态仍由业务设备表维护。
- Google 登录和 Apple 登录统一进入 `saiuser` 会员登录流程：服务端校验第三方 identity token 后，复用 `sa_member_platform` 和 `sa_member_platform_rel` 绑定或创建 `sa_member` 账号，再调用现有会员登录签发链路返回本系统 JWT。

### 5.4 第三方登录

必须支持：

| 登录方式 | Flutter 端 | 后端校验 | 配置项 |
| --- | --- | --- | --- |
| Google 登录 | Google Sign-In SDK | 校验 Google ID Token 的签名、aud、iss、exp、email_verified | Web client id、iOS client id、Android client id |
| Apple 登录 | Sign in with Apple | 校验 Apple identityToken 的签名、aud、iss、exp、sub | Team ID、Bundle ID、Service ID、Key ID、Private Key |

服务端绑定规则：

- 第三方唯一身份复用 `saiuser` 已有绑定表，不新增平行 OAuth 绑定表。
- `sa_member_platform` 写平台类型，例如 `GOOGLE`、`APPLE`。
- `sa_member_platform_rel.platform_openid` 写 Google `sub` 或 Apple `sub`。
- 同一邮箱已经存在会员时，必须有明确绑定策略，避免误合并账号。
- Apple 登录可能只在首次授权返回邮箱和姓名，Flutter 端和服务端都要保存首次返回资料。
- 第三方登录仍必须返回本系统 `access_token`、`refresh_token` 和用户身份资料。
- 医生身份仍要走医生证书上传和后台审核，不因第三方登录自动成为医生。
- 如果 Google/Apple 需要保存额外字段，例如邮箱验证状态、首次资料、授权来源，不新增新的 OAuth 绑定表；优先通过 HelpSupport 业务资料表保存，或在确认父框架允许后对 `sa_member_platform_rel` 做增量字段迁移。

复用父框架已有表：

```text
sa_member_platform
sa_member_platform_rel
```

`sa_member_platform` 现有核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 平台 ID |
| `platform_name` | 平台名称 |
| `platform_code` | 平台唯一标识，例如 `EMAIL`、`MOBILE`、`GOOGLE`、`APPLE` |
| `status` | 状态 |

`sa_member_platform_rel` 现有核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `member_id` | 会员 ID |
| `platform_id` | 平台 ID |
| `platform_openid` | 平台唯一身份，Google/Apple 使用 `sub` |
| `is_bind` | 是否绑定 |
| `bind_time` | 绑定时间 |
| `unbind_time` | 解绑时间 |

HelpSupport 迁移只需要幂等插入 `GOOGLE`、`APPLE` 平台记录；不要重复创建第三方绑定表。

### 5.5 FCM 推送与设备 token

Flutter 端接入 Firebase Cloud Messaging：

- Android 使用 FCM token。
- iOS 使用 APNs + FCM，Flutter 端通过 Firebase Messaging 获取 FCM token，必要时记录 APNs token 作为排查字段。
- 用户登录成功后注册设备 token。
- token 刷新时重新上报。
- 用户退出登录时注销当前设备 token。
- JWT 单设备登录踢掉旧设备后，服务端应将旧设备 token 标记为失效，避免继续推送给已下线设备。

设备 token 不建议保存到 `sa_member` 主表。原因：

- FCM token 会刷新，直接写主表会丢失历史和审计。
- 即使开启单设备登录，也需要记录旧设备失效、退出、刷新和平台信息。
- 后续如改成多设备登录，独立表无需重构会员主表。
- 一个用户可能在同一平台多次安装或换机，独立表更容易做清理。

建议新增设备表：

```text
sa_member_push_device
```

核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `member_id` | 会员 ID |
| `device_id` | Flutter 端生成或系统可用的设备标识 |
| `platform` | `ios`、`android` |
| `fcm_token` | 当前 FCM token |
| `apns_token` | iOS APNs token，可选 |
| `app_version` | App 版本 |
| `locale` | 当前语言 |
| `timezone` | 当前时区 |
| `is_active` | `1` 有效，`2` 失效 |
| `last_active_time` | 最近活跃时间 |
| `logout_time` | 退出或被踢下线时间 |

推荐接口：

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/app/help/push/device/register` | 登录后注册或刷新设备 token |
| `POST` | `/app/help/push/device/unregister` | 退出登录时注销当前设备 token |
| `POST` | `/app/help/push/preference` | 保存推送偏好 |
| `GET` | `/app/help/push/preference` | 读取推送偏好 |

后台发送推送时只选择 `is_active=1` 且匹配当前会员的设备。开启单设备登录后，新登录成功时应将该会员其他设备记录置为失效。

### 5.6 APIDOC 与 OpenAPI

新建 HelpSupport 移动端 APIDOC app key，建议：

```text
helpsupport-api
```

每个移动端接口都必须补 APIDOC 注解：

- 接口标题
- 精确 URL
- 请求方法
- Query/Param 字段
- 返回结构

导出地址：

```text
/apidoc/openapi/helpsupport-api
```

Flutter API 层以该 OpenAPI 为契约。开发早期可以手写 DTO 和 Repository，但 P0 结束前必须保证 OpenAPI 能覆盖所有 Flutter 已使用接口，包括第三方登录、推送设备注册和本地模型目录接口。

### 5.7 日志与 trace

- 业务异常返回 `fail()`，系统异常进入 Webman 异常处理。
- 日志中不得输出 Bearer、Cookie、refresh token、短信验证码、FCM token、Apple identityToken、Google ID Token、医生证书 URL 的完整敏感参数。
- 所有 Flutter 端错误上报或调试弹窗保留 `trace_id`，便于后端定位。

## 6. 数据库设计

### 6.1 数据库源头

新项目数据库源头分两层：

| 层级 | 文件 | 用途 |
| --- | --- | --- |
| 父框架基线 | `Database/b8aiadmin.sql` | SaiAdmin、SaiUser、SaiAI、SaiCode 等基础表 |
| HelpSupport 增量 | `Database/migrations/*.php` | 业务表、字段、菜单、权限、字典、初始化配置 |

旧项目 `Databasse/helpsupport.sql` 只能作为表结构参考。重做时不能继续依赖 `server/plugin/help/update.sql` 或独立 SQL patch。

### 6.2 表设计分组

建议业务表按以下分组新增迁移。

| 领域 | 表 |
| --- | --- |
| 社区 | `sa_community_post`、`sa_community_comment`、`sa_community_tag`、`sa_community_like`、`sa_community_collect`、`sa_community_follow_tag`、`sa_community_follow_member`、`sa_community_report` |
| 内容素材 | `sa_content_category`、`sa_content_material`、`sa_material_comment`、`sa_material_comment_like`、`sa_material_like`、`sa_material_collect` |
| 计划任务 | `sa_treatment_stage`、`sa_treatment_plan`、`sa_daily_task`、`sa_member_assessment_result` |
| 医生资源 | `sa_doctor_patient`、`sa_doctor_task_template_folder`、`sa_doctor_task_template`、`sa_doctor_assessment_scale` |
| 预约 | `sa_doctor_appointment` |
| 聊天 | `sa_member_chat_config`、`sa_member_chat_session`、`sa_member_chat_record` |
| 本地模型配置 | `sa_local_model_catalog`、`sa_local_model_prompt` |
| 第三方登录与推送 | 复用 `sa_member_platform`、`sa_member_platform_rel`，新增 `sa_member_push_device`、`sa_member_push_preference` |
| App 配置 | `sa_app_onboarding_page` |
| 个人记录 | `sa_member_journal`、`sa_member_memoir`、`sa_member_content_history`、`sa_member_message` |
| 康复日志 | `sa_member_recovery_goal_log`、`sa_member_trigger_log` |

注意：旧代码中存在 `SaMemberRecoveryGoalLog`、`SaMemberTriggerLog` 模型，但旧基线 SQL 中没有对应建表。新项目必须通过迁移补齐，不能靠运行时提示用户手动执行 SQL。

### 6.3 表字段约定

后台 CRUD 表默认包含：

```text
id
created_by
updated_by
create_time
update_time
delete_time
```

关键规则：

- `status` 优先使用 `tinyint unsigned NOT NULL DEFAULT 1`。
- 是否类字段使用 `is_*`，默认约定 `1是 2否`。
- 金额使用 `decimal`，不使用 `float`。
- JSON 字段必须在模型里声明类型转换。
- 涉及数据权限的后台表必须有 `created_by`，对应 Logic 显式开启 `protected bool $scope = true;`。
- 医疗、隐私、证书、日记等敏感数据必须标注存储边界和脱敏策略。

### 6.4 本地模型配置表

后台需要配置 Flutter 本地模型模式使用的模型目录。建议新增：

```text
sa_local_model_catalog
sa_local_model_prompt
```

`sa_local_model_catalog` 核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `name` | 模型显示名称 |
| `code` | 模型编码 |
| `provider` | 模型来源 |
| `model_family` | Llama、Qwen、Gemma 等 |
| `quantization` | 量化类型，例如 `Q4_K_M` |
| `file_size` | 文件大小 |
| `download_url` | 模型下载地址 |
| `sha256` | 文件校验值 |
| `intro` | 默认介绍 |
| `intro_i18n` | 多语言介绍 JSON |
| `license` | 许可证说明 |
| `min_memory_mb` | 推荐最小内存 |
| `context_size` | 默认上下文长度 |
| `default_temperature` | 默认温度 |
| `default_top_p` | 默认 top_p |
| `sort` | 排序 |
| `status` | 状态 |

`sa_local_model_prompt` 核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `model_id` | 关联模型，可为空表示通用提示词 |
| `chat_mode` | `doctor`、`companion`、`patient` |
| `locale` | `en-US`、`zh-CN` 等 |
| `title` | 提示词标题 |
| `system_prompt` | 系统提示词 |
| `first_message` | 默认开场白 |
| `safety_prompt` | 安全边界提示 |
| `status` | 状态 |

### 6.5 App 引导页配置表

引导页内容由后台配置，Flutter 不写死图片和文案。建议新增：

```text
sa_app_onboarding_page
```

核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `scene` | 场景，例如 `first_launch`、`feature_intro` |
| `version` | 引导页配置版本 |
| `locale` | `en-US`、`zh-CN` 等 |
| `title` | 标题 |
| `description` | 说明 |
| `image` | 图片 URL 或附件路径 |
| `button_text` | 按钮文案 |
| `action_type` | `next`、`skip`、`route`、`external_url` |
| `action_value` | 跳转路由或 URL |
| `sort` | 排序 |
| `status` | 状态 |
| `start_time` | 生效开始时间 |
| `end_time` | 生效结束时间 |

推荐接口：

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/app/help/common/onboarding` | 获取当前语言和版本可用的引导页 |
| `POST` | `/app/help/common/onboarding/seen` | 登录后可选，上报已看版本 |

Flutter 本地只保存“已看过的引导版本”和短期缓存，不把引导内容作为固定资源写死。

### 6.6 迁移规范

所有业务表通过 Phinx 创建：

```bash
cd server
php webman b8:migrate:create CreateHelpCommunityTables
php -l ../Database/migrations/<file>.php
php webman b8:migrate --dry-run
php webman b8:migrate
php webman b8:migrate:status
```

迁移要求：

- 建表、加字段、插入字典、插入菜单都必须幂等。
- 初始化数据需要可回滚，或在迁移中明确不可逆原因。
- 回滚不能误删用户后续创建的数据。
- 生产执行迁移前必须先确认备份、目标库和回滚窗口。

## 7. 管理后台开发

### 7.1 开发方式

后台 CRUD 优先使用 SaiCode：

```text
需求拆表 -> Phinx 建表 -> dry-run -> migrate -> SaiCode 装载表 -> 配置字段/搜索/表单 -> 预览 -> 生成到项目 -> 验证
```

生成目标：

```text
saiadmin-artd/src/views/plugin/help/<module>/<business>/
saiadmin-artd/src/views/plugin/help/api/<module>/<business>.ts
server/plugin/help/app/admin/controller/<module>/
server/plugin/help/app/admin/logic/<module>/
server/plugin/help/app/admin/validate/<module>/
server/plugin/help/app/model/<module>/
```

### 7.2 后台模块清单

P0 后台必须覆盖：

| 模块 | 能力 |
| --- | --- |
| 医生资质审核 | 查看证书、审核通过、驳回、记录原因 |
| App 引导页配置 | 启动后引导页图片、标题、说明、按钮、跳转、版本、生效状态和多语言内容 |
| 社区内容审核 | 帖子审核、评论审核、举报处理 |
| 内容分类 | 教育素材、娱乐内容分类 |
| 教育素材 | 图文/音视频素材维护、上下架、排序 |
| 治疗阶段 | 阶段名称、说明、排序、状态 |
| 治疗计划 | 计划基础信息、适用人群、状态 |
| 每日任务 | 任务标题、类型、日期、完成条件 |
| 任务模板 | 模板文件夹、模板内容、附件 |
| 评估量表 | 题目、选项、计分方式、草稿/发布 |
| 预约管理 | 医生排班、价格、预约状态 |
| AI 聊天配置 | 模式、模型、提示词、开关、实时配置 |
| 本地模型目录 | 模型下载链接、文件大小、SHA256、量化类型、介绍、许可证、推荐设备、排序上下架 |
| 本地模型提示词 | 按聊天模式和语言配置 system prompt、开场白、安全提示词 |
| 第三方登录配置 | Google/Apple 登录开关、client id、回调策略、`saiuser` 平台绑定规则 |
| 推送配置 | Firebase 项目配置、推送模板、通知开关、设备 token 状态 |
| 消息管理 | 系统消息、任务消息、互动消息 |

P1 再补：

- 荣誉徽章规则
- 积分流水
- 回忆录配置
- 私人素材审核
- 敏感词和风控规则

### 7.3 菜单与权限

权限 slug 建议：

```text
help:<module>:<business>:index
help:<module>:<business>:save
help:<module>:<business>:update
help:<module>:<business>:read
help:<module>:<business>:destroy
help:<module>:<business>:audit
```

生成后必须检查：

- `sa_system_menu` 菜单是否存在。
- 目标角色是否授权。
- 前端 `v-permission` 是否与后端 `Permission` 一致。
- 用户菜单/权限缓存是否刷新。

### 7.4 后台验证

后端：

```bash
cd server
php -l plugin/help/app/admin/controller/<module>/<Controller>.php
php -l plugin/help/app/admin/logic/<module>/<Logic>.php
php -l plugin/help/app/admin/validate/<module>/<Validate>.php
php -l plugin/help/app/model/<module>/<Model>.php
php webman route:list
```

前端：

```bash
cd saiadmin-artd
pnpm exec vue-tsc --noEmit
pnpm build
```

如项目阶段不允许完整 build，至少执行类型检查并打开后台页面做真实请求验证。

## 8. Flutter 移动端开发

### 8.1 Flutter 端定位

Flutter 端覆盖患者端与医生端，共用登录、消息、个人资料和底部导航。角色差异由登录用户身份决定。

现有 `helpsupport_flutter/` 可作为素材和原型参考，但新项目建议在 `flutter_app/` 重新整理结构。

### 8.2 推荐技术栈

| 能力 | 建议 |
| --- | --- |
| 网络 | `dio` |
| 路由 | `go_router` |
| 状态管理 | `riverpod` |
| JSON 模型 | `freezed` + `json_serializable` |
| 本地安全存储 | `flutter_secure_storage` |
| 本地结构化数据 | `drift` 或 SQLite 封装 |
| 普通配置缓存 | `shared_preferences` |
| 图片/文件选择 | `image_picker`、`file_picker` |
| 国际化 | Flutter `gen-l10n` + ARB 文件 |
| Google 登录 | `google_sign_in` |
| Apple 登录 | `sign_in_with_apple` |
| Firebase 推送 | `firebase_core` + `firebase_messaging` |
| 本地通知 | `flutter_local_notifications` + `timezone` |
| 权限申请 | `permission_handler`，必要时结合平台原生权限说明 |
| 本地 LLM | `llama_cpp_dart` + 平台侧 `llama.cpp` 动态库 |

当前原型已有 `dio`、`image_picker`、`file_picker`、`webview_flutter`、`shared_preferences` 等依赖。重做时应补齐路由、状态、模型生成、安全存储、国际化、Google/Apple 登录、Firebase 推送、本地通知、权限申请和本地 LLM 运行能力。

### 8.3 推荐目录

```text
flutter_app/lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme.dart
│   └── bootstrap.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_result.dart
│   │   └── auth_interceptor.dart
│   ├── auth/
│   ├── storage/
│   ├── i18n/
│   ├── push/
│   ├── notifications/
│   ├── permissions/
│   ├── local_llm/
│   └── utils/
├── features/
│   ├── auth/
│   ├── home/
│   ├── chat/
│   ├── community/
│   ├── plan/
│   ├── material/
│   ├── appointment/
│   ├── doctor/
│   ├── local_model/
│   └── me/
└── shared/
    ├── widgets/
    ├── styles/
    └── assets.dart
```

每个 feature 内部按以下方式组织：

```text
features/chat/
├── data/
│   ├── chat_api.dart
│   ├── chat_repository.dart
│   └── models/
├── application/
│   └── chat_controller.dart
├── presentation/
│   ├── pages/
│   └── widgets/
└── chat_routes.dart
```

### 8.4 页面模块

P0 页面：

- Splash
- 登录
- Google 登录
- Apple 登录
- 注册分步
- 医生证书上传
- 患者首页
- 医生首页
- AI 三模式入口
- 在线聊天
- 本地模型目录与下载入口
- 最近会话
- 社区首页
- 帖子详情
- 发布帖子
- 评论面板
- 患者计划
- 医生计划配置
- 教育素材列表与详情
- 预约医生列表、详情、确认、记录
- 我的、个人资料、隐私设置

P1 页面：

- 本地模型下载管理、删除、校验、运行参数设置
- 私人素材
- 浏览历史
- 评估量表编辑/填写
- 我的患者
- 添加患者
- 荣誉徽章
- 回忆录
- 消息中心完整分类

P2 页面：

- 实时语音/视频
- 更完整的风控审核
- 设备管理
- 多语言切换设置

### 8.5 API 调用规则

Flutter 网络层必须统一处理：

- `baseUrl`
- `Authorization: Bearer <token>`
- `code/message/data/trace_id` 响应包
- token 失效跳转登录
- Google/Apple 登录成功后换取本系统 JWT
- FCM token 获取、刷新、注册和注销
- 通知权限、本地通知权限状态读取
- 请求取消
- 上传进度
- 业务错误 toast/dialog
- trace_id 调试输出

推荐响应模型：

```dart
class ApiResult<T> {
  final int code;
  final String message;
  final T? data;
  final String? traceId;
}
```

### 8.6 多语言国际化

Flutter 必须从第一版开始接入多语言，不允许先写死中文再后补。

要求：

- 使用 Flutter 官方 `gen-l10n`。
- 文案统一放在 `lib/l10n/app_en.arb`、`lib/l10n/app_zh.arb` 等 ARB 文件。
- 默认语言优先 `en-US`，中文作为开发和验收辅助语言保留。
- 页面、按钮、错误提示、空态、隐私协议、权限弹窗说明都必须使用 i18n key。
- 后台可配置内容需要支持多语言字段，例如模型介绍、提示词标题、素材标题、推送模板。
- API 返回给 Flutter 的可展示配置优先包含 `locale` 或 `*_i18n` 字段，Flutter 根据当前语言选择。
- 日志、接口错误码和技术字段不翻译，只翻译用户可见 message。

建议目录：

```text
flutter_app/lib/l10n/
├── app_en.arb
├── app_zh.arb
└── app_es.arb      # 后续可选
```

`l10n.yaml` 示例：

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

### 8.7 本地 llama.cpp 对话模式

本地对话模式使用 `llama.cpp` + `llama_cpp_dart`，Flutter 负责模型下载、校验、加载和本地推理，后端只提供模型目录、提示词和安全边界配置。

本地模式要求：

- Flutter 端从 `/app/help/local-model/catalog` 拉取模型目录。
- 模型条目必须包含下载地址、文件大小、SHA256、介绍、量化类型、推荐设备、上下文长度和默认采样参数。
- 下载完成后必须校验 SHA256，不通过不得加载。
- 模型文件存放在 App 私有目录，用户可删除。
- 推理放到 isolate 或后台任务中，避免阻塞 UI。
- 本地会话默认只保存在本机，不上传服务端。
- 本地模式下仍可从后端拉取最新提示词和安全提示，但用户对话内容不上传。
- iOS 与 Android 需要分别验证 `llama.cpp` 动态库打包、ABI、权限和内存占用。

推荐 Flutter 目录：

```text
core/local_llm/
├── llama_engine.dart
├── model_downloader.dart
├── model_registry.dart
├── local_prompt_resolver.dart
└── local_chat_store.dart
```

推荐后端接口：

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/app/help/local-model/catalog` | 获取可下载模型列表 |
| `GET` | `/app/help/local-model/prompts` | 获取本地模式提示词 |
| `POST` | `/app/help/local-model/download-log` | 可选，上报下载成功/失败统计，不上传对话内容 |

### 8.8 推送与本地通知

推送分两类实现：

| 类型 | 触发方 | 技术 | 适用场景 |
| --- | --- | --- | --- |
| 服务器推送 | 后端 | Firebase FCM | 社区回复、新关注、预约状态、医生审核结果、系统公告、后台运营通知 |
| 本地通知 | App 本机 | `flutter_local_notifications` | 治疗任务提醒、日记提醒、本地模型离线会话提醒、无网状态下仍需提醒的计划 |

两类通知都必须进入同一个 Flutter 通知调度层，统一处理权限、展示、点击跳转、去重和静默时段。

推荐目录：

```text
core/push/
├── fcm_service.dart
├── push_device_repository.dart
└── push_message_router.dart

core/notifications/
├── local_notification_service.dart
├── notification_permission_service.dart
├── notification_scheduler.dart
└── notification_payload.dart
```

#### 8.8.1 服务器推送 FCM

Flutter 端接入流程：

1. App 启动时初始化 Firebase。
2. 登录成功后在权限允许或用户同意后获取 FCM token，并调用 `/app/help/push/device/register`。
3. 监听 token refresh，刷新后重新注册。
4. 退出登录时调用 `/app/help/push/device/unregister`。
5. 收到推送后根据 payload 跳转到消息、任务、预约、社区回复等页面。
6. 服务器推送失败时记录失败原因，后台可按设备 token 状态做清理。

推送 payload 约定：

```json
{
  "type": "task_reminder",
  "target_id": "123",
  "route": "/plan/task/123",
  "trace_id": "optional"
}
```

推送类型至少包含：

- `task_reminder`
- `appointment_update`
- `community_reply`
- `new_follower`
- `doctor_audit_result`
- `system_notice`

#### 8.8.2 本地通知

本地通知由 App 自己调度，不依赖服务器在线。

适用场景：

- 治疗计划任务提醒。
- 日记记录提醒。
- 本地模型模式下的陪伴提醒。
- 素材学习提醒。
- 已同步到本地的预约前提醒。

本地通知规则：

- 后端下发任务、计划、预约后，Flutter 将需要本地提醒的条目写入本地通知计划表。
- App 每次启动、登录、计划更新、时区变化、权限变化后重新同步本地通知计划。
- 取消任务、完成任务、预约取消时必须取消对应本地通知。
- 本地通知 payload 使用与 FCM 相同的 `type`、`target_id`、`route` 结构，点击跳转逻辑共用。
- 本地通知不得包含敏感正文，例如心理对话内容、日记内容、证书信息。
- iOS 本地通知数量有限，长周期提醒要滚动调度最近一段时间，不一次性排满全年。

推荐本地表：

```text
local_notification_schedule
```

核心字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 本地主键 |
| `member_id` | 当前账号 ID |
| `type` | 通知类型 |
| `target_id` | 业务 ID |
| `route` | 点击跳转路由 |
| `fire_time` | 本地触发时间 |
| `timezone` | 调度时区 |
| `notification_id` | 本地通知插件 ID |
| `status` | 待触发、已取消、已触发 |

#### 8.8.3 权限申请

权限申请采用“按场景申请”，不在首次启动时一次性弹出所有权限。

| 权限 | 申请时机 | iOS | Android |
| --- | --- | --- | --- |
| 通知权限 | 用户登录后进入首页、开启提醒或首次需要 FCM/本地通知时 | APNs 通知权限，可先解释用途再请求 | Android 13+ 请求 `POST_NOTIFICATIONS` |
| 相册/图片 | 上传头像、医生证书、社区图片、私人素材时 | Photos 权限 | Photos/Media 权限 |
| 相机 | 拍摄头像、证书、素材时 | Camera 权限 | Camera 权限 |
| 视频拍摄 | 录制社区视频、私人素材视频、证书补充视频时 | Camera 权限，录音视频还需要 Microphone | Camera 权限，录音视频还需要 `RECORD_AUDIO` |
| 视频通话 | 实时视频咨询或 AI 视频通话时 | Camera + Microphone 权限 | Camera + Microphone 权限 |
| 视频素材选择 | 从相册选择视频素材时 | Photos 权限 | Android 13+ 使用 `READ_MEDIA_VIDEO` 或系统 Photo Picker，低版本按存储策略适配 |
| 文件 | 上传私人素材、附件时 | 文件选择器能力 | Storage/Photo Picker，按系统版本适配 |
| 麦克风 | 语音消息、语音通话时 | Microphone 权限 | Microphone 权限 |

权限文案要求：

- 权限弹窗前先显示业务解释页或轻量说明。
- 文案走 Flutter i18n。
- 用户拒绝后不反复弹系统权限框，改为展示“去设置开启”入口。
- 权限状态由 `core/permissions/permission_service.dart` 统一读取。
- 权限申请结果要影响功能入口状态，例如无通知权限时仍可使用 App，但提醒开关显示未授权。
- 视频相关入口必须同时检查相机和麦克风权限；只缺其中一个时展示精确缺失原因。
- 选择本地视频素材不等同于视频通话权限，不能为了选择文件提前申请相机或麦克风。

#### 8.8.4 通知偏好

用户可在“隐私/通知设置”管理：

- 总通知开关。
- 任务提醒。
- 社区互动。
- 预约提醒。
- 医生审核/系统通知。
- 本地陪伴提醒。
- 免打扰时段。

服务器推送偏好保存到后端 `sa_member_push_preference`。本地通知偏好在本地缓存一份，并在登录后与服务端同步。

### 8.9 本地存储安排

| 数据 | 存储位置 | 说明 |
| --- | --- | --- |
| access token / refresh token | `flutter_secure_storage` | 不使用普通 shared_preferences |
| 本地数据库加密密钥 | `flutter_secure_storage` | 用于加密 drift/SQLite 敏感库 |
| 当前用户 ID、设备 ID | `flutter_secure_storage` 或加密库 | 账号隔离和设备注册使用 |
| FCM token | Firebase SDK 本地状态 + 服务端设备表 | 登录后注册，退出或被踢下线后失效 |
| 语言、主题、引导页已看版本 | `shared_preferences` | 非敏感偏好；引导页内容来自后端配置 |
| 引导页配置短缓存 | 本地数据库或 `shared_preferences` | 离线兜底，按后端版本和语言失效 |
| 通知偏好缓存 | `shared_preferences` + 服务端偏好 | 本地展示和离线读取，服务端为准 |
| 日记 | 加密本地数据库 | 默认不上传云端 |
| 本地模型会话 | 加密本地数据库 | 默认不上传云端 |
| 本地通知计划 | 本地数据库 | 与任务、预约、提醒同步 |
| 本地模型下载记录 | 本地数据库 | 记录模型版本、SHA256、文件路径、下载状态 |
| 本地模型文件 | App 私有文件目录 | 用户可删除，下载后做 SHA256 校验 |
| 草稿附件、待上传图片 | App 私有文件目录 | 上传成功后按策略清理 |
| 在线 AI 会话 | 服务端 + 本地短缓存 | 服务端为准，缓存只用于列表和弱网体验 |
| 社区、计划、预约、素材收藏 | 服务端 + 本地短缓存 | 以服务端为准 |
| 最近浏览历史 | 本地 + 可选同步 | 用户可清理 |
| Google/Apple identity token | 不落库 | 只用于当次换取本系统 JWT |

本地存储规则：

- 所有本地数据按 `member_id` 隔离。
- 日记、本地模型会话、心理记录、草稿内容必须加密存储。
- 手动退出登录时清除 token、会话态、FCM 注册状态；本地日记和本地模型会话默认保留但继续加密隔离，重新登录同账号后可访问。
- 单设备登录导致被踢下线时，立即清除 token 和在线缓存，并暂停访问本地敏感内容，直到用户重新登录。
- 注销账号或用户选择“清除本地数据”时，删除该账号下的日记、本地模型会话、通知计划、下载记录和草稿附件。
- 调试日志不得打印 token、FCM token、identity token、日记正文、本地对话内容、模型文件完整下载地址中的签名参数。

医疗、心理、医生证书、日记和本地模型会话属于敏感数据。调试日志不得打印完整内容。

### 8.10 UI 与素材

设计稿来源：

```text
医疗支持图片ui/
review/ui/design/医疗支持图片ui/
```

Flutter 素材来源：

```text
helpsupport_flutter/assets/
review/ui/assets/helpsupport-flutter-assets/
```

重做时先建立统一资源命名：

```text
assets/images/auth/
assets/images/home/
assets/images/chat/
assets/images/community/
assets/images/plan/
assets/images/material/
assets/images/appointment/
assets/images/me/
assets/icons/
```

图片必须按页面域归档，禁止继续堆在 `assets/images/` 根目录。

### 8.11 Flutter 验证

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

每个 P0 流程至少在 Android 模拟器或真机完成一次冒烟：

- 注册患者
- 注册医生并上传证书
- 登录
- Google 登录
- Apple 登录
- FCM token 注册和退出注销
- 通知权限申请、拒绝、去设置开启流程
- 视频通话权限申请，相机/麦克风任一被拒绝时的提示流程
- 本地视频素材选择权限申请，不误触发相机/麦克风权限
- 服务器推送点击跳转
- 本地任务提醒调度、触发、取消
- AI 发送一条消息
- 本地模型目录拉取、下载、SHA256 校验和一次本地回复
- 发布社区帖
- 完成一个计划任务
- 查看素材详情
- 预约医生
- 医生查看患者/审核内容

## 9. API 与 Flutter 联调顺序

建议按纵向切片开发，不要先做完全部后台再做 Flutter。

| 阶段 | 后端 | Admin | Flutter |
| --- | --- | --- | --- |
| 0 | 父框架安装、`help` 插件、基础配置 | 能登录后台 | Flutter 空壳、主题、路由 |
| 1 | 认证、Google/Apple 登录、用户资料、医生证书、JWT 单设备 | 医生资质审核、第三方登录配置 | 登录注册、身份分流、第三方登录、证书上传 |
| 2 | FCM 设备注册、推送偏好、首页聚合、消息、聊天配置 | 推送配置、AI 配置 | 首页、消息红点、FCM 注册、AI 模式入口、会话列表 |
| 3 | 聊天会话、记录、在线发送、本地模型目录和提示词 | 聊天记录、本地模型目录、本地模型提示词 | 在线聊天页、本地模型下载和本地回复 |
| 4 | 社区帖子、评论、审核 | 社区审核、举报 | 社区首页、详情、发布、评论 |
| 5 | 计划、任务、评估 | 阶段、计划、任务模板、量表 | 患者计划、医生计划配置 |
| 6 | 素材、历史、私人素材 | 分类、素材 | 教育素材、私人素材、历史 |
| 7 | 预约 | 医生排班、预约记录 | 医生列表、详情、预约确认 |
| 8 | 我的、荣誉、回忆录 | 荣誉/积分规则 | 我的、隐私、荣誉、回忆录 |

每个阶段完成后必须有：

- 数据库迁移状态
- `route:list` 或真实请求验证
- APIDOC/OpenAPI 导出
- Admin 页面请求成功
- Flutter 真机/模拟器截图或录屏

## 10. 数据迁移策略

如果需要从旧库迁移数据，分三步：

1. 建新库：通过 `b8:install` + HelpSupport 迁移生成完整新库。
2. 写迁移脚本：从旧 `helpsupport` 库读取，转换写入新库。
3. 只迁移确认需要保留的数据，不迁移旧测试数据、构建缓存、临时日志。

迁移优先级：

| 优先级 | 数据 |
| --- | --- |
| 必迁 | 用户、医生资料、医生证书、预约、治疗计划、任务、社区正式内容 |
| 选择迁 | 聊天历史、素材收藏、浏览历史、积分、荣誉 |
| 不迁 | 本地日记、本地模型会话、调试数据、旧构建产物 |

生产迁移前必须：

- 备份旧库和新库。
- 明确停机窗口。
- 先在测试库完整演练。
- 保留回滚方案。

## 11. 部署策略

当前 HelpSupport 部署习惯可继续参考：

```text
ssh b8org
/www/wwwroot/helpsupport
```

但重做项目上线前必须重新确认：

- 远端目录
- PHP 版本
- MySQL 数据库名、用户名、密码
- Redis 配置
- Webman 端口
- Nginx 代理
- Flutter API baseUrl
- 上传目录和对象存储
- 迁移是否允许自动执行

生产部署默认不自动迁移数据库。必须通过显式开关或人工确认执行。

## 12. 验收清单

### 12.1 后端

- `composer validate --no-check-publish` 通过。
- `php webman b8:migrate:status` 正常。
- `php webman b8:migrate --dry-run` 正常。
- 所有新增 PHP 文件 `php -l` 通过。
- `php webman route:list` 能看到显式路由。
- `/apidoc/openapi/helpsupport-api` 能导出 JSON。
- 关键接口返回 `{code,message,data}`。

### 12.2 Admin

- `pnpm exec vue-tsc --noEmit` 通过。
- P0 菜单可见。
- CRUD 列表、搜索、新增、编辑、删除可用。
- 审核类页面有审核原因和审核日志。
- 按普通管理员账号验证权限，不只用超管验证。

### 12.3 Flutter

- `flutter analyze` 通过。
- `flutter test` 通过。
- Android 和 iOS 至少各完成一次 P0 冒烟。
- token 失效后能回登录。
- trace_id 可在错误提示或调试日志中定位。
- 英文 i18n key 不缺失。

## 13. 第一阶段任务清单

建议第一阶段只做基础闭环：

1. 新建 `helpsupport-next` 工作目录或当前仓库新分支。
2. 从父框架复制 `server/`、`saiadmin-artd/`、`Database/`、`Doc/`、`OpenAPI/`。
3. 初始化后端依赖与数据库。
4. 创建 `help` 插件。
5. 打开 JWT 单设备登录开关，确认 Redis 连接可用。
6. 建立 HelpSupport 数据库迁移第一批：用户资料扩展、医生证书、`GOOGLE`/`APPLE` 平台初始化、推送设备 token、社区基础表、聊天会话表、本地模型目录表。
7. 建立 `helpsupport-api` APIDOC app。
8. 生成医生资质审核、App 引导页配置、社区帖子、聊天配置、本地模型目录、推送配置六个后台页面。
9. 新建 Flutter 工程壳：主题、路由、网络层、登录态安全存储、国际化、后端引导页拉取、Firebase 初始化、本地通知初始化、权限服务。
10. 完成登录/注册/Google 登录/Apple 登录/医生证书上传/FCM token 注册纵向切片。
11. 完成通知权限申请、服务器推送点击跳转、本地任务提醒调度与取消。
12. 完成本地模型目录拉取、模型下载、SHA256 校验和一次 llama.cpp 本地回复。
13. 形成第一份联调报告：接口、后台、Flutter 截图、剩余问题。

第一阶段完成后，再进入社区、计划、素材、预约等功能开发。

## 14. 关键风险

| 风险 | 处理方式 |
| --- | --- |
| 旧数据库源头混乱 | 以父框架基线 + Phinx 增量为准 |
| 旧 OpenAPI 漂移 | 新接口开发时同步写 APIDOC，并以导出结果给 Flutter 使用 |
| Flutter 页面先行导致接口返工 | 按纵向切片开发，每个页面先确认 API contract |
| 后台 CRUD 生成后权限缺失 | 生成后检查菜单、按钮、角色授权和缓存 |
| 医疗/心理数据合规风险 | 日记、本地模型、证书、聊天记录明确存储边界和脱敏策略 |
| FCM token 放入会员主表导致后续难维护 | 单独建 `sa_member_push_device`，登录、刷新、退出和踢下线都更新设备状态 |
| 重复设计第三方绑定表 | 复用 `saiuser` 的 `sa_member_platform` 和 `sa_member_platform_rel`，只补 Google/Apple 平台初始化和必要业务资料 |
| 服务器推送和本地通知职责混乱 | FCM 只处理服务端事件，本地通知只处理设备本地提醒，点击 payload 统一路由 |
| 权限申请过早导致授权率低 | 按场景申请，拒绝后展示设置入口，不反复弹系统权限框 |
| 视频权限和素材选择权限混用 | 视频通话申请相机和麦克风，选择视频素材只走媒体/文件权限 |
| 引导页写死在 Flutter | 后台配置 `sa_app_onboarding_page`，Flutter 只缓存版本和已看状态 |
| 本地模型下载失败或文件损坏 | 后台配置 SHA256，Flutter 下载后强校验 |
| 多语言后补成本高 | Flutter 第一版就使用 `gen-l10n` 和 ARB 文件 |
| 重做范围过大 | 先完成 P0 闭环，再进入 P1/P2 |
