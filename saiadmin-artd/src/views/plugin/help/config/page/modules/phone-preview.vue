<template>
  <div class="phone-preview">
    <div class="phone-head">
      <b>手机预览</b>
      <span>{{ localeLabel(locale) }} · 第 {{ pageNumber }} / {{ total }} 页{{ actionHint ? ` · ${actionHint}` : '' }}</span>
    </div>
    <div class="phone-shell">
      <div class="phone-screen">
        <div class="phone-chrome">
          <span>{{ skipText }}</span>
          <span>{{ languageText }}</span>
        </div>
        <div v-if="page" class="phone-copy">
          <div class="phone-title">{{ page.title }}</div>
          <div class="phone-desc">{{ page.description }}</div>
        </div>
        <div v-else class="phone-empty">当前语言还没有这一页</div>
        <div class="phone-image" :style="imageBoxStyle">
          <img v-if="imageSrc" :src="imageSrc" alt="" />
          <ArtSvgIcon v-else icon="ri:image-line" class="phone-image-empty" />
        </div>
        <div v-if="page" class="phone-button">
          {{ page.button_text || continueText }}
        </div>
        <div class="phone-dots">
          <button
            v-for="index in total"
            :key="index"
            type="button"
            class="phone-dot"
            :class="{ 'is-active': index - 1 === selectedIndex }"
            @click="emit('select', index - 1)"
          />
        </div>
        <div v-if="fallbackHint" class="phone-fallback">{{ fallbackHint }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
  import { computed } from 'vue'
  import {
    actionTypeLabel,
    localeLabel,
    normalizeImageUrl,
    pickSlidePage,
    type OnboardingSlide
  } from '../onboarding'

  interface Props {
    slides: OnboardingSlide[]
    locale: string
    selectedIndex: number
  }

  const props = defineProps<Props>()

  const emit = defineEmits<{
    select: [index: number]
  }>()

  const total = computed(() => Math.max(props.slides.length, 1))
  const pageNumber = computed(() => (props.slides.length === 0 ? 0 : props.selectedIndex + 1))
  const slide = computed(() => props.slides[props.selectedIndex])
  const page = computed(() => pickSlidePage(slide.value, props.locale))
  const imageSrc = computed(() => (page.value?.image ? normalizeImageUrl(page.value.image) : ''))
  const skipText = computed(() => (props.locale.startsWith('zh') ? '跳过' : 'Skip'))
  const languageText = computed(() => (props.locale.startsWith('zh') ? '中文' : 'EN'))
  const continueText = computed(() => (props.locale.startsWith('zh') ? '继续' : 'Continue'))
  const actionHint = computed(() => {
    if (!page.value) return ''
    const action = actionTypeLabel(page.value.action_type)
    if (page.value.action_type === 'route' || page.value.action_type === 'external_url') {
      return page.value.action_value ? `${action} · ${page.value.action_value}` : action
    }
    return action
  })
  const fallbackHint = computed(() => {
    if (!page.value || page.value.locale === props.locale) return ''
    if (props.locale === 'zh-CN' && page.value.locale === 'zh') return ''
    return `当前语言未配置，预览使用 ${localeLabel(page.value.locale)}`
  })

  const imageBoxStyle = computed(() => {
    const index = props.selectedIndex
    const marker = `${page.value?.action_value ?? ''} ${page.value?.title ?? ''}`.toLowerCase()
    let variant = 'companion'
    if (index === 0 || (page.value?.sort ?? 100) <= 10 || marker.includes('welcome')) {
      variant = 'cat'
    } else if (index === 1 || (page.value?.sort ?? 100) <= 20 || marker.includes('plan')) {
      variant = 'dog'
    }
    const scale = 258 / 375
    const size =
      variant === 'cat'
        ? { width: 257, height: 220 }
        : variant === 'dog'
          ? { width: 215, height: 200 }
          : { width: 254.5, height: 190 }
    return {
      width: `${size.width * scale}px`,
      height: `${size.height * scale}px`
    }
  })
</script>

<style scoped>
  .phone-preview {
    flex: 0 0 300px;
    width: 300px;
  }

  .phone-head {
    margin-bottom: 14px;
  }

  .phone-head span {
    display: block;
    margin-top: 4px;
    font-size: 12px;
    color: var(--el-text-color-secondary);
  }

  .phone-shell {
    width: 270px;
    height: 560px;
    padding: 10px;
    margin: 0 auto;
    border: 3px solid #2b2f36;
    border-radius: 36px;
    background: #111318;
    box-shadow: 0 18px 40px rgb(48 50 54 / 18%);
  }

  .phone-screen {
    position: relative;
    overflow: hidden;
    width: 100%;
    height: 100%;
    border-radius: 26px;
    background: linear-gradient(180deg, #ff9585 0%, #fcb08e 100%);
    color: #fff;
  }

  .phone-chrome {
    display: flex;
    justify-content: space-between;
    padding: 18px 16px 0;
    font-size: 12px;
    font-weight: 700;
  }

  .phone-copy {
    padding: 28px 16px 0;
    text-align: center;
  }

  .phone-title {
    font-size: 18px;
    font-weight: 700;
    line-height: 1.2;
  }

  .phone-desc {
    margin-top: 8px;
    font-size: 11px;
    line-height: 1.35;
    color: rgb(255 255 255 / 78%);
  }

  .phone-empty {
    padding: 48px 16px 0;
    text-align: center;
    color: rgb(255 255 255 / 78%);
  }

  .phone-image {
    position: absolute;
    bottom: 128px;
    left: 50%;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    transform: translateX(-50%);
  }

  .phone-image img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }

  .phone-image-empty {
    font-size: 42px;
    color: rgb(255 255 255 / 72%);
  }

  .phone-button {
    position: absolute;
    right: 24px;
    bottom: 72px;
    left: 24px;
    display: flex;
    height: 44px;
    align-items: center;
    justify-content: center;
    padding: 0 12px;
    border: 2px solid #fff;
    border-radius: 999px;
    font-size: 13px;
    font-weight: 700;
    text-align: center;
  }

  .phone-dots {
    position: absolute;
    right: 0;
    bottom: 28px;
    left: 0;
    display: flex;
    justify-content: center;
    gap: 8px;
  }

  .phone-dot {
    width: 20px;
    height: 4px;
    padding: 0;
    border: 0;
    border-radius: 2px;
    background: rgb(255 255 255 / 40%);
    cursor: pointer;
  }

  .phone-dot.is-active {
    background: #fff;
  }

  .phone-fallback {
    position: absolute;
    right: 12px;
    bottom: 8px;
    left: 12px;
    font-size: 10px;
    text-align: center;
    color: rgb(255 255 255 / 82%);
  }
</style>
