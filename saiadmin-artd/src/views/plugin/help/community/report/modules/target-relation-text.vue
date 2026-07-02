<template>
  <div class="target-relation">
    <ElTag size="small" class="target-type">{{ targetTypeText }}</ElTag>
    <ElTooltip :content="displayText" placement="top" :disabled="!clickable">
      <ElLink
        v-if="clickable"
        type="primary"
        :underline="false"
        class="target-link"
        @click="emit('open', { targetType: Number(targetType), targetId })"
      >
        {{ displayText }}
      </ElLink>
      <span v-else class="target-label">{{ displayText }}</span>
    </ElTooltip>
  </div>
</template>

<script setup lang="ts">
  import type { HelpCrudOption } from '../../../components/helpCrudTypes'
  import {
    formatRelationValue,
    loadRelationOptions,
    type HelpRelationType
  } from '../../../components/relationOptions'

  interface Emits {
    (e: 'open', payload: { targetType: number; targetId: number | string | null }): void
  }

  const props = withDefaults(
    defineProps<{
      targetType?: number | string | null
      targetId?: number | string | null
    }>(),
    {
      targetType: null,
      targetId: null
    }
  )
  const emit = defineEmits<Emits>()
  const options = ref<HelpCrudOption[]>([])

  const targetRelation = computed<HelpRelationType | undefined>(() =>
    relationByTargetType(props.targetType)
  )
  const clickable = computed(() => Boolean(targetRelation.value && props.targetId))
  const displayText = computed(() => {
    if (targetRelation.value) {
      return formatRelationValue(options.value, props.targetId)
    }
    return props.targetId ? `#${props.targetId}` : '-'
  })

  const targetTypeText = computed(() => {
    const map: Record<number, string> = {
      1: '帖子',
      2: '评论',
      3: '用户'
    }
    return map[Number(props.targetType)] || '未知'
  })

  watch(
    targetRelation,
    async (relation) => {
      options.value = relation ? await loadRelationOptions(relation) : []
    },
    { immediate: true }
  )

  function relationByTargetType(
    type: number | string | null | undefined
  ): HelpRelationType | undefined {
    const map: Record<number, HelpRelationType> = {
      1: 'communityPost',
      2: 'communityComment',
      3: 'member'
    }
    return map[Number(type)]
  }
</script>

<style scoped>
  .target-relation {
    display: inline-flex;
    gap: 8px;
    align-items: center;
    max-width: 100%;
    min-width: 0;
  }

  .target-type {
    flex: 0 0 auto;
  }

  .target-label,
  .target-link {
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .target-link {
    max-width: 100%;
  }

  .target-link :deep(.el-link__inner) {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>
