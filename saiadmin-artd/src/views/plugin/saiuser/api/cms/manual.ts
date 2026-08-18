import request from '@/utils/http'

export interface ManualArticleSummary {
  id: number
  title: string
  describe: string
  sort: number
}

export interface ManualCategory {
  id: number
  category_name: string
  describe: string
  sort: number
  articles: ManualArticleSummary[]
}

export interface ManualCatalog {
  categories: ManualCategory[]
}

export interface ManualArticle {
  id: number
  category_id: number
  title: string
  author: string
  describe: string
  content: string
  update_time?: string
  category?: {
    id?: number
    category_name?: string
    describe?: string
  }
}

export default {
  catalog() {
    return request.get<ManualCatalog>({
      url: '/app/saiuser/admin/cms/Article/manual'
    })
  },
  read(id: number | string) {
    return request.get<ManualArticle>({
      url: '/app/saiuser/admin/cms/Article/manualRead',
      params: { id }
    })
  }
}
