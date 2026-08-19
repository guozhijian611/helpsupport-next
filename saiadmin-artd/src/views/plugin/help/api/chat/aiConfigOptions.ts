import configApi from '@/views/plugin/saiai/api/config/config'

export async function loadAiConfigs(type?: string) {
  const result = await configApi.list({ page: 1, limit: 200, type, saiType: 'all' })
  const list = Array.isArray(result) ? result : ((result as any)?.data ?? [])
  return (Array.isArray(list) ? list : []).map((item: any) => ({
    label: `${item.name} (#${item.id})`,
    value: Number(item.id)
  }))
}
