<template>
  <HelpCrudPage
    title="聊天记录"
    :api="api"
    permission-prefix="help:chat:record"
    :fields="fields"
    drawer-size="820px"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/chat/record'
  import { helpChatModeOptions } from '../../components/chatModeOptions'

  defineOptions({ name: 'HelpChatRecord' })

  const chatModeOptions = helpChatModeOptions

  const roleOptions = [
    { label: '用户', value: 'user' },
    { label: '助手', value: 'assistant' },
    { label: '系统', value: 'system' }
  ]

  const contentTypeOptions = [
    { label: '文本', value: 'text' },
    { label: '图片', value: 'image' },
    { label: '文件', value: 'file' },
    { label: '语音', value: 'voice' }
  ]

  const statusOptions = [
    { label: '有效', value: 1, tagType: 'success' as const },
    { label: '无效', value: 2, tagType: 'info' as const }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
    {
      prop: 'session_id',
      label: '会话ID',
      type: 'number',
      search: true,
      form: true,
      required: true,
      width: 100
    },
    {
      prop: 'member_id',
      label: '会员ID',
      type: 'number',
      search: true,
      form: true,
      required: true,
      width: 100
    },
    {
      prop: 'chat_mode',
      label: '会话模式',
      search: true,
      form: true,
      required: true,
      options: chatModeOptions,
      width: 120
    },
    {
      prop: 'role',
      label: '角色',
      search: true,
      form: true,
      required: true,
      options: roleOptions,
      width: 100
    },
    {
      prop: 'content',
      label: '内容',
      type: 'textarea',
      search: true,
      form: true,
      required: true,
      rows: 6,
      minWidth: 260
    },
    {
      prop: 'transcript',
      label: '转写文本',
      type: 'textarea',
      form: false,
      search: false,
      table: true,
      detail: true,
      readonly: true,
      rows: 3,
      minWidth: 220
    },
    {
      prop: 'content_type',
      label: '内容类型',
      form: true,
      required: true,
      default: 'text',
      options: contentTypeOptions,
      width: 110
    },
    { prop: 'token_count', label: 'Token', type: 'number', form: true, default: 0, width: 90 },
    { prop: 'message_time', label: '消息时间', type: 'datetime', form: true, width: 170 },
    { prop: 'ext', label: '扩展信息', type: 'json', form: true, table: false, rows: 4 },
    {
      prop: 'status',
      label: '状态',
      search: true,
      form: true,
      required: true,
      default: 1,
      options: statusOptions,
      width: 100
    }
  ]
</script>
