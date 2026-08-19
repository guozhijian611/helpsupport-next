<template>
  <el-select
    :model-value="modelValue"
    :placeholder="placeholder"
    :clearable="clearable"
    :disabled="disabled"
    class="w-full"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <el-option
      v-for="item in helpChatModeOptions"
      :key="item.value"
      :label="item.label"
      :value="item.value"
    />
  </el-select>
</template>

<script setup lang="ts">
  import { helpChatModeOptions } from './chatModeOptions'

  withDefaults(
    defineProps<{
      modelValue?: string
      placeholder?: string
      clearable?: boolean
      disabled?: boolean
    }>(),
    {
      modelValue: '',
      placeholder: '请选择聊天模式',
      clearable: false,
      disabled: false
    }
  )

  const emit = defineEmits<{
    (e: 'update:modelValue', value: string): void
  }>()
</script>
