<template>
  <el-drawer v-model="visible" size="70%" title="查看详情" :footer="false">
    <!-- 详情 start -->
    <div>
      <el-descriptions :column="1" label-width="100px" border>
        <el-descriptions-item label="帖子内容">
          <div v-html="formData?.content"></div>
        </el-descriptions-item>
        <el-descriptions-item label="图片">
          <div v-if="imageList.length" class="image-list">
            <img v-for="item in imageList" :key="item" :src="item" />
          </div>
          <span v-else>暂无</span>
        </el-descriptions-item>
        <el-descriptions-item label="链接">
          <div v-text="formData?.link_url"></div>
        </el-descriptions-item>
        <el-descriptions-item label="标签">
          <div v-text="tagText"></div>
        </el-descriptions-item>
        <el-descriptions-item label="是否匿名 1是 2否">
          <sa-dict :value="formData?.is_anonymous" dict="yes_or_no" render="span" />
        </el-descriptions-item>
        <el-descriptions-item label="是否医生帖 1是 2否">
          <sa-dict :value="formData?.is_doctor_post" dict="yes_or_no" render="span" />
        </el-descriptions-item>
        <el-descriptions-item label="浏览数">
          <div v-text="formData?.view_count"></div>
        </el-descriptions-item>
        <el-descriptions-item label="点赞数">
          <div v-text="formData?.like_count"></div>
        </el-descriptions-item>
        <el-descriptions-item label="评论数">
          <div v-text="formData?.comment_count"></div>
        </el-descriptions-item>
        <el-descriptions-item label="收藏数">
          <div v-text="formData?.collect_count"></div>
        </el-descriptions-item>
        <el-descriptions-item label="是否置顶 1是 2否">
          <sa-dict :value="formData?.is_top" dict="yes_or_no" render="span" />
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
        <el-descriptions-item label="审核日志">
          <AuditLogTimeline :logs="formData.audit_logs" />
        </el-descriptions-item>
      </el-descriptions>
    </div>
    <!-- 详情 end -->
  </el-drawer>
</template>

<script setup lang="ts">
  import { computed } from 'vue'
  import AuditLogTimeline from '../../../components/AuditLogTimeline.vue'
  import api from '../../../api/community/post'

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
    content: '',
    images: '',
    link_url: '',
    tags: '',
    is_anonymous: 2,
    is_doctor_post: 2,
    view_count: null,
    like_count: null,
    comment_count: null,
    collect_count: null,
    is_top: 2,
    audit_remark: '',
    audit_by: null,
    audit_time: '',
    audit_logs: []
  }

  /**
   * 表单数据
   */
  const formData = reactive({ ...initialFormData })

  const imageList = computed(() => parseJsonList(formData.images))
  const tagText = computed(() => parseJsonList(formData.tags).join('、') || '暂无')

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

  const parseJsonList = (value: unknown): string[] => {
    if (Array.isArray(value)) {
      return value.map(String).filter(Boolean)
    }
    if (typeof value !== 'string' || value === '') {
      return []
    }
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed.map(String).filter(Boolean) : []
    } catch {
      return [value]
    }
  }
</script>

<style scoped>
  .image-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .image-list img {
    width: 120px;
    height: 120px;
    object-fit: cover;
    border-radius: 6px;
  }
</style>
