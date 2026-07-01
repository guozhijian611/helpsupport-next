<template>
  <span>{{ displayText }}</span>
</template>

<script setup lang="ts">
  import { computed, onMounted, ref } from 'vue'
  import type { HelpCrudOption } from './helpCrudTypes'
  import { formatRelationValue, loadRelationOptions } from './relationOptions'
  import type { HelpRelationType } from './relationOptions'

  const props = withDefaults(
    defineProps<{
      relation: HelpRelationType
      value?: string | number | null
      emptyText?: string
    }>(),
    {
      value: null,
      emptyText: '-'
    }
  )

  const options = ref<HelpCrudOption[]>([])
  const displayText = computed(() =>
    formatRelationValue(options.value, props.value, props.emptyText)
  )

  onMounted(async () => {
    options.value = await loadRelationOptions(props.relation)
  })
</script>
