<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="会员ID">
          <div v-text="formData?.member_id"></div>
        </el-descriptions-item>
        <el-descriptions-item label="设备标识">
          <div v-text="formData?.device_id"></div>
        </el-descriptions-item>
        <el-descriptions-item label="平台">
          <div v-text="formData?.platform"></div>
        </el-descriptions-item>
        <el-descriptions-item label="FCM Token">
          <div class="token-text" v-text="formData?.fcm_token"></div>
        </el-descriptions-item>
        <el-descriptions-item label="APNs Token">
          <div class="token-text" v-text="formData?.apns_token"></div>
        </el-descriptions-item>
        <el-descriptions-item label="App版本">
          <div v-text="formData?.app_version"></div>
        </el-descriptions-item>
        <el-descriptions-item label="当前语言">
          <div v-text="formData?.locale"></div>
        </el-descriptions-item>
        <el-descriptions-item label="当前时区">
          <div v-text="formData?.timezone"></div>
        </el-descriptions-item>
        <el-descriptions-item label="是否有效 1是 2否">
          <sa-dict :value="formData?.is_active" dict="yes_or_no" render="span" />
        </el-descriptions-item>
        <el-descriptions-item label="最近活跃时间">
          <div v-text="formData?.last_active_time"></div>
        </el-descriptions-item>
        <el-descriptions-item label="退出或踢下线时间">
          <div v-text="formData?.logout_time"></div>
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/push/device'

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
    member_id: null,
    device_id: '',
    platform: '',
    fcm_token: '',
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

<style scoped>
  .token-text {
    word-break: break-all;
    white-space: pre-wrap;
  }
</style>
