<template>
  <div class="art-card p-5 mb-5 max-sm:mb-4">
    <div class="flex-b gap-6 max-md:flex-col max-md:items-start">
      <div>
        <h2 class="text-2xl font-medium">运营地图</h2>
        <p class="text-g-700 mt-1">
          {{ systemName }} 当前工作台聚合社区、内容、医生服务、康复计划、AI
          咨询、推送触达与风险治理。
        </p>
        <p class="text-g-700 mt-1">
          管理员可以先看运营指标，再进入对应业务页处理帖子、举报、预约、素材、消息和配置。
        </p>
      </div>
      <ElTag type="success" effect="light">运营驾驶舱</ElTag>
    </div>

    <div class="info-grid mt-6">
      <div v-for="item in infoList" :key="item.label" class="info-item">
        <div class="flex-c">
          <ArtSvgIcon :icon="item.icon" class="text-xl text-theme" />
          <span class="ml-2 text-g-600 text-sm">{{ item.label }}</span>
        </div>
        <p class="mt-3 text-lg font-medium text-g-900">{{ item.value }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
  import AppConfig from '@/config'

  const systemName = AppConfig.systemInfo.name

  const infoList = [
    { label: '社区增长', value: '帖子、评论、标签、举报', icon: 'ri:article-line' },
    { label: '服务履约', value: '医生、排班、预约、患者', icon: 'ri:user-heart-line' },
    { label: '康复留存', value: '计划、任务、评估、目标', icon: 'ri:calendar-check-line' },
    { label: '触达转化', value: '消息、推送、AI 会话', icon: 'ri:notification-3-line' }
  ]
</script>

<style lang="scss" scoped>
  .info-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
  }

  .info-item {
    min-width: 0;
    padding: 16px;
    border: 1px solid var(--default-border);
    border-radius: 10px;
    background: var(--default-bg-color);
  }

  @media (max-width: 1100px) {
    .info-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }
  }

  @media (max-width: 640px) {
    .info-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
