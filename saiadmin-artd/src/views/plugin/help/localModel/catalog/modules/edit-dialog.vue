<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增本地模型目录' : '编辑本地模型目录'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="模型显示名称" prop="name">
            <el-input v-model="formData.name" placeholder="请输入模型显示名称" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="模型编码" prop="code">
            <el-input v-model="formData.code" placeholder="请输入模型编码" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="模型来源" prop="provider">
            <el-input v-model="formData.provider" placeholder="请输入模型来源" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="模型家族" prop="model_family">
            <el-input v-model="formData.model_family" placeholder="请输入模型家族" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="能力类型" prop="capability">
            <el-select v-model="formData.capability" class="w-full">
              <el-option label="文本大模型" value="llm" />
              <el-option label="端侧 ASR" value="asr" />
              <el-option label="端侧 TTS" value="tts" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="量化类型" prop="quantization">
            <el-input v-model="formData.quantization" placeholder="请输入量化类型" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="文件大小字节" prop="file_size">
            <el-input-number
              v-model="formData.file_size"
              :min="0"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="模型下载地址" prop="download_url">
            <el-input v-model="formData.download_url" placeholder="请输入模型下载地址" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="SHA256校验值" prop="sha256">
            <el-input v-model="formData.sha256" placeholder="请输入SHA256校验值" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="默认介绍" prop="intro">
            <el-input v-model="formData.intro" placeholder="请输入默认介绍" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="多语言介绍" prop="intro_i18n">
            <el-input
              v-model="formData.intro_i18n"
              type="textarea"
              :rows="4"
              placeholder='可留空；填写 JSON，例如 {"zh-CN":"介绍"}'
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="许可证说明" prop="license">
            <el-input v-model="formData.license" placeholder="请输入许可证说明" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="推荐最小内存MB" prop="min_memory_mb">
            <el-input-number
              v-model="formData.min_memory_mb"
              :min="0"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="默认上下文长度" prop="context_size">
            <el-input-number
              v-model="formData.context_size"
              :min="0"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="默认温度" prop="default_temperature">
            <el-input-number
              v-model="formData.default_temperature"
              :min="0"
              :max="2"
              :step="0.05"
              :precision="2"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="默认top_p" prop="default_top_p">
            <el-input-number
              v-model="formData.default_top_p"
              :min="0"
              :max="1"
              :step="0.05"
              :precision="2"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="排序" prop="sort">
            <el-input-number v-model="formData.sort" :min="0" controls-position="right" class="w-full" />
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
  import api from '../../../api/localModel/catalog'
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
  const validateOptionalJson = (
    _rule: unknown,
    value: unknown,
    callback: (error?: Error) => void
  ) => {
    if (value === undefined || value === null || value === '') {
      callback()
      return
    }
    if (typeof value !== 'string') {
      callback()
      return
    }
    try {
      JSON.parse(value)
      callback()
    } catch {
      callback(new Error('多语言介绍必须是合法 JSON'))
    }
  }

  const rules = reactive<FormRules>({
    name: [{ required: true, message: '模型显示名称必需填写', trigger: 'blur' }],
    code: [{ required: true, message: '模型编码必需填写', trigger: 'blur' }],
    provider: [{ required: true, message: '模型来源必需填写', trigger: 'blur' }],
    model_family: [{ required: true, message: '模型家族必需填写', trigger: 'blur' }],
    quantization: [{ required: true, message: '量化类型必需填写', trigger: 'blur' }],
    file_size: [{ required: true, message: '文件大小字节必需填写', trigger: 'blur' }],
    download_url: [{ required: true, message: '模型下载地址必需填写', trigger: 'blur' }],
    sha256: [{ required: true, message: 'SHA256校验值必需填写', trigger: 'blur' }],
    intro: [{ required: true, message: '默认介绍必需填写', trigger: 'blur' }],
    intro_i18n: [{ validator: validateOptionalJson, trigger: 'blur' }],
    license: [{ required: true, message: '许可证说明必需填写', trigger: 'blur' }],
    min_memory_mb: [{ required: true, message: '推荐最小内存MB必需填写', trigger: 'blur' }],
    context_size: [{ required: true, message: '默认上下文长度必需填写', trigger: 'blur' }],
    default_temperature: [{ required: true, message: '默认温度必需填写', trigger: 'blur' }],
    default_top_p: [{ required: true, message: '默认top_p必需填写', trigger: 'blur' }],
    sort: [{ required: true, message: '排序必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态 1启用 2禁用必需填写', trigger: 'blur' }],
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    name: '',
    code: '',
    provider: '',
    model_family: '',
    capability: 'llm',
    quantization: '',
    file_size: 0,
    download_url: '',
    sha256: '',
    intro: '',
    intro_i18n: '',
    license: '',
    min_memory_mb: 0,
    context_size: 2048,
    default_temperature: 0.7,
    default_top_p: 0.9,
    sort: 100,
    status: 1,
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
