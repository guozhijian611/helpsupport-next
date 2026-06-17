import request from '@/utils/http'

/**
 * 素材举报处理 API接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/material/SaMaterialReport/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/material/SaMaterialReport/read?id=' + id
    })
  },

  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/material/SaMaterialReport/save',
      data: params
    })
  },

  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/material/SaMaterialReport/update',
      data: params
    })
  },

  handle(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/material/SaMaterialReport/handle',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/material/SaMaterialReport/destroy',
      data: params
    })
  }
}
