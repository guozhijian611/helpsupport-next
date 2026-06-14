import request from '@/utils/http'

/**
 * 社区举报处理 API接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/community/SaCommunityReport/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/community/SaCommunityReport/read?id=' + id
    })
  },

  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/community/SaCommunityReport/save',
      data: params
    })
  },

  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/community/SaCommunityReport/update',
      data: params
    })
  },

  handle(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/community/SaCommunityReport/handle',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/community/SaCommunityReport/destroy',
      data: params
    })
  }
}
