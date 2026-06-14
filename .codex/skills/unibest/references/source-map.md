# unibest 源码地图

本参考用于在 unibest 项目里快速定位该改哪个文件。优先结合用户项目的实际文件检查，不要只按模板假设。

## 本地源码

- `references/base-template`：官方 `base` 模板浅克隆，当前用于查看用户项目结构。
- `references/main-source`：官方 `main` 分支浅克隆，当前用于查看 `packages/cli` 和 Feature 注入逻辑。
- `references/official-docs/docs`：官方文档源码。

## 顶层配置

- `package.json`：脚本、依赖、引擎、`unibest` feature 状态。模板要求 `node >=20`、`pnpm >=9`，包管理器是 `pnpm@10.10.0`。
- `env/.env`：公共环境变量，包含 `VITE_APP_TITLE`、`VITE_APP_PORT`、`VITE_UNI_APPID`、`VITE_WX_APPID`、`VITE_SERVER_BASEURL`、微信环境专用 baseURL、代理开关、认证模式、App 原生资源复制开关。
- `env/.env.development`、`env/.env.test`、`env/.env.production`：按 Vite mode 叠加读取。非 H5 端 dev 命令也会走 build command，但 mode 仍可为 development。
- `pages.config.ts`：全局页面配置、easycom、自定义组件映射、`tabBar` 引入。不要手改生成后的 `pages.json`。
- `manifest.config.ts`：App、小程序、H5 manifest 配置。不要手改生成后的 `manifest.json`。
- `vite.config.ts`：插件链、自动导入、分包、manifest/pages/layout/root、H5 代理、开发者工具打开、App nativeplugins 复制。
- `uno.config.ts`：UnoCSS presets、icons、本地图标集合、safelist、安全区规则、主题色、字体尺寸。
- `openapi-ts-request.config.ts`：OpenAPI 生成配置。默认生成到 `src/service`，使用 `@/http/vue-query` 适配请求。

## 应用启动链路

`src/main.ts` 创建 app 后按顺序注册：

1. `app.use(store)`：Pinia 和持久化。
2. `app.use(routeInterceptor)`：uni 路由拦截，处理 tabbar 当前项同步。
3. `app.use(requestInterceptor)`：uni.request / uni.uploadFile 拦截，拼 baseURL、query、Authorization。

如果后续注入 i18n，CLI 会在 `import 'virtual:uno.css'` 后追加 `import i18n from './locale/index'`，并在 `app.use(requestInterceptor)` 后追加 `app.use(i18n)`。

## 页面与路由

- `src/pages`：主包页面。`@uni-helper/vite-plugin-uni-pages` 会扫描生成 `pages.json`。
- `src/pages-demo`：模板预留 demo 分包，`vite.config.ts` 的 `UniPages({ subPackages: ['src/pages-demo'] })` 已配置。
- 页面级配置优先使用 `definePage({ ... })`。
- `src/router/interceptor.ts`：拦截 `navigateTo`、`reLaunch`、`redirectTo`、`switchTab`，解析相对路径和 query，同步 tabbar。
- `src/router/permission.ts`：H5 的 vue-router beforeEach，同步 tabbar。
- `src/utils/index.ts`：`currRoute`、`parseUrlToObj`、`getAllPages`、`HOME_PAGE`、`getEnvBaseUrl`、`isDoubleTokenMode` 等公共路由/环境 helper。
- `src/utils/toLoginPage.ts`：跳登录页。注意模板里 `LOGIN_PAGE = '/pages/login/index'` 是 TODO，用户项目可能需要改成实际登录页。

## 请求与 API

- `src/http/http.ts`：简单版 `uni.request` 封装，处理业务 code、401、单/双 token、刷新队列、toast。
- `src/http/interceptor.ts`：全局请求拦截，拼接 query、baseURL、H5 代理前缀、Authorization。
- `src/http/types.ts`：`CustomRequestOptions`、`IResponse`、分页类型，OpenAPI request adapter 也依赖这里。
- `src/http/vue-query.ts`：给 `openapi-ts-request` 用的 request 适配，把 OpenAPI 的 `params` 转为模板请求的 `query`，把 `headers` 转为 `header`。
- `src/http/alova.ts`：alova 示例，支持动态 domain、响应处理、token 刷新钩子。
- `src/api/foo.ts`：手写 API 示例。
- `src/api/login.ts`：登录、刷新 token、用户信息、微信登录示例。
- `src/service/*`：OpenAPI 生成代码示例，真实项目里通常由 `pnpm openapi` 更新。

## 状态与登录

- `src/store/index.ts`：Pinia 入口。
- `src/store/token.ts`：单 token / 双 token 登录态、过期时间、刷新 token、退出登录、微信登录。
- `src/store/user.ts`：用户信息和头像状态，`persist: true`。
- `env/.env` 中 `VITE_AUTH_MODE = 'single' | 'double'` 控制认证模式。
- 双 token 模式要求后端返回 `accessToken`、`accessExpiresIn`、`refreshToken`、`refreshExpiresIn`；单 token 模式要求返回 `token`、`expiresIn`。

## Tabbar

- `src/tabbar/config.ts`：策略和 tabbar item 配置。改这里后要重新运行项目，让 `pages.json` 重生成。
- `src/tabbar/store.ts`：自定义 tabbar 的当前项、角色过滤、badge、路径归一、刷新同步。
- `src/tabbar/index.vue`：自定义 tabbar 渲染和点击跳转逻辑。
- `src/tabbar/TabbarItem.vue`：图标类型渲染。
- `src/App.ku.vue`：通过 `isPageTabbar(currRoute().path)` 决定是否显示 `FgTabbar`，并挂载 `KuRootView`。

## App 与原生资源

- `manifest.config.ts`：App 权限、图标、SDK、Android minSdk、微信/支付宝小程序配置。
- `vite-plugins/copy-native-resources.ts`：App 平台且 `VITE_COPY_NATIVE_RES_ENABLE=true` 时复制根目录 `nativeplugins` 到 dist。
- `vite-plugins/sync-manifest-plugins.ts`：同步 manifest 插件配置。
- 原生插件目录必须叫 `nativeplugins`，全小写。

## create-unibest CLI

在 `references/main-source/packages/cli`：

- `src/commands/create.ts`：创建命令入口，验证项目名，读取 unibest 版本，调用 prompt 和 generate。
- `src/commands/create/prompts.ts`：CLI 参数和交互选项。平台可选 `h5`、`mp-weixin`、`app`、`mp-alipay`、`mp-toutiao`；UI 可选 `none`、`wot-ui-v2`、`wot-ui`、`uview-pro`、`sard-uniapp`、`uv-ui`、`uview-plus`、`tdesign`；Feature 包含 `i18n`、`login`、`lime-echart`、`ucharts`。
- `src/commands/create/generate.ts`：克隆 `base` 分支，注入 Feature，应用 UI 配置。
- `src/commands/add.ts`：向已有项目追加 Feature，支持 `--force`、`--install`，并更新 `package.json.unibest`。
- `src/utils/injector.ts`：Feature 注入工具，替换/创建文件，更新 `pages-demo` 分包。
- `src/utils/uiLibrary.ts`：UI 库依赖、easycom、types、样式、main.ts、Vite resolver 注入。
- `features/*`：Feature 资源、hooks 和 schema。

## 生成文件

这些文件通常不要手改，改源配置后重新生成：

- `pages.json`
- `manifest.json`
- `src/types/auto-import.d.ts`
- `src/types/uni-pages.d.ts`
- `src/types/components.d.ts`
- `src/service/*`，除非项目明确决定不再自动生成。
