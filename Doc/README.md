# 文档目录

本目录集中存放项目文档。根目录 `readme.md` 是仓库入口，`AGENTS.md` 是协作规范。

## 专题文档

部署、接口、队列、支付、构建和排障说明直接放在本目录。

- [部署指南](deployment-guide.md)
- [Openship Docker Compose](openship-compose.md)
- [Docker 二进制镜像发布](docker-release.md)
- [APIDOC 与移动端代码生成](apidoc-unibest.md)
- [数据库结构规范](database-schema-standard.md)

## 子目录

| 路径 | 内容 |
| --- | --- |
| `OpenAPI/` | 各应用的 OpenAPI 契约快照 |
| `Project_Doc/` | 当前项目梳理与历史评审资料 |

数据库安装基线和 Phinx 迁移仍在仓库根目录的 `Database/`，因为安装与迁移命令直接读取该路径。
