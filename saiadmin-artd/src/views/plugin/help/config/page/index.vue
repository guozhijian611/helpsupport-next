<template>
  <div class="art-full-height">
    <ElCard class="art-card-xs flex flex-col h-full mt-0 onboarding-card" shadow="never">
      <template #header>
        <div class="onboarding-toolbar">
          <div class="onboarding-filters">
            <b>App引导页</b>
            <span class="onboarding-field-label">场景</span>
            <ElSelect v-model="scene" class="onboarding-select" @change="handleFlowChange">
              <ElOption
                v-for="item in sceneOptions"
                :key="item.value"
                :label="item.label"
                :value="item.value"
              />
            </ElSelect>
            <ElRadioGroup v-model="previewLocale">
              <ElRadioButton v-for="item in LOCALE_OPTIONS" :key="item.value" :label="item.value">
                {{ item.label }}
              </ElRadioButton>
            </ElRadioGroup>
          </div>
          <ElSpace wrap>
            <ElButton :loading="loading" @click="loadStoryboard">
              <template #icon>
                <ArtSvgIcon icon="ri:refresh-line" />
              </template>
              刷新
            </ElButton>
            <ElButton v-permission="'help:config:page:save'" type="primary" @click="handleAddSlide">
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增一页
            </ElButton>
          </ElSpace>
        </div>
      </template>

      <div class="onboarding-version-bar">
        <div class="onboarding-version-main">
          <b>版本管理</b>
          <ElSelect
            v-model="version"
            class="onboarding-version-select"
            filterable
            @change="handleFlowChange"
          >
            <ElOption
              v-for="item in versionOptions"
              :key="item.value || '__default__'"
              :label="item.label"
              :value="item.value"
            />
          </ElSelect>
          <ElTag :type="versionTagType" effect="light">{{ versionRole(version) }}</ElTag>
          <span class="onboarding-version-meta">{{ slides.length }} 页</span>
        </div>
        <ElSpace wrap>
          <ElButton v-permission="'help:config:page:save'" @click="openCreateVersion">
            新建版本
          </ElButton>
          <ElButton
            v-permission="'help:config:page:update'"
            type="primary"
            plain
            :disabled="!canPublish"
            @click="handlePublishVersion"
          >
            发布到 App
          </ElButton>
          <ElButton
            v-permission="'help:config:page:update'"
            :disabled="!canRename"
            @click="openRenameVersion"
          >
            重命名
          </ElButton>
          <ElButton
            v-permission="'help:config:page:destroy'"
            type="danger"
            plain
            :disabled="slides.length === 0"
            @click="handleDestroyVersion"
          >
            删除此版本
          </ElButton>
        </ElSpace>
      </div>
      <p class="onboarding-version-hint">{{ versionHint }}</p>

      <div v-loading="loading" class="onboarding-body">
        <Storyboard
          :slides="slides"
          :locale="previewLocale"
          :selected-index="selectedIndex"
          @update:slides="handleSlidesUpdate"
          @select="selectedIndex = $event"
          @add="handleAddSlide"
          @edit="handleEditSlide"
          @fill="handleFillSlide"
          @remove="handleRemoveSlide"
          @reorder="handleReorder"
        />
        <PhonePreview
          :slides="slides"
          :locale="previewLocale"
          :selected-index="selectedIndex"
          @select="selectedIndex = $event"
        />
      </div>
    </ElCard>

    <EditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="loadStoryboard"
    />

    <ElDialog v-model="flowDialogVisible" title="新建引导页版本" width="480px">
      <ElForm label-width="108px">
        <ElFormItem label="场景">
          <ElSelect v-model="newFlow.scene" class="w-full">
            <ElOption
              v-for="item in SCENE_OPTIONS"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </ElSelect>
        </ElFormItem>
        <ElFormItem label="版本号" required>
          <ElInput v-model="newFlow.version" placeholder="例如 v2，不能与默认版本重名" clearable />
        </ElFormItem>
        <ElFormItem v-if="slides.length > 0" label="复制当前">
          <ElSwitch
            v-model="newFlow.copy"
            active-text="复制当前页面当草稿"
            inactive-text="从空白开始"
          />
        </ElFormItem>
      </ElForm>
      <p class="onboarding-dialog-hint">
        新版本先作为草稿编辑，不会立刻改 App。确认无误后再点「发布到 App」。
      </p>
      <template #footer>
        <ElButton @click="flowDialogVisible = false">取消</ElButton>
        <ElButton type="primary" :loading="copying" @click="handleCreateFlow">确定</ElButton>
      </template>
    </ElDialog>

    <ElDialog v-model="renameDialogVisible" title="重命名版本" width="420px">
      <ElForm label-width="108px">
        <ElFormItem label="当前版本">
          <span>{{ versionLabel(version) }}</span>
        </ElFormItem>
        <ElFormItem label="新版本号" required>
          <ElInput v-model="renameVersion" placeholder="例如 v3" clearable />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <ElButton @click="renameDialogVisible = false">取消</ElButton>
        <ElButton type="primary" :loading="renaming" @click="handleRenameVersion">确定</ElButton>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/config/page'
  import EditDialog from './modules/edit-dialog.vue'
  import PhonePreview from './modules/phone-preview.vue'
  import Storyboard from './modules/storyboard.vue'
  import {
    LOCALE_OPTIONS,
    SCENE_OPTIONS,
    emptyStoryboard,
    isPublishedVersion,
    pickSlidePage,
    representativeId,
    slideIds,
    sourceLocaleForFill,
    suggestNextVersion,
    versionLabel,
    versionOptionLabel,
    versionRole,
    type OnboardingFlow,
    type OnboardingSlide,
    type OnboardingStoryboard
  } from './onboarding'

  const scene = ref('first_launch')
  const version = ref('')
  const previewLocale = ref('zh-CN')
  const loading = ref(false)
  const copying = ref(false)
  const renaming = ref(false)
  const selectedIndex = ref(0)
  const storyboard = ref<OnboardingStoryboard>(emptyStoryboard())
  const slides = ref<OnboardingSlide[]>([])
  const flows = ref<OnboardingFlow[]>([])
  const flowDialogVisible = ref(false)
  const renameDialogVisible = ref(false)
  const renameVersion = ref('')
  const newFlow = reactive({
    scene: 'first_launch',
    version: '',
    copy: true
  })

  const { dialogType, dialogVisible, dialogData, showDialog } = useSaiAdmin()

  const sceneOptions = computed(() => {
    const values = new Set(SCENE_OPTIONS.map((item) => item.value))
    const extras = flows.value.map((item) => item.scene).filter((item) => item && !values.has(item))
    return [...SCENE_OPTIONS, ...extras.map((item) => ({ label: item, value: item }))]
  })

  const versionOptions = computed(() => {
    const sceneFlows = flows.value.filter((item) => item.scene === scene.value)
    const items = sceneFlows.map((item) => item.version)
    if (!items.includes(version.value)) {
      items.push(version.value)
    }
    const unique = [...new Set(items)]
    if (!unique.includes('')) unique.unshift('')
    const countMap = new Map(sceneFlows.map((item) => [item.version, item.slide_count]))
    return unique.map((item) => ({
      label: versionOptionLabel(
        item,
        item === version.value ? slides.value.length : countMap.get(item)
      ),
      value: item
    }))
  })

  const canPublish = computed(() => !isPublishedVersion(version.value) && slides.value.length > 0)
  const canRename = computed(() => !isPublishedVersion(version.value) && slides.value.length > 0)
  const versionTagType = computed(() => {
    if (isPublishedVersion(version.value)) return 'success'
    if (version.value.startsWith('archived-')) return 'info'
    return 'warning'
  })
  const versionHint = computed(() => {
    if (isPublishedVersion(version.value)) {
      return '这是 App 启动时正在播放的默认版本。如需改版，请先「新建版本」做成草稿，确认后再发布。'
    }
    if (version.value.startsWith('archived-')) {
      return `这是已归档的历史版本。需要重新上线时，点「发布到 App」，当前默认版本会再被归档。`
    }
    return `正在编辑草稿 ${versionLabel(version.value)}。这里的修改不会立刻影响 App，点「发布到 App」后才会替换默认版本。`
  })

  const handleFlowChange = () => {
    selectedIndex.value = 0
    loadStoryboard()
  }

  const syncSelectedPage = () => {
    if (selectedIndex.value >= slides.value.length) {
      selectedIndex.value = Math.max(slides.value.length - 1, 0)
    }
  }

  const loadStoryboard = async () => {
    loading.value = true
    try {
      const data = (await api.storyboard({
        scene: scene.value,
        version: version.value
      })) as OnboardingStoryboard
      storyboard.value = {
        ...emptyStoryboard(scene.value, version.value),
        ...data
      }
      slides.value = storyboard.value.slides ?? []
      flows.value = storyboard.value.flows ?? []
      scene.value = storyboard.value.scene || scene.value
      version.value = storyboard.value.version ?? version.value
      syncSelectedPage()
    } finally {
      loading.value = false
    }
  }

  const handleAddSlide = () => {
    const isFirst = slides.value.length === 0
    showDialog('add', {
      scene: scene.value,
      version: version.value,
      locale: previewLocale.value,
      sort: storyboard.value.next_sort || 10,
      action_type: isFirst ? 'next' : 'skip',
      status: 1
    })
  }

  const handleEditSlide = (index: number) => {
    const slide = slides.value[index]
    const page = pickSlidePage(slide, previewLocale.value)
    if (!page?.id) {
      const missing = previewLocale.value
      handleFillSlide(index, missing)
      return
    }
    selectedIndex.value = index
    showDialog('edit', { ...page })
  }

  const handleFillSlide = (index: number, locale: string) => {
    const slide = slides.value[index]
    const source = sourceLocaleForFill(slide, locale)
    selectedIndex.value = index
    showDialog('add', {
      scene: scene.value,
      version: version.value,
      locale,
      sort: slide.sort,
      title: source?.title ?? '',
      description: source?.description ?? '',
      image: source?.image ?? '',
      button_text: source?.button_text ?? '',
      action_type: source?.action_type ?? 'next',
      action_value: source?.action_value ?? '',
      status: source?.status ?? 1,
      start_time: source?.start_time ?? '',
      end_time: source?.end_time ?? ''
    })
  }

  const handleRemoveSlide = (index: number) => {
    const slide = slides.value[index]
    const ids = slideIds(slide)
    if (ids.length === 0) return
    ElMessageBox.confirm(`确定删除第 ${index + 1} 页及其全部语言配置吗？`, '删除引导页', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'error'
    }).then(async () => {
      await api.delete({ ids })
      ElMessage.success('删除成功')
      await loadStoryboard()
    })
  }

  const handleSlidesUpdate = (value: OnboardingSlide[]) => {
    const current = slides.value[selectedIndex.value]
    const currentId = current ? representativeId(current) : 0
    slides.value = value
    if (currentId > 0) {
      const nextIndex = value.findIndex((item) => representativeId(item) === currentId)
      if (nextIndex >= 0) {
        selectedIndex.value = nextIndex
      }
    }
  }

  const handleReorder = async (nextSlides: OnboardingSlide[]) => {
    const slideIdsInOrder = nextSlides.map((item) => representativeId(item)).filter((id) => id > 0)
    if (slideIdsInOrder.length === 0) return
    try {
      await api.reorder({
        scene: scene.value,
        version: version.value,
        slide_ids: slideIdsInOrder
      })
      ElMessage.success('播放顺序已更新')
      await loadStoryboard()
    } catch {
      await loadStoryboard()
    }
  }

  const openCreateVersion = () => {
    newFlow.scene = scene.value
    newFlow.version = suggestNextVersion(versionOptions.value.map((item) => item.value))
    newFlow.copy = slides.value.length > 0
    flowDialogVisible.value = true
  }

  const handleCreateFlow = async () => {
    const targetScene = newFlow.scene || 'first_launch'
    const targetVersion = newFlow.version.trim()
    if (!targetVersion) {
      ElMessage.warning('请填写版本号，例如 v2')
      return
    }
    if (targetScene === scene.value && targetVersion === version.value) {
      ElMessage.warning('请换一个版本号')
      return
    }
    copying.value = true
    try {
      if (newFlow.copy && slides.value.length > 0) {
        await api.copyFlow({
          source_scene: scene.value,
          source_version: version.value,
          scene: targetScene,
          version: targetVersion
        })
        ElMessage.success('已复制为草稿版本')
      }
      scene.value = targetScene
      version.value = targetVersion
      flowDialogVisible.value = false
      newFlow.copy = true
      selectedIndex.value = 0
      await loadStoryboard()
    } finally {
      copying.value = false
    }
  }

  const handlePublishVersion = () => {
    if (!canPublish.value) return
    ElMessageBox.confirm(
      `发布后，App 下次启动会播放「${versionLabel(version.value)}」。当前默认版本会自动归档，不会丢失。`,
      '发布到 App',
      {
        confirmButtonText: '发布',
        cancelButtonText: '取消',
        type: 'warning'
      }
    ).then(async () => {
      await api.publishFlow({
        scene: scene.value,
        version: version.value
      })
      ElMessage.success('已发布为 App 当前版本')
      version.value = ''
      selectedIndex.value = 0
      await loadStoryboard()
    })
  }

  const openRenameVersion = () => {
    renameVersion.value = version.value
    renameDialogVisible.value = true
  }

  const handleRenameVersion = async () => {
    const nextVersion = renameVersion.value.trim()
    if (!nextVersion) {
      ElMessage.warning('请填写新版本号')
      return
    }
    renaming.value = true
    try {
      await api.renameFlow({
        scene: scene.value,
        version: version.value,
        new_version: nextVersion
      })
      ElMessage.success('版本号已更新')
      version.value = nextVersion
      renameDialogVisible.value = false
      await loadStoryboard()
    } finally {
      renaming.value = false
    }
  }

  const handleDestroyVersion = () => {
    if (slides.value.length === 0) return
    const published = isPublishedVersion(version.value)
    const message = published
      ? '这是 App 正在使用的默认版本。删除后用户启动将看不到引导页，除非再发布其他版本。确定删除？'
      : `确定删除版本「${versionLabel(version.value)}」的全部 ${slides.value.length} 页吗？删除后后台不再显示。`
    ElMessageBox.confirm(message, '删除版本', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'error'
    }).then(async () => {
      await api.destroyFlow({
        scene: scene.value,
        version: version.value
      })
      ElMessage.success('版本已删除')
      version.value = ''
      selectedIndex.value = 0
      await loadStoryboard()
    })
  }

  watch(slides, () => {
    syncSelectedPage()
  })

  onMounted(() => {
    loadStoryboard()
  })
</script>

<style scoped>
  .onboarding-card {
    min-height: 0;
  }

  .onboarding-toolbar {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .onboarding-filters {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
  }

  .onboarding-field-label,
  .onboarding-version-meta,
  .onboarding-version-hint,
  .onboarding-dialog-hint {
    color: var(--el-text-color-secondary);
    font-size: 13px;
  }

  .onboarding-select {
    width: 160px;
  }

  .onboarding-version-bar {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 12px;
    margin-bottom: 8px;
    border-radius: 8px;
    background: var(--el-fill-color-light);
    border: 1px solid var(--el-border-color-lighter);
  }

  .onboarding-version-main {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
  }

  .onboarding-version-select {
    width: 280px;
  }

  .onboarding-version-hint {
    margin: 0 0 12px;
    line-height: 1.5;
  }

  .onboarding-dialog-hint {
    margin: 0;
    line-height: 1.5;
  }

  .onboarding-body {
    display: flex;
    gap: 20px;
    min-height: 0;
    align-items: stretch;
  }

  @media (max-width: 1100px) {
    .onboarding-body {
      flex-direction: column;
    }
  }
</style>
