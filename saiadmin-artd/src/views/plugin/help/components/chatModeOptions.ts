export type HelpChatMode = 'doctor' | 'companion' | 'patient' | 'ai_doctor'

export const helpChatModeOptions: { label: string; value: HelpChatMode }[] = [
  { label: '医生模式', value: 'doctor' },
  { label: '陪伴模式', value: 'companion' },
  { label: '患者模式', value: 'patient' },
  { label: 'AI医生', value: 'ai_doctor' }
]

const helpChatModeLabelMap: Record<string, string> = Object.fromEntries(
  helpChatModeOptions.map((item) => [item.value, item.label])
)

export function helpChatModeLabel(mode?: string | null): string {
  if (!mode) {
    return ''
  }
  return helpChatModeLabelMap[mode] || mode
}
