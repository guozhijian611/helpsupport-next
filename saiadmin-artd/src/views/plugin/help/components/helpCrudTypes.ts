export interface HelpCrudOption {
  label: string
  value: string | number
  tagType?: 'success' | 'warning' | 'danger' | 'info' | 'primary'
  extra?: Record<string, unknown>
}

export interface HelpCrudField {
  prop: string
  label: string
  type?:
    | 'input'
    | 'textarea'
    | 'number'
    | 'select'
    | 'date'
    | 'datetime'
    | 'time'
    | 'json'
    | 'file'
    | 'image'
    | 'images'
    | 'icon'
    | 'materialPreview'
  table?: boolean
  form?: boolean
  search?: boolean
  detail?: boolean
  required?: boolean
  readonly?: boolean
  editReadonly?: boolean
  width?: number | string
  minWidth?: number | string
  span?: number
  rows?: number
  min?: number
  precision?: number
  default?: unknown
  placeholder?: string
  options?: HelpCrudOption[]
  fillFrom?: Record<string, string>
  relation?:
    | false
    | 'member'
    | 'doctor'
    | 'doctorSchedule'
    | 'treatmentPlan'
    | 'treatmentStage'
    | 'dailyTask'
    | 'assessmentScale'
    | 'contentCategory'
    | 'contentMaterial'
    | 'communityPost'
    | 'communityComment'
    | 'chatSession'
    | 'localModelCatalog'
    | 'taskTemplateFolder'
    | 'badgeRule'
    | 'memberLevel'
  accept?: string
  acceptHint?: string
  maxSize?: number
  drag?: boolean
}

export interface HelpCrudAction {
  label: string
  method: string
  type?: 'primary' | 'success' | 'warning' | 'danger' | 'info'
  permission?: string
  confirm?: string | ((row: Record<string, any>) => string)
  prompt?: {
    field: string
    label: string
    placeholder?: string
    inputType?: 'text' | 'textarea'
    required?: boolean
  }
  visible?: (row: Record<string, any>) => boolean
  payload?: (row: Record<string, any>, value?: string) => Record<string, any>
  onClick?: (row: Record<string, any>) => void | Promise<void>
}

export interface CrudApi {
  list: (params: Record<string, any>) => Promise<Api.Common.ApiPage>
  read: (id: number | string) => Promise<any>
  save: (params: Record<string, any>) => Promise<any>
  update: (params: Record<string, any>) => Promise<any>
  delete: (params: Record<string, any>) => Promise<any>
  [key: string]: any
}
