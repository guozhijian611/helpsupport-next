# 个人中心开发对照表

## 范围说明

- Flutter 个人中心主页面：`flutter_app/lib/features/me/presentation/me_screen.dart`
- Flutter 设置页面：`flutter_app/lib/features/me/presentation/settings_screen.dart`
- HelpSupport 个人中心后端接口：
  - `server/plugin/help/app/api/controller/MeController.php`
  - `server/plugin/help/app/api/controller/PushController.php`
  - `server/plugin/help/app/api/controller/HomeController.php`

当前结论是：后端 `me` 相关接口已经具备较完整的基础能力，但 Flutter 端目前仍存在大量静态数据、假入口、本地偏好未走服务端、保存后状态不刷新的问题。本文用于梳理当前页面元素与后端接口的真实对接情况，作为后续开发依据。

## 主页面对照

| 页面区块 | 当前前端实现 | 已有接口/数据源 | 结论 |
| --- | --- | --- | --- |
| 头像/昵称/年龄/性别 | 直接读取 `authController` 中的 `session.member/profile`，并带有默认兜底值 `316868`、`26` | 登录/刷新返回的 session；`GET /app/help/me/profile` | 部分接通。展示能出，但不是独立拉取资料，资料保存后也不会自动刷新页面数据 |
| 设置按钮 | 已跳转 `/me/settings` | 无需后端 | 已接通 |
| 三张摘要卡：月计划/重点触发/康复目标 | 全是静态文案 | `GET /app/help/home/summary`、`GET /app/help/me/recovery-goals`、`GET /app/help/me/triggers` | 未接通。这三张卡都可以改成真实数据驱动 |
| 荣誉卡：等级/积分/进度 | 全是静态 UI | `GET /app/help/me/points`、`GET /app/help/me/badges`；session 中也有 `member.points_balance` | 部分接通。积分能拿到，徽章能拿到，但“等级名称/升级阈值”当前没有看到直接接口 |
| 权益条：专属回忆录/免费线下咨询 | 纯静态，点击 `coming soon` | `GET /app/help/me/memoirs`、`GET /app/help/me/memoir-configs` | 部分接通。回忆录可以对接；“免费线下咨询”目前没看到明确权益接口 |
| 常用功能：我的关注 | 入口存在，点击 `coming soon` | `POST /app/help/community/follow-member`、`POST /app/help/community/follow-tag` | 缺列表接口。现在只有关注/取消，没有“我关注了谁/哪些标签”的读取接口 |
| 常用功能：我的收藏 | 入口存在，点击 `coming soon` | `GET /app/help/material/collections` | 部分接通。如果“收藏”只指内容素材，可以直接接；如果还包含社区帖子收藏，后端还缺列表接口 |
| 常用功能：历史 | 入口存在，点击 `coming soon` | `GET /app/help/material/history` | 可接通。当前更接近“内容浏览历史” |
| 常用功能：隐私 | 已跳转 `/me/settings/privacy` | 当前前端仅存本地偏好 | 前端已开页，后端未接 |
| 常用功能：回忆录 | 入口存在，点击 `coming soon` | `GET /app/help/me/memoirs`、`GET /app/help/me/memoir` | 可接通，但当前没有对应 Flutter 页面/路由 |
| 常用功能：日记 | 入口存在，点击 `coming soon` | `GET /app/help/me/journals`、`POST /app/help/me/journal`、`POST /app/help/me/journal/delete` | 可接通，但当前没有对应 Flutter 页面/路由 |

## 设置页对照

| 设置分组 | 当前前端实现 | 已有接口/能力 | 结论 |
| --- | --- | --- | --- |
| 个人资料设置 | 头像、昵称、性别生日、手机号、康复目标、重点触发、回忆录资料基本都是假值或占位 | `GET/POST /app/help/me/profile`；`GET /app/help/me/recovery-goals`；`GET /app/help/me/triggers` | 部分接通。资料主干可接，目标/触发也有接口；头像上传和手机号绑定还没形成稳定 Flutter 对接链路 |
| 头像上传 | 前端没有图片选择器能力 | `saiuser` 中存在上传/更新资料逻辑，但当前仓库未见显式路由注册 | 不建议直接接现状。更稳妥的是补 Help 自己的显式头像上传接口，或先确认默认插件路由是否可用 |
| 账号安全 | 修改密码、绑定手机号、第三方账号、登录设备、单点登录状态全是静态 | `saiuser` 侧已有 `updatePassword`、登录日志、积分等逻辑；Help 自己没有这组显式接口 | 部分缺口。改密码能力存在，但路由暴露不清晰；绑定账号/设备/SSO 读取接口不足 |
| 隐私设置 | 全部保存到 `SharedPreferences`，不走服务端 | 当前未看到对应 Help 隐私偏好接口 | 后端缺口。如果要多端同步，需要补表和接口 |
| 系统设置 | 语言、主题、字号、缓存，本地实现 | 本地实现即可 | 可保留本地 |
| 通知设置 | 目前也是本地开关，不走服务端 | `GET/POST /app/help/push/preference` | 可完整接通。这是设置页里最适合优先改成真实接口的一块 |
| 权限管理 | 走 `permission_handler` 本地申请系统权限 | 本地权限服务已存在 | 已合理 |
| 关于 | 协议页已接，版本号写死 `1.0.0` | `GET /app/help/common/protocol` 已在其他页面使用 | 部分接通。协议没有问题，版本号仍为静态值 |

## 额外缺口

| 项目 | 现状 | 说明 |
| --- | --- | --- |
| 资料保存后的页面刷新 | 有问题 | `complete_profile_screen.dart` 调用 `saveProfile()` 后直接回 `/home`，没有刷新 `authController`，而“我的”页又依赖 session，所以保存后存在陈旧数据风险 |
| 个人中心独立数据层 | 还没有 | 当前 `features/me` 没有像 `community/plan` 那样的 repository/provider 结构 |
| 日记/回忆录/收藏/历史/消息页面路由 | 还没有 | 当前路由只有 `/me/settings` 和 `/me/settings/:section`，很多入口虽然已有后端接口，但还没有 Flutter 页面承接 |
| 医生认证 | 后端已备好，前端未露出 | `POST /app/help/me/doctor-certification` 已有，但个人中心还没有入口 |
| 站内消息 | 后端已备好，前端未露出 | `GET /app/help/me/messages`、`PUT /app/help/me/message/read` 已有，但个人中心没有入口 |

## 当前判断

1. 后端主干接口不是空白，个人中心更像是 Flutter 端尚未完成接口落地，而不是需要从零设计接口。
2. 最值得优先接通的是三块：主页面摘要、设置页个人资料、设置页通知偏好。
3. “我的关注”“社区帖子收藏”“隐私多端同步”这三块仍有明确后端缺口，需要补接口或重新收敛 UI 范围。
4. 保存资料后不刷新登录态是当前最直接的用户可见问题之一，建议纳入首批修复。
