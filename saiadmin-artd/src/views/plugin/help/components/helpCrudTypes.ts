export interface HelpCrudOption {
  label: string
  value: string | number
  tagType?: 'success' | 'warning' | 'danger' | 'info' | 'primary'
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
}

export interface CrudApi {
  list: (params: Record<string, any>) => Promise<any>
  read: (id: number | string) => Promise<any>
  save: (params: Record<string, any>) => Promise<any>
  update: (params: Record<string, any>) => Promise<any>
  delete: (params: Record<string, any>) => Promise<any>
  [key: string]: any
}
