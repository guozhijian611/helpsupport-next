<template>
  <sa-search-bar
    ref="searchBarRef"
    v-model="formData"
    label-width="100px"
    :showExpand="false"
    @reset="handleReset"
    @search="handleSearch"
  >
    <template #default>
      <ElFormItem label="角色编码" prop="code">
        <ElInput v-model="formData.code" placeholder="请输入角色编码" clearable />
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
</script>
