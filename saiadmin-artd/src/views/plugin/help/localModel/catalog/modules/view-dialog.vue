<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="模型显示名称">
          <div v-text="formData?.name"></div>
        </el-descriptions-item>
        <el-descriptions-item label="模型编码">
          <div v-text="formData?.code"></div>
        </el-descriptions-item>
        <el-descriptions-item label="模型来源">
          <div v-text="formData?.provider"></div>
        </el-descriptions-item>
        <el-descriptions-item label="模型家族">
          <div v-text="formData?.model_family"></div>
        </el-descriptions-item>
        <el-descriptions-item label="能力类型">
          <div v-text="formData?.capability"></div>
        </el-descriptions-item>
        <el-descriptions-item label="量化类型">
          <div v-text="formData?.quantization"></div>
        </el-descriptions-item>
        <el-descriptions-item label="文件大小字节">
          <div v-text="formData?.file_size"></div>
        </el-descriptions-item>
        <el-descriptions-item label="模型下载地址">
          <div v-text="formData?.download_url"></div>
        </el-descriptions-item>
        <el-descriptions-item label="SHA256校验值">
          <div v-text="formData?.sha256"></div>
        </el-descriptions-item>
        <el-descriptions-item label="默认介绍">
          <div v-text="formData?.intro"></div>
        </el-descriptions-item>
        <el-descriptions-item label="多语言介绍">
          <div v-text="formData?.intro_i18n"></div>
        </el-descriptions-item>
        <el-descriptions-item label="许可证说明">
          <div v-text="formData?.license"></div>
        </el-descriptions-item>
        <el-descriptions-item label="推荐最小内存MB">
          <div v-text="formData?.min_memory_mb"></div>
        </el-descriptions-item>
        <el-descriptions-item label="默认上下文长度">
          <div v-text="formData?.context_size"></div>
        </el-descriptions-item>
        <el-descriptions-item label="默认温度">
          <div v-text="formData?.default_temperature"></div>
        </el-descriptions-item>
        <el-descriptions-item label="默认top_p">
          <div v-text="formData?.default_top_p"></div>
        </el-descriptions-item>
        <el-descriptions-item label="排序">
          <div v-text="formData?.sort"></div>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <sa-dict :value="formData?.status" dict="data_status" render="span" />
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/localModel/catalog'

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
