<template>
  <el-drawer v-model="visible" size="70%" title="评估结果详情" :footer="false">
    <el-descriptions :column="1" label-width="110px" border>
      <el-descriptions-item label="患者ID">{{ formData.member_id }}</el-descriptions-item>
      <el-descriptions-item label="医生ID">{{ formData.doctor_id }}</el-descriptions-item>
      <el-descriptions-item label="任务ID">{{ formData.task_id }}</el-descriptions-item>
      <el-descriptions-item label="量表ID">{{
        formData.assessment_id || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="量表名称">{{ formData.assessment_title }}</el-descriptions-item>
      <el-descriptions-item label="任务标题">{{
        formData.task_title || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="阶段标识">{{
        formData.stage_key || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="题目数">{{ formData.question_count }}</el-descriptions-item>
      <el-descriptions-item label="得分"
        >{{ formData.achieved_score }} / {{ formData.total_score }}</el-descriptions-item
      >
      <el-descriptions-item label="等级">{{
        formData.result_level || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="作答结果">
        <pre>{{ formData.answers || '暂无' }}</pre>
      </el-descriptions-item>
      <el-descriptions-item label="量表快照">
        <pre>{{ formData.assessment_snapshot || '暂无' }}</pre>
      </el-descriptions-item>
      <el-descriptions-item label="评估建议">{{
        formData.suggestions || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="评估时间">{{
        formData.assessed_at || '暂无'
      }}</el-descriptions-item>
    </el-descriptions>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/plan/assessmentResult'

  interface Props {
    modelValue: boolean
    dialogType: string
    data?: Record<string, any>
  }
  interface Emits {
    (e: 'update:modelValue', value: boolean): void
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    dialogType: 'view',
    data: undefined
  })
  const emit = defineEmits<Emits>()
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })
  const formData = reactive({
    id: null,
    member_id: null,
    doctor_id: 0,
    task_id: 0,
    assessment_id: '',
    assessment_title: '',
    task_title: '',
    stage_key: '',
    question_count: 0,
    total_score: 0,
    achieved_score: 0,
    result_level: '',
    answers: '',
    assessment_snapshot: '',
    suggestions: '',
    assessed_at: ''
  })

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (newVal && props.data?.id) {
        Object.assign(formData, await api.read(props.data.id))
      }
    }
  )
</script>

<style scoped>
  pre {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-family: inherit;
  }
</style>
