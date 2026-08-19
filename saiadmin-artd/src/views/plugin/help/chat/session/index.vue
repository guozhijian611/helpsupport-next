<template>
  <div class="chat-session-page">
    <div class="session-pane">
      <HelpCrudPage
        title="聊天会话"
        :api="api"
        permission-prefix="help:chat:session"
        :fields="fields"
        :actions="actions"
      />
    </div>
    <ElDrawer v-model="threadVisible" title="会话记录" size="560px">
      <div v-if="currentSession" class="thread-meta">
        #{{ currentSession.id }} · {{ currentSession.session_name }} ·
        {{ helpChatModeLabel(currentSession.chat_mode) }}
      </div>
      <ElScrollbar height="calc(100vh - 140px)">
        <div v-for="item in records" :key="item.id" class="thread-item" :class="item.role">
          <div class="thread-role">{{ item.role === 'user' ? '用户' : '助手' }}</div>
          <div v-if="item.content_type === 'voice'" class="thread-voice">语音</div>
          <div class="thread-content">{{ item.transcript || item.content }}</div>
          <div class="thread-time">{{ item.message_time }}</div>
        </div>
        <ElEmpty v-if="records.length === 0" description="暂无消息" />
      </ElScrollbar>
    </ElDrawer>
  </div>
</template>

<script setup lang="ts">
  import HelpCrudPage from '../../components/HelpCrudPage.vue'
  import type { HelpCrudAction, HelpCrudField } from '../../components/helpCrudTypes'
  import api from '../../api/chat/session'
  import recordApi from '../../api/chat/record'
  import { helpChatModeLabel, helpChatModeOptions, loadHelpChatModeOptions } from '../../components/chatModeOptions'

  defineOptions({ name: 'HelpChatSession' })

  onMounted(() => {
    void loadHelpChatModeOptions()
  })

  const threadVisible = ref(false)
  const currentSession = ref<Record<string, any> | null>(null)
  const records = ref<any[]>([])

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
    { prop: 'member_id', label: '会员ID', type: 'number', search: true, form: true, required: true, width: 100 },
    {
      prop: 'chat_mode',
      label: '会话模式',
      search: true,
      form: true,
      required: true,
      options: helpChatModeOptions,
      width: 120
    },
    { prop: 'session_name', label: '会话名称', search: true, form: true, required: true, minWidth: 180 },
    { prop: 'last_message', label: '最后消息', type: 'textarea', form: true, rows: 3, minWidth: 220 },
    { prop: 'last_message_time', label: '最后消息时间', type: 'datetime', form: true, width: 170 },
    { prop: 'is_pinned', label: '置顶', form: true, default: 2, options: yesNoOptions, width: 90 },
    { prop: 'status', label: '状态', search: true, form: true, required: true, default: 1, options: statusOptions, width: 100 }
  ]

  const openThread = async (row: Record<string, any>) => {
    currentSession.value = row
    threadVisible.value = true
    const result = await recordApi.list({
      session_id: row.id,
      page: 1,
      limit: 100,
      orderField: 'message_time',
      orderType: 'asc'
    })
    records.value = (result as any)?.data || []
  }

  const actions: HelpCrudAction[] = [
    {
      label: '查看对话',
      method: 'thread',
      type: 'primary',
      onClick: openThread
    }
  ]
</script>

<style scoped>
  .thread-meta {
    margin-bottom: 12px;
    color: var(--el-text-color-secondary);
  }
  .thread-item {
    margin-bottom: 12px;
    padding: 12px;
    border-radius: 12px;
    background: var(--el-fill-color-light);
  }
  .thread-item.assistant {
    background: var(--el-color-primary-light-9);
  }
  .thread-role,
  .thread-time,
  .thread-voice {
    font-size: 12px;
    color: var(--el-text-color-secondary);
  }
  .thread-content {
    margin: 6px 0;
    white-space: pre-wrap;
    line-height: 1.6;
  }
</style>
