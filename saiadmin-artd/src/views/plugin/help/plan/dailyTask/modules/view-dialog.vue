<template>
  <el-drawer v-model="visible" size="70%" title="每日任务详情" :footer="false">
    <el-descriptions :column="1" label-width="110px" border>
      <el-descriptions-item label="患者ID">{{ formData.member_id }}</el-descriptions-item>
      <el-descriptions-item label="计划ID">{{ formData.plan_id }}</el-descriptions-item>
      <el-descriptions-item label="阶段ID">{{ formData.stage_id }}</el-descriptions-item>
      <el-descriptions-item label="任务日期">{{ formData.task_date }}</el-descriptions-item>
      <el-descriptions-item label="时间">
        {{ formData.start_time || '未设置' }} 至 {{ formData.end_time || '未设置' }}
      </el-descriptions-item>
      <el-descriptions-item label="任务标题">{{ formData.title }}</el-descriptions-item>
      <el-descriptions-item label="任务描述">{{
        formData.description || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="任务类型">{{
        taskTypeText(formData.task_type)
      }}</el-descriptions-item>
      <el-descriptions-item label="来源">{{ sourceText(formData.source) }}</el-descriptions-item>
      <el-descriptions-item label="来源ID">{{ formData.source_id || '暂无' }}</el-descriptions-item>
      <el-descriptions-item label="提醒规则">
        <pre>{{ formData.reminders || '暂无' }}</pre>
      </el-descriptions-item>
      <el-descriptions-item label="附件列表">
        <pre>{{ formData.attachments || '暂无' }}</pre>
      </el-descriptions-item>
      <el-descriptions-item label="奖励积分">{{ formData.points_reward }}</el-descriptions-item>
      <el-descriptions-item label="完成时间">{{
        formData.completed_time || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="完成备注">{{
        formData.completion_note || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{
        taskStatusText(formData.status)
      }}</el-descriptions-item>
      <el-descriptions-item label="备注">{{ formData.remark || '暂无' }}</el-descriptions-item>
    </el-descriptions>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/plan/dailyTask'

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
    plan_id: 0,
    stage_id: 0,
    task_date: '',
    start_time: '',
    end_time: '',
    title: '',
    description: '',
    task_type: '',
    source: '',
    source_id: '',
    reminders: '',
    attachments: '',
    points_reward: null,
    completed_time: '',
    completion_note: '',
    status: null,
    remark: ''
  })

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (newVal && props.data?.id) {
        Object.assign(formData, await api.read(props.data.id))
      }
    }
  )

  const taskTypeText = (value: string) => {
    const map: Record<string, string> = {
      daily: '日常',
      assessment: '评估',
      material: '素材',
      checkin: '打卡'
    }
    return map[value] || value || '未知'
  }

  const sourceText = (value: string) => {
    const map: Record<string, string> = {
      chat: '聊天',
      timeline: '时间线',
      manual: '人工',
      template: '模板'
    }
    return map[value] || value || '未知'
  }

  const taskStatusText = (value: number | null) => {
    const map: Record<number, string> = {
      0: '待办',
      1: '完成',
      2: '跳过',
      3: '延期'
    }
    return map[Number(value)] || '未知'
  }
</script>

<style scoped>
  pre {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-family: inherit;
  }
</style>
