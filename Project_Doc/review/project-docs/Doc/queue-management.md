# 队列管理使用说明

本文档说明 B8AIadmin 后台“工具 / 队列运行”、“工具 / 队列配置”、“工具 / 队列任务”和“工具 / 队列消息”的设计、配置、投递、消费、部署和排错方式。当前队列管理同时支持 Redis 队列与 RabbitMQ 队列，并区分内部任务与外部消息两种用途。

## 一、功能入口

队列管理由迁移 `Database/migrations/20260603000600_add_queue_management.php` 初始化；外部消息模式由 `Database/migrations/20260604000100_add_queue_external_message.php` 增加；默认外部消息队列由 `Database/migrations/20260604000200_seed_external_queue_configs.php` 写入；实时队列运行页由 `Database/migrations/20260604000300_add_queue_runtime_menu.php` 加入菜单。

后台菜单位于：

```text
工具
├── 队列运行
├── 队列配置
├── 队列任务
└── 队列消息
```

后端路由位于 `server/plugin/saiadmin/config/route.php`：

| 模块 | 路由前缀 | 说明 |
| --- | --- | --- |
| 队列运行 | `/tool/queueRuntime` | 查看 Redis/RabbitMQ broker 实时积压、未确认、消费者数量，并清空队列待消费消息。 |
| 队列配置 | `/tool/queueConfig` | 管理 Redis/RabbitMQ 队列配置。 |
| 队列任务 | `/tool/queueTask` | 查看任务、重试、取消、删除、清理已完成任务和查看统计。 |
| 队列消息 | `/tool/queueMessage` | 发布给第三方消费的外部消息，并查看发布记录。 |

前端页面位于：

| 页面 | 文件 |
| --- | --- |
| 队列运行 | `saiadmin-artd/src/views/tool/queue/runtime/index.vue` |
| 队列配置 | `saiadmin-artd/src/views/tool/queue/config/index.vue` |
| 队列任务 | `saiadmin-artd/src/views/tool/queue/task/index.vue` |
| 队列消息 | `saiadmin-artd/src/views/tool/queue/message/index.vue` |

后端控制器位于：

| 控制器 | 文件 |
| --- | --- |
| 队列运行 | `server/plugin/saiadmin/app/controller/tool/QueueRuntimeController.php` |
| 队列配置 | `server/plugin/saiadmin/app/controller/tool/QueueConfigController.php` |
| 队列任务 | `server/plugin/saiadmin/app/controller/tool/QueueTaskController.php` |
| 队列消息 | `server/plugin/saiadmin/app/controller/tool/QueueMessageController.php` |

## 二、核心表结构

### 1. `sa_tool_queue_config`

队列配置表。每一条启用配置会在 Webman 启动或 reload 时生成一个消费者进程配置。

| 字段 | 说明 |
| --- | --- |
| `name` | 配置名称，后台展示使用。 |
| `driver` | 队列驱动：`redis` 或 `rabbitmq`。 |
| `message_mode` | 队列用途：`internal_job` 内部任务，`external_message` 外部消息。 |
| `connection` | 连接名，默认 `default`。Redis 对应 `server/config/redis.php`，RabbitMQ 对应 `server/config/plugin/workbunny/webman-rabbitmq/connections.php`。 |
| `queue_name` | 队列名称。 |
| `exchange_name` | RabbitMQ 交换机名称，Redis 不使用。 |
| `exchange_type` | RabbitMQ 交换机类型：`direct`、`fanout`、`topic`、`header`。 |
| `routing_key` | RabbitMQ 路由键。 |
| `is_delayed` | 是否延迟队列：`1` 是，`2` 否。 |
| `delay_mode` | 延迟模式：`none`、`x_delay`、`ttl_dlx`。 |
| `dead_letter_exchange` | 死信交换机。 |
| `dead_letter_routing_key` | 死信路由键。 |
| `prefetch_count` | RabbitMQ QOS 预取数量。慢任务建议设置为 `1`。 |
| `consumer_count` | 消费者进程数量。仅内部任务配置会生成本系统消费者。 |
| `max_attempts` | 最大重试次数配置字段。当前失败任务不会自动按次数重投，主要用于后续扩展和人工判断。 |
| `retry_delay_seconds` | 重试间隔秒数配置字段。当前 `ttl_dlx` 模式会用于队列 TTL 参数。 |
| `arguments` | RabbitMQ 扩展参数 JSON，会合并到队列声明参数。 |
| `status` | `1` 启用，`2` 禁用。 |

迁移默认写入内部任务和外部消息配置：

| 名称 | 驱动 | 队列 | 默认状态 |
| --- | --- | --- | --- |
| Redis快速队列 | `redis` | `fast_queue` | 启用 |
| Redis慢速队列 | `redis` | `slow_queue` | 启用 |
| RabbitMQ快速队列 | `rabbitmq` | `fast_queue` | 禁用 |
| RabbitMQ慢速队列 | `rabbitmq` | `slow_queue` | 禁用 |
| Redis外部消息队列 | `redis` | `external_queue` | 启用 |
| RabbitMQ外部消息队列 | `rabbitmq` | `external_queue` | 禁用 |

注意：同一驱动、同一连接下，启用配置不能共用同一个队列名称。尤其不要让外部消息队列使用内部任务的 `fast_queue`、`slow_queue`，否则外部完整 JSON 可能被内部消费者取走并跳过。

### 2. 队列用途

队列配置必须先区分用途：

| 用途 | 值 | broker 消息内容 | 是否由本系统消费 | 适用场景 |
| --- | --- | --- | --- | --- |
| 内部任务 | `internal_job` | `{"id": 任务ID}` | 是 | 本系统异步执行 PHP 类方法。 |
| 外部消息 | `external_message` | 完整事件 JSON | 否 | 第三方系统直接消费订单、用户、通知等业务事件。 |

只有 `internal_job` 会生成 `RedisQueueConsumer` 或 `RabbitmqQueueConsumer` 消费者进程。`external_message` 只负责发布消息，本系统不会抢消费。

### 3. `sa_tool_queue`

队列任务表。每次投递都会先写入该表，再向 Redis 或 RabbitMQ 发送只包含任务 ID 的消息。

| 字段 | 说明 |
| --- | --- |
| `config_id` | 对应 `sa_tool_queue_config.id`。 |
| `driver` | 任务使用的驱动。 |
| `connections` | 连接名。字段名保留复数是为了兼容旧结构。 |
| `name` | 队列名称。 |
| `class_name` | 待执行类名。 |
| `method_name` | 待执行方法名。 |
| `routing_key` | RabbitMQ 路由键。 |
| `delay` | 延迟秒数。Redis 直接传给 redis-queue；RabbitMQ 延迟队列会转换为毫秒级 `x-delay`。 |
| `request` | JSON 格式任务请求，包含 `class`、`method`、`arguments`。 |
| `response` | 任务执行返回或异常信息。 |
| `io` | 执行期上下文 IO 日志。 |
| `status` | `0` 待消费，`1` 消费中，`2` 已完成，`3` 消费失败，`4` 已取消。 |
| `err_num` | 失败次数。 |
| `source` | 来源，例如 `saiadmin`、`redis`、`rabbitmq`、`codex-test`。 |

### 4. `sa_tool_queue_message`

队列外部消息表。每次外部消息发布都会写入该表，并把完整事件 JSON 投递给 Redis 或 RabbitMQ。

| 字段 | 说明 |
| --- | --- |
| `config_id` | 对应 `sa_tool_queue_config.id`，要求配置用途为 `external_message`。 |
| `message_id` | 系统生成的消息唯一编号。 |
| `driver` | 消息使用的驱动。 |
| `connections` | 连接名。 |
| `name` | 队列名称。 |
| `exchange_name` | RabbitMQ 交换机名称。 |
| `routing_key` | RabbitMQ 路由键。 |
| `event_name` | 事件名称，例如 `order.paid`。 |
| `message_key` | 业务消息键，例如 `order_123`。 |
| `payload` | 原始业务载荷 JSON。 |
| `headers` | 业务消息头 JSON。 |
| `content_type` | 内容类型，默认 `application/json`。 |
| `delay` | 延迟秒数。 |
| `response` | 发布结果或异常信息。 |
| `status` | `0` 待发布，`1` 发布中，`2` 已发布，`3` 发布失败，`4` 已取消。 |
| `publish_time` | 发布时间。 |

## 三、运行流程

### 1. 投递流程

内部任务统一入口是 `server/plugin/saiadmin/app/service/queue/QueuePublisherService.php`。

投递时会先校验：

- 队列配置存在且启用。
- 执行类存在。
- 执行方法存在。

然后创建 `sa_tool_queue` 记录，再发送 broker 消息：

| 驱动 | broker 消息内容 |
| --- | --- |
| Redis | `['id' => <任务ID>]` |
| RabbitMQ | `{"id": <任务ID>}` |

也就是说，内部任务的业务参数不直接放进 Redis/RabbitMQ 消息体，而是存入数据库任务表。这样后台可以完整审计任务、重试任务和查看执行结果。

外部消息统一入口是 `server/plugin/saiadmin/app/service/queue/QueueMessagePublisherService.php`。

外部消息会发送完整 JSON，例如：

```json
{
  "event": "order.paid",
  "message_id": "0f3c4c2a7c1c4e2e9d9e0f5f6a7b8c9d",
  "message_key": "order_123",
  "data": {
    "order_id": 123,
    "amount": "99.00"
  },
  "headers": {
    "trace_id": "trace-001"
  },
  "source": "saiadmin",
  "timestamp": "2026-06-04T00:00:00+08:00"
}
```

第三方程序直接消费这份 JSON，不需要访问 B8AIadmin 的 MySQL，也不需要理解 PHP 类和方法。

### 2. 消费流程

统一执行器是 `server/plugin/saiadmin/app/service/queue/QueueExecutorService.php`。

消费者收到任务 ID 后：

1. 查询 `sa_tool_queue`。
2. 如果任务不存在或状态大于 `0`，直接跳过，避免重复执行。
3. 将任务状态改为 `1` 消费中。
4. 解析 `request` 中的 `class`、`method`、`arguments`。
5. 如果是静态方法，直接调用；如果是实例方法，通过容器创建对象后调用。
6. 执行成功写入 `response`，状态改为 `2`。
7. 普通异常写入异常文件、行号、错误码，状态改为 `3`，`err_num + 1`。
8. 记录 `run_time`、`run_memory`、`io`。

当前 `ApiException` 会按成功处理并写入响应。这是为了兼容部分业务方法用 `ApiException` 表达业务返回的旧用法。

## 四、消费者进程

### 1. 动态进程生成

进程配置由 `server/plugin/saiadmin/app/service/queue/QueueProcessConfigService.php` 从 `sa_tool_queue_config` 动态生成。

Redis 进程配置入口：

```php
server/config/plugin/webman/redis-queue/process.php
```

RabbitMQ 进程配置入口：

```php
server/config/plugin/workbunny/webman-rabbitmq/process.php
```

只有满足以下条件的配置会生成消费者进程：

- `status = 1`
- `message_mode = internal_job`
- `delete_time IS NULL`
- `driver` 与入口匹配

进程名格式：

```text
saiadmin_<driver>_queue_<config_id>_<queue_name>
```

`consumer_count` 决定该队列启动多少个消费者进程。

### 2. Webman reload 要求

Webman 是常驻进程。新增队列配置、修改队列名称、调整启用状态、修改消费者数量、修改 RabbitMQ exchange/routing_key 等配置后，需要 reload 或 restart 才能让消费者进程重新生成。

常用命令：

```bash
cd server
php start.php reload
```

如果进程尚未启动，则使用项目运行方式启动 Webman。

## 五、Redis 队列

Redis 连接配置在：

```text
server/config/redis.php
server/.env
server/.env.example
```

环境变量：

```env
REDIS_HOST = 127.0.0.1
REDIS_PORT = 6379
REDIS_PASSWORD = ''
REDIS_DB = 0
```

内部任务 Redis 投递使用 `Webman\RedisQueue\Redis::connection($connection)->send($queueName, ['id' => $id], $delay)`。

外部消息 Redis 投递会把完整事件 JSON 放入 webman/redis-queue 的 `data` 字段。Redis 原始列表消息仍会有 webman/redis-queue 外层包装，第三方如果直接读 Redis list，需要从 `{redis-queue}-waiting<queue_name>` 中解析外层 JSON，再读取 `data`。

Redis 消费者位于：

```text
server/plugin/saiadmin/process/queue/RedisQueueConsumer.php
```

后台“队列运行”页支持读取 Redis broker 侧等待数和延迟数：

| 指标 | Redis key |
| --- | --- |
| 待消费 | `{redis-queue}-waiting<queue_name>` |
| 延迟 | `{redis-queue}-delayed` 中匹配 `queue = <queue_name>` 的消息 |

清空 Redis 实时队列时，会删除对应 waiting key，并从 delayed zset 中移除该队列的延迟消息。

测试投递示例：

```bash
cd server
php -r 'require "vendor/autoload.php"; require "support/bootstrap.php"; redis_send(\plugin\saiadmin\app\cache\DictCache::class, "getDictAll", [], 0, "fast_queue");'
```

如果投递成功，`sa_tool_queue` 会新增一条待消费任务，并且 Redis waiting 数会增加。

## 六、RabbitMQ 队列

RabbitMQ 使用 `workbunny/webman-rabbitmq`。

连接配置在：

```text
server/config/plugin/workbunny/webman-rabbitmq/connections.php
server/.env
server/.env.example
```

环境变量：

```env
RABBITMQ_HOST = 127.0.0.1
RABBITMQ_PORT = 5672
RABBITMQ_VHOST = /
RABBITMQ_USERNAME = admin
RABBITMQ_PASSWORD = admin
RABBITMQ_DEBUG = false
RABBITMQ_TIMEOUT = 10
RABBITMQ_RESTART_INTERVAL = 5
RABBITMQ_MANAGEMENT_SCHEME = http
RABBITMQ_MANAGEMENT_HOST = 127.0.0.1
RABBITMQ_MANAGEMENT_PORT = 15672
RABBITMQ_MANAGEMENT_USERNAME = admin
RABBITMQ_MANAGEMENT_PASSWORD = admin
RABBITMQ_MANAGEMENT_TIMEOUT = 3
WEBMAN_EVENT_LOOP = Workerman\Events\Fiber
```

后台“队列运行”页读取 RabbitMQ 实时积压依赖 RabbitMQ Management API。需要 RabbitMQ 服务端启用 `rabbitmq_management` 插件，并允许后台服务访问 `15672` 或实际管理端口。页面读取 `/api/queues/{vhost}/{queue}` 获取 `messages_ready`、`messages_unacknowledged` 和 `consumers`，清空队列使用 `/api/queues/{vhost}/{queue}/contents`。

RabbitMQ 消费者依赖 Workerman 协程事件循环。项目默认使用 `Workerman\Events\Fiber`，并已通过 Composer 引入 `revolt/event-loop` 作为 Fiber 事件循环依赖。也可以在 `.env` 中通过 `WEBMAN_EVENT_LOOP` 覆盖为其他支持协程的事件循环，例如：

```env
WEBMAN_EVENT_LOOP = Workerman\Events\Fiber
```

如果老环境的 `.env` 中已经存在 `WEBMAN_EVENT_LOOP = ''`，需要删除该行或改为 `WEBMAN_EVENT_LOOP = Workerman\Events\Fiber`，然后 restart Webman。

RabbitMQ 动态消费者位于：

```text
server/plugin/saiadmin/process/queue/RabbitmqQueueConsumer.php
```

它继承 `Workbunny\WebmanRabbitMQ\Builders\QueueBuilder`，并从后台队列配置中设置：

- connection
- exchange type
- exchange name
- queue name
- routing key
- delayed
- prefetch count
- arguments
- dead-letter exchange
- dead-letter routing key
- x-message-ttl

RabbitMQ 投递使用 Workbunny helper：

```php
use function Workbunny\WebmanRabbitMQ\publish;

publish($builder, json_encode(['id' => $taskId], JSON_UNESCAPED_UNICODE), $routingKey, $headers);
```

注意：Workbunny RabbitMQ 的发布和消费都依赖 Workerman Fiber 运行时。后台 HTTP 请求、Webman 进程和队列消费者进程中可以正常使用；不要用普通 `php -r` 直接调用 `rabbitmq_send()` 或 `rabbitmq_publish()` 做测试，否则仍可能因为不在 Fiber 上下文中报 `Not in fiber context`。

### RabbitMQ 多队列与交换机

多队列、多交换机、多 routing key 可以通过多条“队列配置”表达。

示例：

| 场景 | 配置方式 |
| --- | --- |
| 一个 direct exchange 下多个业务队列 | 多条配置使用相同 `exchange_name`，不同 `queue_name` 和 `routing_key`。 |
| topic 模式按业务分发 | `exchange_type = topic`，不同队列配置不同 `routing_key`，例如 `order.*`、`user.registered`。 |
| fanout 广播 | `exchange_type = fanout`，多个队列配置相同 `exchange_name`，routing key 可留空或按实际兼容值填写。 |
| 不同 RabbitMQ 连接 | 在 `connections.php` 增加命名连接，然后配置表 `connection` 填对应连接名。 |

当前后台配置覆盖的是常用拓扑。更复杂的 exchange、queue、binding、header matching 或插件级策略，建议先在 RabbitMQ 管理台确认拓扑，再把能固化的参数写入配置表 `arguments` 或扩展专用 Builder。

### RabbitMQ 延迟

当前投递服务对 RabbitMQ 延迟的处理规则：

- 当 `is_delayed = 1` 时，投递会带 `x-delay` header，单位为毫秒。
- 当 `is_delayed != 1` 且传入 `delay > 0` 时，会拒绝投递。
- Workbunny 会校验：延迟 Builder 必须有 `x-delay`，普通 Builder 不能有 `x-delay`。

因此，如果要使用 `x_delay`，RabbitMQ 服务端必须安装并启用 `rabbitmq_delayed_message_exchange` 插件。

`ttl_dlx` 当前主要用于队列声明参数，会写入：

- `x-message-ttl`
- `x-dead-letter-exchange`
- `x-dead-letter-routing-key`

这适合构建 TTL + 死信交换机拓扑，但不是完整的“任意单条消息延迟”替代方案。使用前建议单独设计延迟队列、死信队列和回投队列，并在 RabbitMQ 管理台确认消息流向。

## 七、业务投递函数

全局函数位于：

```text
server/plugin/saiadmin/app/functions.php
```

### 1. 按配置 ID 投递内部任务

```php
queue_send(
    int $configId,
    object|string $class,
    string $method,
    array $arguments = [],
    int $delay = 0,
    string $source = 'saiadmin'
): bool
```

示例：

```php
queue_send(
    1,
    \plugin\saiadmin\app\cache\DictCache::class,
    'getDictAll',
    [],
    0,
    'demo'
);
```

### 2. 投递内部任务到 Redis 队列

```php
redis_send(
    object|string|null $class = null,
    string $method = '',
    array $arguments = [],
    int $delay = 0,
    string $queueName = 'fast_queue',
    string $connection = 'default'
): bool
```

示例：

```php
redis_send(
    \plugin\saiadmin\app\cache\DictCache::class,
    'getDictAll',
    [],
    0,
    'fast_queue',
    'default'
);
```

### 3. 投递内部任务到 RabbitMQ 队列

```php
rabbitmq_send(
    object|string|null $class = null,
    string $method = '',
    array $arguments = [],
    int $delay = 0,
    string $queueName = 'fast_queue',
    string $connection = 'default'
): bool
```

示例：

```php
rabbitmq_send(
    \plugin\saiadmin\app\cache\DictCache::class,
    'getDictAll',
    [],
    0,
    'fast_queue',
    'default'
);
```

注意：`rabbitmq_send()` 只会查找已启用的 RabbitMQ 队列配置。默认 RabbitMQ 配置是禁用状态，使用前需要在后台启用并 reload Webman。

### 4. 按配置 ID 发布外部消息

```php
queue_publish(
    int $configId,
    string $eventName,
    array $payload,
    array $headers = [],
    int $delay = 0,
    string $messageKey = '',
    string $source = 'saiadmin'
): bool
```

示例：

```php
queue_publish(
    5,
    'order.paid',
    ['order_id' => 123, 'amount' => '99.00'],
    ['trace_id' => 'trace-001'],
    0,
    'order_123',
    'order-service'
);
```

### 5. 发布外部消息到 Redis 队列

```php
redis_publish(
    string $eventName,
    array $payload,
    array $headers = [],
    int $delay = 0,
    string $queueName = 'external_queue',
    string $connection = 'default',
    string $messageKey = '',
    string $source = 'saiadmin'
): bool
```

### 6. 发布外部消息到 RabbitMQ 队列

```php
rabbitmq_publish(
    string $eventName,
    array $payload,
    array $headers = [],
    int $delay = 0,
    string $queueName = 'external_queue',
    string $connection = 'default',
    string $messageKey = '',
    string $source = 'saiadmin'
): bool
```

外部消息函数只会查找 `message_mode = external_message` 且已启用的配置。

## 八、运行状态操作

后台“队列运行”支持：

| 操作 | 说明 |
| --- | --- |
| 查看列表 | 按配置名称、驱动、用途、队列名、状态筛选队列配置，并展示 broker 实时指标。 |
| 实时指标 | Redis 显示待消费和延迟数；RabbitMQ 显示待消费、未确认和消费者数量。 |
| 数据库记录 | 同时显示后台记录中的待处理、处理中和失败数量，便于区分“系统记录”和“真实 broker 积压”。 |
| 清空队列 | 清空 Redis waiting/delayed 或 RabbitMQ ready 消息。该操作不会删除配置，也不会删除后台历史记录。 |
| 删除配置 | 复用队列配置删除能力，软删除 `sa_tool_queue_config` 配置记录。 |

注意：清空真实队列会删除尚未被消费者处理的消息。生产环境执行前必须确认队列用途、三方消费者状态和回滚方案。

## 九、任务管理操作

后台“队列任务”支持：

| 操作 | 说明 |
| --- | --- |
| 查看列表 | 按配置、驱动、连接、队列名、状态、类名、方法名、来源和创建时间筛选。 |
| 查看详情 | 查看 request、response、io、运行时间、内存和错误次数。 |
| 重试 | 将任务状态重置为待消费并重新投递。消费中的任务不能重试。 |
| 取消 | 将待消费或失败任务标记为已取消。消费中和已完成任务不能取消。 |
| 删除 | 软删除任务记录。 |
| 清理已完成 | 按配置或全局清理已完成任务。 |
| 统计 | 查看各状态数量和每个队列的任务数量。实时 broker 指标以“队列运行”页为准。 |

任务状态：

| 值 | 状态 |
| --- | --- |
| `0` | 待消费 |
| `1` | 消费中 |
| `2` | 已完成 |
| `3` | 消费失败 |
| `4` | 已取消 |

## 十、消息管理操作

后台“队列消息”支持：

| 操作 | 说明 |
| --- | --- |
| 发布消息 | 选择外部消息队列配置，填写事件名称、业务键、延迟秒数、payload 和 headers。 |
| 查看列表 | 按配置、驱动、状态、事件名称等筛选外部消息发布记录。 |
| 查看详情 | 查看 payload、headers、发布结果、消息编号和发布时间。 |
| 重试 | 对待发布、失败或已取消消息重新发布。 |
| 取消 | 将待发布或失败消息标记为已取消。 |
| 删除 | 软删除消息记录。 |
| 清理已发布 | 按配置或全局清理已发布消息。 |

消息状态：

| 值 | 状态 |
| --- | --- |
| `0` | 待发布 |
| `1` | 发布中 |
| `2` | 已发布 |
| `3` | 发布失败 |
| `4` | 已取消 |

## 十一、部署和升级

### 1. 数据库迁移

首次安装会导入基线并执行迁移。后续升级执行：

```bash
cd server
php webman b8:migrate:status
php webman b8:migrate --dry-run
php webman b8:migrate
```

队列管理迁移：

```text
20260603000600_add_queue_management.php
20260604000100_add_queue_external_message.php
20260604000200_seed_external_queue_configs.php
```

### 2. 环境变量

部署前确认：

- Redis 环境变量已配置。
- RabbitMQ 环境变量已配置。
- RabbitMQ 消费者所需的 `WEBMAN_EVENT_LOOP` 已配置，或使用项目默认 `Workerman\Events\Fiber`。
- RabbitMQ 用户、vhost、权限正确。
- 如果使用 x-delay，RabbitMQ 已启用 `rabbitmq_delayed_message_exchange`。

### 3. 进程重载

数据库迁移和环境变量配置完成后，重载 Webman：

```bash
cd server
php start.php reload
```

如果修改了 `.env`，常驻进程必须重启或 reload 才能读取新值。

## 十二、验证命令

### 后端语法

```bash
cd server
php -l plugin/saiadmin/app/service/queue/QueuePublisherService.php
php -l plugin/saiadmin/process/queue/RedisQueueConsumer.php
php -l plugin/saiadmin/process/queue/RabbitmqQueueConsumer.php
php -l plugin/saiadmin/app/service/queue/QueueMessagePublisherService.php
php -l config/plugin/workbunny/webman-rabbitmq/connections.php
```

### 路由

```bash
cd server
php webman route:list | rg "queueConfig|queueTask|queueMessage"
```

外部消息路由：

```bash
cd server
php webman route:list | rg "queueMessage"
```

### 迁移状态

```bash
cd server
php webman b8:migrate:status | rg "20260603000600|20260604000100|20260604000200|AddQueue"
```

### RabbitMQ 插件命令

```bash
cd server
php webman workbunny:rabbitmq-builder -h
php webman workbunny:rabbitmq-list -h
php webman workbunny:rabbitmq-remove -h
```

注意：本项目队列管理使用数据库动态生成 RabbitMQ 消费者，`workbunny:rabbitmq-list` 主要用于查看 Workbunny 生成器生成的静态 Builder，不一定会列出后台配置表中的动态队列。

### 前端类型检查

```bash
cd saiadmin-artd
pnpm -s exec vue-tsc --noEmit
```

## 十三、常见问题

### 1. 后台看不到菜单

先确认迁移已执行，再检查当前用户角色是否拥有菜单权限。必要时清理 SaiAdmin 用户菜单/权限缓存，并重新登录后台。

### 2. 投递成功但任务没有消费

检查：

- 队列配置是否启用。
- Webman 是否已 reload/restart。
- Redis 或 RabbitMQ 服务是否可连接。
- 消费者进程是否生成。
- 任务是否已被标记为取消、失败或完成。

### 3. Redis waiting 增加但状态一直是待消费

说明消息已进入 Redis broker，但消费者可能没有启动或没有订阅该队列。检查 `server/config/plugin/webman/redis-queue/process.php` 是否返回动态进程，确认 Webman reload 后进程已生效。

### 4. RabbitMQ 延迟投递失败

常见原因：

- 队列配置不是延迟队列但传入了 `delay > 0`。
- 启用了延迟队列，但 RabbitMQ 服务端未安装 `rabbitmq_delayed_message_exchange`。
- exchange 已存在但类型与当前配置不一致，RabbitMQ 不允许用不同类型重复声明同名 exchange。

### 5. 修改 RabbitMQ exchange 后仍旧报旧配置

Webman 是常驻进程，配置修改后需要 reload/restart。RabbitMQ broker 中已存在的 exchange/queue 如果参数不同，可能还需要在 RabbitMQ 管理台处理旧拓扑。

### 6. RabbitMQ 消费者一直重启

如果 `server/runtime/logs/workerman.log` 出现 `Not in fiber context`，说明 Workbunny RabbitMQ 运行在非协程事件循环下。确认 `.env` 没有把 `WEBMAN_EVENT_LOOP` 覆盖为空值，必要时设置为 `WEBMAN_EVENT_LOOP = Workerman\Events\Fiber` 并 restart Webman。

### 7. 任务失败后没有自动重试

当前实现会记录失败状态和 `err_num`，后台支持人工重试。`max_attempts` 和 `retry_delay_seconds` 已保存在配置表中，但自动按次数重试需要后续扩展调度逻辑。

### 8. 三方程序拿不到内部任务数据

内部任务模式发给 broker 的消息只有任务 ID，业务参数存储在 `sa_tool_queue.request`。三方程序不应该消费内部任务队列。

如果需要三方程序消费，必须使用外部消息模式，并通过 `queue_publish()`、`redis_publish()` 或 `rabbitmq_publish()` 发布完整业务 payload。默认 Redis 外部消息队列是 `external_queue`。

### 9. 外部消息配置为什么没有消费者进程

这是刻意设计。外部消息由第三方程序消费，本系统只负责发布和记录。如果本系统也启动消费者，会抢走第三方消息。

如果后台“发布消息”的队列配置下拉为空，通常是还没有启用 `message_mode = external_message` 的队列配置。执行最新迁移后会默认启用 `Redis外部消息队列`；RabbitMQ 外部消息队列默认禁用，需要配置 RabbitMQ 后手动启用。

### 10. 业务方法应该怎么写

队列任务可能重复消费，业务方法应满足：

- 可幂等执行。
- 参数可 JSON 序列化。
- 不依赖当前 HTTP Request。
- 对外部接口调用做好超时、重试和日志。
- 对敏感参数不要写入明文日志或 `response`。

## 十四、当前边界

- 内部任务的 Redis/RabbitMQ 消息只保存任务 ID。
- 外部消息会把完整事件 JSON 投递给 Redis/RabbitMQ。
- Redis 支持后台展示 broker 待消费/延迟数量，并支持清空对应队列积压。
- RabbitMQ 支持通过 Management API 展示 broker 待消费/未确认/消费者数量，并支持清空 ready 消息；不在后台直接删除 queue、exchange 或 binding。
- RabbitMQ 默认配置为禁用，需要配置环境变量、启用后台队列配置并 reload Webman 后使用。
- RabbitMQ 复杂拓扑可以通过多条配置和 `arguments` 表达，超出后台表单能力的场景建议增加专用 Builder 或扩展配置字段。
- 生产环境启用新队列前，应先确认 Redis/RabbitMQ 服务、权限、vhost、延迟插件、死信拓扑和 Webman 进程重载窗口。
