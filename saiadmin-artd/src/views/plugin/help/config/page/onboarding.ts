export interface OnboardingPageRow {
  id?: number | null
  scene: string
  version: string
  locale: string
  title: string
  description: string
  image: string
  button_text: string
  action_type: string
  action_value: string
  sort: number
  status: number
  start_time?: string | null
  end_time?: string | null
}

export interface OnboardingSlide {
  sort: number
  locales: Record<string, OnboardingPageRow>
}

export interface OnboardingFlow {
  scene: string
  version: string
  slide_count: number
  locales: string[]
}

export interface OnboardingStoryboard {
  scene: string
  version: string
  locales: string[]
  next_sort: number
  slides: OnboardingSlide[]
  flows: OnboardingFlow[]
}

export const SCENE_OPTIONS = [{ label: '首次启动', value: 'first_launch' }]

export const LOCALE_OPTIONS = [
  { label: '简体中文', value: 'zh-CN' },
  { label: 'English', value: 'en-US' }
]

export const ACTION_TYPE_OPTIONS = [
  { label: '下一页', value: 'next' },
  { label: '跳过', value: 'skip' },
  { label: '跳转路由', value: 'route' },
  { label: '打开外链', value: 'external_url' }
]

export const PREFERRED_LOCALES = ['zh-CN', 'en-US'] as const

export function versionLabel(version: string): string {
  return version === '' ? '默认版本' : version
}

export function localeLabel(locale: string): string {
  return LOCALE_OPTIONS.find((item) => item.value === locale)?.label ?? locale
}

export function actionTypeLabel(type: string): string {
  return ACTION_TYPE_OPTIONS.find((item) => item.value === type)?.label ?? type
}

export function pickSlidePage(
  slide: OnboardingSlide | undefined,
  locale: string
): OnboardingPageRow | null {
  if (!slide) return null
  const locales = slide.locales
  if (locales[locale]) return locales[locale]
  if (locale.startsWith('zh') && locales['zh-CN']) return locales['zh-CN']
  if (locale.startsWith('zh') && locales.zh) return locales.zh
  if (locales['en-US']) return locales['en-US']
  return Object.values(locales)[0] ?? null
}

export function slideIds(slide: OnboardingSlide): number[] {
  return Object.values(slide.locales)
    .map((row) => Number(row.id ?? 0))
    .filter((id) => id > 0)
}

export function representativeId(slide: OnboardingSlide): number {
  for (const locale of ['zh-CN', 'en-US', 'zh']) {
    const id = Number(slide.locales[locale]?.id ?? 0)
    if (id > 0) return id
  }
  return slideIds(slide)[0] ?? 0
}

export function hasLocale(slide: OnboardingSlide, locale: string): boolean {
  if (slide.locales[locale]) return true
  return locale === 'zh-CN' && Boolean(slide.locales.zh)
}

export function missingPreferredLocales(slide: OnboardingSlide): string[] {
  return PREFERRED_LOCALES.filter((locale) => !hasLocale(slide, locale))
}

export function sourceLocaleForFill(
  slide: OnboardingSlide,
  locale: string
): OnboardingPageRow | null {
  if (locale.startsWith('zh')) {
    return slide.locales['zh-CN'] ?? slide.locales.zh ?? pickSlidePage(slide, locale)
  }
  return slide.locales['en-US'] ?? pickSlidePage(slide, locale)
}

export function normalizeImageUrl(url: string): string {
  if (!url) return ''
  if (/^(https?:)?\/\//.test(url) || url.startsWith('data:') || url.startsWith('blob:')) {
    return url
  }
  const base = String(import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
  if (url.startsWith('/') && base) {
    return `${base}${url}`
  }
  return url
}

export function emptyStoryboard(scene = 'first_launch', version = ''): OnboardingStoryboard {
  return {
    scene,
    version,
    locales: [],
    next_sort: 10,
    slides: [],
    flows: []
  }
}
