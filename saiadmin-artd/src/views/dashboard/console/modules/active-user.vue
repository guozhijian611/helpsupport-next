<template>
  <div class="art-card queue-card p-5 box-border mb-5 max-sm:mb-4">
    <div class="art-card-header">
      <div class="title">
        <h4>待处理队列</h4>
        <p>影响运营响应速度的关键事项</p>
      </div>
    </div>

    <div v-loading="loading" class="mt-4 flex flex-col gap-4">
      <div
        v-for="item in queueItems"
        :key="item.label"
        class="queue-item"
        @click="goPage(item.path)"
      >
        <div class="flex-cb">
          <div class="flex-c min-w-0">
            <span class="icon-wrap" :class="item.type">
              <ArtSvgIcon :icon="item.icon" class="text-lg" />
            </span>
            <div class="min-w-0">
              <p class="font-medium text-g-900">{{ item.label }}</p>
              <p class="mt-1 text-xs text-g-600 truncate">{{ item.description }}</p>
            </div>
          </div>
          <div class="queue-count">
            <span>{{ item.value }}</span>
            <small>{{ item.unit }}</small>
          </div>
        </div>
        <ElProgress
          class="mt-3"
          :percentage="item.percent"
          :stroke-width="5"
          :show-text="false"
          :color="item.color"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
  import { useRouter } from 'vue-router'
  import { defaultResponseAdapter } from '@/utils/table/tableUtils'
  import appointmentApi from '@/views/plugin/help/api/appointment/doctorAppointment'
  import doctorProfileApi from '@/views/plugin/help/api/audit/profile'
  import postApi from '@/views/plugin/help/api/community/post'
  import reportApi from '@/views/plugin/help/api/community/report'

  interface QueueItem {
    label: string
    description: string
    value: number
    unit: string
    icon: string
    type: 'success' | 'warning' | 'primary' | 'info'
    percent: number
    color: string
    path: string
  }

  const router = useRouter()
  const loading = ref(false)
  const queueItems = ref<QueueItem[]>([
    {
      label: '举报待处理',
      description: '社区举报未处理会直接影响内容安全',
      value: 0,
      unit: '条',
      icon: 'ri:alarm-warning-line',
      type: 'warning',
      percent: 76,
      color: 'var(--art-warning)',
      path: '/helpsupport/community/report'
    },
    {
      label: '帖子待审核',
      description: '待审核帖子决定社区内容上架效率',
      value: 0,
      unit: '篇',
      icon: 'ri:article-line',
      type: 'primary',
      percent: 68,
      color: 'var(--art-primary)',
      path: '/helpsupport/community/post'
    },
    {
      label: '医生资质待审',
      description: '医生入驻审核影响咨询供给',
      value: 0,
      unit: '人',
      icon: 'ri:user-star-line',
      type: 'info',
      percent: 54,
      color: 'var(--art-info)',
      path: '/helpsupport/audit/profile'
    },
    {
      label: '预约待确认',
      description: '待确认预约影响患者服务履约',
      value: 0,
      unit: '单',
      icon: 'ri:calendar-event-line',
      type: 'success',
      percent: 82,
      color: 'var(--art-success)',
      path: '/helpsupport/appointment/doctorAppointment'
    }
  ])

  const getTotal = async (
    apiFn: (params: Record<string, any>) => Promise<unknown>,
    params = {}
  ) => {
    const response = await apiFn({ current: 1, size: 1, ...params })
    return defaultResponseAdapter(response).total || 0
  }

  const loadQueue = async () => {
    loading.value = true
    const results = await Promise.allSettled([
      getTotal(reportApi.list, { handle_status: 0 }),
      getTotal(postApi.list, { audit_status: 0 }),
      getTotal(doctorProfileApi.list, { audit_status: 0 }),
      getTotal(appointmentApi.list, { status: 0 })
    ])

    queueItems.value = queueItems.value.map((item, index) => ({
      ...item,
      value: results[index]?.status === 'fulfilled' ? results[index].value : 0
    }))
    loading.value = false
  }

  const goPage = (path: string) => {
    router.push(path)
  }

  onMounted(loadQueue)
</script>

<style lang="scss" scoped>
  .queue-item {
    min-width: 0;
    padding: 14px;
    border: 1px solid var(--default-border);
    border-radius: 10px;
    background: var(--default-bg-color);
    cursor: pointer;
    transition: all 0.2s;

    &:hover {
      border-color: var(--art-primary);
      transform: translateY(-1px);
    }
  }

  .queue-card {
    min-height: 420px;
  }

  .queue-count {
    flex: none;
    min-width: 54px;
    text-align: right;

    span {
      display: block;
      font-size: 22px;
      font-weight: 600;
      color: var(--art-gray-900);
      line-height: 1;
    }

    small {
      color: var(--art-gray-500);
    }
  }

  .icon-wrap {
    flex: none;
    width: 38px;
    height: 38px;
    margin-right: 12px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;

    &.success {
      color: var(--art-success);
      background: rgba(64, 190, 88, 0.1);
    }

    &.warning {
      color: var(--art-warning);
      background: rgba(245, 166, 35, 0.12);
    }

    &.primary {
      color: var(--art-primary);
      background: rgba(93, 135, 255, 0.1);
    }

    &.info {
      color: var(--art-info);
      background: rgba(56, 192, 252, 0.1);
    }
  }
</style>
