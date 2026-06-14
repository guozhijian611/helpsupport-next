import { createCrudApi } from '../createCrudApi'

export default createCrudApi('/app/help/admin/appointment/SaDoctorAppointment', [
  'confirm',
  'finish',
  'cancel',
  'reject'
])
