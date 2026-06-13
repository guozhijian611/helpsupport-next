import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/plan_models.dart';
import '../data/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(apiClientProvider));
});

final currentPlansProvider = FutureProvider.autoDispose<List<TreatmentPlan>>((
  ref,
) {
  return ref.watch(planRepositoryProvider).fetchCurrentPlans();
});

final dailyTasksProvider = FutureProvider.autoDispose<PlanPage<DailyTask>>((
  ref,
) {
  return ref.watch(planRepositoryProvider).fetchTasks(date: _today());
});

final assessmentResultsProvider =
    FutureProvider.autoDispose<PlanPage<AssessmentResult>>((ref) {
      return ref.watch(planRepositoryProvider).fetchAssessmentResults();
    });

String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
