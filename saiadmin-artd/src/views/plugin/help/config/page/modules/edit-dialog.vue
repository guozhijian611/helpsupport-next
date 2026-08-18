<template>
  <el-drawer
    v-model="visible"
    :title="drawerTitle"
    :size="520"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="108px">
      <el-form-item label="所属流程">
        <div class="flow-meta">
          {{ sceneLabel }} · {{ versionLabel(formData.version) }} · 第 {{ pageNumber }} 页
        </div>
      </el-form-item>
      <el-form-item label="语言" prop="locale">
        <el-select v-model="formData.locale" placeholder="请选择语言">
          <el-option
            v-for="item in LOCALE_OPTIONS"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="标题" prop="title">
        <el-input v-model="formData.title" placeholder="请输入标题" />
      </el-form-item>
      <el-form-item label="说明" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="请输入说明"
        />
      </el-form-item>
      <el-form-item label="图片" prop="image">
        <sa-image-upload v-model="formData.image" :limit="1" :multiple="false" />
      </el-form-item>
      <el-form-item label="按钮文案" prop="button_text">
        <el-input v-model="formData.button_text" placeholder="当前页底部按钮文案" />
      </el-form-item>
      <el-form-item label="按钮动作" prop="action_type">
        <el-select v-model="formData.action_type" placeholder="请选择动作类型">
          <el-option
            v-for="item in ACTION_TYPE_OPTIONS"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item
        v-if="needsActionValue"
        :label="formData.action_type === 'route' ? '跳转路由' : '外链地址'"
        prop="action_value"
      >
        <el-input
          v-model="formData.action_value"
          :placeholder="
            formData.action_type === 'route' ? '例如 /login' : '例如 https://example.com'
          "
        />
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <sa-radio v-model="formData.status" dict="data_status" />
      </el-form-item>
      <el-form-item label="生效开始" prop="start_time">
        <el-date-picker
          v-model="formData.start_time"
          type="datetime"
          value-format="YYYY-MM-DD HH:mm:ss"
          placeholder="不填表示立即生效"
          clearable
          class="w-full"
        />
      </el-form-item>
      <el-form-item label="生效结束" prop="end_time">
        <el-date-picker
          v-model="formData.end_time"
          type="datetime"
          value-format="YYYY-MM-DD HH:mm:ss"
          placeholder="不填表示长期有效"
          clearable
          class="w-full"
        />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="handleSubmit">提交</el-button>
    </template>
  </el-drawer>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import api from '../../../api/config/page'
  import {
    ACTION_TYPE_OPTIONS,
    LOCALE_OPTIONS,
    SCENE_OPTIONS,
    localeLabel,
    versionLabel
  } from '../onboarding'

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

  const initialFormData = {
    id: null as number | null,
    scene: 'first_launch',
    version: '',
    locale: 'zh-CN',
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

  const formData = reactive({ ...initialFormData })

  const needsActionValue = computed(
    () => formData.action_type === 'route' || formData.action_type === 'external_url'
  )

  const pageNumber = computed(() => Math.max(1, Math.round(Number(formData.sort || 10) / 10)))

  const sceneLabel = computed(
    () => SCENE_OPTIONS.find((item) => item.value === formData.scene)?.label ?? formData.scene
  )

  const drawerTitle = computed(() => {
    if (props.dialogType === 'edit') {
      return `编辑${localeLabel(formData.locale)}引导页`
    }
    return formData.id ? '编辑引导页' : `新增${localeLabel(formData.locale)}引导页`
  })

  const rules = reactive<FormRules>({
    locale: [{ required: true, message: '语言必须填写', trigger: 'change' }],
    title: [{ required: true, message: '标题必须填写', trigger: 'blur' }],
    description: [{ required: true, message: '说明必须填写', trigger: 'blur' }],
    image: [{ required: true, message: '图片必须上传', trigger: 'change' }],
    button_text: [{ required: true, message: '按钮文案必须填写', trigger: 'blur' }],
    action_type: [{ required: true, message: '动作类型必须填写', trigger: 'change' }],
    action_value: [
      {
        validator: (_rule, value, callback) => {
          if (!needsActionValue.value) {
            callback()
            return
          }
          if (!value) {
            callback(new Error('请填写动作值'))
            return
          }
          callback()
        },
        trigger: 'blur'
      }
    ],
    status: [{ required: true, message: '状态必须填写', trigger: 'change' }]
  })

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
    if (!props.data) return
    for (const key in formData) {
      if (props.data[key] != null && props.data[key] != undefined) {
        ;(formData as any)[key] = props.data[key]
      }
    }
    if (!formData.locale) formData.locale = 'zh-CN'
    if (!formData.scene) formData.scene = 'first_launch'
  }

  const handleClose = () => {
    visible.value = false
    formRef.value?.resetFields()
  }

  const handleSubmit = async () => {
    if (!formRef.value) return
    try {
      await formRef.value.validate()
      const payload: Record<string, any> = { ...formData }
      if (!needsActionValue.value) {
        payload.action_value = payload.action_value || ''
      }
      if (!payload.start_time) payload.start_time = null
      if (!payload.end_time) payload.end_time = null
      if (props.dialogType === 'add' || !payload.id) {
        delete payload.id
        await api.save(payload)
        ElMessage.success('新增成功')
      } else {
        await api.update(payload)
        ElMessage.success('修改成功')
      }
      emit('success')
      handleClose()
    } catch (error) {
      console.log('表单验证失败:', error)
    }
  }
</script>

<style scoped>
  .flow-meta {
    color: var(--el-text-color-regular);
  }
</style>
