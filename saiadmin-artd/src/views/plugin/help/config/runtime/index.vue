<template>
  <div class="art-full-height">
    <ElCard class="art-card-xs flex flex-col h-full mt-0 runtime-card" shadow="never">
      <template #header>
        <div class="flex items-center justify-between gap-3">
          <b>登录推送配置</b>
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
                  v-if="item.key === 'enabled'"
                  v-model="formValues[group.code][item.key]"
                  active-value="1"
                  inactive-value="2"
                  active-text="启用"
                  inactive-text="禁用"
                  inline-prompt
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
  import api, { type RuntimeConfigGroup, type RuntimeConfigItem } from '../../api/config/runtime'

  defineOptions({ name: 'HelpRuntimeConfig' })

  const loading = ref(false)
  const saving = ref(false)
  const groups = ref<RuntimeConfigGroup[]>([])
  const activeGroup = ref('')
  const formValues = reactive<Record<string, Record<string, string>>>({})

  const loadConfig = async () => {
    loading.value = true
    try {
      const data = await api.read()
      groups.value = data
      Object.keys(formValues).forEach((key) => delete formValues[key])
      groups.value.forEach((group) => {
        formValues[group.code] = {}
        group.items.forEach((item) => {
          formValues[group.code][item.key] = item.value ?? ''
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

  const handleSubmit = async () => {
    saving.value = true
    try {
      await api.update({ configs: formValues })
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
