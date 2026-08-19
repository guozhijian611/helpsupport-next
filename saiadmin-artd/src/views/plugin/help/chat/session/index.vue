<template>
  <HelpCrudPage
    title="聊天会话"
    :api="api"
    permission-prefix="help:chat:session"
    :fields="fields"
  />
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/chat/session'
  import { helpChatModeOptions } from '../../components/chatModeOptions'

  defineOptions({ name: 'HelpChatSession' })

  const chatModeOptions = helpChatModeOptions

  const yesNoOptions = [
    { label: '是', value: 1, tagType: 'success' as const },
    { label: '否', value: 2, tagType: 'info' as const }
  ]

  const statusOptions = [
    { label: '有效', value: 1, tagType: 'success' as const },
    { label: '无效', value: 2, tagType: 'info' as const }
  ]

  const fields: HelpCrudField[] = [
    { prop: 'id', label: 'ID', table: true, detail: true, width: 80, readonly: true },
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
      prop: 'session_name',
      label: '会话名称',
      search: true,
      form: true,
      required: true,
      minWidth: 180
    },
    {
      prop: 'last_message',
      label: '最后消息',
      type: 'textarea',
      form: true,
      rows: 3,
      minWidth: 220
    },
    { prop: 'last_message_time', label: '最后消息时间', type: 'datetime', form: true, width: 170 },
    { prop: 'is_pinned', label: '置顶', form: true, default: 2, options: yesNoOptions, width: 90 },
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
