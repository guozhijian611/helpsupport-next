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
      <ElFormItem label="会员ID" prop="member_id">
        <ElInput v-model="formData.member_id" placeholder="请输入会员ID" clearable />
      </ElFormItem>
      <ElFormItem label="模式" prop="chat_mode">
        <ElSelect v-model="formData.chat_mode" placeholder="请选择模式" clearable class="w-full">
          <ElOption label="医生模式" value="doctor" />
          <ElOption label="陪伴模式" value="companion" />
          <ElOption label="患者模式" value="patient" />
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
    (e: 'search', params: Record<string, any>): void
    (e: 'reset'): void
  }
  const props = defineProps<Props>()
  const emit = defineEmits<Emits>()

  // 展开/收起
  const isExpanded = ref<boolean>(false)

  // 表单数据双向绑定
  const searchBarRef = ref()
  const formData = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
  })

  // 重置
  function handleReset() {
    searchBarRef.value?.ref.resetFields()
    emit('reset')
  }

  // 搜索
  async function handleSearch() {
    emit('search', formData.value)
  }

  // 展开/收起
  function handleExpand(expanded: boolean) {
    isExpanded.value = expanded
  }

</script>
