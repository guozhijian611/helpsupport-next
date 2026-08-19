export interface MaterialPersonaIcon {
  name: string
  label: string
  keywords: string
}

export const materialPersonaIcons: MaterialPersonaIcon[] = [
  { name: 'smart_toy_rounded', label: '机器人', keywords: 'robot toy ai' },
  { name: 'psychology_rounded', label: '心理', keywords: 'psychology mind brain' },
  { name: 'self_improvement_rounded', label: '自我成长', keywords: 'improve growth' },
  { name: 'spa_rounded', label: '放松', keywords: 'spa relax' },
  { name: 'volunteer_activism_rounded', label: '关爱', keywords: 'care volunteer heart' },
  { name: 'favorite_rounded', label: '喜爱', keywords: 'favorite heart love' },
  { name: 'mood_rounded', label: '心情', keywords: 'mood smile' },
  { name: 'sentiment_satisfied_alt_rounded', label: '微笑', keywords: 'smile happy' },
  { name: 'support_agent_rounded', label: '支持顾问', keywords: 'support agent help' },
  { name: 'chat_rounded', label: '对话', keywords: 'chat message' },
  { name: 'forum_rounded', label: '讨论', keywords: 'forum discuss' },
  { name: 'record_voice_over_rounded', label: '语音', keywords: 'voice speak' },
  { name: 'medical_services_rounded', label: '医疗服务', keywords: 'medical doctor clinic' },
  { name: 'local_hospital_rounded', label: '医院', keywords: 'hospital' },
  { name: 'healing_rounded', label: '疗愈', keywords: 'heal recovery' },
  { name: 'health_and_safety_rounded', label: '健康安全', keywords: 'health safety' },
  { name: 'monitor_heart_rounded', label: '心率', keywords: 'heart monitor' },
  { name: 'medication_rounded', label: '药物', keywords: 'medicine pill' },
  { name: 'emergency_rounded', label: '急救', keywords: 'emergency' },
  { name: 'bloodtype_rounded', label: '血型', keywords: 'blood' },
  { name: 'accessibility_new_rounded', label: '无障碍', keywords: 'access' },
  { name: 'elderly_rounded', label: '长者', keywords: 'elderly senior' },
  { name: 'child_care_rounded', label: '照护', keywords: 'child care' },
  { name: 'family_restroom_rounded', label: '家庭', keywords: 'family' },
  { name: 'groups_rounded', label: '群体', keywords: 'group community' },
  { name: 'handshake_rounded', label: '握手', keywords: 'handshake trust' },
  { name: 'person_rounded', label: '人物', keywords: 'person user' },
  { name: 'face_rounded', label: '面孔', keywords: 'face' },
  { name: 'nightlight_rounded', label: '夜间', keywords: 'night moon' },
  { name: 'wb_sunny_rounded', label: '阳光', keywords: 'sun day' },
  { name: 'park_rounded', label: '公园', keywords: 'park nature' },
  { name: 'eco_rounded', label: '自然', keywords: 'eco leaf' },
  { name: 'water_drop_rounded', label: '水滴', keywords: 'water' },
  { name: 'coffee_rounded', label: '咖啡', keywords: 'coffee' },
  { name: 'music_note_rounded', label: '音乐', keywords: 'music' },
  { name: 'auto_awesome_rounded', label: '闪光', keywords: 'sparkle awesome' },
  { name: 'lightbulb_rounded', label: '灵感', keywords: 'idea light' },
  { name: 'menu_book_rounded', label: '书本', keywords: 'book read' },
  { name: 'school_rounded', label: '学习', keywords: 'school learn' },
  { name: 'assignment_rounded', label: '任务', keywords: 'task assignment' },
  { name: 'checklist_rounded', label: '清单', keywords: 'checklist' },
  { name: 'flag_rounded', label: '目标', keywords: 'flag goal' },
  { name: 'balance_rounded', label: '平衡', keywords: 'balance' },
  { name: 'privacy_tip_rounded', label: '隐私', keywords: 'privacy' },
  { name: 'shield_rounded', label: '保护', keywords: 'shield protect' },
  { name: 'home_rounded', label: '家', keywords: 'home' },
  { name: 'pets_rounded', label: '宠物', keywords: 'pet animal' },
  { name: 'sports_esports_rounded', label: '娱乐', keywords: 'game play' },
  { name: 'palette_rounded', label: '创作', keywords: 'art palette' }
]

export function materialIconifyName(name: string): string {
  if (name.endsWith('_rounded')) {
    return `ic:round-${name.slice(0, -8).replace(/_/g, '-')}`
  }
  if (name.endsWith('_outlined')) {
    return `ic:outline-${name.slice(0, -9).replace(/_/g, '-')}`
  }
  if (name.endsWith('_sharp')) {
    return `ic:sharp-${name.slice(0, -6).replace(/_/g, '-')}`
  }
  return `ic:baseline-${name.replace(/_/g, '-')}`
}

export function defaultPersonaIcon(code: string): string {
  if (code === 'doctor') return 'smart_toy_rounded'
  if (code === 'ai_doctor') return 'medical_services_rounded'
  if (code === 'patient') return 'healing_rounded'
  return 'volunteer_activism_rounded'
}
