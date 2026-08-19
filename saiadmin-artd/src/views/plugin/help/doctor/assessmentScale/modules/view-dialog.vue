<template>
  <el-drawer v-model="visible" title="评估量表详情" size="840px" :footer="false">
    <div v-loading="loading">
      <ScalePreview
        :title="formData.title"
        :description="formData.description"
        :stage="formData.stage"
        :status="formData.status"
        :total-score="formData.total_score"
        :doctor-id="formData.doctor_id"
        :questions="formData.questions"
        :scoring-rule="formData.scoring_rule"
        :remark="formData.remark"
        :published-at="formData.published_at"
      />
    </div>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/doctor/assessmentScale'
  import ScalePreview from './scale-preview.vue'
  import {
    normalizeQuestions,
    normalizeRules,
    type ScaleQuestion,
    type ScaleScoreRule
  } from './scaleHelpers'

  interface Props {
    modelValue: boolean
    data?: Record<string, any>
  }
  interface Emits {
    (e: 'update:modelValue', value: boolean): void
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    data: undefined
  })
  const emit = defineEmits<Emits>()
  const loading = ref(false)
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const formData = reactive({
    title: '',
    description: '',
    stage: '',
    status: 'draft',
    total_score: 0,
    doctor_id: 0,
    questions: [] as ScaleQuestion[],
    scoring_rule: [] as ScaleScoreRule[],
    remark: '',
    published_at: ''
  })

  watch(
    () => props.modelValue,
    async (open) => {
      if (!open) {
        return
      }
      loading.value = true
      try {
        const detail =
          props.data?.id !== undefined ? await api.read(props.data.id) : props.data || {}
        formData.title = String(detail.title || '')
        formData.description = String(detail.description || '')
        formData.stage = String(detail.stage || '')
        formData.status = String(detail.status || 'draft')
        formData.total_score = Number(detail.total_score || 0)
        formData.doctor_id = Number(detail.doctor_id || 0)
        formData.questions = normalizeQuestions(detail.questions)
        formData.scoring_rule = normalizeRules(detail.scoring_rule)
        formData.remark = String(detail.remark || '')
        formData.published_at = String(detail.published_at || '')
      } finally {
        loading.value = false
      }
    }
  )
</script>
