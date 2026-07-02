<template>
  <el-drawer
    v-model="visible"
    :title="dialogType === 'add' ? '新增社区举报' : '编辑社区举报'"
    :size="820"
    align-center
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="formData" :rules="rules" label-width="110px">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="举报会员" prop="member_id">
            <el-input-number
              v-model="formData.member_id"
              :min="1"
              :precision="0"
              controls-position="right"
              class="w-full"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="目标类型" prop="target_type">
            <el-select v-model="formData.target_type" placeholder="请选择目标类型" class="w-full">
              <el-option label="帖子" :value="1" />
              <el-option label="评论" :value="2" />
              <el-option label="用户" :value="3" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="目标ID" prop="target_id">
            <HelpRelationSelect
              v-if="targetRelation"
              :key="targetRelation"
              v-model="formData.target_id"
              :relation="targetRelation"
              placeholder="请选择举报目标"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="处理状态" prop="handle_status">
            <el-select v-model="formData.handle_status" placeholder="请选择处理状态" class="w-full">
              <el-option label="待处理" :value="0" />
              <el-option label="已处理" :value="1" />
              <el-option label="已忽略" :value="2" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="举报原因" prop="reason">
            <el-input v-model="formData.reason" placeholder="请输入举报原因" maxlength="100" />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="举报描述" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :rows="4"
              maxlength="500"
              show-word-limit
              placeholder="请输入举报描述"
            />
          </el-form-item>
        </el-col>
        <el-col :span="24">
          <el-form-item label="处理备注" prop="handle_remark">
            <el-input
              v-model="formData.handle_remark"
              type="textarea"
              :rows="3"
              maxlength="500"
              show-word-limit
              placeholder="可留空；处理举报也可使用列表操作按钮"
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
  import api from '../../../api/community/report'
  import HelpRelationSelect from '../../../components/HelpRelationSelect.vue'
  import type { HelpRelationType } from '../../../components/relationOptions'
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
  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const rules = reactive<FormRules>({
    member_id: [{ required: true, message: '举报会员必须填写', trigger: 'blur' }],
    target_type: [{ required: true, message: '目标类型必须选择', trigger: 'change' }],
    target_id: [{ required: true, message: '目标ID必须填写', trigger: 'change' }],
    reason: [{ required: true, message: '举报原因必须填写', trigger: 'blur' }],
    handle_status: [{ required: true, message: '处理状态必须选择', trigger: 'change' }]
  })

  const initialFormData = {
    id: null,
    member_id: null as number | null,
    target_type: 1,
    target_id: null as number | null,
    reason: '',
    description: '',
    handle_status: 0,
    handle_remark: ''
  }

  const formData = reactive({ ...initialFormData })
  const hydrating = ref(false)

  const targetRelation = computed<HelpRelationType | undefined>(() =>
    relationByTargetType(formData.target_type)
  )

  watch(
    () => props.modelValue,
    async (newVal) => {
      if (newVal) {
        hydrating.value = true
        Object.assign(formData, initialFormData)
        if (props.data) {
          await nextTick()
          for (const key in formData) {
            if (props.data[key] !== null && props.data[key] !== undefined) {
              ;(formData as any)[key] = props.data[key]
            }
          }
        }
        await nextTick()
        hydrating.value = false
      }
    }
  )

  watch(
    () => formData.target_type,
    (newValue, oldValue) => {
      if (!hydrating.value && newValue !== oldValue) {
        formData.target_id = null
      }
    }
  )

  const handleClose = () => {
    visible.value = false
    formRef.value?.resetFields()
  }

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

  function relationByTargetType(
    type: number | string | null | undefined
  ): HelpRelationType | undefined {
    const map: Record<number, HelpRelationType> = {
      1: 'communityPost',
      2: 'communityComment',
      3: 'member'
    }
    return map[Number(type)]
  }
</script>
