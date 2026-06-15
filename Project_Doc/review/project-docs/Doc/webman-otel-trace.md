# Webman OpenTelemetry Trace 使用说明

本文档说明 B8AIadmin 中 `openb8/webman-otel-trace` 的使用方式和业务埋点规范。

## 能看到什么

Trace 插件用于观察一次请求或一次后台任务的关键链路。当前建议覆盖这些节点：

- HTTP 入口请求
- 业务 Logic / Service 关键动作
- SQL / PDO / ThinkORM
- RabbitMQ 发布和消费
- 队列任务消费
- 异常、耗时、业务状态码
- 本地 request/span/sql 日志中的 `trace_id` 和 `span_id`

完整 PHP 方法调用栈不建议放到常驻 trace 里。全量方法调用图属于 Xdebug、Blackfire、Tideways、XHProf、SPX 这类 profiler/debug 工具。

## Logic 手动业务 span

业务 Logic 中优先使用 `Trace::span()` 包住关键业务入口：

```php
use OpenB8\WebmanOtelTrace\Support\Trace;

class OrderLogic
{
    public function pay(int $orderId): bool
    {
        return Trace::span('order.pay', function () use ($orderId) {
            $this->checkOrder($orderId);
            $this->createPayment($orderId);
            $this->markPaid($orderId);

            return true;
        }, [
            'order.id' => $orderId,
        ]);
    }
}
```

`Trace::span()` 会自动：

- 继承当前 HTTP 请求 trace
- 在队列、定时任务、CLI 等无 HTTP 入口场景创建新 trace
- 记录 span 耗时
- 捕获异常并把 span 标记为 error
- 透传回调返回值
- 保持 SQL 自动埋点处于同一上下文

回调可以不接收参数；如果声明一个参数，会收到当前 `SpanInterface`。普通业务优先使用 `Trace::setAttribute()` 和 `Trace::addEvent()`，不要直接依赖 OpenTelemetry 细节。

## 细分关键步骤

复杂业务可以在大 span 内拆分少量子 span：

```php
public function createChat(array $data): array
{
    return Trace::span('saiai.chat.create', function () use ($data) {
        $conversation = $this->createConversation($data);

        $answer = Trace::span('saiai.llm.request', function () use ($data) {
            Trace::setAttribute('model', $data['model'] ?? '');
            Trace::addEvent('llm.request.start');

            return $this->llmService->chat($data);
        });

        $this->saveMessage($conversation, $answer);

        return $answer;
    }, [
        'user.id' => $data['user_id'] ?? 0,
    ]);
}
```

建议命名使用稳定英文标识，例如：

- `order.pay`
- `payment.request`
- `saiai.chat.create`
- `saiai.llm.request`
- `queue.consume`
- `file.parse`

属性 key 建议使用点分格式，例如 `order.id`、`user.id`、`model`、`queue.name`。

## 什么时候不需要手动 span

以下场景通常不需要手动加：

- 普通 CRUD 的每个小方法
- 私有工具方法
- getter / setter
- 简单参数转换
- 框架内部方法
- 已经被 SQL、HTTP、RabbitMQ 自动埋点清楚表达的底层调用

判断标准：这个节点是否能帮助你回答“慢在哪里、失败在哪里、业务对象是谁”。如果不能，就不要加。

## 配置开关

业务 span 默认开启：

```php
'business_span' => [
    'enable' => true,
    'tracer_name' => 'openb8.webman.business',
    'console' => false,
    'file' => true,
],
```

环境变量：

```bash
OTEL_BUSINESS_SPAN=true
OTEL_BUSINESS_SPAN_FILE=true
OTEL_BUSINESS_TRACER_NAME=openb8.webman.business
```

生产环境如果只想保留 HTTP、SQL 和请求日志，可以设置：

```bash
OTEL_BUSINESS_SPAN=false
```

## 调试页

本地 debug 模式可访问：

```text
http://127.0.0.1:8787/__trace
```

浏览器接口响应头中复制 `x-trace-id` 或完整 `traceparent`，在页面中查询本地 request/span/sql 日志。

页面会读取本地 `otel-request-*`、`otel-span-*` 和 `otel-sql-*` 日志，展示 HTTP、业务 Span、SQL 的单次 trace 时间线。业务 span 需要 `business_span.file=true` 或 `OTEL_BUSINESS_SPAN_FILE=true` 才会出现在本地页面中。

如果需要跨服务、跨机器的完整时间线，仍建议配置 OTLP Collector、Jaeger、Tempo 等后端。

## 版本

当前 trace 插件版本：`0.2.1`。

本版本新增：

- `OpenB8\WebmanOtelTrace\Support\Trace::span()`
- `Trace::setAttribute()`
- `Trace::setAttributes()`
- `Trace::addEvent()`
- `Trace::context()`
- `OTEL_BUSINESS_SPAN` 业务 span 开关
- `OTEL_BUSINESS_SPAN_FILE` 业务 span 本地日志开关
- `/__trace` 展示业务 Span 时间线
