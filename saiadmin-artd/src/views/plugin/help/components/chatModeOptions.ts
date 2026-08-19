import personaApi from '../api/chat/persona'

export type HelpChatMode = string

export const helpChatModeOptions: { label: string; value: string }[] = [
  { label: '医生模式', value: 'doctor' },
  { label: '陪伴模式', value: 'companion' },
  { label: '患者模式', value: 'patient' },
  { label: 'AI医生', value: 'ai_doctor' }
]

export function helpChatModeLabel(mode?: string | null): string {
  if (!mode) {
    return ''
  }
  return helpChatModeOptions.find((item) => item.value === mode)?.label || mode
}

let loaded = false
export async function loadHelpChatModeOptions() {
  if (loaded) {
    return helpChatModeOptions
  }
  try {
    const result = await personaApi.options()
    const list = Array.isArray(result) ? result : ((result as any)?.data ?? [])
    if (Array.isArray(list) && list.length > 0) {
      helpChatModeOptions.splice(0, helpChatModeOptions.length, ...list)
      loaded = true
    }
  } catch {
    // keep fallback options
  }
  return helpChatModeOptions
}
