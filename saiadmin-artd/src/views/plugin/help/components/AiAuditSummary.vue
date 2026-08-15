<template>
  <div v-if="audit" class="ai-audit" :class="{ compact }">
    <div class="ai-audit-tags">
      <ElTag :type="taskType" size="small">{{ taskText }}</ElTag>
      <ElTag v-if="audit.decision" :type="decisionType" size="small">
        {{ decisionText }}
      </ElTag>
      <ElTag v-if="audit.risk_level" :type="riskType" size="small">
        {{ riskText }}
      </ElTag>
      <span v-if="audit.confidence" class="confidence">
        {{ Math.round(Number(audit.confidence) * 100) }}%
      </span>
    </div>
    <div v-if="!compact && audit.reason" class="ai-audit-line">结论：{{ audit.reason }}</div>
    <div v-if="!compact && audit.categories?.length" class="ai-audit-line">
      分类：{{ audit.categories.join('、') }}
    </div>
    <div v-if="!compact && audit.matched_segments?.length" class="ai-audit-line">
      风险片段：{{ audit.matched_segments.join('；') }}
    </div>
    <div v-if="!compact && audit.error_message" class="ai-audit-error">
      异常：{{ audit.error_message }}
    </div>
    <div v-if="!compact" class="ai-audit-meta">
      {{ audit.model_name || '模型待调用' }} · 尝试 {{ audit.attempt_count || 0 }} 次
      <template v-if="audit.latency_ms"> · {{ audit.latency_ms }} ms</template>
    </div>
  </div>
  <span v-else class="empty-text">暂无AI审核记录</span>
</template>

<script setup lang="ts">
  const props = withDefaults(
    defineProps<{
      audit?: Record<string, any> | null
      compact?: boolean
    }>(),
    { audit: null, compact: false }
  )

  const taskText = computed(() => {
    const map: Record<number, string> = {
      0: '排队中',
      1: '审核中',
      2: '已完成',
      3: '失败',
      4: '已失效'
    }
    return map[Number(props.audit?.task_status)] || '未知'
  })
  const taskType = computed(() => {
    const map: Record<number, 'primary' | 'success' | 'warning' | 'danger' | 'info'> = {
      0: 'info',
      1: 'primary',
      2: 'success',
      3: 'danger',
      4: 'info'
    }
    return map[Number(props.audit?.task_status)] || 'info'
  })
  const decisionText = computed(() => {
    const map: Record<string, string> = { pass: '建议通过', review: '建议复核', reject: '建议拒绝' }
    return map[String(props.audit?.decision || '')] || ''
  })
  const decisionType = computed(() => {
    const map: Record<string, 'success' | 'warning' | 'danger' | 'info'> = {
      pass: 'success',
      review: 'warning',
      reject: 'danger'
    }
    return map[String(props.audit?.decision || '')] || 'info'
  })
  const riskText = computed(() => {
    const map: Record<string, string> = { low: '低风险', medium: '中风险', high: '高风险' }
    return map[String(props.audit?.risk_level || '')] || ''
  })
  const riskType = computed(() => {
    const map: Record<string, 'success' | 'warning' | 'danger' | 'info'> = {
      low: 'success',
      medium: 'warning',
      high: 'danger'
    }
    return map[String(props.audit?.risk_level || '')] || 'info'
  })
</script>

<style scoped>
  .ai-audit {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .ai-audit.compact {
    gap: 0;
  }

  .ai-audit-tags {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 5px;
  }

  .confidence,
  .ai-audit-meta,
  .empty-text {
    color: var(--el-text-color-secondary);
    font-size: 12px;
  }

  .ai-audit-line,
  .ai-audit-error {
    line-height: 1.55;
    word-break: break-word;
  }

  .ai-audit-error {
    color: var(--el-color-danger);
  }
</style>
