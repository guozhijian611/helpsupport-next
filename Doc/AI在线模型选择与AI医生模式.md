# AI 在线模型选择与 AI 医生模式

## 目标

- 后台继续使用 SAIAI 的“AI 配置”维护多个模型，不新增重复的模型管理页面。
- `temp_save` 是后台 AI 配置上的字符串字段，由管理员填写，App 按当前选用的模型读取。
- App 的在线 AI 聊天可以从后台已启用的文本模型中选择模型；四个聊天模式各自记住最近选择的模型 ID。
- 主界面新增普通聊天模式 `ai_doctor`，显示名为“AI 医生”，入口和陪伴、模拟病人一样支持“在线 AI / 本地 AI”选择。
- 原有 `doctor` 仍是“AI 心理医生”，保留实时音视频能力；在线文字聊天同样可以选择文本模型。

## 数据设计

在 `saiai_config` 增加：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `temp_save` | `varchar(500)` | 后台临时字符串，供 App 读取 |

在 `sa_member_chat_config` 增加：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `online_config_id` | `int` | 该会员在该聊天模式下最近选择的 SAIAI 配置 ID；`0` 表示使用默认模型 |

会员配置仍以 `member_id + chat_mode` 唯一，因此四个模式的模型选择互不影响。

## 后台模型来源

后台管理员在“SAIAI / AI 配置”中新增或启用模型，并在同一页填写 `temp_save`。App 只展示同时满足以下条件的配置：

- `status = 1`
- 未软删除
- 平台类型属于 `openai`、`gemini`、`deepseek`、`generic`
- 不展示 `realtime`，实时音视频继续使用独立实时模型配置

接口不会返回 `ai_key`、`ai_url`、`options` 等敏感配置。

## API 契约

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

聊天概览 `/app/help/chat/overview` 的每个 `mode` 同时返回：

- `online_config_id`：会员最近选择的模型
- `temp_save`：该模型（或默认模型）在后台 AI 配置中的字符串

### 保存模型选择

`POST /app/help/chat/config`

```json
{
  "chat_mode": "ai_doctor",
  "online_config_id": 3
}
```

`prompt_text` 和 `online_config_id` 支持按字段局部更新，至少传一个。保存非 0 的 `online_config_id` 时，API 会确认该模型存在、已启用且属于在线文本模型。

### 发送在线消息

`POST /app/help/chat/send` 和 `POST /app/help/chat/send/stream` 的解析顺序：

1. 请求显式传入且有效的 `config_id`。
2. 当前会员、当前聊天模式配置中的 `online_config_id`。
3. SAIAI 默认文本模型。

## 后台配置入口

- **SAIAI / AI 配置**：维护可被 App 选用的在线文本模型，并填写 `temp_save`。openai、gemini、deepseek、generic 且已启用的配置会出现在 App 模型选择器中。
- **HelpSupport / 机器人形象、本地模型提示词、会员聊天配置、会话、聊天记录**：聊天模式下拉包含 `doctor`、`companion`、`patient`、`ai_doctor`（显示名为“AI医生”）。
- **HelpSupport / 会员聊天配置**：可查看和编辑 `online_config_id`。

## App 交互

1. 用户在主界面点击任一聊天模式。
2. 普通模式先选“在线 AI / 本地 AI”；AI 心理医生直接进入在线流程。
3. 在线流程弹出模型选择器，默认勾选该聊天模式上次选择的模型。
4. 确认后把模型配置 ID 写入 `online_config_id`，再创建会话。App 同时读取该模型的后台 `temp_save`。
5. 在线聊天页右上角提供模型按钮，可随时切换当前聊天模式后续消息使用的模型。
6. 本地 AI 模型选择和下载流程保持不变。

## 部署与测试

后端代码发布后，在 `server/` 目录执行：

```bash
php webman b8:migrate --dry-run
php webman b8:migrate
php webman b8:migrate:status
php webman reload
```

测试重点：

1. 后台 AI 配置中填写 `temp_save`，App 模型列表和聊天概览能读到同一字符串。
2. 后台启用至少两个非 `realtime` 模型，并禁用一个模型。
3. App 四个模式的在线入口只显示两个已启用文本模型，不显示实时或禁用模型。
4. 在不同模式分别选择不同模型，重新进入时仍各自保持选择。
5. 发送消息后检查 `sa_member_chat_record.ext`，其中 `config_id`、`ai_model` 与选择一致。
6. 在聊天页切换模型后发送下一条消息，确认新消息使用新模型。
7. 新增“AI 医生”可以分别进入在线聊天和本地模型流程。
