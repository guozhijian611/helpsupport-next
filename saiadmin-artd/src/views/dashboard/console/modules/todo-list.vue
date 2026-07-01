<template>
  <div class="art-card action-card p-5 mb-5 max-sm:mb-4">
    <div class="art-card-header">
      <div class="title">
        <h4>今日动作</h4>
        <p
          >待处理<span class="text-danger">{{ pendingCount }}</span></p
        >
      </div>
    </div>

    <div class="overflow-auto">
      <ElScrollbar>
        <div
          class="flex-cb h-17.5 border-b border-g-300 text-sm last:border-b-0"
          v-for="(item, index) in list"
          :key="index"
        >
          <div>
            <p class="text-sm">{{ item.title }}</p>
            <p class="text-g-500 mt-1">{{ item.description }}</p>
          </div>
          <ElCheckbox v-model="item.complete" />
        </div>
      </ElScrollbar>
    </div>
  </div>
</template>

<script setup lang="ts">
  interface TodoItem {
    title: string
    description: string
    complete: boolean
  }

  const list = reactive<TodoItem[]>([
    {
      title: '看帖子热榜',
      description: '找可推荐内容和异常互动',
      complete: true
    },
    {
      title: '清空举报队列',
      description: '先处理帖子和评论举报',
      complete: false
    },
    {
      title: '复核待审评论',
      description: '处理 AI 标记与用户反馈',
      complete: false
    },
    {
      title: '跟进医生预约',
      description: '待确认和待完成订单',
      complete: true
    },
    {
      title: '补齐内容供给',
      description: '素材分类、封面、摘要、多语言',
      complete: false
    },
    {
      title: '复盘推送触达',
      description: '失败推送、未读消息、设备偏好',
      complete: false
    }
  ])

  const pendingCount = computed(() => list.filter((item) => !item.complete).length)
</script>

<style lang="scss" scoped>
  .action-card {
    min-height: 360px;
  }
</style>
