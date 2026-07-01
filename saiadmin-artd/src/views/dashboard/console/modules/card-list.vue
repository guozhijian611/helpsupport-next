<template>
  <ElRow :gutter="20" class="flex">
    <ElCol v-for="item in statCards" :key="item.label" :sm="12" :md="6" :lg="6">
      <div
        class="art-card relative flex flex-col justify-center h-35 px-5 mb-5 max-sm:mb-4"
        v-loading="loading"
      >
        <span class="text-g-700 text-sm">{{ item.label }}</span>
        <ArtCountTo class="text-[26px] font-medium mt-2" :target="item.value" :duration="1300" />
        <div class="flex-c mt-1">
          <span class="text-xs text-g-600">{{ item.caption }}</span>
          <span class="ml-1 text-xs font-semibold" :class="item.trendClass">
            {{ item.trend }}
          </span>
        </div>
        <div
          class="absolute top-0 bottom-0 right-5 m-auto size-12.5 rounded-xl flex-cc bg-theme/10"
        >
          <ArtSvgIcon :icon="item.icon" class="text-xl text-theme" />
        </div>
      </div>
    </ElCol>
  </ElRow>
</template>

<script setup lang="ts">
  import { defaultResponseAdapter } from '@/utils/table/tableUtils'
  import chatSessionApi from '@/views/plugin/help/api/chat/session'
  import postApi from '@/views/plugin/help/api/community/post'
  import reportApi from '@/views/plugin/help/api/community/report'
  import materialApi from '@/views/plugin/help/api/material/content'

  interface StatCard {
    label: string
    value: number
    caption: string
    trend: string
    trendClass: string
    icon: string
  }

  const loading = ref(false)
  const statCards = ref<StatCard[]>([
    {
      label: '社区帖子',
      value: 0,
      caption: 'UGC 内容池',
      trend: '总量',
      trendClass: 'text-success',
      icon: 'ri:article-line'
    },
    {
      label: '待处理举报',
      value: 0,
      caption: '社区安全队列',
      trend: '优先',
      trendClass: 'text-danger',
      icon: 'ri:alarm-warning-line'
    },
    {
      label: 'AI 会话',
      value: 0,
      caption: '咨询互动规模',
      trend: '活跃',
      trendClass: 'text-success',
      icon: 'ri:chat-smile-3-line'
    },
    {
      label: '教育素材',
      value: 0,
      caption: '内容运营资产',
      trend: '可展示',
      trendClass: 'text-theme',
      icon: 'ri:book-open-line'
    }
  ])

  const getTotal = async (
    apiFn: (params: Record<string, any>) => Promise<unknown>,
    params = {}
  ) => {
    const response = await apiFn({ current: 1, size: 1, ...params })
    return defaultResponseAdapter(response).total || 0
  }

  const loadStats = async () => {
    loading.value = true
    const results = await Promise.allSettled([
      getTotal(postApi.list),
      getTotal(reportApi.list, { handle_status: 0 }),
      getTotal(chatSessionApi.list),
      getTotal(materialApi.list, { audit_status: 2, status: 1 })
    ])

    statCards.value = statCards.value.map((item, index) => ({
      ...item,
      value: results[index]?.status === 'fulfilled' ? results[index].value : 0
    }))
    loading.value = false
  }

  onMounted(loadStats)
</script>
