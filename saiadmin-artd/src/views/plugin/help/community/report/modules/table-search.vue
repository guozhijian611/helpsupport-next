<template>
  <SaSearchBar
    ref="searchBarRef"
    v-model="formData"
    label-width="100px"
    :showExpand="false"
    @reset="handleReset"
    @search="handleSearch"
  >
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="举报会员" prop="member_id">
        <ElInput v-model="formData.member_id" placeholder="请输入会员ID" clearable />
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="目标类型" prop="target_type">
        <ElSelect v-model="formData.target_type" placeholder="请选择目标类型" clearable>
          <ElOption label="帖子" :value="1" />
          <ElOption label="评论" :value="2" />
          <ElOption label="用户" :value="3" />
        </ElSelect>
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="目标ID" prop="target_id">
        <ElInput v-model="formData.target_id" placeholder="请输入目标ID" clearable />
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="处理状态" prop="handle_status">
        <ElSelect v-model="formData.handle_status" placeholder="请选择处理状态" clearable>
          <ElOption label="待处理" :value="0" />
          <ElOption label="已处理" :value="1" />
          <ElOption label="已忽略" :value="2" />
        </ElSelect>
      </ElFormItem>
    </ElCol>
  </SaSearchBar>
</template>

<script setup lang="ts">
  interface Props {
    modelValue: Record<string, any>
  }

  interface Emits {
    (e: 'update:modelValue', value: Record<string, any>): void
    (e: 'search', params: Record<string, any>): void
    (e: 'reset'): void
  }

  const props = defineProps<Props>()
  const emit = defineEmits<Emits>()
  const searchBarRef = ref()
  const formData = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
  })

  function handleReset() {
    searchBarRef.value?.ref.resetFields()
    emit('reset')
  }

  function handleSearch() {
    emit('search', formData.value)
  }

  const setSpan = (span: number) => ({
    span,
    xs: 24,
    sm: span >= 12 ? span : 12,
    md: span >= 8 ? span : 8,
    lg: span,
    xl: span
  })
</script>
