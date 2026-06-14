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
    <el-col v-bind="setSpan(6)">
      <el-form-item label="聊天模式" prop="chat_mode">
        <el-select v-model="formData.chat_mode" placeholder="请选择聊天模式" clearable class="w-full">
          <el-option label="医生模式" value="doctor" />
          <el-option label="陪伴模式" value="companion" />
          <el-option label="患者模式" value="patient" />
        </el-select>
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="语言" prop="locale">
        <el-input v-model="formData.locale" placeholder="请输入语言" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="提示词标题" prop="title">
        <el-input v-model="formData.title" placeholder="请输入提示词标题" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="状态" prop="status">
        <sa-select v-model="formData.status" dict="data_status" placeholder="请选择状态" />
      </el-form-item>
    </el-col>
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

  // 栅格占据的列数
  const setSpan = (span: number) => {
    return {
      span: span,
      xs: 24, // 手机：满宽显示
      sm: span >= 12 ? span : 12, // 平板：大于等于12保持，否则用半宽
      md: span >= 8 ? span : 8, // 中等屏幕：大于等于8保持，否则用三分之一宽
      lg: span,
      xl: span
    }
  }
</script>
