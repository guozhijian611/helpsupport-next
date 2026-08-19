<template>
  <sa-search-bar
    ref="searchBarRef"
    v-model="formData"
    label-width="100px"
    :showExpand="false"
    @reset="handleReset"
    @search="handleSearch"
  >
    <el-col v-bind="setSpan(6)">
      <el-form-item label="关键字" prop="keywords">
        <el-input v-model="formData.keywords" placeholder="请输入用户名|邮箱|手机号" clearable />
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="用户身份" prop="identity">
        <el-select v-model="formData.identity" placeholder="请选择用户身份" clearable>
          <el-option
            v-for="item in identityOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(6)">
      <el-form-item label="会员等级" prop="member_level_id">
        <el-select
          v-model="formData.member_level_id"
          placeholder="请选择会员等级"
          clearable
        >
          <el-option
            v-for="item in optionData.member_level_id"
            :key="item.id"
            :label="item.level_name"
            :value="item.id"
          />
        </el-select>
      </el-form-item>
    </el-col>
    <el-col v-bind="setSpan(8)">
      <el-form-item label="注册时间" prop="create_time">
        <el-date-picker
          v-model="formData.create_time"
          type="daterange"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          value-format="YYYY-MM-DD"
          clearable
        />
      </el-form-item>
    </el-col>
  </sa-search-bar>
</template>

<script setup lang="ts">
  import levelApi from '../../../api/setting/level'

  interface Props {
    modelValue: Record<string, any>
  }
  interface Emits {
    (e: 'update:modelValue', value: Record<string, any>): void
    (e: 'search', params: Record<string, any>): void
    (e: 'reset'): void
  }
  const props = defineProps<Props>()
  const emit = defineEmits<Emits>()

  const searchBarRef = ref()
  const formData = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
  })

  const identityOptions = [
    { label: '患者', value: 'patient' },
    { label: '医生', value: 'doctor' },
    { label: '医生待审核', value: 'doctor_pending' },
    { label: '医生已拒绝', value: 'doctor_rejected' }
  ]

  const optionData = reactive({
    member_level_id: <any[]>[],
  })

  const initOptions = async () => {
    const resp = await levelApi.list({ saiType: 'all' })
    optionData.member_level_id = resp.data || resp
  }

  onMounted(() => {
    initOptions()
  })

  function handleReset() {
    searchBarRef.value?.ref.resetFields()
    emit('reset')
  }

  async function handleSearch() {
    emit('search', formData.value)
  }

  const setSpan = (span: number) => {
    return {
      span: span,
      xs: 24,
      sm: span >= 12 ? span : 12,
      md: span >= 8 ? span : 8,
      lg: span,
      xl: span
    }
  }
</script>
