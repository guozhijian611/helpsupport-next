import request from '@/utils/http'
import type { CrudApi } from '../components/helpCrudTypes'

export function createCrudApi(baseUrl: string, actions: string[] = []): CrudApi {
  const api: CrudApi = {
    list(params: Record<string, any>) {
      return request.get<Api.Common.ApiPage>({ url: baseUrl + '/index', params })
    },
    read(id: number | string) {
      return request.get<Api.Common.ApiData>({ url: baseUrl + '/read?id=' + id })
    },
    save(params: Record<string, any>) {
      return request.post<any>({ url: baseUrl + '/save', data: params })
    },
    update(params: Record<string, any>) {
      return request.put<any>({ url: baseUrl + '/update', data: params })
    },
    delete(params: Record<string, any>) {
      return request.del<any>({ url: baseUrl + '/destroy', data: params })
    }
  }

  actions.forEach((action) => {
    api[action] = (params: Record<string, any>) =>
      request.post<any>({ url: baseUrl + '/' + action, data: params })
  })

  return api
}
