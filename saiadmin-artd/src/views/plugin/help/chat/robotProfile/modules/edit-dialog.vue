<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增机器人形象' : '编辑机器人形象'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="聊天模式" prop="chat_mode">
            <HelpChatModeSelect v-model="formData.chat_mode" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="运行模式" prop="runtime_mode">
            <el-select v-model="formData.runtime_mode" placeholder="请选择运行模式" class="w-full">
              <el-option label="在线模式" value="online" />
              <el-option label="本地模式" value="local" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="显示名称" prop="display_name">
            <el-input v-model="formData.display_name" placeholder="请输入显示名称" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="英文名称" prop="display_name_en">
            <el-input v-model="formData.display_name_en" placeholder="请输入英文显示名称" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="浅色头像" prop="avatar">
            <sa-image-upload v-model="formData.avatar" :limit="1" :multiple="false" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="深色头像" prop="dark_avatar">
            <sa-image-upload v-model="formData.dark_avatar" :limit="1" :multiple="false" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="简介" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :rows="3"
              placeholder="请输入简介"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="英文简介" prop="description_en">
            <el-input
              v-model="formData.description_en"
              type="textarea"
              :rows="3"
              placeholder="请输入英文简介"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="排序" prop="sort">
            <el-input-number
              v-model="formData.sort"
              :min="0"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
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
  import api from '../../../api/chat/robotProfile'
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
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

  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const rules = reactive<FormRules>({
    chat_mode: [{ required: true, message: '聊天模式必需选择', trigger: 'change' }],
    runtime_mode: [{ required: true, message: '运行模式必需选择', trigger: 'change' }],
    display_name: [{ required: true, message: '显示名称必需填写', trigger: 'blur' }],
    avatar: [{ required: true, message: '浅色头像必需上传', trigger: 'change' }],
    sort: [{ required: true, message: '排序必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态必需选择', trigger: 'change' }]
  })

  const initialFormData = {
    id: null,
    chat_mode: '',
    runtime_mode: 'online',
    display_name: '',
    display_name_en: '',
    description: '',
    description_en: '',
    avatar: '',
    dark_avatar: '',
    sort: 100,
    status: 1
  }

  const formData = reactive({ ...initialFormData })

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (!newVal) return
      Object.assign(formData, initialFormData)
      if (props.data) {
        await nextTick()
        Object.keys(formData).forEach((key) => {
          if (props.data?.[key] !== null && props.data?.[key] !== undefined) {
            ;(formData as any)[key] = props.data[key]
          }
        })
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
