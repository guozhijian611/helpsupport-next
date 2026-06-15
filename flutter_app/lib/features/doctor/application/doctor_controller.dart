import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../plan/data/plan_models.dart';
import '../data/doctor_models.dart';
import '../data/doctor_repository.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(apiClientProvider));
});

final doctorPatientsProvider = FutureProvider.autoDispose
    .family<DoctorPage<DoctorPatient>, DoctorPatientsQuery>((ref, query) {
      return ref
          .watch(doctorRepositoryProvider)
          .fetchPatients(
            status: query.status,
            keyword: query.keyword,
            page: query.page,
            pageSize: query.pageSize,
          );
    });

final doctorDailyTasksProvider = FutureProvider.autoDispose
    .family<PlanPage<DailyTask>, DoctorDailyTasksQuery>((ref, query) {
      return ref
          .watch(doctorRepositoryProvider)
          .fetchDailyTasks(
            memberId: query.memberId,
            date: query.date,
            planId: query.planId,
          );
    });

final doctorPatientPlansProvider = FutureProvider.autoDispose
    .family<List<TreatmentPlan>, DoctorPatientPlansQuery>((ref, query) {
      return ref
          .watch(doctorRepositoryProvider)
          .fetchPatientPlans(memberId: query.memberId, status: query.status);
    });

final doctorTaskTemplateFoldersProvider =
    FutureProvider.autoDispose<List<DoctorTaskTemplateFolder>>((ref) {
      return ref.watch(doctorRepositoryProvider).fetchTaskTemplateFolders();
    });

final doctorTaskTemplatesProvider = FutureProvider.autoDispose
    .family<List<DoctorTaskTemplate>, DoctorTaskTemplatesQuery>((ref, query) {
      return ref
          .watch(doctorRepositoryProvider)
          .fetchTaskTemplates(
            folderId: query.folderId,
            stage: query.stage,
            status: query.status,
          );
    });

final doctorAssessmentScalesProvider = FutureProvider.autoDispose
    .family<List<DoctorAssessmentScale>, DoctorAssessmentScalesQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(doctorRepositoryProvider)
          .fetchAssessmentScales(stage: query.stage, status: query.status);
    });
