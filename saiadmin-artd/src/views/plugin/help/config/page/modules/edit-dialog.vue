<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增App引导页配置' : '编辑App引导页配置'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="配置版本" prop="version">
            <el-input v-model="formData.version" placeholder="留空表示默认版本" clearable />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="场景" prop="scene">
            <el-input v-model="formData.scene" placeholder="请输入场景" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="语言" prop="locale">
            <el-input v-model="formData.locale" placeholder="请输入语言" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="标题" prop="title">
            <el-input v-model="formData.title" placeholder="请输入标题" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="说明" prop="description">
            <el-input v-model="formData.description" placeholder="请输入说明" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="图片URL或附件路径" prop="image">
            <sa-image-upload v-model="formData.image" :limit="1" :multiple="false" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="按钮文案" prop="button_text">
            <el-input v-model="formData.button_text" placeholder="请输入按钮文案" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="动作类型" prop="action_type">
            <el-select v-model="formData.action_type" placeholder="请选择动作类型">
              <el-option
                v-for="item in actionTypeOptions"
                :key="item.value"
                :label="item.label"
                :value="item.value"
              />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="动作值" prop="action_value">
            <el-input v-model="formData.action_value" placeholder="请输入动作值" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="排序" prop="sort">
            <el-input-number v-model="formData.sort" :min="0" :step="10" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="状态 1启用 2禁用" prop="status">
            <sa-radio v-model="formData.status" dict="data_status" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="生效开始时间" prop="start_time">
            <el-date-picker
              v-model="formData.start_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择生效开始时间"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="生效结束时间" prop="end_time">
            <el-date-picker
              v-model="formData.end_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择生效结束时间"
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
  import api from '../../../api/config/page'
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
  const actionTypeOptions = [
    { label: 'next', value: 'next' },
    { label: 'skip', value: 'skip' },
    { label: 'route', value: 'route' },
    { label: 'external_url', value: 'external_url' }
  ]

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
    scene: [{ required: true, message: '场景必需填写', trigger: 'blur' }],
    locale: [{ required: true, message: '语言必需填写', trigger: 'blur' }],
    title: [{ required: true, message: '标题必需填写', trigger: 'blur' }],
    description: [{ required: true, message: '说明必需填写', trigger: 'blur' }],
    image: [{ required: true, message: '图片URL或附件路径必需填写', trigger: 'blur' }],
    button_text: [{ required: true, message: '按钮文案必需填写', trigger: 'blur' }],
    action_type: [{ required: true, message: '动作类型必需填写', trigger: 'change' }],
    sort: [{ required: true, message: '排序必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态 1启用 2禁用必需填写', trigger: 'blur' }]
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    scene: 'first_launch',
    version: '',
    locale: 'en-US',
    title: '',
    description: '',
    image: '',
    button_text: '',
    action_type: 'next',
    action_value: '',
    sort: 10,
    status: 1,
    start_time: '',
    end_time: ''
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
