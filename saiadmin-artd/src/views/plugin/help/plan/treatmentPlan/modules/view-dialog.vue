<template>
  <el-drawer v-model="visible" size="60%" title="治疗计划详情" :footer="false">
    <el-descriptions :column="1" label-width="110px" border>
      <el-descriptions-item label="患者">
        <HelpRelationText relation="member" :value="formData.member_id" />
      </el-descriptions-item>
      <el-descriptions-item label="医生">
        <HelpRelationText relation="doctor" :value="formData.doctor_id" />
      </el-descriptions-item>
      <el-descriptions-item label="计划标题">{{ formData.title }}</el-descriptions-item>
      <el-descriptions-item label="计划说明">{{
        formData.description || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="日期范围">
        {{ formData.start_date || '未设置' }} 至 {{ formData.end_date || '未设置' }}
      </el-descriptions-item>
      <el-descriptions-item label="来源">{{
        sourceTypeText(formData.source_type)
      }}</el-descriptions-item>
      <el-descriptions-item label="状态">{{
        planStatusText(formData.status)
      }}</el-descriptions-item>
      <el-descriptions-item label="备注">{{ formData.remark || '暂无' }}</el-descriptions-item>
      <el-descriptions-item label="创建时间">{{
        formData.create_time || '暂无'
      }}</el-descriptions-item>
      <el-descriptions-item label="更新时间">{{
        formData.update_time || '暂无'
      }}</el-descriptions-item>
    </el-descriptions>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/plan/treatmentPlan'
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
    member_id: null,
    doctor_id: 0,
    title: '',
    description: '',
    start_date: '',
    end_date: '',
    source_type: '',
    status: null,
    remark: '',
    create_time: '',
    update_time: ''
  })

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (newVal && props.data?.id) {
        Object.assign(formData, await api.read(props.data.id))
      }
    }
  )

  const sourceTypeText = (value: string) => {
    const map: Record<string, string> = {
      manual: '人工',
      ai: 'AI',
      template: '模板'
    }
    return map[value] || value || '未知'
  }

  const planStatusText = (value: number | null) => {
    const map: Record<number, string> = {
      1: '进行中',
      2: '已完成',
      3: '已终止'
    }
    return map[Number(value)] || '未知'
  }
</script>
