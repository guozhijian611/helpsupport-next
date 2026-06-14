<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="医生会员ID">
          <div v-text="formData?.member_id"></div>
        </el-descriptions-item>
        <el-descriptions-item label="真实姓名">
          <div v-text="formData?.real_name"></div>
        </el-descriptions-item>
        <el-descriptions-item label="职称">
          <div v-text="formData?.title"></div>
        </el-descriptions-item>
        <el-descriptions-item label="医院/机构">
          <div v-text="formData?.hospital"></div>
        </el-descriptions-item>
        <el-descriptions-item label="科室">
          <div v-text="formData?.department"></div>
        </el-descriptions-item>
        <el-descriptions-item label="专业方向">
          <div v-text="formData?.specialty"></div>
        </el-descriptions-item>
        <el-descriptions-item label="执业证书编号">
          <div v-text="formData?.license_no"></div>
        </el-descriptions-item>
        <el-descriptions-item label="证书图片数组">
          <img :src="formData?.certification_images" style="width: 200px" />
        </el-descriptions-item>
        <el-descriptions-item label="审核状态">
          <el-tag :type="auditStatusType(formData?.audit_status)">
            {{ auditStatusText(formData?.audit_status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="Number(formData?.status) === 1 ? 'success' : 'info'">
            {{ Number(formData?.status) === 1 ? '正常' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="审核备注">
          <div v-text="formData?.audit_remark"></div>
        </el-descriptions-item>
        <el-descriptions-item label="审核人">
          <div v-text="formData?.audit_by"></div>
        </el-descriptions-item>
        <el-descriptions-item label="审核时间">
          <div v-text="formData?.audit_time"></div>
        </el-descriptions-item>
        <el-descriptions-item label="通过时间">
          <div v-text="formData?.approved_time"></div>
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import api from '../../../api/audit/profile'

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
    real_name: '',
    title: '',
    hospital: '',
    department: '',
    specialty: '',
    license_no: '',
    certification_images: '',
    audit_status: 0,
    status: 1,
    audit_remark: '',
    audit_by: null,
    audit_time: '',
    approved_time: '',
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

  const auditStatusText = (status: number) => {
    const map: Record<number, string> = {
      0: '待审核',
      1: '已通过',
      2: '已拒绝'
    }
    return map[Number(status)] || '未知'
  }

  const auditStatusType = (status: number) => {
    const map: Record<number, 'success' | 'warning' | 'danger' | 'info'> = {
      0: 'warning',
      1: 'success',
      2: 'danger'
    }
    return map[Number(status)] || 'info'
  }
</script>
