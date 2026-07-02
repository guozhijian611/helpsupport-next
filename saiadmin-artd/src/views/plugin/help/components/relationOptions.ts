import request from '@/utils/http'
import type { HelpCrudField, HelpCrudOption } from './helpCrudTypes'

export type HelpRelationType = Exclude<HelpCrudField['relation'], false | undefined>

const relationUrls: Record<HelpRelationType, string> = {
  member: '/app/saiuser/admin/member/Member/index',
  doctor: '/app/help/admin/audit/SaHelpDoctorProfile/index',
  doctorSchedule: '/app/help/admin/appointment/SaDoctorSchedule/index',
  treatmentPlan: '/app/help/admin/plan/SaTreatmentPlan/index',
  treatmentStage: '/app/help/admin/plan/SaTreatmentStage/index',
  dailyTask: '/app/help/admin/plan/SaDailyTask/index',
  assessmentScale: '/app/help/admin/doctor/SaDoctorAssessmentScale/index',
  contentCategory: '/app/help/admin/material/SaContentCategory/index',
  contentMaterial: '/app/help/admin/material/SaContentMaterial/index',
  communityPost: '/app/help/admin/community/SaCommunityPost/index',
  communityComment: '/app/help/admin/community/SaCommunityComment/index',
  chatSession: '/app/help/admin/chat/SaMemberChatSession/index',
  localModelCatalog: '/app/help/admin/localModel/SaLocalModelCatalog/index',
  taskTemplateFolder: '/app/help/admin/doctor/SaDoctorTaskTemplateFolder/index',
  badgeRule: '/app/help/admin/gamification/SaMemberBadgeRule/index',
  memberLevel: '/app/saiuser/admin/setting/MemberLevel/index'
}

const optionCache: Partial<Record<HelpRelationType, HelpCrudOption[]>> = {}

export function inferRelationType(field: HelpCrudField): HelpRelationType | undefined {
  if (field.relation === false) {
    return undefined
  }
  if (field.relation) {
    return field.relation
  }

  const label = field.label || ''
  const prop = field.prop
  if (prop === 'member_id') {
    return label.includes('医生') ? 'doctor' : 'member'
  }
  if (prop === 'doctor_id') return 'doctor'
  if (prop === 'schedule_id') return 'doctorSchedule'
  if (prop === 'plan_id') return 'treatmentPlan'
  if (prop === 'stage_id') return 'treatmentStage'
  if (prop === 'task_id') return 'dailyTask'
  if (prop === 'assessment_id' || prop === 'scale_id') return 'assessmentScale'
  if (prop === 'category_id' || prop === 'parent_id') return 'contentCategory'
  if (prop === 'material_id') return 'contentMaterial'
  if (prop === 'post_id') return 'communityPost'
  if (prop === 'comment_id') return 'communityComment'
  if (prop === 'session_id') return 'chatSession'
  if (prop === 'model_id') return 'localModelCatalog'
  if (prop === 'folder_id') return 'taskTemplateFolder'
  if (prop === 'rule_id') return 'badgeRule'
  if (prop === 'member_level_id' || prop === 'grant_level_id') return 'memberLevel'
  return undefined
}

export async function loadRelationOptions(type: HelpRelationType): Promise<HelpCrudOption[]> {
  if (optionCache[type]) {
    return optionCache[type] || []
  }

  try {
    const response = await request.get<unknown>({
      url: relationUrls[type],
      params: { saiType: 'all', page: 1, limit: 500 }
    })
    const rows = normalizeRows(response)
    optionCache[type] = rows.map((row) => toOption(type, row)).filter(Boolean) as HelpCrudOption[]
  } catch (error) {
    console.warn(`[help] 加载${type}关联选项失败`, error)
    optionCache[type] = []
  }

  return optionCache[type] || []
}

export function formatRelationValue(
  options: HelpCrudOption[],
  value: unknown,
  emptyText = '-'
): string {
  if (value === null || value === undefined || value === '') {
    return emptyText
  }
  const option = options.find((item) => String(item.value) === String(value))
  return option?.label || `#${value}`
}

function normalizeRows(response: unknown): Record<string, any>[] {
  if (Array.isArray(response)) {
    return response as Record<string, any>[]
  }
  const data = response as Record<string, any>
  const rows = data?.data || data?.list || data?.records || []
  return Array.isArray(rows) ? rows : []
}

function toOption(type: HelpRelationType, row: Record<string, any>): HelpCrudOption | null {
  const value = optionValue(type, row)
  if (value === null || value === undefined || value === '') {
    return null
  }

  return {
    label: relationLabel(type, row, value),
    value
  }
}

function optionValue(type: HelpRelationType, row: Record<string, any>): string | number | null {
  if (type === 'doctor') {
    return Number(row.member_id || 0) || null
  }
  return Number(row.id || 0) || null
}

function relationLabel(type: HelpRelationType, row: Record<string, any>, value: string | number) {
  const name = firstText(labelCandidates(type, row))
  return name ? `#${value} ${name}` : `#${value}`
}

function labelCandidates(type: HelpRelationType, row: Record<string, any>): unknown[] {
  const candidates: Record<HelpRelationType, unknown[]> = {
    member: [row.nickname, row.username, row.mobile, row.email],
    doctor: [row.real_name, row.doctor_name, row.member_name, row.nickname, row.username],
    doctorSchedule: [
      row.schedule_date && row.time_slot ? `${row.schedule_date} ${row.time_slot}` : '',
      row.schedule_date
    ],
    treatmentPlan: [row.title],
    treatmentStage: [row.stage_name, row.stage_key],
    dailyTask: [row.title, row.task_title],
    assessmentScale: [row.title],
    contentCategory: [row.name],
    contentMaterial: [row.title],
    communityPost: [row.title, row.content],
    communityComment: [row.content],
    chatSession: [row.session_name, row.chat_mode],
    localModelCatalog: [row.display_name, row.model_name, row.name],
    taskTemplateFolder: [row.name],
    badgeRule: [row.badge_name, row.rule_name, row.badge_code],
    memberLevel: [row.level_name, row.level_code]
  }
  return candidates[type]
}

function firstText(values: unknown[]) {
  for (const value of values) {
    const text = String(value || '').trim()
    if (text) {
      return text
    }
  }
  return ''
}
