export interface ScaleOption {
  id: string
  label: string
  score: number
}

export interface ScaleQuestion {
  id: string
  title: string
  options: ScaleOption[]
  optionCount?: number
}

export interface ScaleScoreRule {
  label: string
  min_score: number
  max_score: number
  suggestion: string
}

export const SCALE_STAGE_OPTIONS = [
  { label: '建档评估', value: 'intake' },
  { label: '治疗期', value: 'treatment' },
  { label: '康复期', value: 'recovery' },
  { label: '维持期', value: 'maintenance' }
]

export const SCALE_STATUS_OPTIONS = [
  { label: '草稿', value: 'draft', tagType: 'warning' as const },
  { label: '已发布', value: 'published', tagType: 'success' as const },
  { label: '已禁用', value: 'disabled', tagType: 'info' as const }
]

export const LIKERT4_OPTIONS: Array<Pick<ScaleOption, 'label' | 'score'>> = [
  { label: '没有或很少', score: 0 },
  { label: '偶尔', score: 1 },
  { label: '经常', score: 2 },
  { label: '几乎每天', score: 3 }
]

export const FREQUENCY5_OPTIONS: Array<Pick<ScaleOption, 'label' | 'score'>> = [
  { label: '没有', score: 5 },
  { label: '偶尔', score: 4 },
  { label: '一般', score: 3 },
  { label: '有时', score: 2 },
  { label: '经常', score: 1 }
]

export function parseJsonList<T>(value: unknown): T[] {
  if (Array.isArray(value)) {
    return value as T[]
  }
  if (typeof value === 'string' && value.trim() !== '') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? (parsed as T[]) : []
    } catch {
      return []
    }
  }
  return []
}

export function createUid(prefix: string): string {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`
}

export function createOptions(
  templates: Array<Pick<ScaleOption, 'label' | 'score'>> = LIKERT4_OPTIONS
): ScaleOption[] {
  return templates.map((item, index) => ({
    id: createUid(`opt${index + 1}`),
    label: item.label,
    score: item.score
  }))
}

export function createEmptyQuestion(
  templates: Array<Pick<ScaleOption, 'label' | 'score'>> = LIKERT4_OPTIONS
): ScaleQuestion {
  const options = createOptions(templates)
  return {
    id: createUid('q'),
    title: '',
    options,
    optionCount: options.length
  }
}

export function createEmptyRule(): ScaleScoreRule {
  return {
    label: '',
    min_score: 0,
    max_score: 0,
    suggestion: ''
  }
}

export function normalizeQuestions(value: unknown): ScaleQuestion[] {
  return parseJsonList<Record<string, any>>(value).map((item, index) => {
    const options = parseJsonList<Record<string, any>>(item.options).map((option, optionIndex) => ({
      id: String(option.id || createUid(`opt${optionIndex + 1}`)),
      label: String(option.label || ''),
      score: Number(option.score ?? 0)
    }))
    return {
      id: String(item.id || createUid(`q${index + 1}`)),
      title: String(item.title || ''),
      options,
      optionCount: options.length
    }
  })
}

export function normalizeRules(value: unknown): ScaleScoreRule[] {
  return parseJsonList<Record<string, any>>(value).map((item) => ({
    label: String(item.label || ''),
    min_score: Number(item.min_score ?? item.minScore ?? 0),
    max_score: Number(item.max_score ?? item.maxScore ?? 0),
    suggestion: String(item.suggestion || '')
  }))
}

export function serializeQuestions(questions: ScaleQuestion[]): ScaleQuestion[] {
  return questions.map((question) => ({
    id: question.id,
    title: question.title.trim(),
    options: question.options.map((option) => ({
      id: option.id,
      label: option.label.trim(),
      score: Number(option.score ?? 0)
    })),
    optionCount: question.options.length
  }))
}

export function computeTotalScore(questions: ScaleQuestion[]): number {
  return questions.reduce((sum, question) => {
    const scores = question.options.map((option) => Number(option.score) || 0)
    return sum + (scores.length > 0 ? Math.max(...scores) : 0)
  }, 0)
}

export function questionCount(value: unknown): number {
  return normalizeQuestions(value).length
}

export function buildDefaultScoringRules(totalScore: number): ScaleScoreRule[] {
  const maxScore = Math.max(0, Number(totalScore) || 0)
  const mediumMin = Math.ceil(maxScore * 0.4)
  const highMin = Math.ceil(maxScore * 0.7)
  const mediumMax = Math.max(0, highMin - 1)
  const lightMax = Math.max(0, mediumMin - 1)

  return [
    {
      label: '轻度波动',
      min_score: 0,
      max_score: lightMax,
      suggestion: '当前状态相对稳定，继续保持现有治疗节奏即可。'
    },
    {
      label: '中度波动',
      min_score: mediumMin,
      max_score: mediumMax,
      suggestion: '建议保持规律记录和复测，观察近期情绪与睡眠波动。'
    },
    {
      label: '高风险',
      min_score: highMin,
      max_score: maxScore,
      suggestion: '建议尽快和医生或治疗师复盘当前状态，并及时调整治疗计划。'
    }
  ].filter((rule) => rule.min_score <= rule.max_score)
}

export function formatStage(stage: unknown): string {
  const value = String(stage || '').trim()
  if (!value) {
    return '-'
  }
  return SCALE_STAGE_OPTIONS.find((item) => item.value === value)?.label || value
}

export function formatStatus(status: unknown): string {
  const value = String(status || '').trim()
  return SCALE_STATUS_OPTIONS.find((item) => item.value === value)?.label || value || '-'
}

export function statusTagType(status: unknown): 'success' | 'warning' | 'info' {
  const value = String(status || '').trim()
  return SCALE_STATUS_OPTIONS.find((item) => item.value === value)?.tagType || 'info'
}

export function validateScaleContent(
  questions: ScaleQuestion[],
  rules: ScaleScoreRule[]
): string | null {
  for (const [index, question] of questions.entries()) {
    if (!question.title.trim()) {
      return `第 ${index + 1} 题还没有填写题目标题`
    }
    if (question.options.length < 2) {
      return `第 ${index + 1} 题至少需要 2 个选项`
    }
    if (question.options.some((option) => !option.label.trim())) {
      return `第 ${index + 1} 题存在未填写的选项文案`
    }
  }

  for (const [index, rule] of rules.entries()) {
    if (!rule.label.trim()) {
      return `第 ${index + 1} 条计分规则还没有填写等级名称`
    }
    if (Number(rule.min_score) > Number(rule.max_score)) {
      return `第 ${index + 1} 条计分规则的分值区间不正确`
    }
  }

  return null
}
