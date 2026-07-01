<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增治疗计划' : '编辑治疗计划'"
    :size="760"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="110px">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="患者" prop="member_id">
            <HelpRelationSelect
              v-model="formData.member_id"
              relation="member"
              placeholder="请选择患者"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
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
        <el-col :span="24">
          <el-form-item label="计划标题" prop="title">
            <el-input v-model="formData.title" placeholder="请输入计划标题" maxlength="160" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="计划说明" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :rows="4"
              placeholder="请输入计划说明"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="开始日期" prop="start_date">
            <el-date-picker
              v-model="formData.start_date"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="请选择开始日期"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="结束日期" prop="end_date">
            <el-date-picker
              v-model="formData.end_date"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="请选择结束日期"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="来源" prop="source_type">
            <el-select v-model="formData.source_type" placeholder="请选择来源">
              <el-option label="人工" value="manual" />
              <el-option label="AI" value="ai" />
              <el-option label="模板" value="template" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="状态" prop="status">
            <el-select v-model="formData.status" placeholder="请选择状态">
              <el-option label="进行中" :value="1" />
              <el-option label="已完成" :value="2" />
              <el-option label="已终止" :value="3" />
            </el-select>
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
  import api from '../../../api/plan/treatmentPlan'
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
    title: [{ required: true, message: '计划标题必须填写', trigger: 'blur' }],
    source_type: [{ required: true, message: '来源必须填写', trigger: 'change' }],
    status: [{ required: true, message: '状态必须填写', trigger: 'change' }]
  })

  const initialFormData = {
    id: null,
    member_id: null,
    doctor_id: 0,
    title: '',
    description: '',
    start_date: '',
    end_date: '',
    source_type: 'manual',
    status: 1,
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
