<template>
  <el-dialog
    v-model="visible"
    :title="dialogType === 'add' ? '新增邮件模板' : '编辑邮件模板'"
    width="820px"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-form-item label="模板名称" prop="name">
        <el-input v-model="formData.name" placeholder="请输入模板名称" />
      </el-form-item>
      <el-form-item label="模板标识" prop="code">
        <el-input v-model="formData.code" placeholder="如 register_code" />
      </el-form-item>
      <el-form-item label="邮件主题" prop="subject">
        <el-input v-model="formData.subject" placeholder="请输入邮件主题" />
      </el-form-item>
      <el-form-item label="模板内容" prop="content">
        <sa-editor v-model="formData.content" height="360px" />
      </el-form-item>
      <el-form-item label="变量说明" prop="variables">
        <el-input
          v-model="formData.variables"
          type="textarea"
          :rows="3"
          placeholder="如：code=验证码，name=用户昵称。模板内容中使用 {code} 占位"
        />
      </el-form-item>
      <el-form-item label="排序" prop="sort">
        <el-input-number v-model="formData.sort" :min="0" />
      </el-form-item>
      <el-form-item label="启用" prop="status">
        <sa-radio v-model="formData.status" dict="data_status" />
      </el-form-item>
      <el-form-item label="备注" prop="remark">
        <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="handleSubmit">提交</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
  import api from '@/api/system/emailTemplate'
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'

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
    name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
    code: [{ required: true, message: '请输入模板标识', trigger: 'blur' }],
    subject: [{ required: true, message: '请输入邮件主题', trigger: 'blur' }],
    content: [{ required: true, message: '请输入模板内容', trigger: 'blur' }]
  })

  const initialFormData = {
    id: null,
    name: '',
    code: '',
    subject: '',
    content: '',
    variables: '',
    sort: 100,
    status: 1,
    remark: ''
  }

  const formData = reactive({ ...initialFormData })

  watch(
    () => props.modelValue,
    (newVal) => {
      if (newVal) {
        initPage()
      }
    }
  )

  const initPage = async () => {
    Object.assign(formData, initialFormData)
    if (props.data) {
      await nextTick()
      initForm()
    }
  }

  const initForm = () => {
    if (props.data) {
      for (const key in formData) {
        if (props.data[key] != null && props.data[key] != undefined) {
          ;(formData as any)[key] = props.data[key]
        }
      }
    }
  }

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
