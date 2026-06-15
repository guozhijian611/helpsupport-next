# Project_Doc 文档入口

本目录用于集中存放 HelpSupport Next 的项目资料。当前以“现状文档 + 历史参考资料”两层组织，避免继续把早期重建方案、评审归档和当前运行事实混在一起。

## 当前优先阅读

1. `helpsupport-next-当前项目梳理.md`
   - 基于当前仓库代码、目录、路由、迁移、脚本和端侧结构整理。
   - 用于新成员快速理解仓库现状、开发入口、模块边界和注意事项。
2. `../Doc/`
   - 面向专题的补充文档，例如部署、Docker 发布、APIDOC/OpenAPI、队列、支付、trace 等。
3. `../OpenAPI/help/openapi.yaml`
   - 当前 HelpSupport 移动端 API 契约快照。

## 历史参考

- `help-rebuild-development-guide.md`
  - 这是仓库早期“重做方案”文档，适合了解当时的重建目标与设计决策。
  - 当前项目已经不再只是规划阶段，阅读时应以 `helpsupport-next-当前项目梳理.md` 和实际代码为准。
- `review/`
  - 这是为评审和离线浏览准备的归档资料包，包含旧项目文档、路由快照、UI 资源、数据库资料和历史截图。
  - 它适合做对照和追溯，不应直接视为当前运行仓库的唯一事实来源。

## 使用原则

- 讨论当前仓库结构、命令、模块边界时，以 `server/`、`saiadmin-artd/`、`flutter_app/`、`Database/migrations/`、`OpenAPI/` 的当前内容为准。
- 讨论历史 UI、旧前端静态资源、原始需求或评审材料时，再回看 `review/`。
- 如果后续项目结构继续演进，优先更新 `helpsupport-next-当前项目梳理.md`，保持它是本目录的主入口。
