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
      <el-form-item label="会员" prop="member_id">
        <HelpRelationSelect
          v-model="formData.member_id"
          relation="member"
          placeholder="请选择会员"
        />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="内容" prop="content">
        <el-input v-model="formData.content" placeholder="请输入帖子内容" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="审核状态" prop="audit_status">
        <el-select v-model="formData.audit_status" placeholder="请选择审核状态" clearable>
          <el-option label="待审核" :value="0" />
          <el-option label="已通过" :value="1" />
          <el-option label="已拒绝" :value="2" />
          <el-option label="AI标记" :value="3" />
        </el-select>
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="状态" prop="status">
        <el-select v-model="formData.status" placeholder="请选择状态" clearable>
          <el-option label="正常" :value="1" />
          <el-option label="隐藏" :value="2" />
          <el-option label="封禁" :value="3" />
        </el-select>
      </el-form-item>
    </el-col>
  </sa-search-bar>
</template>

<script setup lang="ts">
  import HelpRelationSelect from '../../../components/HelpRelationSelect.vue'

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
