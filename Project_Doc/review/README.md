# HelpSupport review 资料包

本目录用于把项目评审需要的数据库、项目说明、逻辑结构、接口资料和 UI 图片集中到一个独立目录内，便于脱离源码目录快速浏览。

## 目录说明

| 目录 | 内容 | 来源 |
| --- | --- | --- |
| `database/` | 数据库 SQL、Phinx 配置/迁移、插件安装 SQL | `Databasse/`、`Database/`、`server/plugin/*/db`、`server/plugin/help/install.sql` |
| `project-docs/` | 项目说明、PRD、开发需求、部署/队列/接口文档、OpenAPI、组件 README | 根目录文档、`Doc/`、`OpenAPI/`、`OpenApiYaml/`、各子项目 README |
| `project-docs/generated/` | 当前代码结构清单和真实路由快照 | `find` 结构扫描、`php webman route:list` |
| `ui/design/` | 原型设计 UI 图 | `医疗支持图片ui/` |
| `ui/screenshots/` | 已生成的运行截图 | `helpsupport_flutter/test_screenshots/` |
| `ui/assets/` | 前端、Flutter、后台中使用的静态 UI 图片资产 | `helpsupport-frontend/src/static/`、`helpsupport_flutter/assets/`、`saiadmin-artd/src/assets/images/` |
| `ui/frontend-static-all/` | 患者端前端静态素材完整归档，包含源码素材、平台图标、MLC 素材和已有构建输出静态文件 | `helpsupport-frontend/src/static/`、`unpackage/res/`、`.mlc-llm-source/site/`、`dist/build/*/assets`、`dist/build/*/static`、`dist/dev/app/static` |
| `MANIFEST.txt` | 本资料包内所有文件清单 | 当前 `review/` 目录生成 |

## 推荐阅读顺序

1. `project-docs/root/readme.md`：项目定位、技术栈和三端目录入口。
2. `project-docs/root/开发需求.md`：基于 PRD 和 UI 图整理后的统一需求。
3. `project-docs/项目逻辑结构说明.md`：当前代码层面的业务模块、前后端结构和数据库边界。
4. `project-docs/generated/route-list.txt`：后端真实注册路由快照。
5. `database/Databasse/helpsupport.sql` 与 `database/Database/migrations/`：数据库基线和后续迁移。
6. `ui/design/医疗支持图片ui/` 与 `ui/screenshots/flutter-test-screenshots/`：设计稿与运行截图对照。
7. `ui/frontend-static-all/helpsupport-frontend/`：患者端前端静态素材完整归档。

## 复制范围说明

- 已复制评审需要的文档、数据库、OpenAPI、原型图、运行截图和静态 UI 图片资产。
- 已额外归档患者端前端静态素材，包括源码侧 `src/static`、`unpackage/res/icons`、根图标、页面/manifest 配置、本地模型配置、MLC 站点素材，以及现有 `dist/build`、`dist/dev` 中的 assets/static 静态输出。
- 未复制 `.env`、运行日志、上传存储目录、依赖目录和完整构建产物；`dist` 内仅归档已有的 `assets` / `static` 静态输出。
- `project-docs/generated/route-list.txt` 是本次整理时从 `server/` 目录执行 `php webman route:list` 生成的快照。
