# Openship Docker Compose 部署

本仓库根目录的 `docker-compose.yml` 用于在 Openship 中以 Compose 多服务项目运行 HelpSupport Next。构建过程会同时完成 PHP 依赖安装和 Vue 管理端编译，运行时不需要在容器内再执行 Composer 或 pnpm。

PHP 运行层基于 Alpine 3.22 的预编译 PHP 8.3 软件包，`gd`、`intl`、MySQL、Redis 和 OpenTelemetry 等扩展均直接安装二进制包，不在 Openship 服务器上执行 `phpize`、PECL 或 C/C++ 源码编译。

## 服务结构

| 服务       | 作用                                              | 对外端口                    |
| ---------- | ------------------------------------------------- | --------------------------- |
| `gateway`  | Nginx 入口，转发 HTTP、上传、SSE 和实时 WebSocket | `8080`                      |
| `app`      | Webman、SaiAdmin、Help 业务和管理端静态资源       | 仅 Compose 内网 `8787/8791` |
| `mysql`    | MySQL 8.0 业务数据                                | 仅 Compose 内网             |
| `redis`    | 缓存和 Redis Queue                                | 仅 Compose 内网             |
| `rabbitmq` | RabbitMQ 及其管理 API                             | 仅 Compose 内网             |

Openship 的域名应路由到 `gateway` 服务的容器端口 `8080`。`/v1/realtime` 会由网关自动转发到 Webman 的 `8791` 实时语音端口，其余请求转发到 `8787`。
网关根路径会直接加载管理端入口，`/healthz` 仅用于容器健康检查。

## Openship 部署步骤

1. 在 Openship 中创建项目并连接本 Git 仓库。
2. 选择 Compose 部署，配置文件使用根目录的 `docker-compose.yml`。
3. 在项目环境变量中设置下表的必填项。
4. 将域名或 Openship 预览域名绑定到 `gateway:8080`。
5. 首次空库部署时，确认目标数据库和卷后，临时设置 `B8_RUN_MIGRATIONS=1`。
6. 迁移成功后将 `B8_RUN_MIGRATIONS` 改回 `0`，避免之后每次重建都自动执行生产迁移。

Openship 可直接识别仓库中的 Compose 文件。如使用 CLI，可在项目根目录执行：

```bash
openship init
openship deploy
```

## 必填环境变量

| 变量                  | 说明                                        |
| --------------------- | ------------------------------------------- |
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码，仅用于容器初始化和健康检查 |
| `DB_PASSWORD`         | HelpSupport 业务数据库账号密码              |
| `REDIS_PASSWORD`      | Redis 访问密码                              |
| `RABBITMQ_PASSWORD`   | RabbitMQ 业务账号密码                       |

其他可选项可从 `.env.openship.example` 复制。不要将真实密码、Token 或 AI Key 提交到 Git，应在 Openship 的项目环境变量/密钥管理中配置。

AI 功能按需配置：

- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `DASHSCOPE_API_KEY`

## 数据库初始化与迁移

`mysql_data` 为空时，MySQL 镜像会自动导入 `Database/b8aiadmin.sql`。该初始化脚本对同一数据卷只执行一次。

Phinx 增量迁移默认关闭。只有显式设置以下开关时，`app` 入口才会依次执行 `status`、`dry-run` 和真实迁移：

```dotenv
B8_RUN_MIGRATIONS=1
```

对已有生产库开启该开关前，必须先确认备份、目标环境和回滚窗口。

## 持久化数据

Compose 定义了以下命名卷：

- `mysql_data`：MySQL 数据。
- `redis_data`：Redis AOF 数据。
- `rabbitmq_data`：RabbitMQ 队列与元数据。
- `app_storage`：用户上传文件。
- `app_runtime`：Webman 日志、指标和运行状态。

删除 Compose 项目或卷会丢失业务数据。在 Openship 中重建、迁移或清理服务前，请先备份 `mysql_data` 和 `app_storage`。

## 本地验证

```bash
cp .env.openship.example .env
# 先替换 .env 中的所有示例密码

docker compose config
docker compose build app
docker compose up -d
docker compose ps
```

检查服务：

```bash
curl -I http://127.0.0.1:8080/
docker compose exec app php webman b8:migrate:status
docker compose logs --tail=200 app gateway
```

本地调试完成后可停止服务：

```bash
docker compose down
```

`docker compose down -v` 会同时删除数据卷，仅可用于明确不需要保留数据的临时环境。

## 运行安全

- 对外只发布 `gateway` 端口，MySQL、Redis、RabbitMQ 和 Webman 端口不直接暴露。
- `APP_DEBUG=false`，生产环境不注册 trace 调试页。
- Adminer 和 Webman Log Reader 在 Compose 中默认关闭。
- Nginx 允许最大 500 MB 请求体，并为 AI 慢请求和 WebSocket 设置 3600 秒超时。
