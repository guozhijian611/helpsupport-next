<template>
  <el-drawer v-model="visible" size="60%" title="治疗阶段详情" :footer="false">
    <el-descriptions :column="1" label-width="110px" border>
      <el-descriptions-item label="计划">
        <HelpRelationText relation="treatmentPlan" :value="formData.plan_id" />
      </el-descriptions-item>
      <el-descriptions-item label="患者">
        <HelpRelationText relation="member" :value="formData.member_id" />
      </el-descriptions-item>
      <el-descriptions-item label="阶段标识">{{
        formData.stage_key || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="阶段名称">{{ formData.stage_name }}</el-descriptions-item>
      <el-descriptions-item label="日期范围">
        {{ formData.start_date || '未设置' }} 至 {{ formData.end_date || '未设置' }}
      </el-descriptions-item>
      <el-descriptions-item label="阶段目标">{{
        formData.stage_target || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="排序">{{ formData.sort }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{
        stageStatusText(formData.status)
      }}</el-descriptions-item>
      <el-descriptions-item label="备注">{{ formData.remark || '暂无' }}</el-descriptions-item>
    </el-descriptions>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/plan/treatmentStage'
  import HelpRelationText from '../../../components/HelpRelationText.vue'

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
    plan_id: null,
    member_id: null,
    stage_key: '',
    stage_name: '',
    start_date: '',
    end_date: '',
    stage_target: '',
    sort: null,
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

  const stageStatusText = (value: number | null) => {
    const map: Record<number, string> = {
      0: '待开始',
      1: '进行中',
      2: '已完成'
    }
    return map[Number(value)] || '未知'
  }
</script>
