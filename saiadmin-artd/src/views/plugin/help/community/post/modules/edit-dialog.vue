<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增社区内容审核' : '编辑社区内容审核'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="帖子内容" prop="content">
            <sa-editor v-model="formData.content" height="400px" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="图片URL数组" prop="images">
            <sa-image-upload v-model="formData.images" :limit="1" :multiple="false" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="链接" prop="link_url">
            <el-input v-model="formData.link_url" placeholder="请输入链接" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="标签数组" prop="tags">
            <el-input v-model="formData.tags" placeholder="请输入标签数组" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="是否匿名 1是 2否" prop="is_anonymous">
            <sa-radio v-model="formData.is_anonymous" dict="yes_or_no" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="是否医生帖 1是 2否" prop="is_doctor_post">
            <sa-radio v-model="formData.is_doctor_post" dict="yes_or_no" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="浏览数" prop="view_count">
            <el-input v-model="formData.view_count" placeholder="请输入浏览数" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="点赞数" prop="like_count">
            <el-input v-model="formData.like_count" placeholder="请输入点赞数" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="评论数" prop="comment_count">
            <el-input v-model="formData.comment_count" placeholder="请输入评论数" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="收藏数" prop="collect_count">
            <el-input v-model="formData.collect_count" placeholder="请输入收藏数" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="是否置顶 1是 2否" prop="is_top">
            <sa-radio v-model="formData.is_top" dict="yes_or_no" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="审核备注" prop="audit_remark">
            <el-input v-model="formData.audit_remark" placeholder="请输入审核备注" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="审核人" prop="audit_by">
            <el-input v-model="formData.audit_by" placeholder="请输入审核人" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="审核时间" prop="audit_time">
            <el-date-picker
              v-model="formData.audit_time"
              type="datetime"
              value-format="YYYY-MM-DD HH:mm:ss"
              placeholder="请选择审核时间"
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
  import commonApi from '@/api/common'
  import api from '../../../api/community/post'
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
  const optionData = reactive({
    treeData: <any[]>[],
  })

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
    member_id: [{ required: true, message: '发帖会员ID必需填写', trigger: 'blur' }],
    content: [{ required: true, message: '帖子内容必需填写', trigger: 'blur' }],
    link_url: [{ required: true, message: '链接必需填写', trigger: 'blur' }],
    is_anonymous: [{ required: true, message: '是否匿名 1是 2否必需填写', trigger: 'blur' }],
    is_doctor_post: [{ required: true, message: '是否医生帖 1是 2否必需填写', trigger: 'blur' }],
    view_count: [{ required: true, message: '浏览数必需填写', trigger: 'blur' }],
    like_count: [{ required: true, message: '点赞数必需填写', trigger: 'blur' }],
    comment_count: [{ required: true, message: '评论数必需填写', trigger: 'blur' }],
    collect_count: [{ required: true, message: '收藏数必需填写', trigger: 'blur' }],
    is_top: [{ required: true, message: '是否置顶 1是 2否必需填写', trigger: 'blur' }],
    audit_status: [{ required: true, message: '审核状态 0待审核 1已通过 2已拒绝 3AI预审标记必需填写', trigger: 'blur' }],
    audit_remark: [{ required: true, message: '审核备注必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态 1正常 2隐藏 3封禁必需填写', trigger: 'blur' }],
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
