<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增推送设备' : '编辑推送设备'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="设备标识" prop="device_id">
            <el-input v-model="formData.device_id" placeholder="请输入设备标识" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="平台 ios/android" prop="platform">
            <el-input v-model="formData.platform" placeholder="请输入平台 ios/android" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="APNs Token" prop="apns_token">
            <el-input v-model="formData.apns_token" placeholder="请输入APNs Token" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="App版本" prop="app_version">
            <el-input v-model="formData.app_version" placeholder="请输入App版本" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="当前语言" prop="locale">
            <el-input v-model="formData.locale" placeholder="请输入当前语言" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="当前时区" prop="timezone">
            <el-input v-model="formData.timezone" placeholder="请输入当前时区" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="是否有效 1是 2否" prop="is_active">
            <sa-radio v-model="formData.is_active" dict="yes_or_no" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="最近活跃时间" prop="last_active_time">
            <el-date-picker
              v-model="formData.last_active_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择最近活跃时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="退出或踢下线时间" prop="logout_time">
            <el-date-picker
              v-model="formData.logout_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择退出或踢下线时间"
              clearable
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
  import commonApi from '@/api/common'
  import api from '../../../api/push/device'
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
  const optionData = reactive({
    treeData: <any[]>[],
  })

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
    device_id: [{ required: true, message: '设备标识必需填写', trigger: 'blur' }],
    platform: [{ required: true, message: '平台 ios/android必需填写', trigger: 'blur' }],
    fcm_token: [{ required: true, message: 'FCM Token必需填写', trigger: 'blur' }],
    apns_token: [{ required: true, message: 'APNs Token必需填写', trigger: 'blur' }],
    app_version: [{ required: true, message: 'App版本必需填写', trigger: 'blur' }],
    locale: [{ required: true, message: '当前语言必需填写', trigger: 'blur' }],
    timezone: [{ required: true, message: '当前时区必需填写', trigger: 'blur' }],
    is_active: [{ required: true, message: '是否有效 1是 2否必需填写', trigger: 'blur' }],
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    device_id: '',
    platform: '',
    apns_token: '',
    app_version: '',
    locale: 'en-US',
    timezone: '',
    is_active: 1,
    last_active_time: '',
    logout_time: '',
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
