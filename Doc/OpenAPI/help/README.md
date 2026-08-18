# HelpSupport OpenAPI 文档

本目录维护 HelpSupport 移动端接口的 OpenAPI 快照。

## 文件说明

- `openapi.yaml`：从本地 APIDOC `helpsupport-api` 导出的 OpenAPI 3.0.1 文档，当前覆盖 93 个接口路径。

## 导出来源

```bash
curl http://127.0.0.1:8787/apidoc/openapi/helpsupport-api
```

该快照应与 `server/plugin/help/app/api/controller` 中的 APIDOC 注解保持一致，用于 Flutter 端接口契约核对和后续自动生成。
