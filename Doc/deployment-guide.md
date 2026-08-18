# B8 框架服务端部署说明

本文档用于 B8 框架及其子项目在宝塔面板或普通 Linux 服务器上的部署检查。部署前先确认目标环境、数据库备份和回滚窗口；生产环境数据库迁移或数据库同步必须使用显式开关，默认不要自动覆盖线上数据库。

## 运行环境

- PHP：8.3，命令行 PHP 与宝塔站点 PHP 版本需要一致。
- MySQL：8.0，字符集建议使用 `utf8mb4`。
- Redis：按需启用。启用 Redis 缓存、Redis 队列或分布式锁时必须安装并配置。
- RabbitMQ：按需启用。使用后台队列管理或 RabbitMQ 消费者时再部署。
- Nginx：用于静态资源和 Webman 反向代理。
- Webman：常驻进程，修改 PHP、路由、插件配置或 `.env` 后需要 `restart` 或 `reload`。

## PHP 扩展

必须启用：

- `fileinfo`：文件上传、文件类型识别等功能依赖。
- `pdo_mysql`、`mysqli`、`mysqlnd`：MySQL 连接与 ORM 访问。
- `mbstring`：字符串处理。
- `openssl`：HTTPS、加密、第三方 SDK。
- `curl`：第三方 HTTP 请求。
- `json`：JSON 编解码。
- `gd`：验证码、图片处理。
- `zip`：导入导出、压缩包处理。
- `pcntl`、`posix`：Workerman/Webman 进程管理。

建议启用：

- `redis`：使用 Redis 缓存或 `webman/redis-queue` 时启用。
- `event`：Workerman 性能优化扩展，非必需。
- `opentelemetry`：服务端 PHP 如需上报链路或指标时安装并启用。
- `amqp`：仅在项目直接使用 PHP AMQP 扩展时需要；当前 RabbitMQ 组件优先按 Composer 依赖和项目配置运行。

## PHP 禁用函数

Webman 依赖部分进程、网络和环境变量函数。这里不是要把这些函数加入禁用列表，而是要从 `php.ini` 的 `disable_functions` 中解除禁用。

官方检查命令：

```bash
curl -Ss https://www.workerman.net/webman/check | php
```

如果提示 `Functions 函数名 has be disabled. Please check disable_functions in php.ini`，需要在 CLI PHP 对应的 `php.ini` 中解除对应函数禁用。可通过以下命令确认 CLI 使用的配置文件：

```bash
php --ini
```

常见需要解除禁用的函数如下：

```ini
stream_socket_server
stream_socket_client
pcntl_signal_dispatch
pcntl_signal
pcntl_alarm
pcntl_fork
pcntl_wait
posix_getuid
posix_getpwuid
posix_kill
posix_setsid
posix_getpid
posix_getpwnam
posix_getgrnam
posix_getgid
posix_setgid
posix_initgroups
posix_setuid
posix_isatty
proc_open
proc_get_status
proc_close
shell_exec
exec
putenv
getenv
```

也可以在已安装 `webman/console` 时执行：

```bash
php webman fix-disable-functions
```

或按官方脚本自动处理：

```bash
curl -Ss https://www.workerman.net/webman/fix-disable-functions | php
```

生产环境建议先用检查命令确认问题，再决定是否自动修复。

参考：[Webman 函数禁用检查](https://www.workerman.net/doc/webman/others/disable-function-check.html)

## Nginx 反向代理

Webman 默认监听 `127.0.0.1:8787`。如果前端请求统一走 `/prod/`，Nginx 站点配置需要增加：

```nginx
location /prod/ {
    client_max_body_size 500m;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:8787/;
}
```

`client_max_body_size` 也可以放在当前站点的 `server {}` 内，对该站点所有接口生效。上传大文件出现 Nginx `413 Request Entity Too Large` 时，先确认该值已生效，再执行 `nginx -t && nginx -s reload` 或通过宝塔面板重载 Nginx。

如果后续接口涉及 WebSocket，再补充升级头：

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## 环境变量

服务器上的 `server/.env` 不随部署脚本覆盖，需要在目标服务器手动维护。最少确认：

```dotenv
DB_TYPE=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=b8aiadmin
DB_USER=b8aiadmin
DB_PASSWORD=请替换为线上密码
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_general_ci

CACHE_MODE=file

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=''
REDIS_DB=0
REDIS_QUEUE_PREFIX=''
REDIS_QUEUE_MAX_ATTEMPTS=5
REDIS_QUEUE_RETRY_SECONDS=5
```

启用 Redis 缓存时设置：

```dotenv
CACHE_MODE=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=请替换为线上密码
REDIS_DB=0
```

服务端需要链路或指标上报时，先安装 PHP `opentelemetry` 扩展，再按实际采集端配置 OpenTelemetry 相关环境变量。没有采集端或暂不需要上报时，可以保持本地 trace 文件能力，不强制启用远端上报。

## 部署脚本

父框架提供 `deploy/deploy.sh`，默认目标为：

- 服务器别名：`shanghai`
- 远端目录：`/www/wwwroot/b8aiadmin`
- Webman 端口：`8787`
- 数据库同步：默认关闭
- Webman 禁用函数检查：默认开启

预览部署：

```bash
DRY_RUN=1 ./deploy/deploy.sh
```

正式部署：

```bash
./deploy/deploy.sh
```

常用开关：

```bash
BUILD_ADMIN=1 ./deploy/deploy.sh
SYNC_ADMIN=0 ./deploy/deploy.sh
SYNC_DB=1 ./deploy/deploy.sh
CHECK_WEBMAN_DISABLED_FUNCTIONS=0 ./deploy/deploy.sh
REMOTE_ROOT=/www/wwwroot/justai ./deploy/deploy.sh
```

只发布 PHP 服务端、不碰后台静态资源时用 `SYNC_ADMIN=0`。脚本对 rsync 默认重试 3 次，并给 SSH 打开 keepalive；admin 同步失败时仍会继续修复权限并重启 Webman，避免后台静态资源把接口发布卡住。

脚本会把本地 `server/`、`packages/`、`Database/`（基线 SQL、Phinx 配置、迁移和种子）以及 admin 静态资源和 `public/storage` 同步到远端。`Database/` 与 `server/` 平级，供远端 `php webman b8:migrate` 读取。`SYNC_DB=1` 会把本地数据库同步到远端数据库，生产环境执行前必须确认备份和覆盖风险。

## Docker 二进制镜像发布

如果目标环境希望以 Docker 运行 Webman 二进制镜像，使用 `deploy/docker.sh`。该脚本会构建 `.bin`、打包生产 `.env`、复制 `Database/`、压缩 admin/H5 静态资源、构建 Linux x86_64 镜像、导出 tar 包，并可自动上传服务器重建容器。

详细流程、首次安装、增量迁移、Nginx 反代和 Redis 队列排障见：

```text
Doc/docker-release.md
```

## Webman 启停与验证

在服务器执行：

```bash
cd /www/wwwroot/b8aiadmin/server
composer install --no-dev --optimize-autoloader
php webman restart -d
php webman status
```

部署后至少验证：

```bash
curl -I http://127.0.0.1:8787/
curl -I http://127.0.0.1/prod/
```

如果修改了路由或插件配置，可以在 `server/` 目录检查：

```bash
php webman route:list
```

## 上线检查清单

- PHP CLI 与站点 PHP 均为 8.3。
- MySQL 为 8.0，数据库字符集为 `utf8mb4`。
- PHP 已启用 `fileinfo`、MySQL、`mbstring`、`openssl`、`curl`、`gd`、`zip`、`pcntl`、`posix` 等扩展。
- 如需 Redis 缓存或队列，已安装 `redis` 扩展并正确配置 `REDIS_*`。
- 如需链路或指标上报，已安装并启用 `opentelemetry` 扩展。
- `curl -Ss https://www.workerman.net/webman/check | php` 无禁用函数告警。
- Nginx 已增加 `/prod/` 反向代理并重载配置。
- `server/.env` 已按线上数据库、Redis、RabbitMQ 和 trace 配置完成。
- `php webman restart -d` 后 `php webman status` 正常。
- 生产数据库迁移或同步已经确认备份、目标库和回滚方案。
