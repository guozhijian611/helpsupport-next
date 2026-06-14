<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="场景">
          <div v-text="formData?.scene"></div>
        </el-descriptions-item>
        <el-descriptions-item label="配置版本">
          <div v-text="formData?.version"></div>
        </el-descriptions-item>
        <el-descriptions-item label="语言">
          <div v-text="formData?.locale"></div>
        </el-descriptions-item>
        <el-descriptions-item label="标题">
          <div v-text="formData?.title"></div>
        </el-descriptions-item>
        <el-descriptions-item label="说明">
          <div v-text="formData?.description"></div>
        </el-descriptions-item>
        <el-descriptions-item label="图片URL或附件路径">
          <img :src="formData?.image" style="width: 200px" />
        </el-descriptions-item>
        <el-descriptions-item label="按钮文案">
          <div v-text="formData?.button_text"></div>
        </el-descriptions-item>
        <el-descriptions-item label="动作类型 next/skip/route/external_url">
          <div v-text="formData?.action_type"></div>
        </el-descriptions-item>
        <el-descriptions-item label="动作值">
          <div v-text="formData?.action_value"></div>
        </el-descriptions-item>
        <el-descriptions-item label="排序">
          <div v-text="formData?.sort"></div>
        </el-descriptions-item>
        <el-descriptions-item label="状态 1启用 2禁用">
          <sa-dict :value="formData?.status" dict="data_status" render="span" />
        </el-descriptions-item>
        <el-descriptions-item label="生效开始时间">
          <div v-text="formData?.start_time"></div>
        </el-descriptions-item>
        <el-descriptions-item label="生效结束时间">
          <div v-text="formData?.end_time"></div>
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/config/page'

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
    dialogType: 'view',
    data: undefined
  })

  const emit = defineEmits<Emits>()

  /**
   * 弹窗显示状态双向绑定
   */
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
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
  const initForm = async () => {
    if (props.data && props.data.id) {
      const data = await api.read(props.data.id)
      for (const key in formData) {
        if (data[key] != null && data[key] != undefined) {
          ;(formData as any)[key] = data[key]
        }
      }
    }
  }
</script>
