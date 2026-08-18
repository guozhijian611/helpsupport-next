import request from '@/utils/http'

/**
 * App引导页配置 API接口
 */
export default {
  /**
   * 获取数据列表
   * @param params 搜索参数
   * @returns 数据列表
   */
  list(params: Record<string, any>) {
    return request.get<Api.Common.ApiPage>({
      url: '/app/help/admin/config/SaAppOnboardingPage/index',
      params
    })
  },

  /**
   * 读取故事板
   */
  storyboard(params: { scene?: string; version?: string }) {
    return request.get<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/storyboard',
      params
    })
  },

  /**
   * 按播放顺序重排
   */
  reorder(params: { scene: string; version: string; slide_ids: number[] }) {
    return request.put<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/reorder',
      data: params
    })
  },

  /**
   * 复制整套流程
   */
  copyFlow(params: {
    source_scene: string
    source_version: string
    scene: string
    version: string
  }) {
    return request.post<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/copyFlow',
      data: params
    })
  },

  /**
   * 把草稿版本发布为 App 当前使用的默认版本
   */
  publishFlow(params: { scene: string; version: string }) {
    return request.post<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/publishFlow',
      data: params
    })
  },

  /**
   * 重命名草稿版本
   */
  renameFlow(params: { scene: string; version: string; new_version: string }) {
    return request.post<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/renameFlow',
      data: params
    })
  },

  /**
   * 删除整套版本
   */
  destroyFlow(params: { scene: string; version: string }) {
    return request.post<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/destroyFlow',
      data: params
    })
  },

  /**
   * 读取数据
   * @param id 数据ID
   * @returns 数据详情
   */
  read(id: number | string) {
    return request.get<Api.Common.ApiData>({
      url: '/app/help/admin/config/SaAppOnboardingPage/read?id=' + id
    })
  },

  /**
   * 创建数据
   * @param params 数据参数
   * @returns 执行结果
   */
  save(params: Record<string, any>) {
    return request.post<any>({
      url: '/app/help/admin/config/SaAppOnboardingPage/save',
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
      url: '/app/help/admin/config/SaAppOnboardingPage/update',
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
      url: '/app/help/admin/config/SaAppOnboardingPage/destroy',
      data: params
    })
  }
}
