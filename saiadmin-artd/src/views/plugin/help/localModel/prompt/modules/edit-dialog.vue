<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增本地模型提示词' : '编辑本地模型提示词'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="关联模型" prop="model_id">
            <HelpRelationSelect
              v-model="formData.model_id"
              relation="localModelCatalog"
              placeholder="请选择关联模型"
              include-zero
              zero-label="#0 通用提示词"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="聊天模式" prop="chat_mode">
            <HelpChatModeSelect v-model="formData.chat_mode" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="语言" prop="locale">
            <el-input v-model="formData.locale" placeholder="请输入语言" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="提示词标题" prop="title">
            <el-input v-model="formData.title" placeholder="请输入提示词标题" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="系统提示词" prop="system_prompt">
            <sa-editor v-model="formData.system_prompt" height="400px" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="默认开场白" prop="first_message">
            <el-input v-model="formData.first_message" placeholder="请输入默认开场白" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="安全边界提示" prop="safety_prompt">
            <sa-editor v-model="formData.safety_prompt" height="400px" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="状态" prop="status">
            <sa-radio v-model="formData.status" dict="data_status" />
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
  import api from '../../../api/localModel/prompt'
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import HelpRelationSelect from '../../../components/HelpRelationSelect.vue'
  import HelpChatModeSelect from '../../../components/HelpChatModeSelect.vue'

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

  /**
   * 弹窗显示状态双向绑定
   */
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  /**
   * 表单验证规则
   */
  const rules = reactive<FormRules>({
    chat_mode: [{ required: true, message: '聊天模式必需选择', trigger: 'change' }],
    locale: [{ required: true, message: '语言必需填写', trigger: 'blur' }],
    title: [{ required: true, message: '提示词标题必需填写', trigger: 'blur' }],
    first_message: [{ required: true, message: '默认开场白必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态 1启用 2禁用必需填写', trigger: 'blur' }]
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    model_id: null,
    chat_mode: '',
    locale: 'en-US',
    title: '',
    system_prompt: '',
    first_message: '',
    safety_prompt: '',
    status: 1
  }

  /**
   * 表单数据
   */
  const formData = reactive({ ...initialFormData })

  /**
   * 监听弹窗打开，初始化表单数据
   */
  watch(
    () => props.modelValue,
    (newVal) => {
      if (newVal) {
        initPage()
      }
    }
  )

  /**
   * 初始化页面数据
   */
  const initPage = async () => {
    // 先重置为初始值
    Object.assign(formData, initialFormData)
    // 如果有数据，则填充数据
    if (props.data) {
      await nextTick()
      initForm()
    }
  }

  /**
   * 初始化表单数据
   */
  const initForm = () => {
    if (props.data) {
      for (const key in formData) {
        if (props.data[key] != null && props.data[key] != undefined) {
          ;(formData as any)[key] = props.data[key]
        }
      }
    }
  }

  /**
   * 关闭弹窗并重置表单
   */
  const handleClose = () => {
    visible.value = false
    formRef.value?.resetFields()
  }

  /**
   * 提交表单
   */
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
