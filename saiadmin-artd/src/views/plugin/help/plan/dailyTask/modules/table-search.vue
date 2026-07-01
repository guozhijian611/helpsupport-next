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
      <el-form-item label="患者" prop="member_id">
        <HelpRelationSelect
          v-model="formData.member_id"
          relation="member"
          placeholder="请选择患者"
        />
      </el-form-item>
    </el-col>
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
      <el-form-item label="阶段" prop="stage_id">
        <HelpRelationSelect
          v-model="formData.stage_id"
          relation="treatmentStage"
          placeholder="请选择阶段"
        />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="任务日期" prop="task_date">
        <el-date-picker
          v-model="formData.task_date"
          type="date"
          value-format="YYYY-MM-DD"
          placeholder="请选择任务日期"
          clearable
        />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="标题" prop="title">
        <el-input v-model="formData.title" placeholder="请输入任务标题" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="类型" prop="task_type">
        <el-select v-model="formData.task_type" placeholder="请选择类型" clearable>
          <el-option label="日常" value="daily" />
          <el-option label="评估" value="assessment" />
          <el-option label="素材" value="material" />
          <el-option label="打卡" value="checkin" />
        </el-select>
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="状态" prop="status">
        <el-select v-model="formData.status" placeholder="请选择状态" clearable>
          <el-option label="待办" :value="0" />
          <el-option label="完成" :value="1" />
          <el-option label="跳过" :value="2" />
          <el-option label="延期" :value="3" />
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
