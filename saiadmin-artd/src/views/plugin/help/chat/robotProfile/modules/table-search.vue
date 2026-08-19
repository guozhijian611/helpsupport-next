<template>
  <sa-search-bar
    ref="searchBarRef"
    v-model="formData"
    label-width="100px"
    :showExpand="false"
    @reset="handleReset"
    @search="handleSearch"
    @expand="handleExpand"
  >
    <template #default>
      <ElFormItem label="聊天模式" prop="chat_mode">
        <HelpChatModeSelect v-model="formData.chat_mode" clearable />
      </ElFormItem>
      <ElFormItem label="运行模式" prop="runtime_mode">
        <ElSelect
          v-model="formData.runtime_mode"
          placeholder="请选择运行模式"
          clearable
          class="w-full"
        >
          <ElOption label="在线模式" value="online" />
          <ElOption label="本地模式" value="local" />
        </ElSelect>
      </ElFormItem>
      <ElFormItem label="显示名称" prop="display_name">
        <ElInput v-model="formData.display_name" placeholder="请输入显示名称" clearable />
      </ElFormItem>
      <ElFormItem label="状态" prop="status">
        <ElSelect v-model="formData.status" placeholder="请选择状态" clearable class="w-full">
          <ElOption label="启用" :value="1" />
          <ElOption label="禁用" :value="2" />
        </ElSelect>
      </ElFormItem>
    </template>
  </sa-search-bar>
</template>

<script setup lang="ts">
  import HelpChatModeSelect from '../../../components/HelpChatModeSelect.vue'

  interface Props {
    modelValue: Record<string, any>
  }

  interface Emits {
    (e: 'update:modelValue', value: Record<string, any>): void
    (e: 'search', value: Record<string, any>): void
    (e: 'reset'): void
  }

  const props = defineProps<Props>()
  const emit = defineEmits<Emits>()
  const isExpanded = ref<boolean>(false)
  const searchBarRef = ref()

  const formData = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
  })

  const handleSearch = () => emit('search', formData.value)
  const handleReset = () => {
    searchBarRef.value?.ref.resetFields()
    emit('reset')
  }
  const handleExpand = (expanded: boolean) => {
    isExpanded.value = expanded
  }
</script>
