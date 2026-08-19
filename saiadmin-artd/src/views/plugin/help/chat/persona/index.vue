<template>
  <div class="art-full-height">
    <TableSearch v-model="searchForm" @search="handleSearch" @reset="resetSearchParams" />
    <ElAlert
      class="mb-4"
      type="info"
      show-icon
      :closable="false"
      title="这里配置 App 互动聊天的角色卡片"
      description="新增角色后，App 首页会按启用状态、标题、封面、标签和能力开关展示。实时音视频、ASR、TTS 都在角色上绑定，不要和模型测试台的对话混用。"
    />
    <ElCard class="art-table-card" shadow="never">
      <ArtTableHeader v-model:columns="columnChecks" :loading="loading" @refresh="refreshData">
        <template #left>
          <ElSpace wrap>
            <ElButton v-permission="'help:chat:persona:save'" @click="showDialog('add')" v-ripple>
              <template #icon>
                <ArtSvgIcon icon="ri:add-fill" />
              </template>
              新增角色
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
        @pagination:size-change="handleSizeChange"
        @pagination:current-change="handleCurrentChange"
      >
        <template #cover="{ row }">
          <ElAvatar v-if="row.cover || row.avatar" :size="38" :src="row.cover || row.avatar" />
          <span v-else>暂无</span>
        </template>
        <template #status="{ row }">
          <ElTag :type="Number(row.status) === 1 ? 'success' : 'info'">
            {{ Number(row.status) === 1 ? '启用' : '禁用' }}
          </ElTag>
        </template>
        <template #allow_realtime="{ row }">
          <ElTag :type="Number(row.allow_realtime) === 1 ? 'success' : 'info'">
            {{ Number(row.allow_realtime) === 1 ? '已开放' : '关闭' }}
          </ElTag>
        </template>
        <template #operation="{ row }">
          <div class="flex gap-2">
            <SaButton
              v-permission="'help:chat:persona:update'"
              type="secondary"
              @click="showDialog('edit', row)"
            />
            <SaButton
              v-if="Number(row.is_system) !== 1"
              v-permission="'help:chat:persona:destroy'"
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
  </div>
</template>

<script setup lang="ts">
  import { useTable } from '@/hooks/core/useTable'
  import { useSaiAdmin } from '@/composables/useSaiAdmin'
  import api from '../../api/chat/persona'
  import TableSearch from './modules/table-search.vue'
  import EditDialog from './modules/edit-dialog.vue'

  const searchForm = ref({
    code: undefined,
    status: undefined
  })

  const handleSearch = (params: Record<string, any>) => {
    Object.assign(searchParams, params)
    getData()
  }

  const { columns, columnChecks, data, loading, getData, searchParams, pagination, resetSearchParams, handleSortChange, handleSizeChange, handleCurrentChange, refreshData } =
    useTable({
      core: {
        apiFn: api.list,
        columnsFactory: () => [
          { prop: 'cover', label: '封面', width: 80, useSlot: true },
          { prop: 'code', label: '编码', width: 140 },
          { prop: 'display_name', label: '中文标题', minWidth: 140 },
          { prop: 'display_name_en', label: '英文标题', minWidth: 140 },
          { prop: 'allow_realtime', label: '实时', width: 90, useSlot: true },
          { prop: 'sort', label: '排序', width: 80 },
          { prop: 'status', label: '状态', width: 90, useSlot: true },
          { prop: 'operation', label: '操作', width: 140, fixed: 'right', useSlot: true }
        ]
      }
    })

  const { dialogType, dialogVisible, dialogData, showDialog, deleteRow } = useSaiAdmin()
</script>
