import request from '@/utils/http'

/**
 * 会员评估结果 API 接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/plan/SaMemberAssessmentResult/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/plan/SaMemberAssessmentResult/read?id=' + id
    })
  },

  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/plan/SaMemberAssessmentResult/save',
      data: params
    })
  },

  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/plan/SaMemberAssessmentResult/update',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/plan/SaMemberAssessmentResult/destroy',
      data: params
    })
  }
}
