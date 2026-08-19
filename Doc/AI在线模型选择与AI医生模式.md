# AI 在线模型选择与互动角色

## 目标

- 后台继续使用 SAIAI 的“AI 配置”维护密钥和模型，不把密钥搬到 Help。
- App 互动聊天入口以后台 **互动角色** 为准，不再写死 4 种模式。
- 实时音视频、ASR、TTS 都按角色绑定。
- `temp_save` 仍是后台 AI 配置上的字符串，由 App 按当前选用的文本模型读取。
- 会员提示词、会话、消息仍按 `chat_mode` 隔离；`chat_mode` 写入角色 `code`。

## 三层结构

1. **能力层**：`saiai_config`，类型包括文本（openai / gemini / deepseek / generic）、`realtime`、`asr`、`tts`。
2. **产品层**：`sa_ai_persona` + `sa_ai_persona_prompt`。
3. **用户层**：`sa_member_chat_config.prompt_text`、会话、消息。

## 角色字段

| 字段 | 说明 |
| --- | --- |
| `code` | 角色编码，写入会话 `chat_mode` |
| `is_system` | 内置角色不可删、不可改 code，可停用 |
| `title_i18n` / `description_i18n` / `tags_i18n` | 中英标题、简介、标签 |
| `cover` / `cover_dark` | 浅色 / 深色封面 |
| `allow_online` / `allow_local` / `allow_realtime` / `allow_voice` / `allow_user_prompt` | 能力开关 |
| `speech_runtime` | `online` / `local` / `auto` |
| `online_config_id` | 默认在线文本模型 |
| `realtime_config_id` | 角色绑定的 realtime 配置 |
| `asr_config_id` / `tts_config_id` / `tts_voice` | 在线语音 |
| `local_model_id` / `local_asr_id` / `local_tts_id` | 端侧模型目录。默认各绑定一个系统端侧 ASR/TTS，内存占用最低 |

内置 4 个角色：`doctor` / `companion` / `patient` / `ai_doctor`。`doctor` 默认：在线开、本地关、实时开、用户改提示词关。

语音三条链路必须拆开：

- 文字聊天：ASR → 文本模型 → TTS
- 实时：Omni / realtime
- 本地：系统端侧 ASR/TTS，App 设置可选「优先在线 / 优先本地」；角色 `speech_runtime=auto` 时跟随用户设置

## 语音记录约定

语音消息不新增独立转写列：

- `content`：正文。用户语音 = ASR 文本，助手语音 = 回复文本。
- `content_type=voice`：表示还有音频。
- `ext.transcript`：与 `content` 对齐的转写文本，接口同时返回顶层 `transcript`。
- `ext.media_url`：用户原录音；`ext.audio_url`：助手 TTS。

## 数据设计

在 `saiai_config` 增加：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `temp_save` | `varchar(500)` | 后台临时字符串，供 App 读取 |

在 `sa_member_chat_config` 增加：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `online_config_id` | `int` | 该会员在该角色下最近选择的 SAIAI 配置 ID；`0` 表示使用默认模型 |

会员配置仍以 `member_id + chat_mode` 唯一，因此不同角色的模型选择互不影响。

## 后台模型来源

后台管理员在“AI 管理 / 在线模型”中新增或启用模型，并在同一页填写 `temp_save`。App 只展示同时满足以下条件的配置：

- `status = 1`
- 未软删除
- 平台类型属于 `openai`、`gemini`、`deepseek`、`generic`
- 不展示 `realtime` / `asr` / `tts`，这些能力在互动角色上单独绑定

接口不会返回 `ai_key`、`ai_url`、`options` 等敏感配置。

## API 契约

### 聊天概览

`GET /app/help/chat/overview`

每个 `mode` 返回：

- `chat_mode`：角色编码
- `allow_online` / `allow_local` / `allow_realtime` / `allow_voice` / `allow_user_prompt`
- `speech_runtime`
- `tags`：`{ "zh-CN": [], "en": [] }`
- `robot_profile`：标题、简介、封面
- `online_config_id`、`temp_save`、最近会话

### 实时配置

`GET /app/help/chat/realtime-config?chat_mode=doctor`

按角色 `realtime_config_id` 解析，并可用角色 `tts_voice` 覆盖默认音色。角色未开放实时时返回错误。

### 获取在线文本模型

`GET /app/help/chat/models`

返回示例：

```json
[
  {
    "id": 3,
    "name": "DeepSeek 对话",
    "type": "deepseek",
    "model": "deepseek-chat",
    "is_default": true,
    "temp_save": "后台配置的字符串"
  }
]
```

### 读取聊天配置

`GET /app/help/chat/config?chat_mode=ai_doctor`

配置对象：

```json
{
  "chat_mode": "ai_doctor",
  "prompt_text": "",
  "online_config_id": 3
}
```

### 保存模型选择

`POST /app/help/chat/config`

```json
{
  "chat_mode": "ai_doctor",
  "online_config_id": 3
}
```

`prompt_text` 和 `online_config_id` 支持按字段局部更新，至少传一个。保存非 0 的 `online_config_id` 时，API 会确认该模型存在、已启用且属于在线文本模型。角色关闭用户改提示词时，App 不会再逼填 `prompt_text`。

### 发送在线消息

`POST /app/help/chat/send` 和 `POST /app/help/chat/send/stream` 的解析顺序：

1. 请求显式传入且有效的 `config_id`。
2. 当前会员、当前角色配置中的 `online_config_id`。
3. 角色默认 `online_config_id`，再回落到 SAIAI 默认文本模型。

系统提示词优先读角色预设；仅当角色允许用户改提示词时才拼接会员 `prompt_text`。

## 后台配置入口

- **AI 管理 / 互动角色**：新增、编辑、停用角色；绑定实时 / ASR / TTS / 本地模型；维护系统预设提示词。
- **AI 管理 / 在线模型**：维护可被 App 选用的在线文本模型，以及 realtime / ASR / TTS 配置。
- **AI 管理 / 模型测试**：只做 SAIAI 对话测试，不承担 App 产品角色。
- **HelpSupport / 用户改写提示词、会话、聊天记录**：`chat_mode` 下拉从角色目录动态加载。
- **HelpSupport / 本地模型目录**：`capability` 区分为 `llm` / `asr` / `tts`。

## App 交互

1. 首页按后台启用角色展示卡片，标题、简介、标签、封面来自角色。
2. 点击角色后，按 `allow_local` / `allow_online` 决定是否弹出在线 / 本地选择。
3. 在线流程弹出模型选择器，默认勾选该角色上次选择的模型。
4. 仅当 `allow_user_prompt=1` 且用户尚未填写提示词时，才要求补提示词。
5. 确认后把模型配置 ID 写入 `online_config_id`，再创建会话。
6. 实时通话走 `/chat/realtime-config?chat_mode=`。
7. 本地 AI 模型选择和下载流程保持不变；端侧 ASR/TTS 字段已预留。

## 部署与测试

后端代码发布后，在 `server/` 目录执行：

```bash
php webman b8:migrate --dry-run
php webman b8:migrate
php webman b8:migrate:status
php webman reload
```

测试重点：

1. 后台新增一个非内置角色后，App 首页出现对应卡片。
2. 停用某个角色后，App 不再展示该入口，但历史会话仍可按原 `chat_mode` 打开。
3. 内置角色不能删除，只能停用；code 不可改。
4. 开放实时的角色必须绑定 realtime 配置；App 实时通话使用该配置。
5. 文字聊天语音转写走角色 ASR，播报走角色 TTS，不混用 realtime。
6. 语音记录 `content` 为转写正文，接口同时返回 `transcript` 与 `ext.transcript`。
7. 后台会话页“查看对话”能按时间线展示转写文本。
8. 后台启用至少两个非 `realtime` 文本模型，并禁用一个模型；App 模型选择器只显示已启用文本模型。
9. 不同角色分别选择不同模型，重新进入时仍各自保持选择。
