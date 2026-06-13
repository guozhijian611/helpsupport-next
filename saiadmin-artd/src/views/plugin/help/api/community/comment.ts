import request from '@/utils/http'

/**
 * 社区评论管理 API接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/community/SaCommunityComment/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/community/SaCommunityComment/read?id=' + id
    })
  },

  audit(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/community/SaCommunityComment/audit',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/community/SaCommunityComment/destroy',
      data: params
    })
  }
}
