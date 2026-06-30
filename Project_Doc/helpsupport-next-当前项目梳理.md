# HelpSupport Next 当前项目梳理

本文档基于当前仓库 `/Users/openb8/Downloads/项目/helpsupport-next` 的真实目录、路由、迁移、脚本和代码结构整理，目标是给开发和协作提供一个统一的现状入口。它不是早期“准备重建”的方案文档，而是当前代码已经落地后的项目说明。

## 1. 项目定位

- 当前仓库以 `b8aiadmin` 为父框架基线，核心后端和管理端沿用 SaiAdmin + Webman 插件模式。
- HelpSupport 业务已经在 `server/plugin/help` 中落地，不再是空白插件骨架。
- 移动端当前主线是 `flutter_app/`，不再以 uni-app 作为本仓库的日常开发入口。
- 仓库里仍保留父框架能力与通用插件，例如 `saipay`、`saiai`、`saiuser`、`b8cms`、RabbitMQ、APIDOC、log-reader、trace 等，因此它既是 HelpSupport 业务仓库，也是带父框架基础设施的集成仓库。

## 2. 当前目录结构

```text
helpsupport-next/
├── server/            Webman + SaiAdmin 后端
├── saiadmin-artd/     管理端前端
├── flutter_app/       Flutter 移动端
├── Database/          基线 SQL 与 Phinx 迁移
├── Doc/               专题文档
├── OpenAPI/           OpenAPI 导出快照
├── packages/          本仓库维护的扩展包
├── Project_Doc/       当前整理文档与历史评审资料
├── deploy.sh          传统 rsync/SSH 发布脚本
└── docker.sh          Docker 二进制镜像发布脚本
```

补充说明：

- 当前根目录没有 `uniapp/`，但 `deploy.sh` 和 `docker.sh` 仍保留了 `uniapp H5` 相关打包变量和提示，这是父框架脚本残留，不代表当前仓库已经恢复了 H5 端源码。
- `Project_Doc/review/` 和 `Project_Doc/help-rebuild-development-guide.md` 主要是历史资料，不是当前运行事实的唯一来源。

## 3. 技术栈与运行边界

### 3.1 后端

- PHP `>=8.1`，实际协作规范按 PHP 8.3 使用。
- Webman `^2.1`
- SaiAdmin `^6.0`
- ThinkORM
- Phinx `^0.16.11`
- Redis 队列：`webman/redis-queue`
- RabbitMQ：`workbunny/webman-rabbitmq`
- APIDOC：`hg/apidoc` + `hg/apidoc-export`
- 链路追踪：`openb8/webman-otel-trace`

后端命令入口在 `server/`：

```bash
cd server
composer install
php webman b8:migrate:status
php webman route:list
php start.php start
```

项目内还提供了几个重要命令封装：

- `B8Install.php`
- `B8Migrate.php`
- `B8MigrateStatus.php`
- `B8MigrateRollback.php`
- `B8MigrateCreate.php`
- `BuildBinCommand.php`

### 3.2 管理端

- Vite 7
- Vue 3
- Element Plus
- Art Design Pro
- Pinia
- TypeScript

管理端目录为 `saiadmin-artd/`，`package.json` 中要求：

- Node `>=20.19.0`
- pnpm `>=8.8.0`

常用命令：

```bash
cd saiadmin-artd
pnpm install
pnpm dev
pnpm build
pnpm lint
```

### 3.3 Flutter 移动端

- Flutter / Dart SDK `^3.12.1`
- Riverpod
- go_router
- Dio
- Firebase Core / Messaging
- flutter_local_notifications
- google_sign_in
- sign_in_with_apple
- llama_cpp_dart

当前移动端入口为：

```bash
./run_app.sh
```

脚本会合并显示 `flutter devices`、`adb devices` 和可启动 Android AVD，让用户选择后进入 `flutter_app/` 执行 `flutter run -d <device id>`。API 基础地址写在 `flutter_app/lib/core/api/api_client.dart` 的 `ApiClient.apiBaseUrl` 常量中。

完整 iOS 模拟器构建脚本：

```bash
cd flutter_app
./tool/build_ios_simulator.sh
```

脚本支持的关键环境变量：

- `IOS_SIMULATOR_NAME`
- `IOS_SIMULATOR_UDID`
- `REFRESH_IOS_SPM=1`
- `PUB_GET=1`
- `CLEAN=1`

## 4. Help 插件当前业务边界

当前 HelpSupport 业务主要集中在 `server/plugin/help`，已经形成较完整的插件结构：

```text
server/plugin/help/
├── app/admin/        后台 Controller / Logic / Validate
├── app/api/          移动端 API Controller
├── app/model/        Help 业务模型
├── app/service/      业务服务层
├── app/event/        事件
└── config/route.php  显式业务路由
```

### 4.1 当前 API 控制器分组

`server/plugin/help/app/api/controller` 当前包含 12 个控制器：

- `AuthController`
- `CommonController`
- `HomeController`
- `ChatController`
- `CommunityController`
- `MeController`
- `MaterialController`
- `PlanController`
- `AppointmentController`
- `DoctorController`
- `LocalModelController`
- `PushController`

对应移动端业务已经显式注册在 `server/plugin/help/config/route.php` 的 `/app/help/*` 路由组中。

### 4.2 当前后台模块分组

`server/plugin/help/app/admin` 与 `saiadmin-artd/src/views/plugin/help` 两侧模块基本对齐，已经覆盖：

- `community`
- `config`
- `audit`
- `chat`
- `localModel`
- `plan`
- `material`
- `appointment`
- `doctor`
- `push`
- `message`
- `gamification`
- `me`
- `risk`

这说明当前仓库的后台不只是配置页，而是已经进入到具体业务 CRUD、审核、模板、消息和风控管理阶段。

### 4.3 当前主要模型域

`server/plugin/help/app/model` 已落地的业务域包括：

- 社区：帖子、评论、举报、标签
- 聊天：会话、记录、配置
- 引导/配置：App 引导页
- 医生：资质、患者关系、量表、任务模板
- 预约：预约、排班
- 素材：内容分类、内容素材
- 我的：日记、回忆录、回忆录配置、恢复目标、诱因记录
- 计划：治疗计划、阶段、每日任务、量表结果
- 推送：设备、偏好、模板
- 本地模型：模型目录、提示词
- 成长体系：勋章、积分日志、勋章规则
- 风控：敏感词规则
- 站内消息：成员消息

## 5. 路由与 API 现状

当前已通过 `cd server && php webman route:list` 验证，`/app/help` 路由已经真实注册。

### 5.1 对外 API 主分组

- 认证：`/app/help/auth/*`
- 公共配置：`/app/help/common/*`
- 首页：`/app/help/home/*`
- AI 聊天：`/app/help/chat/*`
- 社区：`/app/help/community/*`
- 我的：`/app/help/me/*`
- 素材：`/app/help/material/*`
- 计划：`/app/help/plan/*`
- 预约：`/app/help/appointment/*`
- 医生端：`/app/help/doctor/*`
- 本地模型：`/app/help/local-model/*`
- 推送：`/app/help/push/*`

已确认的接口示例包括：

- `POST /app/help/auth/account-login`
- `GET /app/help/common/onboarding`
- `POST /app/help/auth/google`
- `POST /app/help/auth/apple`
- `POST /app/help/chat/send`
- `GET /app/help/community/posts`
- `GET /app/help/plan/current`
- `POST /app/help/appointment`
- `POST /app/help/push/device/register`

### 5.2 后台路由主分组

后台显式路由同样已经注册在 `/app/help/admin/*` 下，按模块拆分为：

- `community`
- `config`
- `audit`
- `chat`
- `localModel`
- `plan`
- `material`
- `appointment`
- `doctor`
- `push`
- `message`
- `gamification`
- `me`
- `risk`

其中一部分标准 CRUD 通过 `fastRoute(...)` 暴露，一部分业务动作通过额外 POST 路由显式补充，例如：

- `SaCommunityPost/audit`
- `SaCommunityComment/audit`
- `SaCommunityReport/handle`
- `SaDoctorAssessmentScale/publish`
- `SaContentMaterial/audit`
- `SaDoctorAppointment/confirm`
- `SaMemberMessage/push`
- `SaMemberMemoirConfig/generate`

### 5.3 OpenAPI 快照

当前 HelpSupport OpenAPI 快照位于：

```text
OpenAPI/help/openapi.yaml
```

`OpenAPI/help/README.md` 中已说明它来自：

```bash
curl http://127.0.0.1:8787/apidoc/openapi/helpsupport-api
```

当前说明中写明已覆盖 `93` 个接口路径，可作为 Flutter 端接口契约核对依据。

## 6. 数据库与迁移现状

### 6.1 基线策略

仓库保留了父框架基线和 HelpSupport 增量迁移的组合模式：

- 首次安装基线：`Database/b8aiadmin.sql`
- 后续升级：`Database/migrations/*.php`

### 6.2 HelpSupport 相关迁移

从迁移文件名可以确认，HelpSupport 业务迁移已不止建表，还包含菜单、权限、运行配置、默认数据和角色分组，例如：

- `20260612230839_create_help_core_tables.php`
- `20260612233103_create_help_business_tables.php`
- `20260613080200_seed_help_admin_crud_menus.php`
- `20260614175401_seed_help_onboarding_demo_pages.php`
- `20260614230000_add_help_runtime_config_admin_menu.php`
- `20260615070000_add_help_oauth_runtime_strategies.php`
- `20260615073000_create_help_audit_log.php`
- `20260615100000_group_help_support_admin_menus.php`
- `20260615162000_seed_system_mail_templates.php`

这意味着当前数据库层面已经包含：

- HelpSupport 基础业务表
- 后台菜单与按钮权限
- 引导页演示数据
- OAuth 运行配置
- 审核日志
- 站内信模板
- 运营后台菜单分组

### 6.3 仓库仍包含的父框架/其他业务迁移

除了 HelpSupport，本仓库还保留父框架和其他插件迁移，例如：

- `saipay`
- `saiai`
- `b8cms`
- `queue management`
- `log reader`
- `adminer`

因此执行迁移时要把它视为“整仓库基线 + Help 插件业务”的组合环境，而不是纯 HelpSupport 单模块数据库。

## 7. 管理端现状

`saiadmin-artd/src/views/plugin/help` 当前已经按业务域拆分页面目录，和后端 `help` 插件后台分组基本一一对应。

这部分说明了两件事：

1. 后台页面不是零散试验页，而是已经按插件模式成体系组织。
2. 后续新增后台业务时，应继续沿用 `api/ + 页面目录 + server/plugin/help/app/admin` 对齐的方式扩展，而不是绕开插件边界写到公共目录。

建议把以下路径作为后台开发主入口：

- 页面：`saiadmin-artd/src/views/plugin/help`
- API：`saiadmin-artd/src/views/plugin/help/api`
- 后端控制器：`server/plugin/help/app/admin/controller`
- 后端校验：`server/plugin/help/app/admin/validate`
- 路由：`server/plugin/help/config/route.php`

## 8. Flutter 端现状

### 8.1 当前 feature 树

`flutter_app/lib/features` 当前已拆分出：

- `auth`
- `chat`
- `community`
- `home`
- `local_model`
- `me`
- `onboarding`
- `plan`
- `splash`

每个模块大多已按 `application / data / presentation` 分层。

### 8.2 当前全局能力

`flutter_app/lib/core` 已具备以下公共基础设施：

- `api`
- `auth`
- `config`
- `i18n`
- `local_llm`
- `notifications`
- `permissions`
- `providers`
- `push`
- `settings`

`bootstrap.dart` 已经真实接入：

- `SharedPreferences`
- `flutter_secure_storage`
- `Dio ApiClient`
- 本地通知服务
- Firebase Push 初始化
- 引导页仓储注入

### 8.3 当前路由覆盖

`flutter_app/lib/app/router.dart` 当前已注册的主要页面有：

- `/` 启动页
- `/login`
- `/register`
- `/register/profile`
- `/forgot-password`
- `/protocol/:type`
- `/onboarding`
- `/home`
- `/chat`
- `/chat/session/:id`
- `/community/new`
- `/community/post/:id`
- `/me/settings`
- `/me/settings/:section`
- `/local-model`
- `/local-model/chat/:id`

### 8.4 当前端侧覆盖差异

和后端已存在的业务域相比，Flutter 端当前更偏向以下主线：

- 登录注册与协议
- 首页
- AI 聊天
- 社区
- 我的
- 引导页
- 本地模型
- 基础计划能力

而后端已经有明确接口和数据结构、但 Flutter feature 树里尚未形成独立模块目录的领域包括：

- `appointment`
- `doctor`
- `material`
- `push`
- `message`
- `gamification`
- `risk`

这不代表这些能力完全没做，只表示当前 Flutter 端的目录结构还没有像后端一样全面展开。后续排期和协作时，需要把“后端已具备接口”与“Flutter 页面是否已经成体系落地”分开判断。

## 9. 文档与专题资料分工

### 9.1 当前专题文档

根目录 `Doc/` 现有专题文档包括：

- `Doc/apidoc-unibest.md`
- `Doc/auth-token.md`
- `Doc/b8cms.md`
- `Doc/database-schema-standard.md`
- `Doc/deployment-guide.md`
- `Doc/docker-release.md`
- `Doc/helper-functions.md`
- `Doc/queue-management.md`
- `Doc/saiai.md`
- `Doc/saipay-payment.md`
- `Doc/webman-binary-build.md`
- `Doc/webman-otel-trace.md`

这些文档更多是按主题拆分，不是面向新成员的一站式项目说明，所以本文件的作用是给它们做总导航。

### 9.2 Project_Doc 中的历史资料

- `help-rebuild-development-guide.md`
  - 适合回看项目从父框架重建时的目标与设计判断。
  - 当前已经不应继续把它当成现状文档使用。
- `review/`
  - 是评审归档包，包含旧项目说明、数据库资料、静态素材、截图和历史路由快照。
  - 它更适合做对照，而不是直接指导当前开发。

## 10. 当前协作建议

### 10.1 后端

- 所有 HelpSupport 业务开发继续收敛到 `server/plugin/help`。
- 路由以 `server/plugin/help/config/route.php` 和 `php webman route:list` 为准。
- 数据库变更继续走 `Database/migrations/`，不要回到手写零散 SQL patch。
- 对外接口变更后同步刷新 APIDOC 注解，并更新 `OpenAPI/help/openapi.yaml`。

### 10.2 管理端

- 页面与 API 保持 `saiadmin-artd/src/views/plugin/help` 内聚。
- 新增后台模块时继续对齐后端 `controller / logic / validate` 边界，不把 Help 业务写进公共系统目录。

### 10.3 Flutter

- 默认联调路径仍然是：

```bash
./run_app.sh
```

- API 基础地址写在 `flutter_app/lib/core/api/api_client.dart` 的 `ApiClient.apiBaseUrl` 常量中，不通过环境变量或 `--dart-define` 传入。

- 完整构建验证使用：

```bash
cd flutter_app
./tool/build_ios_simulator.sh
```

- 若 iOS Swift Package 解析异常，再使用：

```bash
cd flutter_app
REFRESH_IOS_SPM=1 ./tool/build_ios_simulator.sh
```

### 10.4 发布与部署

- 当前 `deploy.sh`、`docker.sh` 仍带有 `uniapp H5` 的父框架脚本逻辑。
- 在当前仓库没有 `uniapp/` 的前提下，不应直接假定 H5 构建链路可用。
- 需要发布前，先确认本次是否仅涉及：
  - `server`
  - `saiadmin-artd`
  - `flutter_app`
  - `Database`
- 如果要继续使用根脚本，建议先核对目标是否仍然是当前项目需要的发布边界。

## 11. 推荐阅读顺序

1. 先读本文，理解当前仓库现实边界。
2. 再看 `Project_Doc/README.md` 了解主文档与历史资料分工。
3. 做后端开发时，看 `server/plugin/help`、`Database/migrations/`、`OpenAPI/help`。
4. 做后台开发时，看 `saiadmin-artd/src/views/plugin/help`。
5. 做 Flutter 联调时，看 `flutter_app/lib/app`、`flutter_app/lib/core`、`flutter_app/lib/features` 和 `flutter_app/tool/build_ios_simulator.sh`。
6. 做部署或专题排障时，再进入 `Doc/` 下对应专题文档。
