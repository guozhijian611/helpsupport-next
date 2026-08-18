<template>
  <div class="storyboard">
    <div class="storyboard-head">
      <div>
        <b>播放顺序</b>
        <span class="storyboard-hint">按卡片左右拖拽调整 App 实际播放顺序，中英文会一起改序</span>
      </div>
      <ElButton v-permission="'help:config:page:save'" type="primary" plain @click="emit('add')">
        <template #icon>
          <ArtSvgIcon icon="ri:add-fill" />
        </template>
        新增一页
      </ElButton>
    </div>

    <div v-if="slides.length === 0" class="storyboard-empty">
      还没有引导页。先新增第一页，然后按播放顺序继续往后加。
    </div>

    <VueDraggable
      v-else
      :model-value="slides"
      :animation="200"
      handle=".drag-handle"
      class="storyboard-track"
      @start="handleDragStart"
      @update:model-value="handleDragUpdate"
      @end="handleDragEnd"
    >
      <div
        v-for="(slide, index) in slides"
        :key="representativeId(slide) || slide.sort"
        class="storyboard-card"
        :class="{ 'is-active': index === selectedIndex }"
        @click="emit('select', index)"
      >
        <div class="drag-handle" title="拖拽排序" @click.stop>
          <ArtSvgIcon icon="ri:drag-move-2-fill" />
        </div>
        <div class="storyboard-index">第 {{ index + 1 }} 页</div>
        <div class="storyboard-thumb">
          <img v-if="thumb(slide)" :src="thumb(slide)" alt="" />
          <div v-else class="storyboard-thumb-empty">未上传图片</div>
        </div>
        <div class="storyboard-title">{{ cardTitle(slide) }}</div>
        <div class="storyboard-action">
          {{ cardButton(slide) }}
        </div>
        <div class="storyboard-locales">
          <ElTag
            v-for="item in localeChips(slide)"
            :key="item.value"
            size="small"
            :type="item.present ? 'success' : 'info'"
            :effect="item.present ? 'light' : 'plain'"
          >
            {{ item.label }}{{ item.present ? '' : ' 未配置' }}
          </ElTag>
        </div>
        <div class="storyboard-actions" @click.stop>
          <ElButton
            v-permission="'help:config:page:update'"
            link
            type="primary"
            @click="emit('edit', index)"
          >
            编辑
          </ElButton>
          <ElButton
            v-if="missingPreferredLocales(slide).length > 0"
            v-permission="'help:config:page:save'"
            link
            type="warning"
            @click="emit('fill', index, missingPreferredLocales(slide)[0])"
          >
            补全{{ localeLabel(missingPreferredLocales(slide)[0]) }}
          </ElButton>
          <ElButton
            v-permission="'help:config:page:destroy'"
            link
            type="danger"
            @click="emit('remove', index)"
          >
            删除
          </ElButton>
        </div>
      </div>
    </VueDraggable>
  </div>
</template>

<script setup lang="ts">
  import { VueDraggable } from 'vue-draggable-plus'
  import {
    LOCALE_OPTIONS,
    actionTypeLabel,
    localeLabel,
    missingPreferredLocales,
    normalizeImageUrl,
    pickSlidePage,
    representativeId,
    type OnboardingSlide
  } from '../onboarding'

  interface Props {
    slides: OnboardingSlide[]
    locale: string
    selectedIndex: number
  }

  const props = defineProps<Props>()

  const emit = defineEmits<{
    'update:slides': [value: OnboardingSlide[]]
    select: [index: number]
    add: []
    edit: [index: number]
    fill: [index: number, locale: string]
    remove: [index: number]
    reorder: [slides: OnboardingSlide[]]
  }>()

  const pendingSlides = ref<OnboardingSlide[] | null>(null)
  const startIds = ref('')

  const handleDragStart = () => {
    startIds.value = props.slides.map((item) => String(representativeId(item))).join(',')
  }

  const handleDragUpdate = (value: OnboardingSlide[]) => {
    pendingSlides.value = value
    emit('update:slides', value)
  }

  const handleDragEnd = () => {
    if (!pendingSlides.value) return
    const nextIds = pendingSlides.value.map((item) => String(representativeId(item))).join(',')
    if (nextIds !== startIds.value) {
      emit('reorder', pendingSlides.value)
    }
    pendingSlides.value = null
  }

  const thumb = (slide: OnboardingSlide) => {
    const page = pickSlidePage(slide, props.locale)
    return page?.image ? normalizeImageUrl(page.image) : ''
  }

  const cardTitle = (slide: OnboardingSlide) => {
    return pickSlidePage(slide, props.locale)?.title || '未命名页面'
  }

  const cardButton = (slide: OnboardingSlide) => {
    const page = pickSlidePage(slide, props.locale)
    if (!page) return '未配置按钮'
    const action = actionTypeLabel(page.action_type)
    const text = page.button_text || '未填写文案'
    return `${text} · ${action}`
  }

  const localeChips = (slide: OnboardingSlide) => {
    return LOCALE_OPTIONS.map((item) => ({
      ...item,
      present: Boolean(slide.locales[item.value] || (item.value === 'zh-CN' && slide.locales.zh))
    }))
  }
</script>

<style scoped>
  .storyboard {
    min-width: 0;
    flex: 1;
  }

  .storyboard-head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 14px;
  }

  .storyboard-hint {
    display: block;
    margin-top: 4px;
    font-size: 12px;
    color: var(--el-text-color-secondary);
  }

  .storyboard-empty {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 220px;
    padding: 24px;
    border: 1px dashed var(--el-border-color);
    border-radius: 12px;
    color: var(--el-text-color-secondary);
    background: var(--el-fill-color-lighter);
  }

  .storyboard-track {
    display: flex;
    gap: 12px;
    overflow-x: auto;
    padding-bottom: 8px;
  }

  .storyboard-card {
    position: relative;
    flex: 0 0 196px;
    padding: 14px 12px 10px;
    border: 1px solid var(--el-border-color);
    border-radius: 14px;
    background: var(--el-bg-color);
    cursor: pointer;
    transition:
      border-color 0.2s,
      box-shadow 0.2s;
  }

  .storyboard-card.is-active {
    border-color: #ff9585;
    box-shadow: 0 0 0 3px rgb(255 149 133 / 18%);
  }

  .drag-handle {
    position: absolute;
    top: 8px;
    right: 8px;
    display: flex;
    width: 24px;
    height: 24px;
    align-items: center;
    justify-content: center;
    color: var(--el-text-color-secondary);
    cursor: grab;
  }

  .storyboard-index {
    font-size: 12px;
    color: var(--el-text-color-secondary);
  }

  .storyboard-thumb {
    display: flex;
    overflow: hidden;
    align-items: center;
    justify-content: center;
    height: 118px;
    margin: 10px 0;
    border-radius: 10px;
    background: linear-gradient(180deg, #ff9585, #fcb08e);
  }

  .storyboard-thumb img {
    max-width: 86%;
    max-height: 100%;
    object-fit: contain;
  }

  .storyboard-thumb-empty {
    font-size: 12px;
    color: rgb(255 255 255 / 78%);
  }

  .storyboard-title {
    overflow: hidden;
    font-weight: 600;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .storyboard-action {
    overflow: hidden;
    margin-top: 4px;
    font-size: 12px;
    color: var(--el-text-color-secondary);
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .storyboard-locales {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    margin-top: 8px;
  }

  .storyboard-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0 4px;
    margin-top: 4px;
  }
</style>
