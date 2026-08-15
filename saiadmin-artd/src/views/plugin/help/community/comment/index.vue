<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElButton
            v-permission="'help:community:comment:destroy'"
            :disabled="selectedRows.length === 0"
            @click="deleteSelectedRows(api.delete, refreshData)"
            v-ripple
          >
            <template #icon>
              <ArtSvgIcon icon="ri:delete-bin-5-line" />
            </template>
            删除
          </ElButton>
        </template>
      </ArtTableHeader>

      <ArtTable
        ref="tableRef"
        rowKey="id"
        :loading="loading"
        :data="data"
        :columns="columns"
        :pagination="pagination"
        @sort-change="handleSortChange"
        @selection-change="handleSelectionChange"
        @pagination:size-change="handleSizeChange"
        @pagination:current-change="handleCurrentChange"
      >
        <template #post_id="{ row }">
          <div class="identity-cell">
            <span class="id-text">#{{ row.post_id }}</span>
            <span class="sub-text">{{ row.post_title }}</span>
          </div>
        </template>
        <template #member_id="{ row }">
          <div class="identity-cell">
            <span class="id-text">#{{ row.member_id }}</span>
            <span class="sub-text">{{ row.member_name }}</span>
          </div>
        </template>
        <template #content="{ row }">
          <ElTooltip :content="plainText(row.content)" placement="top">
            <span>{{ plainText(row.content).slice(0, 72) }}</span>
          </ElTooltip>
        </template>
        <template #audit_status="{ row }">
          <ElTag :type="auditStatusType(row.audit_status)">
            {{ auditStatusText(row.audit_status) }}
          </ElTag>
        </template>
        <template #ai_audit="{ row }">
          <AiAuditSummary :audit="row.ai_audit" compact />
        </template>
        <template #status="{ row }">
          <ElTag :type="row.status === 1 ? 'success' : 'info'">
            {{ row.status === 1 ? '正常' : '隐藏' }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <ElButton size="small" @click="openDetail(row)">查看</ElButton>
            <ElButton
              v-permission="'help:community:comment:aiAudit'"
              size="small"
              type="primary"
              :loading="aiAuditingId === row.id"
              @click="retryAiAudit(row)"
            >
              AI审核
            </ElButton>
            <ElButton
              v-if="row.audit_status !== 1"
              v-permission="'help:community:comment:audit'"
              size="small"
              type="success"
              @click="auditComment(row, 1)"
            >
              通过
            </ElButton>
            <ElButton
              v-if="row.audit_status !== 2"
              v-permission="'help:community:comment:audit'"
              size="small"
              type="warning"
              @click="auditComment(row, 2)"
            >
              隐藏
            </ElButton>
            <SaButton
              v-permission="'help:community:comment:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <ElDrawer v-model="detailVisible" size="60%" title="评论详情">
      <ElDescriptions :column="1" border>
        <ElDescriptionsItem label="评论ID">{{ detail.id }}</ElDescriptionsItem>
        <ElDescriptionsItem label="帖子"
          >#{{ detail.post_id }} {{ detail.post_title }}</ElDescriptionsItem
        >
        <ElDescriptionsItem label="会员"
          >#{{ detail.member_id }} {{ detail.member_name }}</ElDescriptionsItem
        >
        <ElDescriptionsItem label="父评论ID">{{ detail.parent_id }}</ElDescriptionsItem>
        <ElDescriptionsItem label="评论内容">
          <div class="content-text">{{ detail.content }}</div>
        </ElDescriptionsItem>
        <ElDescriptionsItem label="审核状态">
          {{ auditStatusText(detail.audit_status) }}
        </ElDescriptionsItem>
        <ElDescriptionsItem label="审核备注">{{ detail.audit_remark || '无' }}</ElDescriptionsItem>
        <ElDescriptionsItem label="AI审核结论">
          <AiAuditSummary :audit="detail.ai_audit" />
        </ElDescriptionsItem>
        <ElDescriptionsItem label="审核人">{{ detail.audit_by || '无' }}</ElDescriptionsItem>
        <ElDescriptionsItem label="审核时间">{{ detail.audit_time || '无' }}</ElDescriptionsItem>
        <ElDescriptionsItem label="审核日志">
          <AuditLogTimeline :logs="detail.audit_logs || []" />
        </ElDescriptionsItem>
        <ElDescriptionsItem label="创建时间">{{ detail.create_time }}</ElDescriptionsItem>
      </ElDescriptions>
    </ElDrawer>
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import AuditLogTimeline from '../../components/AuditLogTimeline.vue'
  import api from '../../api/community/comment'
  import TableSearch from './modules/table-search.vue'
  import AiAuditSummary from '../../components/AiAuditSummary.vue'

  const searchForm = ref({
    post_id: undefined,
    member_id: undefined,
    content: undefined,
    audit_status: undefined,
    status: undefined
  })

  const detailVisible = ref(false)
  const detail = ref<Record<string, any>>({})
  const aiAuditingId = ref<number | null>(null)

  const handleSearch = (params: Record<string, any>) => {
    Object.assign(searchParams, params)
    getData()
  }

  const {
    columns,
    columnChecks,
    data,
    loading,
    getData,
    searchParams,
    pagination,
    resetSearchParams,
    handleSortChange,
    handleSizeChange,
    handleCurrentChange,
    refreshData
  } = useTable({
    core: {
      apiFn: api.list,
      columnsFactory: () => [
        { type: 'selection' },
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'post_id', label: '帖子', minWidth: 220, useSlot: true },
        { prop: 'member_id', label: '会员', minWidth: 160, useSlot: true },
        { prop: 'content', label: '评论内容', minWidth: 280, useSlot: true },
        { prop: 'like_count', label: '点赞', width: 80 },
        { prop: 'audit_status', label: '审核', width: 110, useSlot: true },
        { prop: 'ai_audit', label: 'AI结论', minWidth: 210, useSlot: true },
        { prop: 'audit_by', label: '审核人', width: 100 },
        { prop: 'audit_time', label: '审核时间', width: 170 },
        { prop: 'status', label: '状态', width: 90, useSlot: true },
        { prop: 'create_time', label: '评论时间', width: 170 },
        { prop: 'operation', label: '操作', width: 310, fixed: 'right', useSlot: true }
      ]
    }
  })

  const { deleteRow, deleteSelectedRows, handleSelectionChange, selectedRows } = useSaiAdmin()

  const openDetail = async (row: Record<string, any>) => {
    detail.value = await api.read(row.id)
    detailVisible.value = true
  }

  const auditComment = async (row: Record<string, any>, auditStatus: number) => {
    let auditRemark = ''
    if (auditStatus === 2) {
      const result = await ElMessageBox.prompt('请输入隐藏原因', '审核评论', {
        inputType: 'textarea',
        inputValidator: (value) => String(value || '').trim() !== '' || '隐藏原因必须填写',
        confirmButtonText: '确定',
        cancelButtonText: '取消'
      })
      auditRemark = String(result.value || '').trim()
    } else {
      await ElMessageBox.confirm(`确定通过评论 #${row.id} 吗？`, '审核评论', { type: 'warning' })
    }
    await api.audit({ id: row.id, audit_status: auditStatus, audit_remark: auditRemark })
    ElMessage.success('审核成功')
    refreshData()
  }

  const retryAiAudit = async (row: Record<string, any>) => {
    await ElMessageBox.confirm(`确定重新提交评论 #${row.id} 进行AI审核吗？`, 'AI内容审核', {
      type: 'warning'
    })
    aiAuditingId.value = Number(row.id)
    try {
      await api.aiAudit(Number(row.id))
      ElMessage.success('AI审核任务已提交')
      refreshData()
    } finally {
      aiAuditingId.value = null
    }
  }

  const plainText = (content: string | undefined) => {
    return String(content || '')
      .replace(/<[^>]+>/g, '')
      .trim()
  }

  const auditStatusText = (status: number) => {
    const map: Record<number, string> = {
      0: '待审核',
      1: '已通过',
      2: '已拒绝',
      3: 'AI审核中'
    }
    return map[Number(status)] || '未知'
  }

  const auditStatusType = (status: number) => {
    const map: Record<number, 'success' | 'warning' | 'danger' | 'info'> = {
      0: 'warning',
      1: 'success',
      2: 'danger',
      3: 'warning'
    }
    return map[Number(status)] || 'info'
  }
</script>

<style scoped>
  .identity-cell {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
    line-height: 1.3;
  }

  .id-text {
    font-weight: 600;
    color: var(--el-text-color-primary);
  }

  .sub-text {
    max-width: 100%;
    overflow: hidden;
    color: var(--el-text-color-secondary);
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .content-text {
    white-space: pre-wrap;
    word-break: break-word;
  }
</style>
