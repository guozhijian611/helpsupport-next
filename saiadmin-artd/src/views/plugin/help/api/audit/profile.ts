import request from '@/utils/http'

/**
 * 医生资质审核 API接口
 */
export default {
  /**
   * 获取数据列表
   * @param params 搜索参数
   * @returns 数据列表
   */
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/index',
      params
    })
  },

  /**
   * 读取数据
   * @param id 数据ID
   * @returns 数据详情
   */
  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/read?id=' + id
    })
  },

  /**
   * 创建数据
   * @param params 数据参数
   * @returns 执行结果
   */
  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/save',
      data: params
    })
  },

  /**
   * 更新数据
   * @param params 数据参数
   * @returns 执行结果
   */
  update(params: Record<string, any>) {
    return request.put<any>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/update',
      data: params
    })
  },

  /**
   * 删除数据
   * @param id 数据ID
   * @returns 执行结果
   */
  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/destroy',
      data: params
    })
  },

  /**
   * 审核医生资质
   * @param params 审核参数
   * @returns 执行结果
   */
  audit(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/audit/SaHelpDoctorProfile/audit',
      data: params
    })
  }
}
