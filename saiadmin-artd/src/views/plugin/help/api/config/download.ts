import request from '@/utils/http'
import type { RuntimeConfigGroup } from './runtime'

/**
 * HelpSupport App 下载配置 API接口
 */
export default {
  read() {
    return request.get<RuntimeConfigGroup>({
      url: '/app/help/admin/config/HelpRuntimeConfig/readDownload'
    })
  },

  update(params: { config: Record<string, string> }) {
    return request.post<any>({
      url: '/app/help/admin/config/HelpRuntimeConfig/updateDownload',
      data: params
    })
  }
}
