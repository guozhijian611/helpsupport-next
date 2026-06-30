<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增医生资质审核' : '编辑医生资质审核'"
    :size="900"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="120px">
      <el-row :gutter="20">
        <el-col :span="24">
          <el-form-item label="医生会员ID" prop="member_id">
            <el-input-number
              v-model="formData.member_id"
              :min="1"
              :precision="0"
              placeholder="请输入医生会员ID"
              class="w-full"
            />
            <div class="relation-hint">
              关联会员：{{ formData.member_display || memberFallbackText }}
            </div>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="真实姓名" prop="real_name">
            <el-input v-model="formData.real_name" placeholder="请输入真实姓名" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="职称" prop="title">
            <el-input v-model="formData.title" placeholder="请输入职称" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="医院/机构" prop="hospital">
            <el-input v-model="formData.hospital" placeholder="请输入医院/机构" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="科室" prop="department">
            <el-input v-model="formData.department" placeholder="请输入科室" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="专业方向" prop="specialty">
            <el-input v-model="formData.specialty" placeholder="请输入专业方向" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="执业证书编号" prop="license_no">
            <el-input v-model="formData.license_no" placeholder="请输入执业证书编号" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="证书图片数组" prop="certification_images">
            <sa-image-upload v-model="formData.certification_images" :limit="1" :multiple="false" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="状态" prop="status">
            <el-select v-model="formData.status" placeholder="请选择状态" class="w-full">
              <el-option label="正常" :value="1" />
              <el-option label="禁用" :value="2" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="审核备注" prop="audit_remark">
            <el-input
              v-model="formData.audit_remark"
              type="textarea"
              :rows="3"
              placeholder="可留空；审核通过/拒绝请使用列表操作按钮"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="审核人">
            <el-input :model-value="formData.audit_by_display || '无'" disabled />
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
  import api from '../../../api/audit/profile'
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
  const rules = reactive<FormRules>({
    member_id: [{ required: true, message: '医生会员ID必需填写', trigger: 'blur' }],
    real_name: [{ required: true, message: '真实姓名必需填写', trigger: 'blur' }],
    title: [{ required: true, message: '职称必需填写', trigger: 'blur' }],
    hospital: [{ required: true, message: '医院/机构必需填写', trigger: 'blur' }],
    department: [{ required: true, message: '科室必需填写', trigger: 'blur' }],
    specialty: [{ required: true, message: '专业方向必需填写', trigger: 'blur' }],
    license_no: [{ required: true, message: '执业证书编号必需填写', trigger: 'blur' }],
    status: [{ required: true, message: '状态 1正常 2禁用必需填写', trigger: 'blur' }]
  })

  /**
   * 初始数据
   */
  const initialFormData = {
    id: null,
    member_id: null as number | null,
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
    status: 1,
    audit_remark: '',
    audit_by: null as number | null,
    audit_by_name: '',
    audit_by_display: ''
  }

  /**
   * 表单数据
   */
  const formData = reactive({ ...initialFormData })
  const memberFallbackText = computed(() =>
    formData.member_id ? `#${formData.member_id} 会员已删除或未找到` : '请先填写医生会员ID'
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
      await initForm()
    }
  }

  /**
   * 初始化表单数据
   */
  const initForm = async () => {
    if (props.data) {
      const source = props.data.id ? await api.read(props.data.id) : props.data
      for (const key in formData) {
        if (source[key] != null && source[key] != undefined) {
          if (key === 'certification_images') {
            ;(formData as any)[key] = firstImageUrl(
              source.certification_image_urls || source.certification_images
            )
            continue
          }
          ;(formData as any)[key] = source[key]
        }
      }
    }
  }

  const firstImageUrl = (value: unknown): string => {
    if (!value) return ''
    if (Array.isArray(value)) return String(value[0] || '')
    if (typeof value !== 'string') return ''
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) return String(parsed[0] || '')
      if (typeof parsed === 'string') return parsed
    } catch {
      return value
    }
    return value
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

<style scoped>
  .relation-hint {
    margin-top: 6px;
    color: var(--el-text-color-secondary);
    font-size: 12px;
    line-height: 1.4;
  }
</style>
