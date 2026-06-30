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
- `flutter_app/`：Flutter 客户端，Flutter 相关命令默认在此目录执行；Flutter 运行、联调、安装和测试命令默认由用户在本机启动，Codex 只提供准确命令、设备选择建议和失败排查，不主动执行 `./run_app.sh`、`flutter run`、`./tool/build_ios_simulator.sh` 等会启动设备或模拟器的命令；只有用户明确要求 Codex 代为启动时，才优先连接 iOS 真机并使用 `flutter run -d <device id>` 获取热重载，提交前或需要补充模拟器链路验证时再使用 iOS 模拟器；允许在真机 `flutter run` 挂载期间并行执行 `./tool/build_ios_simulator.sh` 做模拟器验证，但模拟器链路不得清理或覆盖 `build/ios/iphoneos`、`build/ios/Debug-iphoneos` 等真机产物；热重启后如出现代码、路由、资源、生成缓存或启动状态异常，应停止当前运行会话并重新完整构建，不允许用兼容方法、旧分支、fallback、别名或临时适配绕过；完整构建、安装和启动验证使用 `./tool/build_ios_simulator.sh`。
- `packages/`：本仓库维护的扩展包或插件源码，修改后需确认是否通过 `server/vendor` 软链或 Composer 安装进入运行时。
- `.codex/skills/`：本项目沉淀的开发技能和参考手册；涉及对应技术时优先读取相关 `SKILL.md`。
- `Doc/`、`OpenAPI/`、`Database/`：项目文档、接口文档和数据库资料，更新时以实际路由、控制器、数据库结构、安装 SQL 或 Phinx 迁移为准。

## Flutter 用户端视觉规范
- 用户端视觉基准以当前已完成页面为准，参考 `flutter_app/lib/features/auth/presentation/auth_page_frame.dart`、`flutter_app/lib/features/me/presentation/me_screen.dart`、`flutter_app/lib/features/me/presentation/settings_screen.dart`；不要把 Flutter 默认绿色或当前 `ColorScheme.fromSeed` 生成的绿色系当作用户端品牌主色。
- 用户端主强调色使用珊瑚橙体系：主色 `#FF9585`，浅色近邻可用 `#FF8D7F`，深色模式高亮使用 `#FFB4A8`；主按钮、选中态、关键图标、进度强调和品牌识别统一围绕这组颜色，不再引入绿色作为 CTA 主色。
- 引导页与登录页头部渐变沿用 `#FF9585 -> #FCB08E`；页面背景、输入框与浅色容器延续 `#F3F5FA`、`#F4F5F9`、`#F7F7FA` 和白色的暖灰体系；分隔线和弱边框使用 `#ECE7E4`、`#E4E7EC`；主文案优先使用 `#303236` / `#343437`，次级文案使用 `#96999F`、`#A5A9B0`、`#7D828A`。
- 功能辅助色只用于局部信息分层，不替代品牌主色：数据/目标可用蓝色 `#5A81DA`，提醒/任务可用橙色 `#FFAE4D`，隐私或社区辅助可用灰青 `#A4C3CC`，标签点缀可用紫色 `#986FF5`；新增页面优先复用这些既有辅助色，不要无约束扩散新的主色系统。
- 暗黑模式必须与浅色模式同时设计，并至少支持 `跟随系统 / 浅色 / 深色` 三档；深色态继续保留珊瑚橙品牌识别，背景、卡片、分隔和开关轨道优先从暗色 `ColorScheme` 推导，再叠加暖色强调，避免直接搬运浅色硬编码导致对比度不足或眩光。
- 字体大小必须支持现有 `小 / 标准 / 大` 三档缩放，也就是 `0.92 / 1.0 / 1.08`；新增页面和自定义组件要确保在 `MediaQuery.textScaler` 放大后不出现标题截断、按钮溢出、表单压缩或固定高度文字错位。
- 多语言必须默认支持现有 `简体中文 / English` 双语切换；标题、按钮、提示语、空状态、错误文案、设置项和弹窗文案都不能写死单语字符串，新增页面要接入 `AppLocalizations` 和现有语言控制器。
- 新增 Flutter 页面如果依赖 `Theme.of(context).colorScheme`，必须先把颜色映射回上述暖灰底加珊瑚橙强调的体系，再落地到界面；后续如统一重构全局主题，也要以这套用户端现状色板为准，而不是回到默认绿色方案。

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
- Flutter 客户端文件变更后，默认由用户启动运行联调或测试；Codex 应给出建议命令，例如在项目根目录执行 `./run_app.sh`，或在 `flutter_app/` 目录先执行 `flutter devices` 确认 iOS 真机设备 ID 后再执行 `flutter run -d <device id>`，但不得主动启动这些命令，除非用户明确要求 Codex 代为运行；API 基础地址写在 `flutter_app/lib/core/api/api_client.dart` 的 `ApiClient.apiBaseUrl` 常量里，不通过环境变量或 `--dart-define` 传入；如果用户需要补充平板/刘海屏等模拟器适配验证、或需要完整构建安装链路，再提示用户使用 iOS 模拟器或执行 `./tool/build_ios_simulator.sh`；用户明确要求 Codex 代跑时，允许真机 `flutter run` 与 `./tool/build_ios_simulator.sh` 并行运行，但模拟器脚本和相关清理动作不得影响真机构建产物与调试会话；如果热重启后出现代码问题、状态不一致、资源未更新、生成代码未生效或启动链路异常，直接停止会话并重新构建安装，不为了绕过问题新增兼容方法、旧分支、fallback、别名或临时适配；需要完整构建、安装、启动链路验证时再执行 `./tool/build_ios_simulator.sh`，并可按需通过 `IOS_SIMULATOR_NAME`、`IOS_SIMULATOR_UDID` 指定目标。
- Flutter 客户端变更不使用 `flutter analyze` 或所谓 `flutter analysis` 作为默认验证；如果 `flutter run` 或模拟器脚本失败，记录失败阶段和原因，不改用 analyze 代替运行验证。

## 验证要求
- 后端 PHP 文件变更后，至少执行相关 `php -l`；路由或插件变更需结合 `php webman route:list`、相关命令帮助或运行时页面验证。SaiCode 生成 CRUD 后，如果依赖 Webman 插件默认路由，需用前端 API 中的 `/app/<插件名>/admin/...` 实际访问或运行时页面确认；如果改用显式路由，则必须在 `route:list` 中核对。
- 管理端或移动端变更后，优先执行项目已有的类型检查、lint 或最小可行验证命令。
- Flutter 客户端变更后的运行验证默认由用户启动：Codex 在最终回复中给出 `./run_app.sh`、`flutter devices`、`flutter run -d <iOS 真机 device id>` 或 `./tool/build_ios_simulator.sh` 等具体命令，并说明本轮未由 Codex 启动；只有用户明确要求 Codex 代为运行时，才执行真机或模拟器运行验证；如果热重启后暴露代码或运行状态问题，以重新构建安装为准，不通过兼容逻辑掩盖；不要运行 `flutter analyze` 或 `flutter analysis`。
- OpenAPI、数据库文档、数据库迁移或生成文件变更后，要用实际源头复核：`route.php`、控制器、`information_schema`、`SHOW CREATE TABLE`、`php webman b8:migrate:status`、`php webman b8:migrate --dry-run` 或生成器输出。
- 如果某项验证无法执行，要在最终回复里说明原因和剩余风险。

## Git 规范
- Commit 使用中文 Conventional Commits，例如：`feat: 增加短信宝网关支持`、`docs: 更新项目协作规范`。
- 提交前执行 `git diff --check`。
- 如果工作区存在无关改动，只提交本次任务文件，并在回复中说明已保持隔离。
