<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增每日任务' : '编辑每日任务'"
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
          <el-form-item label="计划" prop="plan_id">
            <HelpRelationSelect
              v-model="formData.plan_id"
              relation="treatmentPlan"
              placeholder="请选择计划"
              include-zero
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="阶段" prop="stage_id">
            <HelpRelationSelect
              v-model="formData.stage_id"
              relation="treatmentStage"
              placeholder="请选择阶段"
              include-zero
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="任务日期" prop="task_date">
            <el-date-picker
              v-model="formData.task_date"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="请选择任务日期"
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="开始时间" prop="start_time">
            <el-time-picker
              v-model="formData.start_time"
              value-format="HH:mm:ss"
              placeholder="请选择开始时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="结束时间" prop="end_time">
            <el-time-picker
              v-model="formData.end_time"
              value-format="HH:mm:ss"
              placeholder="请选择结束时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="任务标题" prop="title">
            <el-input v-model="formData.title" placeholder="请输入任务标题" maxlength="160" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="任务描述" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :rows="4"
              placeholder="请输入任务描述"
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="任务类型" prop="task_type">
            <el-select v-model="formData.task_type" placeholder="请选择任务类型">
              <el-option label="日常" value="daily" />
              <el-option label="评估" value="assessment" />
              <el-option label="素材" value="material" />
              <el-option label="打卡" value="checkin" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="来源" prop="source">
            <el-select v-model="formData.source" placeholder="请选择来源">
              <el-option label="聊天" value="chat" />
              <el-option label="时间线" value="timeline" />
              <el-option label="人工" value="manual" />
              <el-option label="模板" value="template" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="来源ID" prop="source_id">
            <el-input v-model="formData.source_id" placeholder="请输入来源ID" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="提醒规则" prop="reminders">
            <el-input
              v-model="formData.reminders"
              type="textarea"
              :rows="4"
              placeholder="JSON，可为空"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="附件列表" prop="attachments">
            <el-input
              v-model="formData.attachments"
              type="textarea"
              :rows="4"
              placeholder="JSON，可为空"
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="奖励积分" prop="points_reward">
            <el-input-number v-model="formData.points_reward" :min="0" controls-position="right" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="完成时间" prop="completed_time">
            <el-date-picker
              v-model="formData.completed_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择完成时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="状态" prop="status">
            <el-select v-model="formData.status" placeholder="请选择状态">
              <el-option label="待办" :value="0" />
              <el-option label="完成" :value="1" />
              <el-option label="跳过" :value="2" />
              <el-option label="延期" :value="3" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="完成备注" prop="completion_note">
            <el-input
              v-model="formData.completion_note"
              placeholder="请输入完成备注"
              maxlength="500"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="备注" prop="remark">
            <el-input v-model="formData.remark" placeholder="请输入备注" maxlength="255" />
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
  import api from '../../../api/plan/dailyTask'
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
    task_date: [{ required: true, message: '任务日期必须填写', trigger: 'change' }],
    title: [{ required: true, message: '任务标题必须填写', trigger: 'blur' }],
    task_type: [{ required: true, message: '任务类型必须填写', trigger: 'change' }],
    source: [{ required: true, message: '来源必须填写', trigger: 'change' }],
    status: [{ required: true, message: '状态必须填写', trigger: 'change' }]
  })

  const initialFormData = {
    id: null,
    member_id: null,
    plan_id: 0,
    stage_id: 0,
    task_date: '',
    start_time: '',
    end_time: '',
    title: '',
    description: '',
    task_type: 'daily',
    source: 'manual',
    source_id: '',
    reminders: '',
    attachments: '',
    points_reward: 10,
    completed_time: '',
    completion_note: '',
    status: 0,
    remark: ''
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
