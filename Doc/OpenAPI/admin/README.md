# SaiAdmin Admin OpenAPI 文档

本目录用于维护 SaiAdmin 后台管理端接口文档，来源为：

- 后端路由：`server/plugin/saiadmin/config/route.php`
- 快速路由规则：`server/plugin/saiadmin/app/functions.php`
- 后台控制器：`server/plugin/saiadmin/app/controller`
- 前端调用层：`saiadmin-artd/src/api`

## 文件说明

- `openapi.yaml`：OpenAPI 3.0 规范文件，覆盖后台核心 `/core` 与工具 `/tool` 接口。

## 使用说明

可将 `openapi.yaml` 导入 Apifox、Postman、Swagger UI 或 openapi-generator 等工具。接口默认使用 `bearerAuth`，登录与验证码接口无需登录。

统一响应格式来自 `plugin\saiadmin\basic\OpenController`：

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

分页列表通常返回在 `data.list` 与 `data.total` 等字段中，具体字段由各 Logic 层与模型决定。
