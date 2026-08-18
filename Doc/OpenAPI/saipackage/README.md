# SaiPackage 插件管理接口

本目录维护 saipackage 插件的 OpenAPI 文档。

## 文件说明

- `openapi.yaml`：OpenAPI 3.0 规范文件，共整理 20 个接口。

## 来源

- 后端控制器：`server/plugin/saipackage/app`
- 插件路由：`server/plugin/saipackage/config/route.php`
- 前端调用：`saiadmin-artd/src/views/plugin/saipackage`

默认使用 `bearerAuth`，公开接口已在文档中单独标记为空鉴权。
