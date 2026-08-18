<template>
  <div class="art-full-height manual-page">
    <ElCard class="manual-card h-full" shadow="never">
      <template #header>
        <div class="manual-header">
          <div>
            <b>操作说明手册</b>
            <p class="manual-subtitle">给后台管理员阅读。内容来自内置 CMS，可在「用户帮助中心 / 帮助文章」中维护「后台操作手册」分类。</p>
          </div>
          <ElButton :loading="loading" @click="loadCatalog">
            <template #icon>
              <ArtSvgIcon icon="ri:refresh-line" />
            </template>
            刷新
          </ElButton>
        </div>
      </template>

      <div v-loading="loading" class="manual-body">
        <aside class="manual-aside">
          <ElInput
            v-model="keyword"
            clearable
            placeholder="搜索章节"
            class="manual-search"
          >
            <template #prefix>
              <ArtSvgIcon icon="ri:search-line" />
            </template>
          </ElInput>
          <ElScrollbar class="manual-nav">
            <ElEmpty v-if="filteredCategories.length === 0" description="暂无操作说明，请先在帮助文章中发布后台手册内容。" />
            <ElMenu
              v-else
              :key="menuKey"
              :default-openeds="openedCategoryIds"
              :default-active="activeId"
              @select="handleSelect"
            >
              <ElSubMenu
                v-for="category in filteredCategories"
                :key="category.id"
                :index="'c-' + category.id"
              >
                <template #title>{{ category.category_name }}</template>
                <ElMenuItem
                  v-for="articleItem in category.articles"
                  :key="articleItem.id"
                  :index="'a-' + articleItem.id"
                >
                  {{ articleItem.title }}
                </ElMenuItem>
              </ElSubMenu>
            </ElMenu>
          </ElScrollbar>
        </aside>

        <section class="manual-content">
          <ElEmpty v-if="!article && !reading" description="请选择左侧章节查看操作说明。" />
          <div v-else v-loading="reading" class="manual-article">
            <div class="manual-article-meta">
              <ElTag v-if="article?.category?.category_name" effect="plain">
                {{ article.category.category_name }}
              </ElTag>
              <span v-if="article?.update_time">更新于 {{ article.update_time }}</span>
            </div>
            <h1>{{ article?.title }}</h1>
            <p v-if="article?.describe" class="manual-describe">{{ article.describe }}</p>
            <div class="manual-html" v-html="article?.content"></div>
          </div>
        </section>
      </div>
    </ElCard>
  </div>
</template>

<script setup lang="ts">
  import api, { type ManualArticle, type ManualCategory } from '../../api/cms/manual'

  defineOptions({ name: 'SaiuserCmsManual' })

  const loading = ref(false)
  const reading = ref(false)
  const keyword = ref('')
  const categories = ref<ManualCategory[]>([])
  const article = ref<ManualArticle | null>(null)
  const activeId = ref('')
  const menuKey = ref(0)

  const openedCategoryIds = computed(() => categories.value.map((item) => 'c-' + item.id))

  const filteredCategories = computed(() => {
    const text = keyword.value.trim().toLowerCase()
    if (!text) {
      return categories.value
    }
    return categories.value
      .map((category) => ({
        ...category,
        articles: category.articles.filter((item) => {
          return (
            item.title.toLowerCase().includes(text) ||
            item.describe.toLowerCase().includes(text) ||
            category.category_name.toLowerCase().includes(text)
          )
        })
      }))
      .filter((category) => category.articles.length > 0)
  })

  const firstArticleId = computed(() => {
    for (const category of filteredCategories.value) {
      if (category.articles[0]?.id) {
        return category.articles[0].id
      }
    }
    return 0
  })

  const loadCatalog = async () => {
    loading.value = true
    try {
      const data = await api.catalog()
      categories.value = data?.categories || []
      if (firstArticleId.value > 0) {
        await loadArticle(firstArticleId.value)
      } else {
        article.value = null
        activeId.value = ''
      }
      menuKey.value += 1
    } finally {
      loading.value = false
    }
  }

  const loadArticle = async (id: number) => {
    reading.value = true
    try {
      article.value = await api.read(id)
      activeId.value = 'a-' + id
    } finally {
      reading.value = false
    }
  }

  const handleSelect = (index: string) => {
    if (!index.startsWith('a-')) {
      return
    }
    const id = Number(index.slice(2))
    if (!Number.isFinite(id) || id <= 0) {
      return
    }
    loadArticle(id)
  }

  onMounted(() => {
    loadCatalog()
  })
</script>

<style scoped>
  .manual-page {
    min-height: 0;
  }

  .manual-card {
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .manual-card :deep(.el-card__body) {
    flex: 1;
    min-height: 0;
    display: flex;
  }

  .manual-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
  }

  .manual-subtitle {
    margin: 6px 0 0;
    color: var(--el-text-color-secondary);
    font-size: 13px;
    font-weight: 400;
    line-height: 1.6;
  }

  .manual-body {
    display: grid;
    grid-template-columns: 280px minmax(0, 1fr);
    gap: 16px;
    width: 100%;
    min-height: 0;
  }

  .manual-aside {
    display: flex;
    flex-direction: column;
    min-height: 0;
    border-right: 1px solid var(--el-border-color-lighter);
    padding-right: 12px;
  }

  .manual-search {
    margin-bottom: 12px;
  }

  .manual-nav {
    flex: 1;
    min-height: 0;
  }

  .manual-content {
    min-width: 0;
    min-height: 0;
    overflow: auto;
    padding: 8px 8px 24px 4px;
  }

  .manual-article h1 {
    margin: 12px 0 8px;
    font-size: 24px;
    line-height: 1.4;
  }

  .manual-article-meta {
    display: flex;
    align-items: center;
    gap: 12px;
    color: var(--el-text-color-secondary);
    font-size: 13px;
  }

  .manual-describe {
    margin: 0 0 20px;
    color: var(--el-text-color-secondary);
    line-height: 1.7;
  }

  .manual-html {
    line-height: 1.8;
    color: var(--el-text-color-primary);
  }

  .manual-html :deep(h2),
  .manual-html :deep(h3) {
    margin: 24px 0 8px;
  }

  .manual-html :deep(p),
  .manual-html :deep(ul),
  .manual-html :deep(ol) {
    margin: 0 0 12px;
  }

  .manual-html :deep(li) {
    margin: 4px 0;
  }

  @media (max-width: 960px) {
    .manual-body {
      grid-template-columns: 1fr;
    }

    .manual-aside {
      border-right: 0;
      border-bottom: 1px solid var(--el-border-color-lighter);
      padding-right: 0;
      padding-bottom: 12px;
      max-height: 280px;
    }
  }
</style>
