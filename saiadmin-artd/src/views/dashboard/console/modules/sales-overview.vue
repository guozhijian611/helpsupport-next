<template>
  <div class="art-card hot-card p-5 mb-5 max-sm:mb-4">
    <div class="art-card-header">
      <div class="title">
        <h4>帖子热榜</h4>
        <p>按浏览、点赞、评论综合排序，帮助运营快速发现高价值内容</p>
      </div>
      <ElButton type="primary" link @click="goPage('/helpsupport/community/post')">
        查看帖子
      </ElButton>
    </div>

    <ElSkeleton :loading="loading" animated :rows="5">
      <div class="hot-list">
        <div v-for="(item, index) in hotPosts" :key="item.id || index" class="hot-item">
          <div class="rank" :class="{ top: index < 3 }">{{ index + 1 }}</div>
          <div class="min-w-0 flex-1">
            <p class="truncate font-medium text-g-900">{{ item.content }}</p>
            <div class="mt-2 flex flex-wrap gap-3 text-xs text-g-600">
              <span>浏览 {{ item.view_count }}</span>
              <span>点赞 {{ item.like_count }}</span>
              <span>评论 {{ item.comment_count }}</span>
              <ElTag :type="auditStatusType(item.audit_status)" effect="light" size="small">
                {{ auditStatusText(item.audit_status) }}
              </ElTag>
            </div>
          </div>
          <div class="score">
            <span>{{ item.score }}</span>
            <small>热度</small>
          </div>
        </div>
        <ElEmpty v-if="!hotPosts.length" description="暂无帖子数据" :image-size="80" />
      </div>
    </ElSkeleton>
  </div>
</template>

<script setup lang="ts">
  import type { TagProps } from 'element-plus'
  import { useRouter } from 'vue-router'
  import { defaultResponseAdapter } from '@/utils/table/tableUtils'
  import postApi from '@/views/plugin/help/api/community/post'

  interface HotPost {
    id: number
    content: string
    view_count: number
    like_count: number
    comment_count: number
    audit_status: number
    score: number
  }

  const router = useRouter()
  const loading = ref(false)
  const hotPosts = ref<HotPost[]>([])

  const plainText = (content: unknown) =>
    String(content || '')
      .replace(/<[^>]+>/g, '')
      .trim() || '未命名帖子'

  const auditStatusText = (status: number) => {
    const map: Record<number, string> = {
      0: '待审核',
      1: '已通过',
      2: '已拒绝',
      3: 'AI标记'
    }
    return map[Number(status)] || '未知'
  }

  const auditStatusType = (status: number): TagProps['type'] => {
    const map: Record<number, TagProps['type']> = {
      0: 'warning',
      1: 'success',
      2: 'danger',
      3: 'info'
    }
    return map[Number(status)] || 'info'
  }

  const loadHotPosts = async () => {
    loading.value = true
    try {
      const response = await postApi.list({ current: 1, size: 12 })
      const rows = defaultResponseAdapter<Record<string, any>>(response).records || []
      hotPosts.value = rows
        .map((row) => {
          const viewCount = Number(row.view_count || 0)
          const likeCount = Number(row.like_count || 0)
          const commentCount = Number(row.comment_count || 0)
          return {
            id: Number(row.id || 0),
            content: plainText(row.content).slice(0, 80),
            view_count: viewCount,
            like_count: likeCount,
            comment_count: commentCount,
            audit_status: Number(row.audit_status || 0),
            score: viewCount + likeCount * 3 + commentCount * 5
          }
        })
        .sort((a, b) => b.score - a.score)
        .slice(0, 6)
    } finally {
      loading.value = false
    }
  }

  const goPage = (path: string) => {
    router.push(path)
  }

  onMounted(loadHotPosts)
</script>

<style lang="scss" scoped>
  .hot-card {
    min-height: 420px;
  }

  .hot-list {
    max-height: 330px;
    margin-top: 14px;
    overflow: auto;
  }

  .hot-item {
    display: flex;
    align-items: center;
    gap: 14px;
    min-width: 0;
    padding: 13px 0;
    border-bottom: 1px solid var(--default-border);

    &:last-child {
      border-bottom: 0;
    }
  }

  .rank {
    flex: none;
    width: 30px;
    height: 30px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--art-gray-700);
    background: var(--default-bg-color);

    &.top {
      color: #fff;
      background: var(--art-primary);
    }
  }

  .score {
    flex: none;
    width: 62px;
    text-align: right;

    span {
      display: block;
      font-size: 18px;
      font-weight: 600;
      color: var(--art-gray-900);
    }

    small {
      color: var(--art-gray-500);
    }
  }
</style>
