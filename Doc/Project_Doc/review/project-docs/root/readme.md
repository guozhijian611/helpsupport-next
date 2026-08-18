# HelpSupport — 治疗支持 App

面向医院内小规模部署（≈100 并发），为患者提供日常支持和行为改变辅助的移动应用。

界面语言为英文，面向海外市场。设计风格参考 Keep —— 卡片式、简洁、激励感。

## 📎 相关资源

- 📄 [需求文档（金山文档）](https://www.kdocs.cn/l/cccZanudDrQU)
- 🎨 [Figma 设计图](https://www.figma.com/design/ncw22JvBO55krkHxXMgEFx/%E5%8C%BB%E7%96%97--Copy-?t=8c8aXcTxmoOarGWY-0)
- 📋 [项目需求说明 PRD](./PRD.md)
- 🤖 [AI IDE 项目指南](./AGENTS.md)
- 📖 [unibest 开发手册](https://unibest.tech/base/1-introduction)
- 🛠️ [SaiAdmin 开发手册](https://saithink.top/documents/v6/)

## 📁 项目结构

```
helpsupport/
├── helpsupport-frontend/   # 患者端移动应用
├── saiadmin-artd/          # 管理后台
├── server/                 # 后端 API 服务
├── PRD.md                  # 产品需求说明
├── AGENTS.md               # AI IDE 项目指南
└── readme.md               # 本文件
```

| 子项目                  | 说明                                  | 技术栈                                                         |
| ----------------------- | ------------------------------------- | -------------------------------------------------------------- |
| `helpsupport-frontend/` | 患者端跨平台应用（H5 / 小程序 / APP） | UniApp + Vue 3 + TypeScript + Vite 5 + UnoCSS + wot-design-uni |
| `saiadmin-artd/`        | 医院管理后台                          | Vue 3 + Art Design Pro + Element Plus + Tailwind CSS 4         |
| `server/`               | 后端服务                              | Webman 2.x（PHP 8.1+）+ ThinkORM 3.0 + SaiAdmin 6.x            |

## 🧩 功能模块

| 模块            | 说明                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------- |
| AI 聊天         | 三种模式（心理医生 / 心理陪伴 / 模拟病人），支持文字、语音、视频通话，AI 任务下发，离线模型 |
| 社区            | Keep 风格同伴互助区，帖子 / 评论 / 点赞 / 收藏，匿名机制，AI + 人工审核                     |
| 个人资料        | 患者 & 医生两种角色，医生需资质认证，隐私设置                                               |
| 日记            | 私密记录，仅设备本地存储，日历 / 列表两种视图                                               |
| 治疗计划 & 奖励 | 时间线卡片、日历视图、拖拽编辑、奖励分数等级系统、AI 生成里程碑回忆录视频                   |
| 教育素材        | 文章 / 视频 / 音频 / PDF，离线缓存，进度记忆，私人上传                                      |
| 娱乐内容        | 书籍、电影、音乐推荐                                                                        |
| 医生预约        | 真人医生在线预约，同步日历                                                                  |
| 账号登录        | 手机号 / 邮箱注册，单端在线限制，隐私条款                                                   |

## 🚀 快速开始

### 前端（患者端）

```bash
cd helpsupport-frontend
pnpm install
pnpm dev          # H5 开发
pnpm dev:mp       # 微信小程序
pnpm dev:app      # APP
```

### 管理后台

```bash
cd saiadmin-artd
pnpm install
pnpm dev          # 开发（自动打开浏览器）
```

### 后端服务

```bash
cd server
composer install
php start.php start
```

## 🔒 安全与隐私

- 传输加密：HTTPS / TLS
- 敏感数据加密存储（日记、健康相关字段）
- 日记数据仅设备本地存储，不上传服务器
- 参考 HIPAA / GDPR 规范处理健康数据
