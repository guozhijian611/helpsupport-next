# HelpSupport Next

HelpSupport Next 是基于 B8AIAdmin 框架开发的智能健康支持平台，包含 Webman 后端、Vue 3 管理端和 Flutter 移动端。项目围绕 AI 对话、康复计划、医患协作、内容社区与个人健康档案建设，当前仍在持续开发。

## 核心能力

- AI 互动聊天：在线模型、本地 GGUF 模型、会话记录与 AI 医生配置。
- 多媒体消息：图片上传、点击/长按录音、异步语音输入、AI 语音播放和文本展开。
- 康复管理：治疗计划、阶段目标、每日任务、评估结果和成长风险追踪。
- 医生与预约：医生资料、患者管理、排班、预约与积分支付。
- 内容与社区：素材分类、收藏历史、帖子评论、关注、举报和 AI 内容审核。
- 个人中心：康复目标、重点触发、日记、回忆录、积分徽章和消息通知。
- 运营管理：SaiAdmin 后台 CRUD、菜单权限、数据迁移、OpenAPI 文档和调用链路追踪。

## 技术栈

| 层级     | 技术                                                        |
| -------- | ----------------------------------------------------------- |
| 后端     | PHP 8.3、Webman、SaiAdmin、ThinkORM、MySQL 8.0、Phinx       |
| 管理端   | Vue 3、TypeScript、Art Design Pro、Element Plus、Vite、pnpm |
| 移动端   | Flutter、Riverpod、Dio、Firebase、llama.cpp                 |
| 基础能力 | RabbitMQ、Redis Queue、OpenTelemetry、hg/apidoc、OpenAPI    |

## 目录结构

```text
helpsupport-next/
├── server/          Webman/SaiAdmin 后端与插件运行时
├── saiadmin-artd/  Vue 3 管理端
├── flutter_app/    Flutter 用户端
├── Database/       安装基线、Phinx 迁移与种子数据
├── Doc/            专题文档、OpenAPI 契约与项目梳理资料
├── deploy/         Docker Compose、镜像构建与发布脚本
└── packages/       本仓库维护的扩展包
```

## 环境要求

- PHP 8.3、Composer
- MySQL 8.0
- Node.js 24、pnpm
- Flutter SDK（需要移动端开发时）
- Redis / RabbitMQ（需要相关队列功能时）

## 快速开始

### 1. 后端

```bash
cd server
composer install
php webman b8:install
php start.php start
```

`b8:install` 用于配置数据库、导入安装基线并执行后续迁移。已安装环境升级时，请使用 `php webman b8:migrate` 处理新迁移。

### 2. 管理端

```bash
cd saiadmin-artd
pnpm install
pnpm dev
```

生产构建：

```bash
pnpm build
```

### 3. Flutter 移动端

```bash
cd flutter_app
flutter pub get
cd ..
./run_app.sh
```

`run_app.sh` 会列出可用设备并启动 Flutter 应用。API 基础地址由 `flutter_app/lib/core/api/api_client.dart` 中的 `ApiClient.apiBaseUrl` 统一管理。正式包可用根目录 `./package_release.sh` 打包 APK、AAB 和 IPA。

## 常用验证

```bash
# 查看后端路由
cd server
php webman route:list

# 检查迁移状态和 dry-run
php webman b8:migrate:status
php webman b8:migrate --dry-run

# 验证管理端
cd ../saiadmin-artd
pnpm build
```

Flutter 真机、模拟器与发布构建请参考 [`flutter_app/README.md`](flutter_app/README.md) 和 [`Doc/flutter-release-build.md`](Doc/flutter-release-build.md)。

## 文档导航

- [当前项目梳理](Doc/Project_Doc/helpsupport-next-当前项目梳理.md)
- [互动聊天图片与语音消息](Doc/互动聊天图片与语音消息.md)
- [Help API 契约](Doc/OpenAPI/help/README.md)
- [APIDOC 与移动端代码生成](Doc/apidoc-unibest.md)
- [Openship Docker Compose 部署](Doc/openship-compose.md)
- [部署指南](Doc/deployment-guide.md)
- [SAIAI 插件说明](Doc/saiai.md)
- [通知架构](Doc/notification-architecture.md)
- [数据库结构规范](Doc/database-schema-standard.md)

## 协作约定

- 后端业务能力优先以 `server/plugin/help/` 的实际路由和实现为准。
- 数据库变更通过 `Database/migrations/` 中的 Phinx 迁移交付。
- 接口变更同步更新 APIDOC 注解与 `Doc/OpenAPI/` 契约。
- 不要提交 `.env`、Token、私钥或其他敏感配置。

## 仓库

[https://github.com/guozhijian611/helpsupport-next](https://github.com/guozhijian611/helpsupport-next)
