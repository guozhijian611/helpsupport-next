# SaiUser 会员插件接口

本目录维护 saiuser 插件的 OpenAPI 文档。

## 文件说明

- `openapi.yaml`：OpenAPI 3.0 规范文件，共整理 82 个接口。

## 来源

- 后端控制器：`server/plugin/saiuser/app`
- 插件路由：`server/plugin/saiuser/config/route.php`
- 前端调用：`saiadmin-artd/src/views/plugin/saiuser`

默认使用 `bearerAuth`，公开接口已在文档中单独标记为空鉴权。
