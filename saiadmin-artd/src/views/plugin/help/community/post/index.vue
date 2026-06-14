<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-permission="'help:community:post:destroy'"
              :disabled="selectedRows.length === 0"
              @click="deleteSelectedRows(api.delete, refreshData)"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:delete-bin-5-line" />
              </template>
              删除
            </ElButton>
          </ElSpace>
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
        <template #content="{ row }">
          <ElTooltip :content="plainText(row.content)" placement="top">
            <span>{{ plainText(row.content).slice(0, 64) }}</span>
          </ElTooltip>
        </template>
        <template #audit_status="{ row }">
          <ElTag :type="auditStatusType(row.audit_status)">
            {{ auditStatusText(row.audit_status) }}
          </ElTag>
        </template>
        <template #status="{ row }">
          <ElTag :type="row.status === 1 ? 'success' : 'info'">
            {{ row.status === 1 ? '正常' : '隐藏' }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton type="success" @click="showViewDialog('view', row)" />
            <ElButton
              v-if="row.audit_status !== 1"
              v-permission="'help:community:post:audit'"
              size="small"
              type="success"
              @click="auditPost(row, 1)"
            >
              通过
            </ElButton>
            <ElButton
              v-if="row.audit_status !== 2"
              v-permission="'help:community:post:audit'"
              size="small"
              type="warning"
              @click="auditPost(row, 2)"
            >
              拒绝
            </ElButton>
            <SaButton
              v-permission="'help:community:post:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <ViewDialog v-model="viewDialogVisible" :dialog-type="dialogType" :data="viewDialogData" />
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/community/post'
  import TableSearch from './modules/table-search.vue'
  import ViewDialog from './modules/view-dialog.vue'

  const searchForm = ref({
    member_id: undefined,
    content: undefined,
    audit_status: undefined,
    status: undefined
  })

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
        { prop: 'member_id', label: '会员ID', width: 100 },
        { prop: 'content', label: '帖子内容', minWidth: 260, useSlot: true },
        { prop: 'view_count', label: '浏览', width: 80 },
        { prop: 'like_count', label: '点赞', width: 80 },
        { prop: 'comment_count', label: '评论', width: 80 },
        { prop: 'audit_status', label: '审核', width: 110, useSlot: true },
        { prop: 'status', label: '状态', width: 90, useSlot: true },
        { prop: 'create_time', label: '发布时间', width: 170 },
        { prop: 'operation', label: '操作', width: 230, fixed: 'right', useSlot: true }
      ]
    }
  })

  const { dialogType, deleteRow, deleteSelectedRows, handleSelectionChange, selectedRows } =
    useSaiAdmin()

  // 查看详情
  const {
    showDialog: showViewDialog,
    dialogVisible: viewDialogVisible,
    dialogData: viewDialogData
  } = useSaiAdmin()

  const auditPost = async (row: Record<string, any>, auditStatus: number) => {
    let auditRemark = ''
    if (auditStatus === 2) {
      const result = await ElMessageBox.prompt('请输入拒绝原因', '拒绝帖子', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: '必填',
        inputValidator: (value) => String(value || '').trim() !== '' || '请输入拒绝原因'
      })
      auditRemark = String(result.value || '').trim()
    } else {
      await ElMessageBox.confirm(`确定通过帖子 #${row.id} 吗？`, '审核帖子', {
        type: 'warning'
      })
    }
    await api.audit({ id: row.id, audit_status: auditStatus, audit_remark: auditRemark })
    ElMessage.success('审核成功')
    refreshData()
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
      3: 'AI标记'
    }
    return map[Number(status)] || '未知'
  }

  const auditStatusType = (status: number) => {
    const map: Record<number, 'primary' | 'success' | 'warning' | 'danger' | 'info'> = {
      0: 'warning',
      1: 'success',
      2: 'danger',
      3: 'info'
    }
    return map[Number(status)] || 'info'
  }
</script>
