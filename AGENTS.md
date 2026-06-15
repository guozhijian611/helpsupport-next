# B8AIadmin 开发框架项目规范

## 基本要求
- 始终使用中文回复用户。
- 每一次进行功能变更、文档变更或规范变更之后，都要提交中文 Git commit，commit message 需符合 Conventional Commits 规范。
- 开始改动前先查看 `git status --short`，不要覆盖或回退用户已有改动。
- 提交前只暂存本次任务相关文件，避免把无关改动带入 commit。
- `b8aiadmin` 是父框架，`justai` 是基于本框架的子项目；凡是属于框架层的修复、规范或能力增强，必须优先或同步修改到父框架，不能只落在子项目里。
- `b8aiadmin` 是开发框架，默认按当前规范和最新设计演进，不主动保留旧字段、旧平台类型、旧接口别名或历史兼容分支；只有用户明确要求“兼容”时才加入兼容逻辑。

## 项目技术栈
- 后端：PHP 8.3、Webman、SaiAdmin、ThinkORM、MySQL 8.0、Phinx。
- 管理端：Node 24、pnpm、Vue 3、Art Design Pro、Element Plus。
- 移动端：uni-app、unibest、Flutter、pnpm。
- 部署环境：宝塔面板。

## 目录边界
- `server/`：Webman/SaiAdmin 后端，Composer 命令和 PHP 校验默认在此目录执行。
- `saiadmin-artd/`：SaiAdmin 管理端前端，pnpm 命令默认在此目录执行。
- `uniapp/`：uni-app/unibest 移动端，pnpm 命令默认在此目录执行。
- `flutter_app/`：Flutter 客户端，Flutter 相关命令默认在此目录执行；日常开发联调优先使用 `flutter run -d ios` 获取热重载，完整构建、安装和启动验证再使用 `./tool/build_ios_simulator.sh`。
- `packages/`：本仓库维护的扩展包或插件源码，修改后需确认是否通过 `server/vendor` 软链或 Composer 安装进入运行时。
- `.codex/skills/`：本项目沉淀的开发技能和参考手册；涉及对应技术时优先读取相关 `SKILL.md`。
- `Doc/`、`OpenAPI/`、`Database/`：项目文档、接口文档和数据库资料，更新时以实际路由、控制器、数据库结构、安装 SQL 或 Phinx 迁移为准。

## 开发工作流
- 先确认真实运行入口：Webman 插件以 `server/config/plugin/...`、`server/plugin/...`、`server/vendor/...` 和路由配置为准，不能只看复制来的参考目录。
- 涉及 SaiAdmin/Webman、unibest、RabbitMQ、宝塔等任务时，先查看 `.codex/skills/` 中对应技能，再动手修改。
- 新建业务应用默认使用 SaiAdmin 插件模式，在 `server/` 目录执行 `php webman sai:plugin <插件名>` 创建插件骨架，再在 `server/plugin/<插件名>/app/admin` 与 `server/plugin/<插件名>/app/api` 下继续开发。
- `php webman sai:plugin <插件名>` 只创建基础插件目录、配置和示例 API，不会自动生成业务 Controller/Logic/Model/Validate；新增后台业务时必须通过 SaiCode 生成 CRUD 或手动补齐 Validate，并在控制器构造函数中注入 `$this->validate`，在 `save`、`update` 等写接口调用 `$this->validate('<scene>', $data)`。
- 业务路由默认写在对应插件的 `server/plugin/<插件名>/config/route.php`；标准 CRUD 可用 `fastRoute('<业务路径>', Controller::class)` 注册，非标准动作必须显式补充 `Route::get/post/put/delete`。SaiCode 生成的后台 CRUD 默认使用 `/app/<插件名>/admin/<模块>/<控制器>/<动作>` 形式的 Webman 插件默认路由，不会自动修改 `config/route.php`；如目标插件关闭默认路由、需要稳定 `route:list` 可见性、或新增自定义动作，必须手动注册路由并让前端 API 与之保持一致。
- SaiAdmin 数据权限不是默认自动启用：`plugin\saiadmin\basic\think\BaseLogic` 默认 `protected bool $scope = false`。涉及后台业务数据隔离时，必须确认业务表具备 `created_by` 等审计字段，并在对应 Logic 中显式开启 `protected bool $scope = true;`。
- 后端新增或修改控制器方法时，应同步补充 APIDOC 注解，至少说明接口标题、路径、请求方法、参数和返回结构，保证 `/apidoc/openapi/<app-key>` 可用于 unibest 自动生成接口。
- B8 新业务 API 响应优先使用 `server/app/functions.php` 中的 `ok()`、`fail()` 辅助方法，不再直接手写 `json(['code' => ...])`；底层通过 `b8_json_response()` 保持 `{code,message,data}` 业务响应格式，并在 trace 插件有有效上下文时自动追加 `trace_id`。不要为了新业务响应规范去修改 SaiAdmin 核心 `OpenController`。
- 数据库变更默认使用 Phinx：`composer install` 后缺少 `.env` 时会自动从 `.env.example` 复制；首次安装优先在 `server/` 目录执行 `php webman b8:install` 配置数据库、导入 `Database/b8aiadmin.sql` 基线并执行迁移；后续升级只新增 `Database/migrations/` 迁移，不再新增独立 SQL patch。
- 新增迁移必须支持回滚或明确说明不可逆原因；涉及菜单、权限、初始化数据时要写成幂等逻辑，并避免回滚误删用户原有数据。
- 数据库迁移常用命令：`php webman b8:install`、`php webman b8:migrate:status`、`php webman b8:migrate --dry-run`、`php webman b8:migrate`、`php webman b8:migrate:rollback`、`php webman b8:migrate:create <Name>`。
- 对不确定的生产部署路径、数据库覆盖、安装 SQL、构建发布、队列消费、升级命令等高风险事项，必须先询问用户确认。
- 生产部署中自动执行数据库迁移必须通过显式开关启用，默认关闭；执行前需确认数据库备份、目标环境和回滚窗口。
- Webman 是常驻进程，修改 PHP、路由、插件配置后，验证前需要考虑 reload/restart。
- 日志、调试页和请求记录默认要脱敏 Bearer、Cookie、token、secret 等敏感信息；如需放开，只能做成显式调试开关。
- Flutter 客户端文件变更后，日常开发联调优先在 `flutter_app/` 目录执行 `flutter run -d ios --dart-define=HELP_SUPPORT_API_BASE_URL=...`，连接 iOS 模拟器保持热重载；需要指定设备时优先用 `-d <device id>`，需要完整构建、安装、启动链路验证时再执行 `./tool/build_ios_simulator.sh`，并可按需通过 `IOS_SIMULATOR_NAME`、`IOS_SIMULATOR_UDID`、`HELP_SUPPORT_API_BASE_URL` 指定目标和接口地址。
- Flutter 客户端变更不使用 `flutter analyze` 或所谓 `flutter analysis` 作为默认验证；如果 `flutter run` 或模拟器脚本失败，记录失败阶段和原因，不改用 analyze 代替运行验证。

## 验证要求
- 后端 PHP 文件变更后，至少执行相关 `php -l`；路由或插件变更需结合 `php webman route:list`、相关命令帮助或运行时页面验证。SaiCode 生成 CRUD 后，如果依赖 Webman 插件默认路由，需用前端 API 中的 `/app/<插件名>/admin/...` 实际访问或运行时页面确认；如果改用显式路由，则必须在 `route:list` 中核对。
- 管理端或移动端变更后，优先执行项目已有的类型检查、lint 或最小可行验证命令。
- Flutter 客户端变更后的默认开发验证是从 `flutter_app/` 执行 `flutter run -d ios --dart-define=HELP_SUPPORT_API_BASE_URL=...`，确认 iOS 模拟器联调与热重载可用；提交前或需要完整链路验证时，再执行 `./tool/build_ios_simulator.sh` 确认构建、安装、启动到模拟器完整跑通；不要运行 `flutter analyze` 或 `flutter analysis`。
- OpenAPI、数据库文档、数据库迁移或生成文件变更后，要用实际源头复核：`route.php`、控制器、`information_schema`、`SHOW CREATE TABLE`、`php webman b8:migrate:status`、`php webman b8:migrate --dry-run` 或生成器输出。
- 如果某项验证无法执行，要在最终回复里说明原因和剩余风险。

## Git 规范
- Commit 使用中文 Conventional Commits，例如：`feat: 增加短信宝网关支持`、`docs: 更新项目协作规范`。
- 提交前执行 `git diff --check`。
- 如果工作区存在无关改动，只提交本次任务文件，并在回复中说明已保持隔离。
