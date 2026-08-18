<template>
  <div class="art-full-height">
    <ElCard class="art-card-xs flex flex-col h-full mt-0 onboarding-card" shadow="never">
      <template #header>
        <div class="onboarding-toolbar">
          <div class="onboarding-filters">
            <b>App引导页</b>
            <ElSelect v-model="scene" class="onboarding-select" @change="handleFlowChange">
              <ElOption
                v-for="item in sceneOptions"
                :key="item.value"
                :label="item.label"
                :value="item.value"
              />
            </ElSelect>
            <ElSelect v-model="version" class="onboarding-select" @change="handleFlowChange">
              <ElOption
                v-for="item in versionOptions"
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
            <ElButton v-permission="'help:config:page:save'" @click="flowDialogVisible = true">
              <template #icon>
                <ArtSvgIcon icon="ri:stack-line" />
              </template>
              新增流程
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

    <ElDialog v-model="flowDialogVisible" title="新增引导流程" width="480px">
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
        <ElFormItem label="版本号">
          <ElInput v-model="newFlow.version" placeholder="留空表示默认版本" clearable />
        </ElFormItem>
        <ElFormItem v-if="slides.length > 0" label="复制当前">
          <ElSwitch v-model="newFlow.copy" active-text="复制当前页面" inactive-text="空白流程" />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <ElButton @click="flowDialogVisible = false">取消</ElButton>
        <ElButton type="primary" :loading="copying" @click="handleCreateFlow">确定</ElButton>
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
    pickSlidePage,
    representativeId,
    slideIds,
    sourceLocaleForFill,
    versionLabel,
    type OnboardingFlow,
    type OnboardingSlide,
    type OnboardingStoryboard
  } from './onboarding'

  const scene = ref('first_launch')
  const version = ref('')
  const previewLocale = ref('zh-CN')
  const loading = ref(false)
  const copying = ref(false)
  const selectedIndex = ref(0)
  const storyboard = ref<OnboardingStoryboard>(emptyStoryboard())
  const slides = ref<OnboardingSlide[]>([])
  const flows = ref<OnboardingFlow[]>([])
  const flowDialogVisible = ref(false)
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
    const items = flows.value
      .filter((item) => item.scene === scene.value)
      .map((item) => item.version)
    if (!items.includes(version.value)) {
      items.push(version.value)
    }
    const unique = [...new Set(items)]
    if (!unique.includes('')) unique.unshift('')
    return unique.map((item) => ({ label: versionLabel(item), value: item }))
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

  const handleCreateFlow = async () => {
    const targetScene = newFlow.scene || 'first_launch'
    const targetVersion = newFlow.version.trim()
    if (targetScene === scene.value && targetVersion === version.value) {
      ElMessage.warning('请换一个版本号，或选择其他场景')
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
        ElMessage.success('流程已复制')
      }
      scene.value = targetScene
      version.value = targetVersion
      flowDialogVisible.value = false
      newFlow.version = ''
      newFlow.copy = true
      selectedIndex.value = 0
      await loadStoryboard()
    } finally {
      copying.value = false
    }
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

  .onboarding-select {
    width: 160px;
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
