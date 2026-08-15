import request from '@/utils/http'

/**
 * 社区内容审核 API接口
 */
export default {
  /**
   * 获取数据列表
   * @param params 搜索参数
   * @returns 数据列表
   */
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/community/SaCommunityPost/index',
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
      url: '/app/help/admin/community/SaCommunityPost/read?id=' + id
    })
  },

  /**
   * 创建数据
   * @param params 数据参数
   * @returns 执行结果
   */
  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/community/SaCommunityPost/save',
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
      url: '/app/help/admin/community/SaCommunityPost/update',
      data: params
    })
  },

  /**
   * 审核帖子
   * @param params 审核参数
   * @returns 执行结果
   */
  audit(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/community/SaCommunityPost/audit',
      data: params
    })
  },

  aiAudit(id: number) {
    return request.post<{ task_id: number }>({
      url: '/app/help/admin/community/SaCommunityPost/aiAudit',
      data: { id }
    })
  },

  /**
   * 删除数据
   * @param id 数据ID
   * @returns 执行结果
   */
  delete(params: Record<string, any>) {
    return request.del<any>({
      url: '/app/help/admin/community/SaCommunityPost/destroy',
      data: params
    })
  }
}
