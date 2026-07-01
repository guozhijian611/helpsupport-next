<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增评估结果' : '编辑评估结果'"
    :size="860"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="110px">
      <el-row :gutter="20">
        <el-col :span="8">
          <el-form-item label="患者" prop="member_id">
            <HelpRelationSelect
              v-model="formData.member_id"
              relation="member"
              placeholder="请选择患者"
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="医生" prop="doctor_id">
            <HelpRelationSelect
              v-model="formData.doctor_id"
              relation="doctor"
              placeholder="请选择医生"
              include-zero
              zero-label="#0 未指定医生"
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="关联任务" prop="task_id">
            <HelpRelationSelect
              v-model="formData.task_id"
              relation="dailyTask"
              placeholder="请选择关联任务"
              include-zero
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="量表ID" prop="assessment_id">
            <el-input v-model="formData.assessment_id" placeholder="请输入量表ID" maxlength="64" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="量表名称" prop="assessment_title">
            <el-input
              v-model="formData.assessment_title"
              placeholder="请输入量表名称"
              maxlength="160"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="任务标题" prop="task_title">
            <el-input v-model="formData.task_title" placeholder="请输入任务标题" maxlength="160" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="阶段标识" prop="stage_key">
            <el-input v-model="formData.stage_key" placeholder="请输入阶段标识" maxlength="30" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="题目数" prop="question_count">
            <el-input-number v-model="formData.question_count" :min="0" controls-position="right" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="总分" prop="total_score">
            <el-input-number v-model="formData.total_score" :min="0" controls-position="right" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="实得分" prop="achieved_score">
            <el-input-number v-model="formData.achieved_score" :min="0" controls-position="right" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="等级" prop="result_level">
            <el-input v-model="formData.result_level" placeholder="请输入评估等级" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="评估时间" prop="assessed_at">
            <el-date-picker
              v-model="formData.assessed_at"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择评估时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="作答结果" prop="answers">
            <el-input
              v-model="formData.answers"
              type="textarea"
              :rows="5"
              placeholder="JSON，可为空"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="量表快照" prop="assessment_snapshot">
            <el-input
              v-model="formData.assessment_snapshot"
              type="textarea"
              :rows="5"
              placeholder="JSON，可为空"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="评估建议" prop="suggestions">
            <el-input
              v-model="formData.suggestions"
              type="textarea"
              :rows="4"
              placeholder="请输入评估建议"
            />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="handleSubmit">提交</el-button>
    </template>
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/plan/assessmentResult'
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import HelpRelationSelect from '../../../components/HelpRelationSelect.vue'

  interface Props {
    modelValue: boolean
    dialogType: string
    data?: Record<string, any>
  }
  interface Emits {
    (e: 'update:modelValue', value: boolean): void
    (e: 'success'): void
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    dialogType: 'add',
    data: undefined
  })
  const emit = defineEmits<Emits>()
  const formRef = ref<FormInstance>()
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const rules = reactive<FormRules>({
    member_id: [{ required: true, message: '患者ID必须填写', trigger: 'blur' }],
    assessment_title: [{ required: true, message: '量表名称必须填写', trigger: 'blur' }]
  })

  const initialFormData = {
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
  }
  const formData = reactive({ ...initialFormData })

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (newVal) {
        Object.assign(formData, initialFormData)
        if (props.data) {
          await nextTick()
          for (const key in formData) {
            if (props.data[key] !== null && props.data[key] !== undefined) {
              ;(formData as any)[key] = props.data[key]
            }
          }
        }
      }
    }
  )

  const handleClose = () => {
    visible.value = false
    formRef.value?.resetFields()
  }

  const handleSubmit = async () => {
    if (!formRef.value) return
    try {
      await formRef.value.validate()
      if (props.dialogType === 'add') {
        await api.save(formData)
        ElMessage.success('新增成功')
      } else {
        await api.update(formData)
        ElMessage.success('修改成功')
      }
      emit('success')
      handleClose()
    } catch (error) {
      console.log('表单验证失败:', error)
    }
  }
</script>
