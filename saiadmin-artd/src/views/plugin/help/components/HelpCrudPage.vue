<template>
  <div class="art-full-height">
    <ElCard v-if="searchFields.length > 0" class="help-search-card" shadow="never">
      <ElForm :model="searchForm" inline label-width="96px">
        <ElFormItem v-for="field in searchFields" :key="field.prop" :label="field.label">
          <ElSelect
            v-if="field.options"
            v-model="searchForm[field.prop]"
            clearable
            filterable
            :placeholder="field.placeholder || '请选择' + field.label"
            class="help-search-control"
          >
            <ElOption
              v-for="option in field.options"
              :key="String(option.value)"
              :label="option.label"
              :value="option.value"
            />
          </ElSelect>
          <ElDatePicker
            v-else-if="field.type === 'date'"
            v-model="searchForm[field.prop]"
            type="date"
            value-format="YYYY-MM-DD"
            :placeholder="field.placeholder || '请选择' + field.label"
            class="help-search-control"
          />
          <ElInput
            v-else
            v-model="searchForm[field.prop]"
            clearable
            :placeholder="field.placeholder || '请输入' + field.label"
            class="help-search-control"
          />
        </ElFormItem>
        <ElFormItem>
          <ElSpace>
            <ElButton type="primary" @click="handleSearch">
              <template #icon>
                <ArtSvgIcon icon="ri:search-line" />
              </template>
              查询
            </ElButton>
            <ElButton @click="handleReset">
              <template #icon>
                <ArtSvgIcon icon="ri:refresh-line" />
              </template>
              重置
            </ElButton>
          </ElSpace>
        </ElFormItem>
      </ElForm>
    </ElCard>

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-if="allowCreate"
              v-permission="permission('save')"
              @click="openForm('add')"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-if="allowDelete"
              v-permission="permission('destroy')"
              :disabled="selectedRows.length === 0"
              @click="deleteSelectedRows(api.delete, refreshData)"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:delete-bin-5-line" />
              </template>
              删除
            </ElButton>
          </ElSpace>
        </template>
      </ArtTableHeader>

      <ArtTable
        rowKey="id"
        :loading="loading"
        :data="tableData"
        :columns="columns"
        :pagination="pagination"
        @sort-change="handleSortChange"
        @selection-change="handleSelectionChange"
        @pagination:size-change="handleSizeChange"
        @pagination:current-change="handleCurrentChange"
      >
        <template v-for="field in tableFields" :key="field.prop" #[field.prop]="{ row }">
          <ElTag v-if="shouldUseTag(field)" :type="tagType(field, row[field.prop])">
            {{ formatValue(field, row[field.prop]) }}
          </ElTag>
          <ElTooltip
            v-else-if="isLongValue(field, row[field.prop])"
            :content="formatValue(field, row[field.prop])"
            placement="top"
          >
            <span>{{ shortValue(field, row[field.prop]) }}</span>
          </ElTooltip>
          <span v-else>{{ formatValue(field, row[field.prop]) }}</span>
        </template>

        <template #operation="{ row }">
          <div class="help-row-actions">
            <ElButton size="small" @click="openDetail(row)">查看</ElButton>
            <ElButton
              v-if="allowEdit"
              v-permission="permission('update')"
              size="small"
              type="primary"
              @click="openForm('edit', row)"
            >
              编辑
            </ElButton>
            <ElButton
              v-for="action in visibleActions(row)"
              :key="action.method + action.label"
              v-permission="action.permission"
              size="small"
              :type="action.type || 'primary'"
              @click="runAction(action, row)"
            >
              {{ action.label }}
            </ElButton>
            <SaButton
              v-if="allowDelete"
              v-permission="permission('destroy')"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <ElDrawer
      v-model="formVisible"
      :title="dialogType === 'add' ? '新增' + title : '编辑' + title"
      :size="drawerSize"
      :close-on-click-modal="false"
      @close="handleFormClose"
    >
      <ElForm ref="formRef" :model="formData" :rules="rules" label-width="128px">
        <ElRow :gutter="20">
          <ElCol v-for="field in formFields" :key="field.prop" :span="field.span || 24">
            <ElFormItem :label="field.label" :prop="field.prop">
              <ElSelect
                v-if="field.options"
                v-model="formData[field.prop]"
                clearable
                filterable
                :placeholder="field.placeholder || '请选择' + field.label"
                :disabled="isFieldDisabled(field)"
                class="help-form-control"
              >
                <ElOption
                  v-for="option in field.options"
                  :key="String(option.value)"
                  :label="option.label"
                  :value="option.value"
                />
              </ElSelect>
              <ElInputNumber
                v-else-if="field.type === 'number'"
                v-model="formData[field.prop]"
                :min="field.min"
                :precision="field.precision"
                :disabled="isFieldDisabled(field)"
                class="help-form-control"
              />
              <ElDatePicker
                v-else-if="field.type === 'date'"
                v-model="formData[field.prop]"
                type="date"
                value-format="YYYY-MM-DD"
                :placeholder="field.placeholder || '请选择' + field.label"
                :disabled="isFieldDisabled(field)"
                class="help-form-control"
              />
              <ElTimePicker
                v-else-if="field.type === 'time'"
                v-model="formData[field.prop]"
                value-format="HH:mm:ss"
                :placeholder="field.placeholder || '请选择' + field.label"
                :disabled="isFieldDisabled(field)"
                class="help-form-control"
              />
              <ElDatePicker
                v-else-if="field.type === 'datetime'"
                v-model="formData[field.prop]"
                type="datetime"
                value-format="YYYY-MM-DD HH:mm:ss"
                :placeholder="field.placeholder || '请选择' + field.label"
                :disabled="isFieldDisabled(field)"
                class="help-form-control"
              />
              <ElInput
                v-else-if="field.type === 'textarea' || field.type === 'json'"
                v-model="formData[field.prop]"
                type="textarea"
                :rows="field.rows || 4"
                :placeholder="field.placeholder || '请输入' + field.label"
                :disabled="isFieldDisabled(field)"
              />
              <ElInput
                v-else
                v-model="formData[field.prop]"
                clearable
                :placeholder="field.placeholder || '请输入' + field.label"
                :disabled="isFieldDisabled(field)"
              />
            </ElFormItem>
          </ElCol>
        </ElRow>
      </ElForm>
      <template #footer>
        <ElButton @click="handleFormClose">取消</ElButton>
        <ElButton type="primary" :loading="submitLoading" @click="handleSubmit">提交</ElButton>
      </template>
    </ElDrawer>

    <ElDrawer v-model="detailVisible" :size="drawerSize" :title="title + '详情'">
      <ElDescriptions :column="1" border>
        <ElDescriptionsItem v-for="field in detailFields" :key="field.prop" :label="field.label">
          <pre v-if="field.type === 'json' || field.type === 'textarea'" class="help-detail-pre">{{
            formatValue(field, detailData[field.prop])
          }}</pre>
          <span v-else>{{ formatValue(field, detailData[field.prop]) }}</span>
        </ElDescriptionsItem>
      </ElDescriptions>
    </ElDrawer>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import type { FormInstance, FormRules } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import type { CrudApi, HelpCrudAction, HelpCrudField } from './helpCrudTypes'

  const props = withDefaults(
    defineProps<{
      title: string
      api: CrudApi
      permissionPrefix: string
      fields: HelpCrudField[]
      actions?: HelpCrudAction[]
      drawerSize?: string | number
      allowCreate?: boolean
      allowEdit?: boolean
      allowDelete?: boolean
    }>(),
    {
      actions: () => [],
      drawerSize: '720px',
      allowCreate: true,
      allowEdit: true,
      allowDelete: true
    }
  )

  const searchFields = computed(() =>
    props.fields.filter((field) => field.search !== false && field.search === true)
  )
  const tableFields = computed(() => props.fields.filter((field) => field.table !== false))
  const formFields = computed(() =>
    props.fields.filter((field) => field.form === true && !field.readonly)
  )
  const detailFields = computed(() => props.fields.filter((field) => field.detail !== false))

  const searchForm = reactive<Record<string, any>>({})
  searchFields.value.forEach((field) => {
    searchForm[field.prop] = undefined
  })

  const permission = (action: string) => props.permissionPrefix + ':' + action

  const handleSearch = () => {
    Object.assign(searchParams, searchForm)
    getData()
  }

  const handleReset = () => {
    Object.keys(searchForm).forEach((key) => {
      searchForm[key] = undefined
    })
    resetSearchParams()
  }

  const {
    columns,
    columnChecks,
    data,
    loading,
    getData,
    searchParams,
    pagination,
    resetSearchParams,
    handleSortChange,
    handleSizeChange,
    handleCurrentChange,
    refreshData
  } = useTable({
    core: {
      apiFn: props.api.list,
      columnsFactory: () => [
        { type: 'selection' },
        ...tableFields.value.map((field) => ({
          prop: field.prop,
          label: field.label,
          width: field.width,
          minWidth: field.minWidth || 120,
          useSlot: true
        })),
        {
          prop: 'operation',
          label: '操作',
          width: props.actions.length > 0 ? 300 : 190,
          fixed: 'right',
          useSlot: true
        }
      ]
    }
  })

  const { deleteRow, deleteSelectedRows, handleSelectionChange, selectedRows } = useSaiAdmin()
  const tableData = computed(() => data.value as Record<string, any>[])

  const formRef = ref<FormInstance>()
  const formVisible = ref(false)
  const dialogType = ref<'add' | 'edit'>('add')
  const formData = ref<Record<string, any>>({})
  const submitLoading = ref(false)
  const detailVisible = ref(false)
  const detailData = ref<Record<string, any>>({})

  const isFieldDisabled = (field: HelpCrudField) =>
    dialogType.value === 'edit' && field.editReadonly === true

  const rules = computed<FormRules>(() => {
    const nextRules: FormRules = {}
    formFields.value.forEach((field) => {
      const fieldRules: NonNullable<FormRules[string]> = []
      if (field.required) {
        fieldRules.push({ required: true, message: field.label + '必须填写', trigger: 'blur' })
      }
      if (field.type === 'json') {
        fieldRules.push({
          validator: (_rule, value, callback) => {
            if (value === undefined || value === null || value === '') {
              callback()
              return
            }
            if (typeof value !== 'string') {
              callback()
              return
            }
            try {
              JSON.parse(value)
              callback()
            } catch {
              callback(new Error(field.label + '必须是合法 JSON'))
            }
          },
          trigger: 'blur'
        })
      }
      if (fieldRules.length > 0) {
        nextRules[field.prop] = fieldRules
      }
    })
    return nextRules
  })

  const initialFormData = () => {
    const data: Record<string, any> = {}
    formFields.value.forEach((field) => {
      if (field.default !== undefined) {
        data[field.prop] = field.default
      } else if (field.type === 'number') {
        data[field.prop] = null
      } else {
        data[field.prop] = ''
      }
    })
    return data
  }

  const openForm = async (type: 'add' | 'edit', row?: Record<string, any>) => {
    dialogType.value = type
    if (type === 'edit' && row?.id !== undefined) {
      try {
        const detail = await props.api.read(row.id)
        formData.value = { ...initialFormData(), ...detail }
      } catch {
        formData.value = { ...initialFormData(), ...row }
      }
    } else {
      formData.value = initialFormData()
    }
    formVisible.value = true
  }

  const handleFormClose = () => {
    formVisible.value = false
    formRef.value?.clearValidate()
  }

  const handleSubmit = async () => {
    await formRef.value?.validate()
    submitLoading.value = true
    try {
      const payload = { ...formData.value }
      if (dialogType.value === 'edit') {
        await props.api.update(payload)
      } else {
        await props.api.save(payload)
      }
      ElMessage.success('保存成功')
      formVisible.value = false
      refreshData()
    } finally {
      submitLoading.value = false
    }
  }

  const openDetail = async (row: Record<string, any>) => {
    detailData.value = row?.id !== undefined ? await props.api.read(row.id) : row
    detailVisible.value = true
  }

  const visibleActions = (row: Record<string, any>) => {
    return props.actions.filter((action) => !action.visible || action.visible(row))
  }

  const runAction = async (action: HelpCrudAction, row: Record<string, any>) => {
    let promptValue: string | undefined
    if (action.prompt) {
      const result = await ElMessageBox.prompt(action.prompt.label, action.label, {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputType: action.prompt.inputType || 'text',
        inputPlaceholder: action.prompt.placeholder || '',
        inputValidator: action.prompt.required
          ? (value) => String(value || '').trim() !== '' || action.prompt?.label || '请输入内容'
          : undefined
      })
      promptValue = result.value
    } else {
      const message =
        typeof action.confirm === 'function'
          ? action.confirm(row)
          : action.confirm || '确定执行该操作吗？'
      await ElMessageBox.confirm(message, action.label, { type: 'warning' })
    }

    const payload = action.payload ? action.payload(row, promptValue) : { id: row.id }
    await props.api[action.method](payload)
    ElMessage.success('操作成功')
    refreshData()
  }

  const optionOf = (field: HelpCrudField, value: unknown) => {
    return field.options?.find((option) => String(option.value) === String(value))
  }

  const formatValue = (field: HelpCrudField, value: unknown) => {
    if (value === null || value === undefined || value === '') {
      return '-'
    }
    const option = optionOf(field, value)
    if (option) {
      return option.label
    }
    if (typeof value === 'object') {
      return JSON.stringify(value, null, 2)
    }
    if (field.type === 'json') {
      try {
        return JSON.stringify(JSON.parse(String(value)), null, 2)
      } catch {
        return String(value)
      }
    }
    return String(value)
  }

  const shortValue = (field: HelpCrudField, value: unknown) => {
    const text = formatValue(field, value)
    return text.length > 80 ? text.slice(0, 80) + '...' : text
  }

  const isLongValue = (field: HelpCrudField, value: unknown) => {
    return (
      field.type === 'textarea' || field.type === 'json' || formatValue(field, value).length > 80
    )
  }

  const shouldUseTag = (field: HelpCrudField) => {
    return (
      field.options !== undefined &&
      [
        'status',
        'audit_status',
        'media_type',
        'material_type',
        'is_public',
        'is_recommended',
        'message_type',
        'push_status',
        'is_read',
        'is_pushed',
        'is_active'
      ].includes(field.prop)
    )
  }

  const tagType = (field: HelpCrudField, value: unknown) => {
    return optionOf(field, value)?.tagType || 'info'
  }
</script>

<style scoped>
  .help-search-card {
    margin-bottom: 16px;
  }

  .help-search-control {
    width: 220px;
  }

  .help-form-control {
    width: 100%;
  }

  .help-row-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .help-detail-pre {
    max-width: 100%;
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-family: inherit;
  }
</style>
