# B8 Webman 二进制打包说明

本文档说明如何把 `server/` 下的 Webman 服务端打包成独立二进制文件，以及打包产物命名、运行时配置和部署验证注意事项。

当前框架已内置自定义 `build:bin` 命令，默认产物为：

```text
server/build/server
```

也就是说，默认生成物名称是 `server`，没有 `.bin`、`.phar` 等后缀。

## 适用场景

- 需要把 B8AIadmin 父框架或基于本框架的子项目后端打包成单文件服务端程序。
- 希望部署时只分发二进制文件、`.env` 和运行时必要目录。
- 希望二进制产物名称可按项目自由指定，例如 `server`、`b8-server`、`justai-api`。

注意：当前 `build:bin` 使用 PHP micro.sfx 生成 Linux x86_64 可执行文件。macOS 本机可以执行构建命令，但不能直接运行生成的 Linux 二进制产物；运行验证需要放到 Linux 服务器或 Linux 容器中执行。

## 构建前要求

在 `server/` 目录执行构建命令：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin
```

构建前确认：

- `server/vendor/` 已安装完成，Composer 自动加载可正常工作。
- CLI PHP 能运行当前项目，建议使用 PHP 8.3。
- `phar.readonly=0`，否则无法生成 PHAR。
- 构建进程有足够内存，建议命令行显式加 `-d memory_limit=-1`。
- 首次构建需要访问 `download.workerman.net` 下载 `phpX.micro.sfx.zip`；下载后的 PHP micro 运行时会缓存在 `server/runtime/build-bin-cache/`，后续构建会自动复用。
- PHP 建议启用 `zip`、`openssl`。没有 `zip` 时会尝试下载未压缩的 micro.sfx；没有 `openssl` 时会回退到 HTTP 下载。

## 默认构建

默认命令：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin
```

默认结果：

```text
server/build/server
```

默认行为：

- 生成最终二进制文件 `build/server`。
- 中间文件 `build/webman.phar` 构建成功后会自动清理。
- PHP micro 运行时缓存保留在 `runtime/build-bin-cache/`，用于后续构建复用，不会因为默认清理策略被删除。
- `server/build/` 已加入 `.gitignore`，不要提交构建产物。

## 自定义产物名称

命令行临时指定名称：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin --name=b8-runner
```

生成结果：

```text
server/build/b8-runner
```

通过 `.env` 固定默认名称：

```dotenv
WEBMAN_BIN_FILENAME=b8-runner
```

然后执行：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin
```

名称规则：

- 可以是任意普通文件名，例如 `server`、`api`、`b8-server`、`justai-api`。
- 不能为空。
- 不能是 `.` 或 `..`。
- 不能包含目录分隔符，不能写成 `build/server`、`../server`、`release/server`。

框架会在 PHAR 内修补 Workerman 的进程识别逻辑，保证任意二进制文件名下的 `status`、`stop` 等命令能识别当前主进程。

## PHP micro 缓存

默认缓存目录：

```text
server/runtime/build-bin-cache/
```

首次构建会下载并缓存：

```text
server/runtime/build-bin-cache/php8.3.micro.sfx
server/runtime/build-bin-cache/php8.3.micro.sfx.zip
```

后续构建会直接输出 `使用本地 PHP8.3 资源...`，不会重新下载。

如需自定义缓存目录，可在 `.env` 中配置：

```dotenv
WEBMAN_BIN_RUNTIME_CACHE_DIR=/absolute/path/to/build-bin-cache
```

也可以使用相对项目根目录的路径：

```dotenv
WEBMAN_BIN_RUNTIME_CACHE_DIR=runtime/build-bin-cache
```

## 保留中间文件

默认构建完成后会清理 `build/webman.phar`。如果需要排查 PHAR 内容，可使用：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin --keep-intermediate
```

也可以在 `.env` 中关闭自动清理：

```dotenv
WEBMAN_BIN_CLEANUP=false
```

保留后可能出现：

```text
server/build/server
server/build/webman.phar
```

中间文件仅用于构建和排查，不应提交到 Git。PHP micro 运行时缓存始终放在 `runtime/build-bin-cache/`。

## 指定 PHP micro 版本

`build:bin` 支持可选的 PHP 版本参数：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin 8.3
```

命令会下载对应版本的 `php8.3.micro.sfx` 并拼接 PHAR。传入版本低于 `8.1` 时会按 `8.1` 处理。

## 打包内容和排除内容

构建以 `server/` 为应用根目录，主要会打入：

- `app/`
- `config/`
- `plugin/`
- `vendor/`
- `public/`
- 运行所需的 Composer 自动加载和框架代码

默认排除：

- `.env`
- `runtime/`
- `build/`
- `.git/`、`.github/`、`.idea/` 等开发目录
- `vendor-bin/`
- `vendor/webman/admin/`
- `composer.json`、`composer.lock`
- `start.php`
- `webman.phar`、`webman.bin`
- `app/command/BuildBinCommand.php`

因此，部署二进制产物时不要假设 `.env` 会被打包进去。生产环境的 `.env` 应独立放在二进制文件同级目录，或通过系统环境变量提供。

## Composer path 仓库注意事项

本框架中 `openb8/webman-otel-trace` 使用本地 path 仓库进入 `server/vendor`。打包二进制时，PHAR 不能可靠打入指向 `server/` 外部的 vendor 软链，因此该依赖必须以复制方式安装。

当前 `server/composer.json` 已配置：

```json
{
  "repositories": [
    {
      "type": "path",
      "url": "../packages/openb8/webman-otel-trace",
      "options": {
        "symlink": false
      }
    }
  ]
}
```

如果后续新增本地 path 包，也要确认是否需要 `"symlink": false`。否则本地开发可以运行，但 `php webman build:bin` 打出的 PHAR 可能包含不可用软链，导致服务器运行时找不到类或文件。

## 运行时目录和配置

二进制文件启动时，当前工作目录就是运行根目录。建议部署目录结构：

```text
/www/wwwroot/b8aiadmin-server/
├── server
├── .env
└── runtime/
```

首次运行前：

```bash
chmod +x server
mkdir -p runtime
```

常用命令：

```bash
./server version
./server start -d
./server status
./server reload
./server restart -d
./server stop
```

运行时注意：

- `.env` 需要放在二进制文件同级目录，或由系统环境变量提供。
- `runtime/` 需要可写，用于日志、PID、缓存、本地 trace、临时文件等。
- 数据库、Redis、RabbitMQ、OpenTelemetry 等配置仍以 `.env` 和实际环境变量为准。
- 打包不会自动执行数据库迁移；生产迁移仍需显式确认备份、目标环境和回滚窗口后单独执行。
- Webman 是常驻进程，替换二进制文件或修改 `.env` 后需要 `restart` 或 `reload`。

## Linux 容器验证

macOS 上不能直接运行 Linux 二进制产物，可以用 Docker 做最小验证：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin

docker run --rm --platform linux/amd64 \
  -v "$PWD/build:/app" \
  -w /app \
  debian:bookworm-slim \
  ./server version
```

验证启动、状态和停止：

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD/build:/app" \
  -w /app \
  debian:bookworm-slim \
  sh -lc './server start -d; sleep 2; ./server status; ./server stop'
```

如果使用自定义名称：

```bash
cd server
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin --name=b8-runner

docker run --rm --platform linux/amd64 \
  -v "$PWD/build:/app" \
  -w /app \
  debian:bookworm-slim \
  sh -lc './b8-runner start -d; sleep 2; ./b8-runner status; ./b8-runner stop'
```

在只有最小系统包的容器里，如果看到类似 `opentelemetry extension must be loaded` 的提示，表示容器内没有安装 PHP OpenTelemetry 扩展。这个提示不代表二进制命令本身不可用；如果生产环境需要 PDO 自动链路上报，再安装并启用对应扩展。

## 服务器验证清单

上传到 Linux 服务器后，建议按顺序检查：

```bash
chmod +x server
./server version
./server route:list
./server start -d
./server status
./server stop
```

再确认：

- `.env` 存在，数据库、Redis、RabbitMQ、OpenTelemetry 配置指向目标环境。
- `runtime/` 可写。
- Webman 监听端口未被占用，默认 HTTP 端口为 `8787`。
- 如果启用 Monitor、队列、WebSocket 等独立进程，对应端口和服务依赖可用。
- Nginx 反向代理指向正确的 Webman HTTP 端口。
- 生产数据库迁移没有被构建流程隐式执行。

## 常见问题

### 构建提示 phar.readonly

执行命令时加：

```bash
php -d phar.readonly=0 -d memory_limit=-1 webman build:bin
```

或修改 CLI PHP 的 `php.ini`：

```ini
phar.readonly = Off
```

### 构建时下载 micro.sfx 失败

检查构建机器是否能访问：

```text
download.workerman.net
```

如果网络不稳定，可以在网络可用环境先构建一次，确认 `server/runtime/build-bin-cache/` 已有 `phpX.micro.sfx` 或 `phpX.micro.sfx.zip` 后再离线构建。

### 运行时找不到 .env 配置

`.env` 不会被打包。把 `.env` 放到二进制文件同级目录，或者用系统环境变量提供配置。

### status 或 stop 找不到进程

先确认当前运行的就是同名二进制文件，例如：

```bash
./server start -d
./server status
./server stop
```

不要用 `./server start -d` 启动后再用另一个文件名执行 `status` 或 `stop`。如果自定义产物名为 `b8-runner`，后续管理命令也必须使用：

```bash
./b8-runner status
./b8-runner stop
```
