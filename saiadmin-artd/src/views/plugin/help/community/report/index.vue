<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-permission="'help:community:report:save'"
              @click="showDialog('add')"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:community:report:destroy'"
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
        <template #target_type="{ row }">
          <ElTag>{{ targetTypeText(row.target_type) }}</ElTag>
        </template>
        <template #handle_status="{ row }">
          <ElTag :type="handleStatusType(row.handle_status)">
            {{ handleStatusText(row.handle_status) }}
          </ElTag>
        </template>
        <template #description="{ row }">
          <ElTooltip :content="row.description || '无补充描述'" placement="top">
            <span>{{ String(row.description || '').slice(0, 48) || '无补充描述' }}</span>
          </ElTooltip>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <ElButton size="small" @click="openDetail(row)">查看</ElButton>
            <ElButton
              v-permission="'help:community:report:update'"
              size="small"
              type="primary"
              @click="showDialog('edit', row)"
            >
              编辑
            </ElButton>
            <ElButton
              v-if="row.handle_status === 0"
              v-permission="'help:community:report:handle'"
              size="small"
              type="success"
              @click="handleReport(row, 1)"
            >
              处理
            </ElButton>
            <ElButton
              v-if="row.handle_status === 0"
              v-permission="'help:community:report:handle'"
              size="small"
              type="info"
              @click="handleReport(row, 2)"
            >
              忽略
            </ElButton>
            <SaButton
              v-permission="'help:community:report:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <ElDrawer v-model="detailVisible" size="60%" title="举报详情">
      <ElDescriptions :column="1" border>
        <ElDescriptionsItem label="举报ID">{{ detail.id }}</ElDescriptionsItem>
        <ElDescriptionsItem label="举报会员">{{ detail.member_id }}</ElDescriptionsItem>
        <ElDescriptionsItem label="举报目标">
          {{ targetTypeText(detail.target_type) }} #{{ detail.target_id }}
        </ElDescriptionsItem>
        <ElDescriptionsItem label="原因">{{ detail.reason }}</ElDescriptionsItem>
        <ElDescriptionsItem label="描述">{{ detail.description || '无' }}</ElDescriptionsItem>
        <ElDescriptionsItem label="处理状态">
          {{ handleStatusText(detail.handle_status) }}
        </ElDescriptionsItem>
        <ElDescriptionsItem label="处理备注">{{ detail.handle_remark || '无' }}</ElDescriptionsItem>
        <ElDescriptionsItem label="举报时间">{{ detail.create_time }}</ElDescriptionsItem>
      </ElDescriptions>
    </ElDrawer>

    <EditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="refreshData"
    />
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/community/report'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'

  const searchForm = ref({
    member_id: undefined,
    target_type: undefined,
    target_id: undefined,
    reason: undefined,
    handle_status: undefined
  })

  const detailVisible = ref(false)
  const detail = ref<Record<string, any>>({})

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
        { prop: 'member_id', label: '举报会员', width: 100 },
        { prop: 'target_type', label: '目标类型', width: 100, useSlot: true },
        { prop: 'target_id', label: '目标ID', width: 100 },
        { prop: 'reason', label: '原因', width: 150 },
        { prop: 'description', label: '描述', minWidth: 220, useSlot: true },
        { prop: 'handle_status', label: '处理状态', width: 110, useSlot: true },
        { prop: 'handle_remark', label: '处理备注', minWidth: 180 },
        { prop: 'create_time', label: '举报时间', width: 170 },
        { prop: 'operation', label: '操作', width: 230, fixed: 'right', useSlot: true }
      ]
    }
  })

  const {
    dialogType,
    dialogVisible,
    dialogData,
    showDialog,
    deleteRow,
    deleteSelectedRows,
    handleSelectionChange,
    selectedRows
  } = useSaiAdmin()

  const openDetail = async (row: Record<string, any>) => {
    detail.value = await api.read(row.id)
    detailVisible.value = true
  }

  const handleReport = async (row: Record<string, any>, handleStatus: number) => {
    const result = await ElMessageBox.prompt(
      `请输入${handleStatus === 1 ? '处理' : '忽略'}备注`,
      handleStatus === 1 ? '处理举报' : '忽略举报',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: '可选'
      }
    )
    await api.handle({
      id: row.id,
      handle_status: handleStatus,
      handle_remark: String(result.value || '')
    })
    ElMessage.success('处理成功')
    refreshData()
  }

  const targetTypeText = (type: number) => {
    const map: Record<number, string> = {
      1: '帖子',
      2: '评论',
      3: '用户'
    }
    return map[Number(type)] || '未知'
  }

  const handleStatusText = (status: number) => {
    const map: Record<number, string> = {
      0: '待处理',
      1: '已处理',
      2: '已忽略'
    }
    return map[Number(status)] || '未知'
  }

  const handleStatusType = (status: number) => {
    const map: Record<number, 'success' | 'warning' | 'info'> = {
      0: 'warning',
      1: 'success',
      2: 'info'
    }
    return map[Number(status)] || 'info'
  }
</script>
