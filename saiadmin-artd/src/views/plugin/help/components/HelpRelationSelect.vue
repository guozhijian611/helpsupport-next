<template>
  <ElSelect
    v-model="model"
    :clearable="clearable"
    filterable
    :placeholder="placeholder"
    :disabled="disabled"
    class="w-full"
  >
    <ElOption
      v-for="option in mergedOptions"
      :key="String(option.value)"
      :label="option.label"
      :value="option.value"
    />
  </ElSelect>
</template>

<script setup lang="ts">
  import { computed, onMounted, ref } from 'vue'
  import type { HelpCrudOption } from './helpCrudTypes'
  import { loadRelationOptions } from './relationOptions'
  import type { HelpRelationType } from './relationOptions'

  const model = defineModel<string | number | null | undefined>()
  const props = withDefaults(
    defineProps<{
      relation: HelpRelationType
      placeholder?: string
      clearable?: boolean
      disabled?: boolean
      includeZero?: boolean
      zeroLabel?: string
    }>(),
    {
      placeholder: '请选择',
      clearable: true,
      disabled: false,
      includeZero: false,
      zeroLabel: '#0 未关联'
    }
  )

  const options = ref<HelpCrudOption[]>([])
  const mergedOptions = computed(() =>
    props.includeZero ? [{ label: props.zeroLabel, value: 0 }, ...options.value] : options.value
  )

  onMounted(async () => {
    options.value = await loadRelationOptions(props.relation)
  })
</script>
