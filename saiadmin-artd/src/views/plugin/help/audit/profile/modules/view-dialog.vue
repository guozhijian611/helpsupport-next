<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="关联会员">
          <div>{{ formData.member_display || emptyMemberText }}</div>
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
          <el-space v-if="certificationImages.length" wrap>
            <el-image
              v-for="image in certificationImages"
              :key="image"
              :src="image"
              :preview-src-list="certificationImages"
              fit="cover"
              class="certification-image"
            />
          </el-space>
          <span v-else>暂无</span>
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
          <div>{{ formData.audit_by_display || '无' }}</div>
        </el-descriptions-item>
        <el-descriptions-item label="审核时间">
          <div v-text="formData?.audit_time"></div>
        </el-descriptions-item>
        <el-descriptions-item label="通过时间">
          <div v-text="formData?.approved_time"></div>
        </el-descriptions-item>
        <el-descriptions-item label="审核日志">
          <AuditLogTimeline :logs="formData.audit_logs" />
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import AuditLogTimeline from '../../../components/AuditLogTimeline.vue'
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
    member_name: '',
    member_username: '',
    member_avatar: '',
    member_display: '',
    real_name: '',
    title: '',
    hospital: '',
    department: '',
    specialty: '',
    license_no: '',
    certification_images: '',
    certification_image_urls: [] as string[],
    audit_status: 0,
    status: 1,
    audit_remark: '',
    audit_by: null,
    audit_by_name: '',
    audit_by_display: '',
    audit_time: '',
    approved_time: '',
    audit_logs: []
  }

  /**
   * 表单数据
   */
  const formData = reactive({ ...initialFormData })
  const certificationImages = computed(() =>
    parseImageList(formData.certification_image_urls || formData.certification_images).map(
      normalizeImageUrl
    )
  )
  const emptyMemberText = computed(() =>
    formData.member_id ? `#${formData.member_id} 会员已删除或未找到` : '无'
  )

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

  const parseImageList = (value: unknown): string[] => {
    if (!value) return []
    if (Array.isArray(value)) return value.map(String).filter(Boolean)
    if (typeof value !== 'string') return []
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean)
      if (typeof parsed === 'string' && parsed) return [parsed]
    } catch {
      return value ? [value] : []
    }
    return value ? [value] : []
  }

  const normalizeImageUrl = (url: string) => {
    if (!url) return ''
    if (/^(https?:)?\/\//.test(url) || url.startsWith('data:') || url.startsWith('blob:')) {
      return url
    }
    const base = import.meta.env.VITE_API_URL || ''
    if (url.startsWith('/') && base && base !== '/') {
      return `${base.replace(/\/$/, '')}${url}`
    }
    return url
  }
</script>

<style scoped>
  .certification-image {
    width: 200px;
    height: 120px;
    border-radius: 6px;
  }
</style>
