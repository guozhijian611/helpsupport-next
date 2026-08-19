import request from '@/utils/http'

export type SpeechConfigItem = {
  id: number
  name: string
  model: string
  type: 'asr' | 'tts'
  status: number
  ai_url: string
  voice: string
}

export default {
  configs(type: 'asr' | 'tts') {
    return request.get<SpeechConfigItem[]>({
      url: '/app/saiai/admin/speech/SpeechTest/configs',
      params: { type }
    })
  },

  asr(data: FormData) {
    return request.post<{ text: string; config_id: number }>({
      url: '/app/saiai/admin/speech/SpeechTest/asr',
      data,
      timeout: 0
    })
  },

  tts(data: { config_id: number; text: string; voice?: string }) {
    return request.post<{
      audio_url: string
      audio_mime_type: string
      model: string
      voice: string
    }>({
      url: '/app/saiai/admin/speech/SpeechTest/tts',
      data,
      timeout: 0
    })
  }
}
