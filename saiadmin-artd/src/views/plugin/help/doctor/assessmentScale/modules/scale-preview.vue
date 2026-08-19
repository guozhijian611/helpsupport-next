<template>
  <div class="scale-preview">
    <div class="scale-preview-hero">
      <div class="scale-preview-hero__main">
        <h3>{{ title || '未命名量表' }}</h3>
        <p v-if="description" class="scale-preview-hero__desc">{{ description }}</p>
        <p v-else class="scale-preview-hero__desc is-empty">暂无简介</p>
      </div>
      <div class="scale-preview-hero__meta">
        <ElTag :type="statusTagType(status)" effect="light">{{ formatStatus(status) }}</ElTag>
        <ElTag type="primary" effect="plain">{{ formatStage(stage) }}</ElTag>
        <span>{{ questions.length }} 题</span>
        <span>总分 {{ totalScore || 0 }}</span>
      </div>
    </div>

    <ElDescriptions :column="2" border class="scale-preview-info">
      <ElDescriptionsItem label="所属医生">
        <span v-if="!doctorId">系统/未指定</span>
        <HelpRelationText v-else relation="doctor" :value="doctorId" />
      </ElDescriptionsItem>
      <ElDescriptionsItem label="发布时间">{{ publishedAt || '-' }}</ElDescriptionsItem>
      <ElDescriptionsItem v-if="remark" label="备注" :span="2">{{ remark }}</ElDescriptionsItem>
    </ElDescriptions>

    <section class="scale-preview-section">
      <div class="scale-preview-section__title">
        <span>题目</span>
        <ElTag size="small" type="info" effect="plain">{{ questions.length }}</ElTag>
      </div>
      <ElEmpty v-if="questions.length === 0" description="还没有配置题目" :image-size="72" />
      <div v-else class="scale-preview-list">
        <article
          v-for="(question, index) in questions"
          :key="question.id"
          class="scale-preview-card"
        >
          <header>
            <strong>题目 {{ index + 1 }}</strong>
            <span>{{ question.options.length }} 个选项</span>
          </header>
          <p>{{ question.title || '未填写题目标题' }}</p>
          <ul>
            <li v-for="option in question.options" :key="option.id">
              <span>{{ option.label || '未填写选项' }}</span>
              <ElTag size="small" effect="plain">{{ option.score }} 分</ElTag>
            </li>
          </ul>
        </article>
      </div>
    </section>

    <section class="scale-preview-section">
      <div class="scale-preview-section__title">
        <span>计分规则</span>
        <ElTag size="small" type="info" effect="plain">{{ scoringRule.length }}</ElTag>
      </div>
      <ElEmpty v-if="scoringRule.length === 0" description="还没有配置计分规则" :image-size="72" />
      <div v-else class="scale-preview-list">
        <article
          v-for="(rule, index) in scoringRule"
          :key="`${rule.label}-${index}`"
          class="scale-preview-card"
        >
          <header>
            <strong>{{ rule.label || `规则 ${index + 1}` }}</strong>
            <ElTag size="small" type="warning" effect="plain">
              {{ rule.min_score }} - {{ rule.max_score }} 分
            </ElTag>
          </header>
          <p>{{ rule.suggestion || '暂无建议' }}</p>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
  import HelpRelationText from '../../../components/HelpRelationText.vue'
  import {
    formatStage,
    formatStatus,
    statusTagType,
    type ScaleQuestion,
    type ScaleScoreRule
  } from './scaleHelpers'

  defineProps<{
    title?: string
    description?: string
    stage?: string
    status?: string
    totalScore?: number
    doctorId?: number
    questions: ScaleQuestion[]
    scoringRule: ScaleScoreRule[]
    remark?: string
    publishedAt?: string
  }>()
</script>

<style scoped>
  .scale-preview {
    display: flex;
    flex-direction: column;
    gap: 18px;
  }

  .scale-preview-hero {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    justify-content: space-between;
    padding: 18px 20px;
    background: var(--el-fill-color-blank);
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 12px;
  }

  .scale-preview-hero__main {
    flex: 1;
    min-width: 0;
  }

  .scale-preview-hero h3 {
    margin: 0 0 8px;
    font-size: 18px;
    line-height: 1.4;
  }

  .scale-preview-hero__desc {
    margin: 0;
    line-height: 1.7;
    color: var(--el-text-color-regular);
  }

  .scale-preview-hero__desc.is-empty {
    color: var(--el-text-color-placeholder);
  }

  .scale-preview-hero__meta {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    font-size: 13px;
    color: var(--el-text-color-secondary);
  }

  .scale-preview-info {
    width: 100%;
  }

  .scale-preview-section {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .scale-preview-section__title {
    display: flex;
    gap: 8px;
    align-items: center;
    font-size: 15px;
    font-weight: 600;
  }

  .scale-preview-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .scale-preview-card {
    padding: 14px 16px;
    background: var(--el-bg-color);
    border: 1px solid var(--el-border-color-lighter);
    border-radius: 10px;
  }

  .scale-preview-card header {
    display: flex;
    gap: 12px;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
    font-size: 13px;
    color: var(--el-text-color-secondary);
  }

  .scale-preview-card p {
    margin: 0 0 10px;
    line-height: 1.6;
  }

  .scale-preview-card ul {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 0;
    margin: 0;
    list-style: none;
  }

  .scale-preview-card li {
    display: flex;
    gap: 12px;
    align-items: center;
    justify-content: space-between;
    padding: 8px 10px;
    background: var(--el-fill-color-light);
    border-radius: 8px;
  }
</style>
