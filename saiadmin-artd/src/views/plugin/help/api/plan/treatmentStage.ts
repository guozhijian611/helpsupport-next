import request from '@/utils/http'

/**
 * 治疗阶段 API 接口
 */
export default {
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/plan/SaTreatmentStage/index',
      params
    })
  },

  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/plan/SaTreatmentStage/read?id=' + id
    })
  },

  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/plan/SaTreatmentStage/save',
      data: params
    })
  },

  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/plan/SaTreatmentStage/update',
      data: params
    })
  },

  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/plan/SaTreatmentStage/destroy',
      data: params
    })
  }
}
