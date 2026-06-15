import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(apiClientProvider));
});

final appointmentDoctorListProvider = FutureProvider.autoDispose
    .family<AppointmentPage<AppointmentDoctor>, AppointmentDoctorQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(appointmentRepositoryProvider)
          .fetchDoctors(
            keyword: query.keyword,
            page: query.page,
            pageSize: query.pageSize,
          );
    });

final appointmentDoctorDetailProvider = FutureProvider.autoDispose
    .family<AppointmentDoctor, int>((ref, doctorId) {
      return ref
          .watch(appointmentRepositoryProvider)
          .fetchDoctorDetail(doctorId);
    });

final appointmentSlotsProvider = FutureProvider.autoDispose
    .family<List<AppointmentSlot>, AppointmentSlotQuery>((ref, query) {
      return ref
          .watch(appointmentRepositoryProvider)
          .fetchSlots(doctorId: query.doctorId, date: query.date);
    });

final appointmentMineProvider = FutureProvider.autoDispose
    .family<AppointmentPage<AppointmentRecord>, AppointmentMineQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(appointmentRepositoryProvider)
          .fetchAppointments(
            status: query.status,
            page: query.page,
            pageSize: query.pageSize,
          );
    });
