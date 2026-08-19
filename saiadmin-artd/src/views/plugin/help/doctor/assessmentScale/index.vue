<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />

    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton
              v-permission="'help:doctor:assessmentScale:save'"
              @click="showDialog('add')"
              v-ripple
            >
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增
            </ElButton>
            <ElButton
              v-permission="'help:doctor:assessmentScale:destroy'"
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
        <template #title="{ row }">
          <div class="scale-title-cell">
            <strong>{{ row.title || '-' }}</strong>
            <span v-if="row.description">{{ row.description }}</span>
          </div>
        </template>
        <template #doctor_id="{ row }">
          <span v-if="!Number(row.doctor_id)">系统/未指定</span>
          <HelpRelationText v-else relation="doctor" :value="row.doctor_id" />
        </template>
        <template #stage="{ row }">
          <ElTag type="primary" effect="plain">{{ formatStage(row.stage) }}</ElTag>
        </template>
        <template #question_count="{ row }"> {{ questionCount(row.questions) }} 题 </template>
        <template #status="{ row }">
          <ElTag :type="statusTagType(row.status)">{{ formatStatus(row.status) }}</ElTag>
        </template>
        <template #operation="{ row }">
          <div class="help-row-actions">
            <ElButton size="small" @click="showViewDialog('view', row)">查看</ElButton>
            <ElButton
              v-permission="'help:doctor:assessmentScale:update'"
              size="small"
              type="primary"
              @click="showDialog('edit', row)"
            >
              编辑
            </ElButton>
            <ElButton
              v-if="row.status !== 'published'"
              v-permission="'help:doctor:assessmentScale:publish'"
              size="small"
              type="success"
              @click="runScaleAction('publish', row, '确定发布该评估量表吗？')"
            >
              发布
            </ElButton>
            <ElButton
              v-if="row.status !== 'disabled'"
              v-permission="'help:doctor:assessmentScale:disable'"
              size="small"
              type="warning"
              @click="runScaleAction('disable', row, '确定禁用该评估量表吗？')"
            >
              禁用
            </ElButton>
            <SaButton
              v-permission="'help:doctor:assessmentScale:destroy'"
              type="error"
              @click="deleteRow(row, api.delete, refreshData)"
            />
          </div>
        </template>
      </ArtTable>
    </ElCard>

    <EditDialog
      v-model="dialogVisible"
      :dialog-type="dialogType"
      :data="dialogData"
      @success="refreshData"
    />
    <ViewDialog v-model="viewDialogVisible" :data="viewDialogData" />
  </div>
</template>

<script setup lang="ts">
  import { ElMessage, ElMessageBox } from 'element-plus'
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/doctor/assessmentScale'
  import HelpRelationText from '../../components/HelpRelationText.vue'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'
  import ViewDialog from './modules/view-dialog.vue'
  import { formatStage, formatStatus, questionCount, statusTagType } from './modules/scaleHelpers'

  const searchForm = ref({
    title: undefined,
    doctor_id: undefined,
    stage: undefined,
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
        { prop: 'title', label: '量表名称', minWidth: 220, useSlot: true },
        { prop: 'doctor_id', label: '所属医生', minWidth: 150, useSlot: true },
        { prop: 'stage', label: '所属阶段', width: 110, useSlot: true },
        { prop: 'question_count', label: '题目', width: 80, useSlot: true },
        { prop: 'total_score', label: '总分', width: 80 },
        { prop: 'status', label: '状态', width: 100, useSlot: true },
        { prop: 'published_at', label: '发布时间', width: 170 },
        { prop: 'id', label: 'ID', width: 180 },
        { prop: 'operation', label: '操作', width: 320, fixed: 'right', useSlot: true }
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

  const {
    showDialog: showViewDialog,
    dialogVisible: viewDialogVisible,
    dialogData: viewDialogData
  } = useSaiAdmin()

  const runScaleAction = async (
    method: 'publish' | 'disable',
    row: Record<string, any>,
    message: string
  ) => {
    await ElMessageBox.confirm(message, method === 'publish' ? '发布量表' : '禁用量表', {
      type: 'warning'
    })
    await api[method]({ id: row.id })
    ElMessage.success('操作成功')
    refreshData()
  }
</script>

<style scoped>
  .scale-title-cell {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }

  .scale-title-cell strong {
    font-weight: 600;
    line-height: 1.4;
  }

  .scale-title-cell span {
    overflow: hidden;
    font-size: 12px;
    line-height: 1.4;
    color: var(--el-text-color-secondary);
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .help-row-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }
</style>
