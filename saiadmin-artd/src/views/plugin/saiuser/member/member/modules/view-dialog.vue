<template>
  <el-dialog
    v-model="visible"
    fullscreen
    append-to-body
    destroy-on-close
    :show-close="false"
    class="member-view-dialog"
    @closed="handleClosed"
  >
    <template #header>
      <div class="member-view-header">
        <div class="member-view-identity">
          <el-avatar :src="formData.avatar" :size="56">
            {{ (formData.nickname || formData.username || '会').slice(0, 1) }}
          </el-avatar>
          <div>
            <div class="member-view-name">
              {{ formData.nickname || formData.username || '未命名会员' }}
              <el-tag size="small" :type="identityTagType">{{ formData.identity_text || '患者' }}</el-tag>
              <sa-dict :value="formData.status" dict="data_status" render="tag" />
            </div>
            <div class="member-view-meta">
              #{{ formData.id }} · {{ formData.username || '-' }} · {{ formData.mobile || formData.email || '未绑定联系方式' }}
            </div>
          </div>
        </div>
        <el-button @click="visible = false">关闭</el-button>
      </div>
    </template>

    <div v-loading="pageLoading" class="member-view-layout">
      <aside class="member-view-nav">
        <button
          v-for="item in navItems"
          :key="item.key"
          class="member-view-nav-item"
          :class="{ active: activeTab === item.key }"
          type="button"
          @click="activeTab = item.key"
        >
          <span>{{ item.label }}</span>
          <el-badge v-if="item.count !== undefined" :value="item.count" :max="999" />
        </button>
      </aside>

      <section class="member-view-content">
        <template v-if="activeTab === 'profile'">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="用户名">{{ formData.username || '-' }}</el-descriptions-item>
            <el-descriptions-item label="用户昵称">{{ formData.nickname || '-' }}</el-descriptions-item>
            <el-descriptions-item label="用户身份">{{ formData.identity_text || '-' }}</el-descriptions-item>
            <el-descriptions-item label="资料身份">{{ formData.profile_role_text || '-' }}</el-descriptions-item>
            <el-descriptions-item label="当前生效身份">{{ formData.current_role_text || '-' }}</el-descriptions-item>
            <el-descriptions-item label="医生审核状态">{{ formData.doctor_audit_status_text || '-' }}</el-descriptions-item>
            <el-descriptions-item v-if="showDoctorsTab" :span="2" label="当前绑定医生">
              <div v-if="boundDoctors.length" class="bind-list">
                <el-tag v-for="item in boundDoctors" :key="item.id" type="success" class="bind-tag">
                  {{ doctorBindText(item) }}
                </el-tag>
              </div>
              <span v-else>未绑定医生</span>
            </el-descriptions-item>
            <el-descriptions-item v-if="showPatientsTab" :span="2" label="当前绑定患者">
              <div v-if="boundPatients.length" class="bind-list">
                <el-tag v-for="item in boundPatients" :key="item.id" type="primary" class="bind-tag">
                  {{ displayName(item.member_nickname, item.member_username, item.member_id) }}
                </el-tag>
              </div>
              <span v-else>暂无绑定患者</span>
            </el-descriptions-item>
            <el-descriptions-item label="性别">{{ genderText(memberProfile.gender) }}</el-descriptions-item>
            <el-descriptions-item label="生日">{{ memberProfile.birthday || '-' }}</el-descriptions-item>
            <el-descriptions-item :span="2" label="个人简介">{{ memberProfile.bio || '-' }}</el-descriptions-item>
            <el-descriptions-item :span="2" label="康复目标">{{ memberProfile.recovery_goal || '-' }}</el-descriptions-item>
            <el-descriptions-item label="邮箱">{{ formData.email || '-' }}</el-descriptions-item>
            <el-descriptions-item label="手机">{{ formData.mobile || '-' }}</el-descriptions-item>
            <el-descriptions-item label="会员等级">{{ formData.level_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="注册平台">{{ formData.platform_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="积分余额">{{ formData.points_balance ?? 0 }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <sa-dict :value="formData.status" dict="data_status" render="span" />
            </el-descriptions-item>
            <el-descriptions-item label="最后登录IP">{{ formData.last_login_ip || '-' }}</el-descriptions-item>
            <el-descriptions-item label="最后登录时间">{{ formData.last_login_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="语言">{{ memberProfile.locale || '-' }}</el-descriptions-item>
            <el-descriptions-item label="时区">{{ memberProfile.timezone || '-' }}</el-descriptions-item>
          </el-descriptions>
        </template>

        <template v-else-if="activeTab === 'doctor'">
          <el-empty v-if="!hasDoctorProfile" description="该会员尚未提交医生资质资料" />
          <template v-else>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="真实姓名">{{ doctorProfile.real_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="职称">{{ doctorProfile.title || '-' }}</el-descriptions-item>
              <el-descriptions-item label="医院/机构">{{ doctorProfile.hospital || '-' }}</el-descriptions-item>
              <el-descriptions-item label="科室">{{ doctorProfile.department || '-' }}</el-descriptions-item>
              <el-descriptions-item :span="2" label="专业方向">{{ doctorProfile.specialty || '-' }}</el-descriptions-item>
              <el-descriptions-item label="执业证书编号">{{ doctorProfile.license_no || '-' }}</el-descriptions-item>
              <el-descriptions-item label="审核状态">
                <el-tag :type="auditStatusType(doctorProfile.audit_status)">
                  {{ doctorAuditText(doctorProfile.audit_status) }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="账号状态">
                <el-tag :type="Number(doctorProfile.status) === 1 ? 'success' : 'info'">
                  {{ Number(doctorProfile.status) === 1 ? '正常' : '禁用' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="审核人">{{ doctorProfile.audit_by_display || '-' }}</el-descriptions-item>
              <el-descriptions-item label="审核时间">{{ doctorProfile.audit_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="通过时间">{{ doctorProfile.approved_time || '-' }}</el-descriptions-item>
              <el-descriptions-item :span="2" label="审核备注">{{ doctorProfile.audit_remark || '-' }}</el-descriptions-item>
              <el-descriptions-item :span="2" label="证书图片">
                <el-space v-if="certificationImages.length" wrap>
                  <el-image
                    v-for="image in certificationImages"
                    :key="image"
                    :src="image"
                    :preview-src-list="certificationImages"
                    fit="cover"
                    class="certification-image"
                  />
                </el-space>
                <span v-else>暂无</span>
              </el-descriptions-item>
            </el-descriptions>
            <div class="mt-4">
              <div class="section-title">审核日志</div>
              <AuditLogTimeline :logs="doctorProfile.audit_logs || []" />
            </div>
          </template>
        </template>

        <template v-else>
          <div v-if="activeTab === 'comments'" class="mb-3">
            <el-radio-group v-model="commentSource">
              <el-radio-button value="comments">社区评论 ({{ counts.comments || 0 }})</el-radio-button>
              <el-radio-button value="material_comments">
                素材评论 ({{ counts.material_comments || 0 }})
              </el-radio-button>
            </el-radio-group>
          </div>
          <div v-else-if="activeTab === 'collects'" class="mb-3">
            <el-radio-group v-model="collectSource">
              <el-radio-button value="post_collects">帖子收藏 ({{ counts.post_collects || 0 }})</el-radio-button>
              <el-radio-button value="material_collects">
                素材收藏 ({{ counts.material_collects || 0 }})
              </el-radio-button>
            </el-radio-group>
          </div>
          <div v-else-if="activeTab === 'plans'" class="mb-3">
            <el-radio-group v-model="planSource">
              <el-radio-button value="plans">作为患者 ({{ counts.plans || 0 }})</el-radio-button>
              <el-radio-button v-if="showDoctorNav" value="doctor_plans">
                作为医生 ({{ counts.doctor_plans || 0 }})
              </el-radio-button>
            </el-radio-group>
          </div>

          <RelatedTable
            v-model:page="relatedPage"
            v-model:limit="relatedLimit"
            :data="relatedList"
            :columns="currentColumns"
            :loading="relatedLoading"
            :total="relatedTotal"
            @change="onRelatedPageChange"
          >
            <template #content="{ row }">
              {{ plainText(row.content) }}
            </template>
            <template #target="{ row }">
              {{ plainText(row.target_content) }}
            </template>
            <template #audit="{ row }">
              <el-tag :type="currentAuditType(row.audit_status)">
                {{
                  relatedType === 'materials'
                    ? materialAuditText(row.audit_status)
                    : communityAuditText(row.audit_status)
                }}
              </el-tag>
            </template>
            <template #status="{ row }">
              <el-tag :type="Number(row.status) === 1 ? 'success' : 'info'">
                {{ statusText(row.status) }}
              </el-tag>
            </template>
            <template #planStatus="{ row }">
              <el-tag :type="planStatusType(row.status)">{{ planStatusText(row.status) }}</el-tag>
            </template>
            <template #member="{ row }">
              {{ displayName(row.member_nickname, row.member_username, row.member_id) }}
            </template>
            <template #doctor="{ row }">
              {{ displayName(row.doctor_nickname, row.doctor_username, row.doctor_id) }}
            </template>
            <template #score="{ row }">{{ row.achieved_score ?? 0 }} / {{ row.total_score ?? 0 }}</template>
            <template #loginResult="{ row }">
              <el-tag :type="row.login_result === 1 ? 'success' : 'danger'">
                {{ row.login_result === 1 ? '成功' : '失败' }}
              </el-tag>
            </template>
            <template #changeType="{ row }">
              <el-tag :type="changeTypeTag(row.change_type)">{{ changeTypeText(row.change_type) }}</el-tag>
            </template>
            <template #bindStatus="{ row }">
              <el-tag :type="Number(row.status) === 1 ? 'success' : 'info'">
                {{ Number(row.status) === 1 ? '绑定中' : '已解绑' }}
              </el-tag>
            </template>
            <template #bindSource="{ row }">{{ bindSourceText(row.bind_source) }}</template>
            <template #appointStatus="{ row }">
              <el-tag :type="appointStatusType(row.status)">{{ appointStatusText(row.status) }}</el-tag>
            </template>
            <template #materialType="{ row }">{{ materialTypeText(row.material_type) }}</template>
          </RelatedTable>
        </template>
      </section>
    </div>
  </el-dialog>
</template>

<script setup lang="ts">
  import api from '../../../api/member/member'
  import AuditLogTimeline from '../../../../help/components/AuditLogTimeline.vue'
  import RelatedTable, { type RelatedColumn } from './related-table.vue'

  type TagType = 'success' | 'warning' | 'info' | 'danger' | 'primary'

  interface Props {
    modelValue: boolean
    dialogType: string
    data?: Record<string, any>
  }

  const props = withDefaults(defineProps<Props>(), {
    modelValue: false,
    dialogType: 'view',
    data: undefined
  })

  const emit = defineEmits<{
    (e: 'update:modelValue', value: boolean): void
    (e: 'success'): void
  }>()

  const visible = computed({
    get: () => props.modelValue,
    set: (value) => emit('update:modelValue', value)
  })

  const pageLoading = ref(false)
  const activeTab = ref('profile')
  const commentSource = ref('comments')
  const collectSource = ref('post_collects')
  const planSource = ref('plans')
  const relatedList = ref<Record<string, any>[]>([])
  const relatedTotal = ref(0)
  const relatedPage = ref(1)
  const relatedLimit = ref(10)
  const relatedLoading = ref(false)

  const initialFormData = {
    id: null as number | null,
    username: '',
    nickname: '',
    identity_text: '',
    profile_role: '',
    profile_role_text: '',
    current_role: '',
    current_role_text: '',
    doctor_audit_status: null as number | null,
    doctor_audit_status_text: '',
    avatar: '',
    email: '',
    mobile: '',
    level_name: '',
    platform_name: '',
    points_balance: 0,
    last_login_ip: '',
    last_login_time: '',
    status: 1,
    member_profile: {} as Record<string, any>,
    doctor_profile: {} as Record<string, any>,
    related_counts: {} as Record<string, number>,
    bound_doctors: [] as Record<string, any>[],
    bound_patients: [] as Record<string, any>[]
  }

  const formData = reactive({ ...initialFormData })
  const memberProfile = computed(() => formData.member_profile || {})
  const doctorProfile = computed(() => formData.doctor_profile || {})
  const counts = computed(() => formData.related_counts || {})
  const hasDoctorProfile = computed(() => Number(doctorProfile.value.id || 0) > 0)
  const showDoctorNav = computed(
    () => formData.profile_role === 'doctor' || hasDoctorProfile.value
  )
  const showDoctorsTab = computed(
    () => formData.current_role === 'patient' || formData.profile_role !== 'doctor'
  )
  const showPatientsTab = computed(() => showDoctorNav.value)
  const boundDoctors = computed(() => formData.bound_doctors || [])
  const boundPatients = computed(() => formData.bound_patients || [])
  const identityTagType = computed<TagType>(() => {
    if (formData.identity_text === '医生') return 'success'
    if (formData.identity_text === '医生待审核') return 'warning'
    if (formData.identity_text === '医生已拒绝') return 'danger'
    return 'info'
  })
  const certificationImages = computed(() =>
    parseImageList(doctorProfile.value.certification_image_urls || doctorProfile.value.certification_images).map(
      normalizeImageUrl
    )
  )

  const navItems = computed(() => {
    const items = [
      { key: 'profile', label: '基本信息' },
      ...(showDoctorNav.value ? [{ key: 'doctor', label: '医生资料' }] : []),
      ...(showDoctorsTab.value
        ? [{ key: 'doctors', label: '绑定医生', count: counts.value.doctors || 0 }]
        : []),
      ...(showPatientsTab.value
        ? [{ key: 'patients', label: '绑定患者', count: counts.value.patients || 0 }]
        : []),
      { key: 'posts', label: '帖子', count: counts.value.posts || 0 },
      {
        key: 'comments',
        label: '评论',
        count: (counts.value.comments || 0) + (counts.value.material_comments || 0)
      },
      { key: 'materials', label: '素材', count: counts.value.materials || 0 },
      {
        key: 'collects',
        label: '收藏',
        count: (counts.value.post_collects || 0) + (counts.value.material_collects || 0)
      },
      {
        key: 'plans',
        label: '计划',
        count: (counts.value.plans || 0) + (showDoctorNav.value ? counts.value.doctor_plans || 0 : 0)
      },
      { key: 'assessments', label: '评估表', count: counts.value.assessments || 0 },
      { key: 'appointments', label: '预约', count: counts.value.appointments || 0 },
      { key: 'login_logs', label: '登录日志', count: counts.value.login_logs || 0 },
      { key: 'points_logs', label: '积分日志', count: counts.value.points_logs || 0 }
    ]
    return items
  })

  const relatedType = computed(() => {
    if (activeTab.value === 'comments') return commentSource.value
    if (activeTab.value === 'collects') return collectSource.value
    if (activeTab.value === 'plans') return planSource.value
    return activeTab.value
  })

  const currentColumns = computed<RelatedColumn[]>(() => {
    const map: Record<string, RelatedColumn[]> = {
      posts: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'content', label: '帖子内容', minWidth: 260, slot: 'content' },
        { prop: 'view_count', label: '浏览', width: 80 },
        { prop: 'like_count', label: '点赞', width: 80 },
        { prop: 'comment_count', label: '评论', width: 80 },
        { prop: 'audit_status', label: '审核', width: 100, slot: 'audit' },
        { prop: 'status', label: '状态', width: 90, slot: 'status' },
        { prop: 'create_time', label: '发布时间', width: 170 }
      ],
      comments: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'post_id', label: '帖子ID', width: 90 },
        { prop: 'target_content', label: '所属帖子', minWidth: 180, slot: 'target' },
        { prop: 'content', label: '评论内容', minWidth: 220, slot: 'content' },
        { prop: 'audit_status', label: '审核', width: 100, slot: 'audit' },
        { prop: 'create_time', label: '评论时间', width: 170 }
      ],
      material_comments: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'target_title', label: '素材标题', minWidth: 180 },
        { prop: 'content', label: '评论内容', minWidth: 240, slot: 'content' },
        { prop: 'audit_status', label: '审核', width: 100, slot: 'audit' },
        { prop: 'create_time', label: '评论时间', width: 170 }
      ],
      materials: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'title', label: '素材标题', minWidth: 200 },
        { prop: 'material_type', label: '类型', width: 100, slot: 'materialType' },
        { prop: 'media_type', label: '媒介', width: 90 },
        { prop: 'audit_status', label: '审核', width: 100, slot: 'audit' },
        { prop: 'status', label: '状态', width: 90, slot: 'status' },
        { prop: 'create_time', label: '创建时间', width: 170 }
      ],
      post_collects: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'post_id', label: '帖子ID', width: 90 },
        { prop: 'target_content', label: '帖子内容', minWidth: 280, slot: 'target' },
        { prop: 'create_time', label: '收藏时间', width: 170 }
      ],
      material_collects: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'material_id', label: '素材ID', width: 90 },
        { prop: 'target_title', label: '素材标题', minWidth: 240 },
        { prop: 'material_type', label: '类型', width: 100, slot: 'materialType' },
        { prop: 'create_time', label: '收藏时间', width: 170 }
      ],
      plans: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'title', label: '计划标题', minWidth: 180 },
        { prop: 'member_id', label: '患者', minWidth: 140, slot: 'member' },
        { prop: 'doctor_id', label: '医生', minWidth: 140, slot: 'doctor' },
        { prop: 'start_date', label: '开始', width: 120 },
        { prop: 'end_date', label: '结束', width: 120 },
        { prop: 'status', label: '状态', width: 100, slot: 'planStatus' },
        { prop: 'create_time', label: '创建时间', width: 170 }
      ],
      doctor_plans: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'title', label: '计划标题', minWidth: 180 },
        { prop: 'member_id', label: '患者', minWidth: 140, slot: 'member' },
        { prop: 'start_date', label: '开始', width: 120 },
        { prop: 'end_date', label: '结束', width: 120 },
        { prop: 'status', label: '状态', width: 100, slot: 'planStatus' },
        { prop: 'create_time', label: '创建时间', width: 170 }
      ],
      assessments: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'assessment_title', label: '量表名称', minWidth: 180 },
        { prop: 'task_title', label: '任务标题', minWidth: 160 },
        { prop: 'score', label: '得分', width: 100, slot: 'score' },
        { prop: 'result_level', label: '等级', width: 100 },
        { prop: 'assessed_at', label: '评估时间', width: 170 }
      ],
      appointments: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'appoint_date', label: '预约日期', width: 120 },
        { prop: 'appoint_time_slot', label: '时段', width: 140 },
        { prop: 'member_id', label: '患者', minWidth: 140, slot: 'member' },
        { prop: 'doctor_id', label: '医生', minWidth: 140, slot: 'doctor' },
        { prop: 'status', label: '状态', width: 100, slot: 'appointStatus' },
        { prop: 'create_time', label: '创建时间', width: 170 }
      ],
      patients: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'member_id', label: '患者', minWidth: 180, slot: 'member' },
        { prop: 'member_mobile', label: '手机', width: 130 },
        { prop: 'status', label: '绑定状态', width: 100, slot: 'bindStatus' },
        { prop: 'bind_source', label: '来源', width: 110, slot: 'bindSource' },
        { prop: 'bind_time', label: '绑定时间', width: 170 },
        { prop: 'unbind_time', label: '解绑时间', width: 170 }
      ],
      doctors: [
        { prop: 'id', label: 'ID', width: 80 },
        { prop: 'doctor_id', label: '医生', minWidth: 160, slot: 'doctor' },
        { prop: 'real_name', label: '真实姓名', width: 120 },
        { prop: 'title', label: '职称', width: 100 },
        { prop: 'hospital', label: '医院/机构', minWidth: 160 },
        { prop: 'department', label: '科室', width: 120 },
        { prop: 'status', label: '绑定状态', width: 100, slot: 'bindStatus' },
        { prop: 'bind_source', label: '来源', width: 110, slot: 'bindSource' },
        { prop: 'bind_time', label: '绑定时间', width: 170 }
      ],
      login_logs: [
        { prop: 'create_time', label: '登录时间', width: 180 },
        { prop: 'platform_name', label: '登录平台', width: 120 },
        { prop: 'login_ip', label: '登录IP', width: 150 },
        { prop: 'login_location', label: '登录地点', minWidth: 140 },
        { prop: 'login_result', label: '结果', width: 90, slot: 'loginResult' },
        { prop: 'fail_reason', label: '失败原因', minWidth: 160 }
      ],
      points_logs: [
        { prop: 'create_time', label: '发生时间', width: 180 },
        { prop: 'change_type', label: '变动类型', width: 110, slot: 'changeType' },
        { prop: 'source_type', label: '来源类型', width: 140 },
        { prop: 'title', label: '积分标题', minWidth: 180 },
        { prop: 'points', label: '积分变动', width: 110 },
        { prop: 'balance_after', label: '变动后积分', width: 120 }
      ]
    }
    return map[relatedType.value] || []
  })

  watch(
    () => props.modelValue,
    (open) => {
      if (open) initPage()
    }
  )

  watch([activeTab, commentSource, collectSource, planSource], () => {
    relatedPage.value = 1
    if (activeTab.value !== 'profile' && activeTab.value !== 'doctor') {
      loadRelated()
    }
  })

  const initPage = async () => {
    Object.assign(formData, initialFormData)
    relatedList.value = []
    relatedTotal.value = 0
    relatedPage.value = 1
    activeTab.value = 'profile'
    commentSource.value = 'comments'
    collectSource.value = 'post_collects'
    planSource.value = 'plans'
    if (!props.data?.id) return

    pageLoading.value = true
    try {
      const resp = await api.read(props.data.id)
      const data = (resp as any).data || resp
      for (const key in formData) {
        if (data[key] != null) {
          ;(formData as any)[key] = data[key]
        }
      }
    } finally {
      pageLoading.value = false
    }
  }

  const onRelatedPageChange = (payload: { page: number; limit: number }) => {
    relatedPage.value = payload.page
    relatedLimit.value = payload.limit
    loadRelated()
  }

  const loadRelated = async () => {
    if (!formData.id) return
    relatedLoading.value = true
    try {
      const page = await api.related({
        id: formData.id,
        type: relatedType.value,
        page: relatedPage.value,
        limit: relatedLimit.value
      })
      relatedList.value = Array.isArray(page) ? page : page?.data || []
      relatedTotal.value = Array.isArray(page) ? page.length : Number(page?.total || 0)
    } finally {
      relatedLoading.value = false
    }
  }

  const handleClosed = () => {
    relatedList.value = []
    relatedTotal.value = 0
  }

  const genderText = (value: unknown) => {
    return ({ 1: '男', 2: '女', 3: '保密' } as Record<string, string>)[String(value)] || '-'
  }

  const communityAuditText = (status: number) =>
    ({ 0: '待审核', 1: '已通过', 2: '已拒绝', 3: 'AI审核中' } as Record<number, string>)[Number(status)] ||
    '未知'

  const materialAuditText = (status: number) =>
    ({ 1: '待审核', 2: '已通过', 3: '已拒绝' } as Record<number, string>)[Number(status)] || '未知'

  const doctorAuditText = (status: number) =>
    ({ 0: '待审核', 1: '已通过', 2: '已拒绝' } as Record<number, string>)[Number(status)] || '未提交'

  const auditStatusType = (status: number): TagType => {
    const value = Number(status)
    if (value === 1) return 'success'
    if (value === 2) return 'danger'
    if (value === 3) return 'info'
    return 'warning'
  }

  const materialAuditType = (status: number): TagType => {
    const value = Number(status)
    if (value === 2) return 'success'
    if (value === 3) return 'danger'
    return 'warning'
  }

  const currentAuditType = (status: number): TagType => {
    return relatedType.value === 'materials' ? materialAuditType(status) : auditStatusType(status)
  }

  const statusText = (status: number) => {
    const value = Number(status)
    if (value === 1) return '正常'
    if (value === 2) return '隐藏'
    if (value === 3) return '封禁'
    return '未知'
  }

  const planStatusText = (value: number) =>
    ({ 1: '进行中', 2: '已完成', 3: '已终止' } as Record<number, string>)[Number(value)] || '未知'

  const planStatusType = (value: number): TagType =>
    ({ 1: 'success', 2: 'info', 3: 'warning' } as Record<number, TagType>)[Number(value)] || 'info'

  const appointStatusText = (value: number) =>
    ({ 0: '待确认', 1: '已确认', 2: '已完成', 3: '已取消', 4: '已拒绝' } as Record<number, string>)[
      Number(value)
    ] || '未知'

  const appointStatusType = (value: number): TagType =>
    ({ 0: 'warning', 1: 'success', 2: 'info', 3: 'info', 4: 'danger' } as Record<number, TagType>)[
      Number(value)
    ] || 'info'

  const materialTypeText = (value: string) =>
    ({ education: '教育素材', entertainment: '娱乐素材', private: '私人素材' } as Record<string, string>)[
      value
    ] || value || '-'

  const changeTypeText = (value: string) =>
    ({ income: '收入', expense: '支出', adjust: '调整' } as Record<string, string>)[value] || value || '-'

  const changeTypeTag = (value: string): TagType => {
    if (value === 'income') return 'success'
    if (value === 'expense') return 'warning'
    return 'info'
  }

  const displayName = (nickname?: string, username?: string, id?: number) => {
    const name = nickname || username
    if (name) return name
    return id ? `#${id}` : '-'
  }

  const doctorBindText = (item: Record<string, any>) => {
    const name = item.real_name || displayName(item.doctor_nickname, item.doctor_username, item.doctor_id)
    const hospital = [item.hospital, item.department, item.title].filter(Boolean).join(' / ')
    return hospital ? `${name}（${hospital}）` : name
  }

  const bindSourceText = (value: string) =>
    ({ manual: '手动', system: '系统', appointment: '预约' } as Record<string, string>)[value] ||
    value ||
    '-'

  const plainText = (content: string | undefined) =>
    String(content || '')
      .replace(/<[^>]+>/g, '')
      .trim() || '-'

  const parseImageList = (value: unknown): string[] => {
    if (!value) return []
    if (Array.isArray(value)) return value.map(String).filter(Boolean)
    if (typeof value !== 'string') return []
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean)
    } catch {
      return value ? [value] : []
    }
    return value ? [value] : []
  }

  const normalizeImageUrl = (url: string) => {
    if (!url) return ''
    if (/^(https?:)?\/\//.test(url) || url.startsWith('data:') || url.startsWith('blob:')) {
      return url
    }
    const base = import.meta.env.VITE_API_URL || ''
    if (url.startsWith('/') && base && base !== '/') {
      return `${base.replace(/\/$/, '')}${url}`
    }
    return url
  }
</script>

<style lang="scss" scoped>
  .member-view-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .member-view-identity {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .member-view-name {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 18px;
    font-weight: 600;
  }

  .member-view-meta {
    margin-top: 4px;
    color: var(--el-text-color-secondary);
  }

  .member-view-layout {
    display: flex;
    min-height: calc(100vh - 120px);
    gap: 16px;
  }

  .member-view-nav {
    width: 180px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    gap: 4px;
    padding-right: 8px;
    border-right: 1px solid var(--el-border-color-lighter);
  }

  .member-view-nav-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 10px 12px;
    border: 0;
    border-radius: 8px;
    background: transparent;
    color: var(--el-text-color-regular);
    cursor: pointer;
    text-align: left;
  }

  .member-view-nav-item.active {
    background: var(--el-color-primary-light-9);
    color: var(--el-color-primary);
    font-weight: 600;
  }

  .member-view-content {
    flex: 1;
    min-width: 0;
    overflow: auto;
  }

  .section-title {
    margin-bottom: 12px;
    font-weight: 600;
  }

  .bind-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }

  .bind-tag {
    max-width: 100%;
    height: auto;
    white-space: normal;
    line-height: 1.4;
  }

  .certification-image {
    width: 160px;
    height: 100px;
    border-radius: 6px;
  }

  :deep(.el-descriptions__label) {
    width: 140px;
  }
</style>
