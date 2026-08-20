<template>
  <div class="art-full-height">
    <ElCard class="art-card-xs flex flex-col h-full mt-0 runtime-card" shadow="never">
      <template #header>
        <div class="flex items-center justify-between gap-3">
          <b>运行配置</b>
          <ElSpace>
            <SaButton
              type="primary"
              icon="ri:refresh-line"
              :loading="loading"
              @click="loadConfig"
            />
            <ElButton
              v-permission="'help:config:runtime:update'"
              type="primary"
              :loading="saving"
              @click="handleSubmit"
            >
              <template #icon>
                <ArtSvgIcon icon="ri:save-3-line" />
              </template>
              保存修改
            </ElButton>
          </ElSpace>
        </div>
      </template>

      <div v-loading="loading" class="runtime-body">
        <ElTabs v-if="groups.length > 0" v-model="activeGroup" class="runtime-tabs">
          <ElTabPane
            v-for="group in groups"
            :key="group.code"
            :label="group.name"
            :name="group.code"
          >
            <ElForm label-width="180px" class="runtime-form">
              <ElFormItem
                v-for="item in group.items"
                :key="group.code + ':' + item.key"
                :label="item.name"
              >
                <ElSwitch
                  v-if="isSwitchItem(item)"
                  v-model="formValues[group.code][item.key]"
                  active-value="1"
                  inactive-value="2"
                  :active-text="switchTexts(group.code, item.key).active"
                  :inactive-text="switchTexts(group.code, item.key).inactive"
                  inline-prompt
                />
                <ElSelect
                  v-else-if="isMultiSelect(item)"
                  v-model="formValues[group.code][item.key]"
                  multiple
                  collapse-tags
                  collapse-tags-tooltip
                  filterable
                  class="runtime-select"
                  :placeholder="'请选择' + item.name"
                >
                  <ElOption
                    v-for="option in item.options"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </ElSelect>
                <ElSelect
                  v-else-if="group.code === 'help_ai_audit' && item.key === 'ai_config_id'"
                  v-model="formValues[group.code][item.key]"
                  filterable
                  class="runtime-select"
                  placeholder="请选择审核模型"
                  no-data-text="暂无可用于文本审核的已启用模型"
                >
                  <ElOption
                    v-for="option in aiModelOptions"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </ElSelect>
                <ElInput
                  v-else-if="item.input_type === 'number'"
                  v-model="formValues[group.code][item.key]"
                  type="number"
                  :min="numberLimits(group.code, item.key).min"
                  :max="numberLimits(group.code, item.key).max"
                  :step="numberLimits(group.code, item.key).step"
                  clearable
                  :placeholder="secretPlaceholder(item)"
                />
                <ElInput
                  v-else-if="item.input_type === 'textarea'"
                  v-model="formValues[group.code][item.key]"
                  type="textarea"
                  :autosize="{ minRows: item.is_secret ? 6 : 4, maxRows: 12 }"
                  :placeholder="secretPlaceholder(item)"
                />
                <ElSelect
                  v-else-if="item.options?.length"
                  v-model="formValues[group.code][item.key]"
                  filterable
                  class="runtime-select"
                  :placeholder="'请选择' + item.name"
                >
                  <ElOption
                    v-for="option in item.options"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </ElSelect>
                <ElInput
                  v-else
                  v-model="formValues[group.code][item.key]"
                  :show-password="item.is_secret"
                  clearable
                  :placeholder="secretPlaceholder(item)"
                />
                <div v-if="item.remark" class="runtime-help">{{ item.remark }}</div>
              </ElFormItem>
            </ElForm>
          </ElTabPane>
        </ElTabs>
        <ElEmpty v-else description="暂无配置" />
      </div>
    </ElCard>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import api, {
    type AiModelOption,
    type RuntimeConfigGroup,
    type RuntimeConfigItem
  } from '../../api/config/runtime'

  defineOptions({ name: 'HelpRuntimeConfig' })

  const PLAN_CARD_MULTI_KEYS = [
    'enabled_fields',
    'allowed_task_types',
    'allowed_reminders',
    'default_reminders'
  ]

  const loading = ref(false)
  const saving = ref(false)
  const groups = ref<RuntimeConfigGroup[]>([])
  const activeGroup = ref('')
  const aiModelOptions = ref<AiModelOption[]>([])
  const formValues = reactive<Record<string, Record<string, string | string[]>>>({})

  const loadConfig = async () => {
    loading.value = true
    try {
      const [data, models] = await Promise.all([api.read(), api.aiOptions()])
      groups.value = data
      aiModelOptions.value = models
      Object.keys(formValues).forEach((key) => delete formValues[key])
      groups.value.forEach((group) => {
        formValues[group.code] = {}
        group.items.forEach((item) => {
          const value = item.value ?? ''
          if (isMultiSelect(item)) {
            formValues[group.code][item.key] = splitCsv(value)
            return
          }
          formValues[group.code][item.key] =
            group.code === 'help_ai_audit' && item.key === 'ai_config_id' && value === '0'
              ? ''
              : value
        })
      })
      activeGroup.value = groups.value[0]?.code ?? ''
    } finally {
      loading.value = false
    }
  }

  const secretPlaceholder = (item: RuntimeConfigItem) => {
    if (!item.is_secret) {
      return '请输入' + item.name
    }

    return item.has_value ? '已配置，留空则不修改' : '请输入' + item.name
  }

  const isMultiSelect = (item: RuntimeConfigItem) => {
    return item.input_type === 'checkbox' || PLAN_CARD_MULTI_KEYS.includes(item.key)
  }

  const isSwitchItem = (item: RuntimeConfigItem) => {
    return item.key === 'enabled' || item.input_type === 'radio'
  }

  const splitCsv = (value: string) => {
    return value
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item !== '')
  }

  const switchTexts = (groupCode: string, key: string) => {
    if (groupCode === 'help_ai_plan_card' && key === 'default_requires_feedback') {
      return { active: '需要', inactive: '不需要' }
    }
    if (groupCode === 'help_ai_plan_card' && key === 'force_emit') {
      return { active: '强制', inactive: '按需' }
    }
    return { active: '启用', inactive: '禁用' }
  }

  const numberLimits = (groupCode: string, key: string) => {
    if (groupCode === 'help_ai_audit' && key === 'auto_pass_confidence') {
      return { min: 0.5, max: 1, step: 0.01 }
    }
    if (groupCode === 'help_ai_audit' && key === 'auto_reject_confidence') {
      return { min: 0.8, max: 1, step: 0.01 }
    }
    if (groupCode === 'help_ai_audit' && key === 'max_attempts') {
      return { min: 1, max: 5, step: 1 }
    }
    if (groupCode === 'help_ai_audit' && key === 'retry_delay_seconds') {
      return { min: 1, max: 300, step: 1 }
    }
    if (groupCode === 'help_ai_plan_card') {
      const limits: Record<string, { min: number; max: number; step: number }> = {
        min_tasks: { min: 0, max: 5, step: 1 },
        max_tasks: { min: 1, max: 5, step: 1 },
        title_max_length: { min: 10, max: 80, step: 1 },
        description_max_length: { min: 20, max: 1000, step: 1 },
        default_duration_minutes: { min: 0, max: 180, step: 5 },
        points_min: { min: 0, max: 100, step: 1 },
        points_max: { min: 1, max: 200, step: 1 },
        points_default: { min: 0, max: 200, step: 1 },
        feedback_prompt_max_length: { min: 0, max: 255, step: 1 }
      }
      return limits[key] || { min: 0, max: undefined, step: 1 }
    }
    return { min: 1, max: undefined, step: 1 }
  }

  const handleSubmit = async () => {
    saving.value = true
    try {
      const configs: Record<string, Record<string, string>> = {}
      Object.entries(formValues).forEach(([groupCode, values]) => {
        configs[groupCode] = {}
        Object.entries(values).forEach(([key, value]) => {
          configs[groupCode][key] = Array.isArray(value) ? value.join(',') : String(value ?? '')
        })
      })
      await api.update({ configs })
      ElMessage.success('保存成功')
      await loadConfig()
    } finally {
      saving.value = false
    }
  }

  onMounted(() => {
    loadConfig()
  })
</script>

<style scoped lang="scss">
  .runtime-card :deep(.el-card__body) {
    flex: 1;
    min-height: 0;
  }

  .runtime-body {
    height: 100%;
    min-height: 420px;
    overflow-y: auto;
  }

  .runtime-tabs {
    max-width: 980px;
  }

  .runtime-form {
    padding-top: 12px;
  }

  .runtime-select {
    width: 100%;
  }

  .runtime-help {
    width: 100%;
    padding-top: 6px;
    color: var(--art-gray-500);
    font-size: 12px;
    line-height: 1.5;
  }
</style>
