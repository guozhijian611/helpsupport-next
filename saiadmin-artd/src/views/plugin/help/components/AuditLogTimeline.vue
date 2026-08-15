<template>
  <ElTimeline v-if="logs.length > 0">
    <ElTimelineItem v-for="log in logs" :key="log.id" :timestamp="log.create_time" placement="top">
      <div class="audit-log-title">
        {{ actionText(log.action) }}：{{ statusText(log.before_status) }} ->
        {{ statusText(log.after_status) }}
      </div>
      <div class="audit-log-meta">
        来源：{{ operatorTypeText(log.operator_type) }} · 操作人：{{ log.operator_id || '系统' }}
      </div>
      <div v-if="log.reason" class="audit-log-reason">{{ log.reason }}</div>
    </ElTimelineItem>
  </ElTimeline>
  <ElEmpty v-else description="暂无审核日志" :image-size="72" />
</template>

<script setup lang="ts">
  interface AuditLog {
    id: number
    action: string
    before_status: string | null
    after_status: string
    reason?: string
    operator_id?: number | null
    operator_type?: string
    metadata?: Record<string, any>
    create_time?: string
  }

  defineProps<{
    logs: AuditLog[]
  }>()

  const actionText = (action: string) => {
    const map: Record<string, string> = {
      audit: '审核',
      handle: '处理',
      ai_retry: '重新AI审核'
    }
    return map[action] || action
  }

  const statusText = (status: string | null | undefined) => {
    if (status === null || status === undefined || status === '') {
      return '无'
    }
    return String(status)
  }

  const operatorTypeText = (type: string | undefined) => {
    return (
      ({ system: '系统', ai: 'AI', doctor: '医生', admin: '管理员' } as Record<string, string>)[
        type || ''
      ] || '系统'
    )
  }
</script>

<style scoped>
  .audit-log-title {
    font-weight: 600;
    color: var(--el-text-color-primary);
  }

  .audit-log-meta,
  .audit-log-reason {
    margin-top: 4px;
    color: var(--art-gray-600);
    line-height: 1.5;
    word-break: break-word;
  }
</style>
