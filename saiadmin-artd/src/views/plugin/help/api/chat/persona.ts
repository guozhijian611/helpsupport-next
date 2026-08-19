import request from '@/utils/http'
import { createCrudApi } from '../createCrudApi'

const personaApi = createCrudApi('/app/help/admin/chat/SaAiPersona', [])

export default {
  ...personaApi,
  options() {
    return request.get<Api.Common.ApiData[]>({
      url: '/app/help/admin/chat/SaAiPersona/options'
    })
  }
}

export const personaPromptApi = createCrudApi('/app/help/admin/chat/SaAiPersonaPrompt', [])
