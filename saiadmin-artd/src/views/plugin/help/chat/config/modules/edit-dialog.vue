<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增AI聊天配置' : '编辑AI聊天配置'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="会员" prop="member_id">
            <HelpRelationSelect
              v-model="formData.member_id"
              relation="member"
              placeholder="请选择会员"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="模式" prop="chat_mode">
            <el-select v-model="formData.chat_mode" placeholder="请选择模式" class="w-full">
              <el-option label="医生模式" value="doctor" />
              <el-option label="陪伴模式" value="companion" />
              <el-option label="患者模式" value="patient" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="用户模式描述和前置提示" prop="prompt_text">
            <sa-editor v-model="formData.prompt_text" height="400px" />
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
  import api from '../../../api/chat/config'
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
    member_id: [{ required: true, message: '会员ID必需填写', trigger: 'blur' }],
    chat_mode: [{ required: true, message: '模式必需选择', trigger: 'change' }]
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    member_id: null,
    chat_mode: '',
    prompt_text: ''
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
