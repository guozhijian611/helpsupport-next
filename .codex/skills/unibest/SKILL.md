---
name: unibest
description: unibest / create-unibest uni-app 开发指南。用于创建、维护、排错或升级基于 unibest 的 uni-app 项目，涉及 Vue3、TypeScript、Vite、UnoCSS、wot-ui-v2、uni-helper 插件、tabbar 策略、请求封装、Pinia、i18n、HBuilderX/App 打包、OpenAPI 代码生成或 create-unibest CLI 开发时使用。
---

# unibest 开发技能

## 使用场景

当用户要处理以下任务时使用本技能：

- 创建或初始化 `unibest` / `create-unibest` 项目。
- 调整 `pages.config.ts`、`manifest.config.ts`、`vite.config.ts`、`uno.config.ts`、`src/tabbar`、`src/router`、`src/http`、`src/store`、`src/locale`、`App.ku.vue`。
- 排查 H5、小程序、App、HBuilderX、微信开发者工具、支付宝/钉钉小程序运行构建问题。
- 选择或替换 UI 库，尤其是 `wot-ui-v2`、`wot-ui`、`uv-ui`、`uview-plus`、`sard-uniapp`、`uni-ui`。
- 生成接口代码、配置 OpenAPI、处理 `vue-query`、`uni.request`、上传、多后端地址。
- 参与 `create-unibest` CLI 开发或新增 Feature。

本地参考文档在 `references/official-docs/docs`，本地 base 模板源码在 `references/base-template`，main 分支源码在 `references/main-source`。官方站点是 https://unibest.tech/ ，代码仓库是 https://github.com/feige996/unibest ，文档仓库是 https://github.com/unibest-tech/unibest-docs 。

## 深度参考

这份 `SKILL.md` 只放核心规则。遇到具体开发任务时，按需读取：

- `references/source-map.md`：源码目录职责、关键配置文件、运行链路、生成文件。
- `references/workflows.md`：新增页面、接口、OpenAPI 自动生成、tabbar、登录、UI 库、App 打包等任务流程和代码模板。
- `references/troubleshooting.md`：按错误文本和症状定位原因与修复动作。

## 项目定位

unibest 是 uni-app + Vue3 + TypeScript + Vite + UnoCSS 的多端模板。它内置约定式路由、layout、请求封装、请求拦截、登录拦截、Pinia 持久化、i18n、自定义 tabbar、SVG/图标方案、UI 库接入和 OpenAPI 接口生成。

`unibest` 主仓库采用 Monorepo：

```text
unibest/
├── packages/cli/   # create-unibest CLI 源码
├── src/            # 模板源码
└── ...
```

分支语义：

- `main`：CLI 开发分支，包含 `packages/cli/` 和模板源码。
- `base`：用户创建项目时克隆的纯净模板。

注意：`references/base-template` 是官方 `base` 模板浅克隆，当前用于查看用户项目结构。若要改 `create-unibest` CLI，优先查看 `references/main-source/packages/cli/`。

## 创建项目

优先使用 CLI 创建项目：

```bash
pnpm create unibest my-project -t base
cd my-project
pnpm install
pnpm dev
```

常用参数：

```bash
# 创建时选择功能
pnpm create unibest my-project --i18n --login --lime-echart --ucharts

# 创建后追加功能
pnpm create unibest add i18n login lime-echart ucharts

# 指定 UI 和平台
pnpm create unibest my-project -u wot-ui-v2 -p h5,mp-weixin
```

前置环境以当前文档为准：Node 推荐 `>=20`，pnpm 推荐 `>=9`；旧 README 可能仍写 `node>=18`、`pnpm>=8`，排错时优先按最新快速开始和 FAQ 处理，特别是微信开发者工具升级后的编译问题可直接升级到 Node 22+。

## 运行与发布

开发：

```bash
pnpm dev           # H5，通常等价 dev:h5
pnpm dev:h5        # H5，默认 localhost:9000
pnpm dev:mp-weixin # 微信小程序，导入 dist/dev/mp-weixin
pnpm dev:app       # App，导入 dist/dev/app 到 HBuilderX
```

发布：

```bash
pnpm build:h5        # 输出 dist/build/h5
pnpm build:mp-weixin # 输出 dist/build/mp-weixin
pnpm build:app       # 输出 dist/build/app，后续用 HBuilderX 打包
```

App 打包注意：

- 必须配置 `VITE_UNI_APPID`。
- `manifest.config.ts` 中 `app-plus.distribute.android.minSdkVersion` 建议至少 21。
- `@dcloudio/uni-app` SDK 版本要和 HBuilderX 匹配，不匹配时优先用 `pnpm uvm` / `npx @dcloudio/uvm@latest` 升级。
- 如果不是部署在站点根目录，H5 需要改 `manifest.config.ts` 的 `h5.router.base`。

## 路由与配置

核心规则：不要手改生成物。

- 不要直接编辑生成后的 `pages.json`；全局配置写 `pages.config.ts`，页面配置写页面内 `definePage`。
- 新代码优先用 `definePage`，不要继续依赖旧的 route-block 习惯；旧项目遇到 route-block 可以兼容处理。
- 不要直接编辑生成后的 `manifest.json`；修改写进 `manifest.config.ts`。
- 首页只保留一个 `type: 'home'` 或等效首页声明，多个首页会按字母顺序取第一个。
- 分包、页面过滤、排除组件目录在 `vite.config.ts` 的 `UniPages` 配置里处理，分包目录不能是 `src/pages` 的子目录。
- layout 放在 `src/layouts`；默认 layout 是 `default`，页面里通过 `layout` 指定。
- 全局根组件放在 `src/App.ku.vue`，可通过 `KuRootView` / root 插件挂载全局内容。

典型页面配置：

```ts
definePage({
  type: 'home',
  layout: 'default',
  style: {
    navigationBarTitleText: '首页',
  },
})
```

## Tabbar 策略

当前核心策略：

| 值 | 策略 | 导航方式 | 缓存 | 使用建议 |
| --- | --- | --- | --- | --- |
| `0` | `NO_TABBAR` | 普通页面导航 | 视页面而定 | 活动页、单入口项目 |
| `1` | `NATIVE_TABBAR` | `uni.switchTab` | 有 | 稳定优先、原生体验优先 |
| `2` | `CUSTOM_TABBAR` | `uni.switchTab` | 有 | 需要自定义样式、图标、徽标 |

操作规则：

- 改 tabbar 配置后必须重新运行项目，让 `pages.json` 重新生成。
- 自定义 tabbar 支持 `uiLib`、`unocss`、`iconfont`、`image` 等图标类型；动态 UnoCSS 图标必须在代码注释、静态 class 或 `uno.config.ts` safelist 中显式出现。
- 切换 tabbar 页优先用 `uni.switchTab`，不要直接改 `tabbarStore.curIdx`。
- 从登录、分享、H5 直达等路径恢复时，用 `tabbarStore.syncCurIdxByCurrentPageAsync()` 同步状态。

## UI 库选择

新项目优先选 `wot-ui-v2`，即 `@wot-ui/ui`。CLI 会自动注入：

- `@wot-ui/ui`
- easycom `^wd-(.*)`
- `@wot-ui/ui/global` 类型声明
- `wot-ui-resolver.ts`
- `vite.config.ts` 的 `UniComponents` resolver

其他选择：

- `wot-ui` / `wot-design-uni`：旧项目兼容。
- `uv-ui`、`uview-plus`、`uview-pro`、`uni-ui`、`sard-uniapp`：按平台兼容性和组件数量选择。
- 不推荐在 uni-app 中使用 `vant-ui`，因为它是 Web UI 库，依赖 `window` / `document` 等 Web API。

如果 `wot-ui` 的 toast / message-box 不生效，确认 layout 中包含：

```vue
<template>
  <view>
    <slot />
    <wd-toast />
    <wd-message-box />
  </view>
</template>
```

## 样式、图标与 SVG

样式：

- 优先使用 UnoCSS；它比原生 TailwindCSS 更适合小程序和 rpx 场景。
- 小程序侧关注 `presetApplet` / `presetRemRpx` / `@uni-helper/unocss-preset-uni` 这类小程序适配。
- 传统 CSS 和 UnoCSS 可以混用。设计稿按 750 宽转换时，普通 CSS 写 `rpx`；UnoCSS 可直接写 `w-100rpx`。
- App 端如果遇到颜色函数兼容问题，检查 UnoCSS legacy 兼容预设。

图标：

- UI 库 Icons：用组件 props 控制尺寸和颜色；注意部分 UI 库的 `color` prop 优先级高于 class。
- UnoCSS Icons：安装 `@iconify-json/<collection>`，使用 `i-carbon-user-avatar` 这类连字符写法，避免 `i-carbon:user-avatar` 在小程序端出问题。
- iconfont：优先用 Font class，不用 Unicode；小程序/App 下将字体资源转 base64，并把 `//at.alicdn.com` 改成 `https://at.alicdn.com`。

SVG：

- 小程序和 App 不支持直接写 SVG 标签。
- 跨端优先使用 `<image src="...">`，来源可以是 `/static`、相对导入后的 URL 或线上地址。
- `vite-svg-loader`、`vite-plugin-svg-icons` 这类方案只适合 H5 或 H5 专属分支。

## 请求与接口生成

请求方案：

- 简单项目：使用 `src/http/http.ts`，接口集中放 `src/api/*.ts`。
- 复杂缓存/状态需求：可使用 alova。
- OpenAPI + vue-query：生成到 `src/service/app`，配合 `src/utils/request.ts`。

基础规则：

- `VITE_SERVER_BASEURL` 配在 env 文件中；微信开发版/体验版/正式版可用 `VITE_SERVER_BASEURL__WEIXIN_DEVELOP`、`VITE_SERVER_BASEURL__WEIXIN_TRIAL`、`VITE_SERVER_BASEURL__WEIXIN_RELEASE`。
- 请求拦截器只给相对 URL 拼接 baseURL；以 `http` 开头的 URL 不应被拼接。
- 多后端地址用 `proxyMap` 或等效映射。
- header 通常作为最后一个参数传入。
- 上传接口可单独配置 `VITE_UPLOAD_BASEURL`。

OpenAPI 生成：

```bash
pnpm openapi
```

配置入口通常是 `openapi-ts-request.config.ts`：

```ts
export default [
  {
    schemaPath: 'http://petstore.swagger.io/v2/swagger.json',
    serversPath: './src/service/app',
    requestLibPath: `import request from '@/utils/request';\n import { CustomRequestOptions } from '@/interceptors/request';`,
    requestOptionsType: 'CustomRequestOptions',
    isGenReactQuery: true,
    reactQueryMode: 'vue',
    isGenJavaScript: false,
  },
]
```

## 状态与登录

Pinia 已接入 `pinia-plugin-persistedstate`，并使用 `uni.getStorageSync` / `uni.setStorageSync` 做跨端存储。定义 store 时第三个参数可开 `persist: true`。

不要把所有状态都放进 Pinia。页面局部状态优先使用 `ref`、`reactive` 或页面附近的 composable。

App 白屏常见原因是顶层直接执行 `useXxxStore()`，此时 Pinia 还未初始化。把 store 获取放进函数、生命周期或已初始化后的逻辑里。

登录策略在 `src/router/config.ts` 附近：

- `DEFAULT_NO_NEED_LOGIN`：默认可进入，`EXCLUDE_PAGE_LIST` 是需要登录的黑名单。
- `DEFAULT_NEED_LOGIN`：默认需要登录，`EXCLUDE_PAGE_LIST` 是不需要登录的白名单。

小程序静默登录仍应由后端签发 token。OpenID 只是身份标识，不是接口认证凭证；涉及用户数据、支付、订单、个人信息时必须用 token 做鉴权。

## i18n

创建 i18n 模板：

```bash
pnpm create unibest my-project -t i18n
```

使用规则：

- Vue 模板中用 `{{ $t('app.name') }}`。
- TS 或非 Vue 场景从 `@/locale/index` 引入 `translate`。
- 带参数的多语言在非 H5 端可能有兼容问题，优先用 `formatI18n(translate('key'), data)`。
- 小程序导航栏标题在 `onShow` 中执行 `uni.setNavigationBarTitle({ title: t('i18n.title') })`。
- v3.4.0 以后 tabbar 和 navbar 多语言切换由框架处理。
- App iOS 模拟器语言切换直接生效；Android 真机可能自动重启后生效。

## 环境变量

Vite 环境变量只暴露 `VITE_` 前缀变量。优先使用 `import.meta.env`，不要用 `process.env`。

常见文件：

```text
.env
.env.local
.env.development
.env.production
.env.[mode]
.env.[mode].local
```

注意 `.env.local` 不能覆盖 `.env.[mode]`。uni 平台变量可通过 `define: { __UNI_PLATFORM__: JSON.stringify(UNI_PLATFORM) }` 暴露，项目内通常已有 `isH5`、`isApp`、`isMp` 等 helper。

## App 与 HBuilderX

- `base` 模板现在可以覆盖多数 App 和 uniCloud 场景，`hbx` 模板不再维护，除非用户明确需要旧 hbx 模板。
- iOS 模拟器开发可运行 `pnpm dev:app` 后把 `dist/dev/app` 导入 HBuilderX。
- Android / 鸿蒙热更新更推荐把整个 unibest 项目导入 HBuilderX。
- 在 HBuilderX 里改出的 `manifest.json` 源码视图配置，要同步回 `manifest.config.ts`。
- 原生插件放项目根目录小写 `nativeplugins`；配置后需要自定义基座，标准基座不会包含插件。
- 需要复制原生资源时确认 `VITE_COPY_NATIVE_RES_ENABLE=true`。

## 常见排错

- `pages.json` 或 `manifest.json` 修改后被覆盖：改 `pages.config.ts` / `manifest.config.ts`。
- 首次非 H5 运行提示找不到 `src/manifest.json`：先执行 `pnpm install`。
- 微信开发者工具打开 timeout：通常不是编译失败，配置 `WECHAT_DEVTOOLS_CLI_PATH` 或手动导入 `dist/dev/mp-weixin`，并开启微信开发者工具服务端口。
- 微信小程序 WXSS 编译出现 unexpected `\`：优先升级 Node 到 22+；仍不行可回退微信开发者工具版本或使用模板 lock 文件。
- `pnpm i` 报 `ERR PNPM INVALID WORKSPACE CONFIGURATION packages field missing or empty`：Node 18 + pnpm 9 组合可能触发，优先升级 Node 22，其次 pnpm 10。
- iOS 模拟器报 esbuild host/binary version mismatch：按 FAQ 将 `esbuild` 版本对齐到 `0.20.2`。
- 支付宝小程序运行报错：开发工具勾选“本地开发跳过 ES5 转译”。
- `defineModel` 仅 H5 支持；小程序/App 端不要默认使用。
- Vue Official 可用版本曾建议停在 `v2.2.8`，遇到 `v2.2.10` 报错时先回退。
- `[plugin:uni:mp-using-component] Unexpected token S in JSON`：旧项目可尝试回退 `@uni-helper/vite-plugin-uni-pages@0.2.20`。
- 严格 git 提交检查不想要：可删除或注释 `.husky`。

## 升级策略

升级前先确认当前 unibest 版本、uni-app SDK、HBuilderX、Node、pnpm、lock 文件是否匹配。

常用升级动作：

```bash
pnpm uvm
# 或
npx @dcloudio/uvm@latest
```

升级 `uni-helper` 插件时，对齐文档中给出的版本。旧项目如果迁移到 oxlint，注意文档建议不要贪新：`oxlint@1.0.0`、`unocss@65.4.2` 曾是稳定选择。v3 之后 lint 方案又经历过变化，处理现有项目时以项目 `package.json` 和 lock 文件为准，不要盲目覆盖。

## CLI 开发

参与 `create-unibest` CLI 开发时：

```bash
git clone https://github.com/feige996/unibest.git
cd unibest/packages/cli
pnpm install
pnpm dev
pnpm start -- my-test-project
```

本地模板调试：

```bash
LOCAL_TEMPLATE=true pnpm start -- my-test-project
```

新增 Feature：

1. 在 `packages/cli/features/` 下创建功能目录。
2. 添加 `hooks.js` 和 `package.json`。
3. 在 `packages/cli/src/features/index.ts` 注册。
4. 用 `pnpm start -- my-test-project` 或 `LOCAL_TEMPLATE=true` 测试。

发布 CLI：

```bash
npm login --registry=https://registry.npmjs.org/
npm version patch
pnpm build
npm publish --no-workspaces --registry=https://registry.npmjs.org/
```

## 辅助经验

- uni-app 插件市场中不支持 npm 的插件，放到项目 `uni_modules`，目录名要去掉版本号，按插件规范直接使用组件。
- 给 npm 包打补丁使用 `pnpm patch <package-name>`，修改后 `pnpm patch-commit <patch-dir>`，提交生成的 patch。
- 微信弹窗滚动穿透可用 `uni.setPageStyle({ style: { overflow: 'hidden' } })`，不支持时退回页面固定高度和 `position: fixed`。
- 图片占位可用 `https://via.placeholder.com/400x200.png/3c9cff/fff` 或 `https://picsum.photos/400/200?random=1`。
- 钉钉小程序可在 `package.json` 的 `uni-app.scripts` 中把 `mp-dingtalk` 映射到 `UNI_PLATFORM=mp-alipay` 并定义 `MP-DINGTALK`。
