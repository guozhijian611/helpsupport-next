import { createCrudApi } from '../createCrudApi'

export default createCrudApi('/app/help/admin/message/SaMemberMessage', [
  'markRead',
  'markPushed',
  'markFailed'
])
