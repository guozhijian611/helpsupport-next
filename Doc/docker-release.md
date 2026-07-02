# B8AIadmin Docker 二进制镜像发布说明

本文档说明根目录 `docker.sh` 的发布流程。该脚本用于把 `server/` 打成 Linux x86_64 二进制文件，再构建 Docker 镜像、导出 tar 包，并可自动上传服务器、执行首次安装或增量迁移、重建线上容器。

`docker.sh` 是发布编排脚本，不替代底层 `build:bin` 文档。二进制打包细节见 `Doc/webman-binary-build.md`。

## 核心原则

- 使用 `bash docker.sh` 或 `./docker.sh`，不要用 `sh docker.sh`。
- 生产数据库操作必须显式选择：首次空库用 `RUN_INSTALL=1`，已有库升级用 `RUN_MIGRATE=1`。
- `RUN_INSTALL=1` 和 `RUN_MIGRATE=1` 不要同时使用。首次安装会自动执行迁移。
- 自动发布前必须确认目标数据库、备份和回滚窗口。
- 镜像会默认包含 `/app/.env`。这意味着生产数据库、Redis、Token 等配置会进入镜像 tar 包，只能在可信发布链路使用。

## 镜像内容

脚本会生成 Docker 构建上下文，并写入：

- `/app/server`：由 `server/app/command/BuildBinCommand.php` 生成的 Webman 二进制文件。
- `/app/.env`：默认从 `server/.env.production` 复制。
- `/app/Database`：默认复制 `Database/`，供 `b8:install` 和 `b8:migrate` 使用。
- `/app/public`：默认复制 `server/public/`，用于后端公开资源，例如 `favicon.ico`、`apidoc/` 等。
- `/app/public/.release/admin.tar.gz`：如果 `saiadmin-artd/dist` 存在，会压缩管理端静态资源。
- `/app/public/.release/h5.tar.gz`：如果 `uniapp/dist/build/h5` 存在，会压缩 H5 静态资源。
- `/usr/local/bin/docker-entrypoint`：容器入口脚本。

容器启动时会把静态资源释放到：

```text
/app/public/admin
/app/public/h5
```

`server/public/` 会在构建阶段直接同步到 `/app/public`；admin 和 H5 会以压缩包形式放入 `/app/public/.release`，再由容器启动入口释放。这样做是为了避免把大量静态文件直接放进 `.bin`，否则二进制启动和访问静态文件都会变慢。宿主机 Nginx 不能直接读取容器内目录，默认应通过容器暴露的 Webman HTTP 端口反代 `/admin/`、`/h5/` 和接口。

## 关键配置

所有参数都可以在命令前用环境变量覆盖，也可以直接修改 `docker.sh` 的用户配置区。

| 参数 | 说明 |
| --- | --- |
| `REMOTE_ALIAS` | SSH 服务器别名，默认使用 `~/.ssh/config` 里的 `shanghai`。 |
| `REMOTE_UPLOAD_DIR` | 服务器接收镜像 tar 包的目录。 |
| `IMAGE_NAME` / `IMAGE_TAG` | Docker 镜像名和标签。标签默认当前时间。 |
| `BIN_NAME` | `build:bin` 输出名，复制到镜像后固定为 `/app/server`。 |
| `LOCAL_PRODUCTION_ENV_FILE` | 本地生产配置文件，默认 `server/.env.production`。 |
| `INCLUDE_PRODUCTION_ENV` | 是否把生产 `.env` 打进镜像，默认 `1`。 |
| `INCLUDE_DATABASE` | 是否把 `Database/` 打进镜像，默认 `1`。 |
| `BUILD_ADMIN` / `BUILD_H5` | 是否重新编译管理端和 H5。 |
| `RUN_INSTALL` | 是否执行首次安装基线。仅空库第一次部署使用。 |
| `RUN_MIGRATE` | 是否执行已有库增量迁移，会先 `status` 和 `dry-run`。 |
| `AUTO_REMOTE_UPDATE` | 是否自动上传、`docker load` 并重建容器。 |
| `REMOTE_REBUILD_ONLY` | 是否跳过本地构建和上传，直接用服务器已有镜像重建容器。 |
| `REMOTE_REBUILD_IMAGE_REF` | 直接重建时指定远程镜像；留空则选服务器上同名最新镜像。 |
| `APP_PORT` / `HOST_PORT` | 容器内 Webman HTTP 端口和宿主机发布端口。 |
| `SAIAI_REALTIME_WS_PORT` / `SAIAI_REALTIME_HOST_PORT` | AI 实时 WebSocket 容器端口和宿主机端口。 |
| `PUBLISH_SAIAI_REALTIME_PORT` | 是否发布 AI 实时端口，默认 `1`。 |
| `MOUNT_RUNTIME_DIR` | 是否把 `/app/runtime` 挂载到宿主机，默认 `0`。 |
| `MOUNT_STORAGE_DIR` | 是否把 `/app/public/storage` 挂载到宿主机，默认 `0`。 |
| `REMOTE_ENV_FILE` | 远程运行时 `.env` 覆盖文件。留空时使用镜像内 `/app/.env`。 |
| `REMOTE_DOCKER_RUN_ARGS` | 额外 `docker run` 参数。默认加入 `host.docker.internal` 映射，不使用 host 网络。 |

## 生产 .env 要点

Docker bridge 网络中，容器访问宿主机 MySQL、Redis、RabbitMQ 时建议使用：

```dotenv
DB_HOST=host.docker.internal
REDIS_HOST=host.docker.internal
```

默认 `REMOTE_DOCKER_RUN_ARGS` 会加入：

```bash
--add-host host.docker.internal:host-gateway
```

Redis 有密码时必须确保：

```dotenv
REDIS_PASSWORD=线上 Redis 密码
```

如果容器日志出现：

```text
RuntimeException: NOAUTH Authentication required.
```

说明服务已连接到需要认证的 Redis，但当前 `/app/.env` 的 `REDIS_PASSWORD` 未生效或值不正确。这不是数据库首次导入失败。

## 首次空库部署

首次部署到空库时使用 `RUN_INSTALL=1`。该模式会在新镜像的一次性容器中执行：

```bash
/app/server b8:install --force
```

安装流程会读取 `/app/.env`，在缺少 `sa_system_menu` 时导入 `Database/b8aiadmin.sql` 基线数据，然后执行所有 Phinx 增量迁移。

交互方式：

```bash
bash docker.sh
```

选择：

```text
是否编译 admin 管理端？按需选择
是否编译 uniapp H5？按需选择
是否执行首次安装基线？y
是否自动上传并更新线上镜像？y
```

非交互方式：

```bash
RUN_INSTALL=1 RUN_MIGRATE=0 AUTO_REMOTE_UPDATE=1 bash docker.sh
```

配置摘要中必须看到：

```text
线上迁移：0
首次安装基线：1
```

如果 `.bin` 代码本身刚修改过，必须重新构建镜像。`REMOTE_REBUILD_ONLY=1` 只适合服务器上已经存在目标镜像的情况。

## 已有库升级部署

已有线上库只需要执行增量迁移时使用：

```bash
RUN_INSTALL=0 RUN_MIGRATE=1 AUTO_REMOTE_UPDATE=1 bash docker.sh
```

脚本会依次执行：

```bash
/app/server b8:migrate:status
/app/server b8:migrate --dry-run
/app/server b8:migrate
```

交互模式下，真实迁移前会再次确认数据库已备份。迁移失败时脚本会停止容器重建：镜像可能已经上传并 `docker load`，但不会执行新的 `docker run`。

## 直接重建远程容器

如果镜像已经上传并 `docker load` 到服务器，只想用服务器已有镜像重建容器：

```bash
REMOTE_REBUILD_ONLY=1 RUN_INSTALL=0 RUN_MIGRATE=0 bash docker.sh
```

如果服务器已有镜像还没有执行首次安装，也可以：

```bash
REMOTE_REBUILD_ONLY=1 RUN_INSTALL=1 RUN_MIGRATE=0 bash docker.sh
```
注意：如果本地代码刚改过并且新 `.bin` 还没有构建上传，不能使用 `REMOTE_REBUILD_ONLY=1`。

## Nginx 反向代理

容器默认发布 Webman HTTP 端口和 AI 实时 WebSocket 端口。外部 Nginx 应反代宿主机端口，而不是读取容器内 `/app/public`。

示例：

```nginx
location / {
    client_max_body_size 500m;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:18787;
}

location /admin/ {
    client_max_body_size 500m;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:18787/admin/;
}

location /h5/ {
    client_max_body_size 500m;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header REMOTE-HOST $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:18787/h5/;
}
```

`client_max_body_size` 可以放在当前站点的 `server {}` 内统一生效。上传大文件遇到 Nginx `413 Request Entity Too Large` 时，确认站点配置已包含该值后执行 `nginx -t && nginx -s reload` 或在宝塔面板重载 Nginx。

AI 实时 WebSocket 必须代理到实时端口，不能落到普通 HTTP 入口：

```nginx
location /v1/realtime {
    proxy_pass http://127.0.0.1:18791;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

如果实际宿主机端口不是 `18787` 或 `18791`，以 `docker.sh` 配置摘要里的端口映射为准。

## 发布后验证

查看容器和镜像：

```bash
ssh shanghai "docker ps -a --filter name=b8aiadmin"
ssh shanghai "docker image ls b8aiadmin | head"
```

查看 Webman 进程状态：

```bash
ssh shanghai "docker exec b8aiadmin /app/server status"
```

查看迁移状态：

```bash
ssh shanghai "docker exec b8aiadmin /app/server b8:migrate:status"
```

所有迁移显示 `up`，并且 `AddAdminerMenu`、`AddB8cmsCarousel` 等迁移有完成时间，说明基线和增量迁移已经成功。

查看容器日志：

```bash
ssh shanghai "docker logs --tail=200 b8aiadmin"
```

接口和静态资源：

```bash
curl -I http://127.0.0.1:18787/
curl -I http://127.0.0.1:18787/admin/
curl -I http://127.0.0.1:18787/h5/
```

## 常见问题

### 迁移报 `sa_system_menu` 不存在

这是目标库没有导入基线 SQL。确认目标库是空库且已备份后，使用首次安装模式：

```bash
RUN_INSTALL=1 RUN_MIGRATE=0 AUTO_REMOTE_UPDATE=1 bash docker.sh
```

不要对已有业务数据的库盲目执行首次安装。

### `b8:install` 报 `phar.readonly`

旧镜像中的 `b8:install` 会尝试写 `phar:///app/server/.env`，导致：

```text
phar error: write operations disabled by the php.ini setting phar.readonly
```

修复后安装命令会写运行目录 `/app/.env`。如果仍看到该错误，说明服务器运行的是旧镜像，必须重新构建并上传新镜像。

### 迁移状态全是 `up`，但日志刷 `NOAUTH Authentication required`

这表示数据库基线和迁移已经成功，当前问题是 Redis 队列认证失败。检查：

```bash
ssh shanghai "docker exec b8aiadmin sh -lc 'grep -nE \"^REDIS_\" /app/.env'"
```

重点确认：

```dotenv
REDIS_HOST=host.docker.internal
REDIS_PORT=6379
REDIS_PASSWORD=线上 Redis 密码
REDIS_DB=0
```

修正 `.env.production` 后需要重新构建镜像，或使用 `REMOTE_ENV_FILE` 提供运行时 `.env` 并重建容器。

### `docker driver` 不支持外部缓存导出

如果 buildx driver 是 `docker`，脚本会跳过 `--cache-to type=local`，使用 Docker 原生层缓存。这是正常行为。

### 只 `docker load` 了镜像但容器没变

迁移失败时脚本会停止在容器重建前。修复迁移或配置后，可以直接使用服务器已有镜像重建：

```bash
REMOTE_REBUILD_ONLY=1 RUN_INSTALL=0 RUN_MIGRATE=0 bash docker.sh
```

如果还需要执行首次安装：

```bash
REMOTE_REBUILD_ONLY=1 RUN_INSTALL=1 RUN_MIGRATE=0 bash docker.sh
```
