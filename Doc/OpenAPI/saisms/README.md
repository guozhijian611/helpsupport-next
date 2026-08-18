# SaiSMS 短信插件接口

本目录维护 saisms 插件的 OpenAPI 文档。

## 文件说明

- `openapi.yaml`：OpenAPI 3.0 规范文件，共整理 15 个接口。

## 来源

- 后端控制器：`server/plugin/saisms/app`
- 插件路由：`server/plugin/saisms/config/route.php`
- 前端调用：`saiadmin-artd/src/views/plugin/saisms`

默认使用 `bearerAuth`，公开接口已在文档中单独标记为空鉴权。
