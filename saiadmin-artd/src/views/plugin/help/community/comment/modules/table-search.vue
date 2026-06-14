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
      <ElFormItem label="帖子ID" prop="post_id">
        <ElInput v-model="formData.post_id" placeholder="请输入帖子ID" clearable />
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="会员ID" prop="member_id">
        <ElInput v-model="formData.member_id" placeholder="请输入会员ID" clearable />
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="内容" prop="content">
        <ElInput v-model="formData.content" placeholder="请输入评论内容" clearable />
      </ElFormItem>
    </ElCol>
    <ElCol v-bind="setSpan(6)">
      <ElFormItem label="审核状态" prop="audit_status">
        <ElSelect v-model="formData.audit_status" placeholder="请选择审核状态" clearable>
          <ElOption label="待审核" :value="0" />
          <ElOption label="已通过" :value="1" />
          <ElOption label="已拒绝" :value="2" />
          <ElOption label="AI预审" :value="3" />
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
