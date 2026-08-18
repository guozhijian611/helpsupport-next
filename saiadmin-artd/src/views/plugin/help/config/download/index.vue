<template>
  <div class="art-full-height">
    <ElCard class="art-card-xs flex flex-col h-full mt-0 download-card" shadow="never">
      <template #header>
        <div class="flex items-center justify-between gap-3">
          <b>App下载配置</b>
          <ElSpace wrap>
            <ElButton @click="previewDownloadPage">
              <template #icon>
                <ArtSvgIcon icon="ri:external-link-line" />
              </template>
              预览下载页面
            </ElButton>
            <ElButton @click="copyDownloadPageUrl">
              <template #icon>
                <ArtSvgIcon icon="ri:file-copy-line" />
              </template>
              复制公开地址
            </ElButton>
            <SaButton
              type="primary"
              icon="ri:refresh-line"
              :loading="loading"
              @click="loadConfig"
            />
            <ElButton
              v-permission="'help:config:download:update'"
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

      <div v-loading="loading" class="download-body">
        <div class="download-public">
          公开下载页：
          <a :href="downloadPageUrl" target="_blank" rel="noopener noreferrer">{{ downloadPageUrl }}</a>
        </div>
        <ElForm
          v-if="group.items.length > 0"
          ref="formRef"
          :model="formValues"
          label-width="170px"
          class="download-form"
        >
          <section class="download-section">
            <div class="section-title">正式版商店链接</div>
            <ElRow :gutter="20">
              <ElCol :xs="24" :lg="18">
                <ElFormItem label="Google Play 链接" prop="google_play_url">
                  <ElInput
                    v-model="formValues.google_play_url"
                    clearable
                    placeholder="请输入 Google Play 商店链接"
                  >
                    <template #append>
                      <ElButton
                        :disabled="!formValues.google_play_url"
                        @click="openUrl(formValues.google_play_url)"
                      >
                        打开
                      </ElButton>
                    </template>
                  </ElInput>
                  <div class="download-help">{{ itemRemark('google_play_url') }}</div>
                </ElFormItem>
              </ElCol>
              <ElCol :xs="24" :lg="18">
                <ElFormItem label="App Store 链接" prop="app_store_url">
                  <ElInput
                    v-model="formValues.app_store_url"
                    clearable
                    placeholder="请输入 App Store 商店链接"
                  >
                    <template #append>
                      <ElButton
                        :disabled="!formValues.app_store_url"
                        @click="openUrl(formValues.app_store_url)"
                      >
                        打开
                      </ElButton>
                    </template>
                  </ElInput>
                  <div class="download-help">{{ itemRemark('app_store_url') }}</div>
                </ElFormItem>
              </ElCol>
            </ElRow>
          </section>

          <section class="download-section">
            <div class="section-title">开发版安装包</div>
            <ElRow :gutter="20">
              <ElCol :xs="24" :lg="18">
                <ElFormItem label="开发版 APK" prop="dev_apk_url">
                  <div class="file-field">
                    <SaFileUpload
                      v-model="formValues.dev_apk_url"
                      accept=".apk"
                      accept-hint="APK"
                      :max-size="500"
                      button-text="上传 APK"
                    />
                    <ElInput
                      v-model="formValues.dev_apk_url"
                      clearable
                      placeholder="上传 APK 后自动填入，也可手动粘贴下载链接"
                    >
                      <template #append>
                        <ElButton
                          :disabled="!formValues.dev_apk_url"
                          @click="openUrl(formValues.dev_apk_url)"
                        >
                          打开
                        </ElButton>
                      </template>
                    </ElInput>
                  </div>
                  <div class="download-help">{{ itemRemark('dev_apk_url') }}</div>
                </ElFormItem>
              </ElCol>
              <ElCol :xs="24" :lg="18">
                <ElFormItem label="开发版 IPA" prop="dev_ipa_url">
                  <div class="file-field">
                    <SaFileUpload
                      v-model="formValues.dev_ipa_url"
                      accept=".ipa"
                      accept-hint="IPA"
                      :max-size="800"
                      button-text="上传 IPA"
                    />
                    <ElInput
                      v-model="formValues.dev_ipa_url"
                      clearable
                      placeholder="上传 IPA 后自动填入，也可手动粘贴下载链接"
                    >
                      <template #append>
                        <ElButton
                          :disabled="!formValues.dev_ipa_url"
                          @click="openUrl(formValues.dev_ipa_url)"
                        >
                          打开
                        </ElButton>
                      </template>
                    </ElInput>
                  </div>
                  <div class="download-help">{{ itemRemark('dev_ipa_url') }}</div>
                </ElFormItem>
              </ElCol>
            </ElRow>
          </section>
        </ElForm>
        <ElEmpty v-else description="暂无配置，请先执行数据库迁移" />
      </div>
    </ElCard>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage } from 'element-plus'
  import api from '../../api/config/download'
  import type { RuntimeConfigGroup, RuntimeConfigItem } from '../../api/config/runtime'

  defineOptions({ name: 'HelpAppDownloadConfig' })

  const emptyGroup: RuntimeConfigGroup = {
    id: 0,
    code: 'help_app_download',
    name: 'App下载配置',
    remark: '',
    items: []
  }

  const loading = ref(false)
  const saving = ref(false)
  const group = ref<RuntimeConfigGroup>({ ...emptyGroup })
  const formValues = reactive<Record<string, string>>({
    google_play_url: '',
    app_store_url: '',
    dev_apk_url: '',
    dev_ipa_url: ''
  })

  const itemMap = computed<Record<string, RuntimeConfigItem>>(() => {
    return group.value.items.reduce<Record<string, RuntimeConfigItem>>((map, item) => {
      map[item.key] = item
      return map
    }, {})
  })

  const loadConfig = async () => {
    loading.value = true
    try {
      const data = await api.read()
      group.value = data || { ...emptyGroup }
      Object.keys(formValues).forEach((key) => {
        formValues[key] = itemMap.value[key]?.value ?? ''
      })
    } finally {
      loading.value = false
    }
  }

  const itemRemark = (key: string) => itemMap.value[key]?.remark ?? ''

  const downloadPageUrl = computed(() => {
    const proxy = String(import.meta.env.VITE_API_PROXY_URL || '').replace(/\/$/, '')
    if (import.meta.env.DEV && proxy) {
      return `${proxy}/download`
    }
    return `${window.location.origin}/download`
  })

  const previewDownloadPage = () => {
    window.open(downloadPageUrl.value, '_blank', 'noopener,noreferrer')
  }

  const copyDownloadPageUrl = async () => {
    try {
      await navigator.clipboard.writeText(downloadPageUrl.value)
      ElMessage.success('已复制公开下载地址')
    } catch {
      ElMessage.error('复制失败，请手动复制地址')
    }
  }

  const openUrl = (url: string) => {
    const value = url.trim()
    if (!value) return
    window.open(value, '_blank')
  }

  const handleSubmit = async () => {
    saving.value = true
    try {
      await api.update({ config: formValues })
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
  .download-card :deep(.el-card__body) {
    flex: 1;
    min-height: 0;
  }

  .download-body {
    height: 100%;
    min-height: 420px;
    overflow-y: auto;
  }

  .download-public {
    max-width: 980px;
    padding: 4px 2px 14px;
    color: var(--art-gray-600);
    font-size: 13px;
    line-height: 1.6;

    a {
      color: var(--el-color-primary);
      word-break: break-all;
    }
  }

  .download-form {
    max-width: 980px;
    padding-top: 8px;
  }

  .download-section {
    padding: 10px 0 20px;
    border-bottom: 1px solid var(--default-border);

    &:last-child {
      border-bottom: 0;
    }
  }

  .section-title {
    margin: 0 0 16px 2px;
    color: var(--art-gray-900);
    font-size: 15px;
    font-weight: 600;
  }

  .file-field {
    display: grid;
    width: 100%;
    gap: 10px;
  }

  .download-help {
    width: 100%;
    padding-top: 6px;
    color: var(--art-gray-500);
    font-size: 12px;
    line-height: 1.5;
  }
</style>
