import request from '@/utils/http'

export interface RuntimeConfigItem {
  id: number
  key: string
  name: string
  value: string
  input_type: string
  remark: string
  is_secret: boolean
  has_value: boolean
  options: Array<{ label: string; value: string }>
}

export interface RuntimeConfigGroup {
  id: number
  code: string
  name: string
  remark: string
  items: RuntimeConfigItem[]
}

/**
 * HelpSupport 运行配置 API接口
 */
export default {
  read() {
    return request.get<RuntimeConfigGroup[]>({
      url: '/app/help/admin/config/HelpRuntimeConfig/read'
    })
  },

  update(params: { configs: Record<string, Record<string, string>> }) {
    return request.post<any>({
      url: '/app/help/admin/config/HelpRuntimeConfig/update',
      data: params
    })
  }
}
