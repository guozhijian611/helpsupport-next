<template>
  <div>
    <el-table v-loading="loading" :data="data" border stripe>
      <el-table-column
        v-for="column in columns"
        :key="column.prop"
        :prop="column.prop"
        :label="column.label"
        :width="column.width"
        :min-width="column.minWidth"
        :show-overflow-tooltip="column.showOverflowTooltip !== false"
      >
        <template v-if="column.slot" #default="scope">
          <slot :name="column.slot" v-bind="scope" />
        </template>
      </el-table-column>
    </el-table>
    <div class="related-table-pager">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        background
      />
    </div>
  </div>
</template>

<script setup lang="ts">
  export interface RelatedColumn {
    prop: string
    label: string
    width?: number
    minWidth?: number
    slot?: string
    showOverflowTooltip?: boolean
  }

  const props = withDefaults(
    defineProps<{
      data: Record<string, any>[]
      columns: RelatedColumn[]
      loading?: boolean
      total?: number
      page?: number
      limit?: number
    }>(),
    {
      data: () => [],
      columns: () => [],
      loading: false,
      total: 0,
      page: 1,
      limit: 10
    }
  )

  const emit = defineEmits<{
    (e: 'update:page', value: number): void
    (e: 'update:limit', value: number): void
    (e: 'change', payload: { page: number; limit: number }): void
  }>()

  const currentPage = computed({
    get: () => props.page,
    set: (value: number) => {
      emit('update:page', value)
      emit('change', { page: value, limit: props.limit })
    }
  })

  const pageSize = computed({
    get: () => props.limit,
    set: (value: number) => {
      emit('update:limit', value)
      emit('update:page', 1)
      emit('change', { page: 1, limit: value })
    }
  })
</script>

<style scoped>
  .related-table-pager {
    display: flex;
    justify-content: flex-end;
    margin-top: 16px;
  }
</style>
