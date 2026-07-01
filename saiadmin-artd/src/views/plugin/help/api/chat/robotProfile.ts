import request from '@/utils/http'

/**
 * AI机器人形象 API接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/chat/SaAiRobotProfile/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/chat/SaAiRobotProfile/read?id=' + id
    })
  },

  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/chat/SaAiRobotProfile/save',
      data: params
    })
  },

  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/chat/SaAiRobotProfile/update',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/chat/SaAiRobotProfile/destroy',
      data: params
    })
  }
}
