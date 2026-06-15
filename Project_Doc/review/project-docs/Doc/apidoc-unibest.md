# APIDOC 与 unibest 自动接口联动说明

本文档记录本项目安装 `hg/apidoc`、`hg/apidoc-export` 后，如何在 Webman/SaiAdmin 中查看接口文档，并给 `uniapp` 的 `openapi-ts-request` 生成类型化接口代码。

## 安装结果

后端依赖安装在 `server/`：

```bash
cd server
composer require hg/apidoc hg/apidoc-export
```

Composer 会生成以下配置：

- `server/config/plugin/hg/apidoc/app.php`
- `server/config/plugin/hg/apidoc/route.php`
- `server/config/plugin/hg/apidoc-export/app.php`

APIDOC 前端静态资源已放入：

```text
server/public/apidoc
```

本地 Webman 服务启动后可访问：

```text
http://127.0.0.1:8787/apidoc/index.html
```

如果修改了 PHP 配置、路由或控制器注解，Webman 常驻进程需要 reload/restart 后再验证：

```bash
cd server
php start.php reload
```

## APIDOC 扫描范围

当前 `server/config/plugin/hg/apidoc/app.php` 默认只配置移动端相关 app key：

| app key | 说明 | 控制器目录 |
| --- | --- | --- |
| `saiai-api` | AI 插件移动端接口 | `plugin\saiai\app\api\controller` |
| `saiuser-api` | 会员插件移动端接口 | `plugin\saiuser\app\api\controller` |
| `saipay-api` | 支付插件移动端接口 | `plugin\saipay\app\api\controller` |

## Swagger/OpenAPI 导出地址

`hg/apidoc-export` 原生的 `/apidoc/exportSwagger` 需要 APIDOC 分享 key，不适合 unibest 直接按 app key 拉取。项目已增加一个按 app key 导出的适配接口：

```text
http://127.0.0.1:8787/apidoc/openapi/<app-key>
```

移动端常用地址：

```text
http://127.0.0.1:8787/apidoc/openapi/saiuser-api
http://127.0.0.1:8787/apidoc/openapi/saiai-api
http://127.0.0.1:8787/apidoc/openapi/saipay-api
```

这些地址会输出 OpenAPI 3 JSON，可作为 unibest 自动生成接口的 schemaPath。

## unibest 自动生成接口

`uniapp/openapi-ts-request.config.ts` 已改为读取 APIDOC 导出的移动端 schema：

- `saiuser-api` 生成到 `uniapp/src/service/saiuser`
- `saiai-api` 生成到 `uniapp/src/service/saiai`
- `saipay-api` 生成到 `uniapp/src/service/saipay`

本地生成：

```bash
cd uniapp
pnpm openapi
```

`pnpm openapi` 会进入交互选择。常用固定脚本：

```bash
cd uniapp
pnpm openapi:saiuser
pnpm openapi:saiai
pnpm openapi:saipay
pnpm openapi:mobile
```

如果后端不是本机 `8787`，通过环境变量覆盖：

```bash
cd uniapp
APIDOC_OPENAPI_BASE_URL=https://api.example.com pnpm openapi:mobile
```

生成的接口会继续使用 unibest 现有请求适配器：

```text
uniapp/src/http/vue-query.ts
uniapp/src/http/types.ts
```

## 注解要求

APIDOC 是通过解析控制器注解生成文档。当前安装和联动配置已经完成，但要生成准确的接口路径、请求参数和响应类型，需要在后端控制器方法上补充 `hg\apidoc\annotation` 注解，例如 `Title`、`Url`、`Method`、`Param`、`Query`、`Returned` 等。

没有注解时，APIDOC 只能按控制器和方法名尝试推导，生成出来的 OpenAPI 可能缺少参数和响应结构，不适合直接作为移动端强类型接口的最终依据。
