<template>
  <sa-search-bar
    ref="searchBarRef"
    v-model="formData"
    label-width="90px"
    :showExpand="false"
    @reset="handleReset"
    @search="handleSearch"
    @expand="handleExpand"
  >
    <el-col v-bind="setSpan(6)">
      <el-form-item label="计划" prop="plan_id">
        <HelpRelationSelect
          v-model="formData.plan_id"
          relation="treatmentPlan"
          placeholder="请选择计划"
        />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="患者" prop="member_id">
        <HelpRelationSelect
          v-model="formData.member_id"
          relation="member"
          placeholder="请选择患者"
        />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="阶段标识" prop="stage_key">
        <el-input v-model="formData.stage_key" placeholder="请输入阶段标识" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="阶段名称" prop="stage_name">
        <el-input v-model="formData.stage_name" placeholder="请输入阶段名称" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="状态" prop="status">
        <el-select v-model="formData.status" placeholder="请选择状态" clearable>
          <el-option label="待开始" :value="0" />
          <el-option label="进行中" :value="1" />
          <el-option label="已完成" :value="2" />
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
  const isExpanded = ref<boolean>(false)
  const searchBarRef = ref()
  const formData = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
  })

  function handleReset() {
    searchBarRef.value?.ref.resetFields()
    emit('reset')
  }

  async function handleSearch() {
    emit('search', formData.value)
  }

  function handleExpand(expanded: boolean) {
    isExpanded.value = expanded
  }

  const setSpan = (span: number) => {
    return {
      span,
      xs: 24,
      sm: span >= 12 ? span : 12,
      md: span >= 8 ? span : 8,
      lg: span,
      xl: span
    }
  }
</script>
